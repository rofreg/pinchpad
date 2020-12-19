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
#if canImport(FLEX)
//    import FLEX
#endif

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var canvasView: PKCanvasView!
    @IBOutlet var canvasContainerView: UIView! // Extra container needed to support transformation on canvasView
    @IBOutlet var undoButton: UIBarButtonItem!
    @IBOutlet var redoButton: UIBarButtonItem!
    let toolPicker = PKToolPicker.init()

    var realmNotificationToken: NotificationToken?
    var gestures: [UIGestureRecognizer]!

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToNotifications()
        AppConfig.shared.canvasView = canvasView
        navigationController?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        // Set up the tool picker
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder() // Show drawing tools

        // No undo/redo buttons necessary on iPad; they are included in the PKToolPicker
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems?.filter {
                $0 != undoButton && $0 != redoButton
            }
        }

        // Set the font for syncing messages in the nav bar
        navigationController?.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]

        updateStatusBar()

        // Set up gesture recognizers so we can pinch + pan + rotate the canvas
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotate))
        rotationGesture.delegate = self
        view.addGestureRecognizer(rotationGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 2
        view.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(scale))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)

        gestures = [rotationGesture, panGesture, pinchGesture]
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ViewController.updateGestures),
            name: NSNotification.Name(rawValue: "AllowGesturesDidChange"),
            object: nil
        )
        updateGestures()

        #if canImport(FLEX)
//            FLEXManager.shared.showExplorer()
        #endif
    }

    @objc func updateGestures() {
        for gesture in gestures {
            gesture.isEnabled = AppConfig.shared.allowGestures
        }
    }

    @objc func pan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        canvasContainerView.center = CGPoint(
          x: canvasContainerView.center.x + translation.x,
          y: canvasContainerView.center.y + translation.y
        )
        gesture.setTranslation(.zero, in: view)
    }

    @objc func rotate(_ gesture: UIRotationGestureRecognizer) {
        canvasContainerView.transform = canvasContainerView.transform.rotated(by: gesture.rotation)
        gesture.rotation = 0
    }

    @objc func scale(_ gesture: UIPinchGestureRecognizer) {
        canvasContainerView.transform = canvasContainerView.transform.scaledBy(
          x: gesture.scale,
          y: gesture.scale
        )
        gesture.scale = 1
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.view == view && otherGestureRecognizer.view == view
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
            return true
        }

        return canvasView.drawing.strokes.count == 0
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

            if let canvasImageData = canvasImage.pngData() {
                saveImageData(canvasImageData, animated: false)
            }
        }
    }

    func saveImageData(_ imageData: Data, animated: Bool) {
        // If we're not logged into any services, let's just share this using the native iOS dialog
        if !TwitterAccount.isLoggedIn && !TumblrAccount.isLoggedIn {
            // Dismiss any modals that are open
            dismiss(animated: true, completion: nil)

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
        resetCanvasPosition()

        AppConfig.shared.animationFrames = []
        dismiss(animated: true, completion: nil)
    }

    @IBAction func resetCanvasPosition() {
        canvasContainerView.transform = .identity

        // TODO: find a less hacky solution for this "reset translation" issue
        var newOrigin = view.frame.origin
        newOrigin.x -= 100
        newOrigin.y -= 100
        if let barHeight = navigationController?.navigationBar.frame.size.height,
           let statusBarheight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height {
            newOrigin.y += barHeight + statusBarheight
        }
        canvasContainerView.frame.origin = newOrigin
    }

    @IBAction func toggleToolPicker() {
        if canvasView.isFirstResponder {
            canvasView.resignFirstResponder()
        } else {
            canvasView.becomeFirstResponder()
        }
    }

    @IBAction func undo() {
        canvasView.undoManager?.undo()
    }

    @IBAction func redo() {
        canvasView.undoManager?.redo()
    }
}

// Force iPhone to use the popover style, rather than a modal window
extension ViewController: UIPopoverPresentationControllerDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let currentPopoverController = segue.destination
        currentPopoverController.modalPresentationStyle = .popover

        if let popoverPresentationController = currentPopoverController.popoverPresentationController {
            popoverPresentationController.delegate = self

            // Also set the popover arrow color to match the rest of the popover
            popoverPresentationController.backgroundColor = currentPopoverController.view.backgroundColor

            // Allow touches on the drawing view while the popover is open
            popoverPresentationController.passthroughViews = [canvasView]
        }
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension ViewController: UINavigationControllerDelegate {
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController)
      -> UIInterfaceOrientationMask {
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
