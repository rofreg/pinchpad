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
    @IBOutlet var undoButton: UIBarButtonItem!
    @IBOutlet var redoButton: UIBarButtonItem!
    @IBOutlet var pencilButton: UIBarButtonItem!
    @IBOutlet var eraserButton: UIBarButtonItem!
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var canvasView: PKCanvasView!
    @IBOutlet var statusBarLabel: UILabel!
    var currentPopoverController: UIViewController?

    var realmNotificationToken: NotificationToken?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Allow free rotation when the canvas is blank and the platform is iPad
        if canvasIsBlank() {
            return .all
        }

        // Once we start drawing, don't allow rotation between landscape and portrait
        // (It would distort the drawing view)
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft, .landscapeRight:
            return .landscape
        default:
            return [.portrait, .portraitUpsideDown]
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        view.layoutIfNeeded()
        self.view.bringSubviewToFront(statusBarLabel)

        updateStatusBar()
    }

    deinit {
        realmNotificationToken?.invalidate()
    }

    func subscribeToNotifications() {
        // When our tool changes, update the display
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.updateToolbarDisplay),
                                               name: NSNotification.Name(rawValue: "ToolConfigChanged"),
                                               object: nil)
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

    @objc func updateToolbarDisplay() {
        if AppConfig.shared.tool == .eraser {
            pencilButton.tintColor = UIColor.lightGray
            eraserButton.tintColor = self.view.tintColor
        } else {
            pencilButton.tintColor = self.view.tintColor
            eraserButton.tintColor = UIColor.lightGray
        }
    }

    func updateStatusBar() {
        let realm = try! Realm()
        self.statusBarLabel.isHidden = realm.objects(Sketch.self).count == 0
        if realm.objects(Sketch.self).filter("twitterSyncStarted != nil || tumblrSyncStarted != nil").count > 0 {
            statusBarLabel.text = "Syncing..."
        } else {
            statusBarLabel.text = "\(realm.objects(Sketch.self).count) sketches pending sync"
        }
    }

    @IBAction func undo() {
//        jotView.undo()
    }

    @IBAction func redo() {
//        jotView.redo()
    }

    func canvasIsBlank() -> Bool {
        return false
        
        guard let canvasView = canvasView else {
            // If the JotView isn't initialized yet, we can rotate however we want
            return true
        }

//        return jotView.state.everyVisibleStroke().count == 0
        return false
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
//            let scale = (jotView.frame.width >= 768 ? 1.0 : UIScreen.main.scale)
//            jotView.exportToImage(onComplete: self.saveImage, withScale: scale)
        }
    }

    func saveImage(_ image: UIImage?) {
        guard let image = image, let imageData = image.pngData() else {
            return
        }

        saveImageData(imageData, animated: false)
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

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // There's a weird boolean bug here, so let's force this explicitly to be 'true' or 'false'
        let toolPopoverWasOpen = currentPopoverController is ToolConfigViewController ? true : false
        dismissPopover()

        if identifier == "EraserSegue" && AppConfig.shared.tool != .eraser {
            AppConfig.shared.tool = .eraser

            // If the tool config view was already open, then let's re-open it
            return toolPopoverWasOpen
        } else if identifier == "PencilSegue" && AppConfig.shared.tool == .eraser {
            AppConfig.shared.tool = .pen

            // If the tool config view was already open, then let's re-open it
            return toolPopoverWasOpen
        }

        return true
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
            popoverPresentationController.passthroughViews = [] // jotView
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
        // Fixes a tint color bug when switching between pencil and eraser tools w/ a popover open
        updateToolbarDisplay()

        currentPopoverController = nil
    }
}
