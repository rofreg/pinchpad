//
//  ViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/29/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import UIKit
import RealmSwift
import PencilKit

class ViewController: UIViewController {
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var canvasView: PKCanvasView!
    var currentPopoverController: UIViewController?

    var realmNotificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToNotifications()
        AppConfig.shared.canvasView = canvasView
        navigationController?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        // Set up the tool picker
        if let appDelegate = UIApplication.shared.delegate,
           let window = appDelegate.window!,
           let toolPicker = PKToolPicker.shared(for: window) {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder() // Show drawing tools
        }

        // Set the font for syncing messages in the nav bar
        navigationController?.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]

        updateStatusBar()
    }

    deinit {
        realmNotificationToken?.invalidate()
    }

    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.clear),
                                               name: NSNotification.Name(rawValue: "ClearCanvas"),
                                               object: nil)

        // Update the status bar after any database change
        let realm = try! Realm()
        realmNotificationToken = realm.observe { _, _ in
            self.updateStatusBar()
        }
    }

    func updateStatusBar() {
        let realm = try! Realm()
        let sketchesToSyncCount = realm.objects(Sketch.self).count

        if sketchesToSyncCount == 0 {
            title = ""
        } else if realm.objects(Sketch.self).filter("twitterSyncStarted != nil || tumblrSyncStarted != nil").count > 0 {
            title = "Syncing..."
        } else if sketchesToSyncCount == 1 {
            title = "1 unsynced sketch"
        } else {
            title = "\(sketchesToSyncCount) unsynced sketches"
        }
    }

    func canvasIsBlank() -> Bool {
        guard let canvasView = canvasView else {
            // If there's no drawing yet yet, we can rotate however we want
            return true
        }

        // PKCanvasView/PKDrawing don't let us directly check if a canvas is empty
        // So we have to compare against a blank image of the same size
        let canvasImageData = canvasView.drawing.image(from: canvasView.bounds, scale: 1.0).pngData()!
        let blankImageData = PKDrawing().image(from: canvasView.bounds, scale: 1.0).pngData()!

        return canvasImageData == blankImageData
    }

    @IBAction func post(_ sender: AnyObject) {
        // Don't post if we haven't drawn any strokes
        guard !canvasIsBlank() else {
            let alert = UIAlertController(
                title: "Your sketch is blank",
                message: "You haven't drawn anything yet, silly!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }

        if let animation = AppConfig.shared.animation {
            self.saveImageData(animation, animated: true)
        } else {
            // To prevent iPad drawings from getting too massive, let's export at a non-Retina resolution
            let scale = (canvasView.frame.width >= 768 ? 1.0 : UIScreen.main.scale)
            let canvasImage = canvasView.image(scale: scale)
            saveImageData(canvasImage.pngData()!, animated: false)
        }
    }

    func saveImageData(_ imageData: Data, animated: Bool) {
        // If we're not logged into any services, let's just share this using the native iOS dialog
        if !TwitterAccount.isLoggedIn && !TumblrAccount.isLoggedIn {
            dismissPopover()

            let viewController = UIActivityViewController(activityItems: [imageData], applicationActivities: nil)

            DispatchQueue.main.async {
                viewController.popoverPresentationController?.barButtonItem = self.postButton
                self.present(viewController, animated: true, completion: nil)
            }

            return
        }

        // If we ARE logged into services, we need to post the sketch to those services
        // We do this by saving Sketch records to the local database, then syncing them in the background
        let date = Date(), dateFormatter = DateFormatter(), timeFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        timeFormatter.dateFormat = "h:mma"
        let caption = "\(dateFormatter.string(from: date)), \(timeFormatter.string(from: date).lowercased())"

        let sketch = Sketch()
        sketch.caption = caption
        sketch.imageData = imageData

        if animated {
            sketch.imageType = "image/gif"
        }

        let realm = try! Realm()
        try! realm.write {
            realm.add(sketch)
        }

        // Now try to post the new Sketch
        sketch.post()

        // On the main thread, clear the drawing view
        DispatchQueue.main.async {
            self.clear()
        }
    }

    @objc func clear() {
        canvasView.drawing = PKDrawing()
        AppConfig.shared.animationFrames = []
        dismissPopover()
    }

    func dismissPopover() {
        if Thread.isMainThread {
            dismissPopoverOnCurrentThread()
        } else {
            DispatchQueue.main.async {
                self.dismissPopoverOnCurrentThread()
            }
        }
    }

    func dismissPopoverOnCurrentThread() {
        currentPopoverController?.dismiss(animated: false, completion: nil)
        currentPopoverController = nil
    }
}

// Force iPhone to use the popover style, rather than a modal window
extension ViewController: UIPopoverPresentationControllerDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        currentPopoverController = segue.destination
        currentPopoverController!.modalPresentationStyle = .popover

        if let popoverPresentationController = currentPopoverController!.popoverPresentationController {
            popoverPresentationController.delegate = self

            // Also set the popover arrow color to match the rest of the popover
            popoverPresentationController.backgroundColor = currentPopoverController!.view.backgroundColor

            // Allow touches on the drawing view while the popover is open
            popoverPresentationController.passthroughViews = [canvasView]
        }
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

// Dismiss popover controllers instantly, with no animation
extension ViewController: UIPopoverControllerDelegate {
    func popoverPresentationControllerShouldDismissPopover(_ controller: UIPopoverPresentationController) -> Bool {
        currentPopoverController?.dismiss(animated: false)
        return true
    }

    func popoverPresentationControllerDidDismissPopover(_ _: UIPopoverPresentationController) {
        currentPopoverController = nil
    }
}

extension ViewController: UINavigationControllerDelegate {
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        // Allow free rotation when the canvas is blank and the platform is iPad
        if canvasIsBlank() {
            return .all
        }

        // Once we start drawing, don't allow rotation between landscape and portrait
        // (It would distort the drawing view)
        if UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isPortrait ?? false {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .landscape
        }
    }
}
