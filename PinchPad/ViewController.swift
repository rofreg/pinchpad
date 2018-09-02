//
//  ViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/29/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {
    @IBOutlet var undoButton: UIBarButtonItem!
    @IBOutlet var redoButton: UIBarButtonItem!
    @IBOutlet var pencilButton: UIBarButtonItem!
    @IBOutlet var eraserButton: UIBarButtonItem!
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var jotView: JotView!
    @IBOutlet var statusBarLabel: UILabel!
    var jotViewStateProxy: JotViewStateProxy!
    var currentPopoverController: UIViewController?

    var realmNotificationToken: NotificationToken?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Allow free rotation when the canvas is blank and the platform is iPad
        if canvasIsBlank() && UIScreen.main.portraitBounds().width >= 768 {
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
        // Set up the jotView for drawing
        // For some reason, JotViews don't like to be included via Interface Builder, so we redo ours here
        view.layoutIfNeeded()
        jotView.removeFromSuperview()
        jotView.invalidate()

        jotView = JotView(frame: jotView.frame)
        jotView.delegate = self
        self.view.addSubview(jotView)
        self.view.bringSubview(toFront: statusBarLabel)

        jotViewStateProxy = JotViewStateProxy()
        jotViewStateProxy.delegate = self
        jotViewStateProxy.loadJotStateAsynchronously(false,
                                                     with: jotView.bounds.size,
                                                     andScale: UIScreen.main.scale,
                                                     andContext: jotView.context,
                                                     andBufferManager: JotBufferManager.sharedInstance())
        jotViewStateProxy.undoLimit = 20
        jotView.loadState(jotViewStateProxy)

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

    func updateToolbarDisplay() {
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
        jotView.undo()
    }

    @IBAction func redo() {
        jotView.redo()
    }

    func canvasIsBlank() -> Bool {
        guard let jotView = jotView else {
            // If the JotView isn't initialized yet, we can rotate however we want
            return true
        }

        return jotView.state.everyVisibleStroke().count == 0
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

        // To prevent iPad drawings from getting too massive, let's export at a non-Retina resolution
        let scale = (jotView.frame.width >= 768 ? 1.0 : UIScreen.main.scale)
        jotView.exportToImage(onComplete: self.saveImage, withScale: scale)
    }

    func saveImage(_ image: UIImage?) {
        guard let image = image else {
            return
        }

        let imageData = UIImagePNGRepresentation(image)!

        // If we're not logged into any services, let's just share this using the native iOS dialog
        if !TwitterAccount.isLoggedIn && !TumblrAccount.isLoggedIn {
            dismissPopover()

            let vc = UIActivityViewController(activityItems: [imageData], applicationActivities: nil)
            vc.popoverPresentationController?.barButtonItem = postButton
            self.present(vc, animated: true, completion: nil)
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

    func clear() {
        jotView.clear(true)
        dismissPopover()
    }

    func dismissPopover() {
        currentPopoverController?.dismiss(animated: false, completion: nil)
        currentPopoverController = nil
    }
}

extension ViewController: JotViewDelegate {

    func textureForStroke() -> JotBrushTexture! {
        return JotDefaultBrushTexture.sharedInstance()
    }

    func stepWidthForStroke() -> CGFloat {
        return 0.2
    }

    func supportsRotation() -> Bool {
        return false
    }

    func width(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!, in jotView: JotView!) -> CGFloat {
        // change the width based on pressure
        let minSize = AppConfig.shared.width, maxSize = minSize * 1.5
        var width = (maxSize + minSize) / 2.0
        width *= Double(coalescedTouch.force)
        if width < minSize {
            width = minSize
        }
        if width > maxSize {
            width = maxSize
        }
        return CGFloat(width)
    }

    func color(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!, in jotView: JotView!) -> UIColor! {
        if AppConfig.shared.tool == .eraser {
            return nil
        }

        return AppConfig.shared.color
    }

    func smoothness(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!, in jotView: JotView!) -> CGFloat {
        return 0.75
    }

    func willAddElements(_ elements: [Any]!,
                         to stroke: JotStroke!,
                         fromPreviousElement previousElement: AbstractBezierPathElement!,
                         in jotView: JotView!) -> [Any]! {
        return elements
    }

    func willBeginStroke(withCoalescedTouch coalescedTouch: UITouch!,
                         from touch: UITouch!,
                         in jotView: JotView!) -> Bool {
        return true
    }

    func willMoveStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!, in jotView: JotView!) {
    }

    func willEndStroke(withCoalescedTouch coalescedTouch: UITouch!,
                       from touch: UITouch!,
                       shortStrokeEnding: Bool,
                       in jotView: JotView!) {
    }

    func didEndStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!, in jotView: JotView!) {
    }

    func willCancel(_ stroke: JotStroke!,
                    withCoalescedTouch coalescedTouch: UITouch!,
                    from touch: UITouch!,
                    in jotView: JotView!) {
    }

    func didCancel(_ stroke: JotStroke!,
                   withCoalescedTouch coalescedTouch: UITouch!,
                   from touch: UITouch!,
                   in jotView: JotView!) {
    }
}

extension ViewController: JotViewStateProxyDelegate {
    var jotViewStatePlistPath: String! {
        return "state.plist"
    }

    var jotViewStateInkPath: String! {
        return "ink.png"
    }

    func didLoadState(_ state: JotViewStateProxy!) {
        print("didLoadState")
    }

    func didUnloadState(_ state: JotViewStateProxy!) {
        print("didUnloadState")
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
            popoverPresentationController.passthroughViews = [jotView]
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
