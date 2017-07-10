//
//  ViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/29/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var undoButton: UIBarButtonItem!
    @IBOutlet var redoButton: UIBarButtonItem!
    @IBOutlet var pencilButton: UIBarButtonItem!
    @IBOutlet var eraserButton: UIBarButtonItem!
    @IBOutlet var jotView: JotView!
    var jotViewStateProxy: JotViewStateProxy!
    var currentPopoverController: UIViewController?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Don't allow rotation between landscape and portrait – it would corrupt the drawing view
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

        jotViewStateProxy = JotViewStateProxy()
        jotViewStateProxy.delegate = self
        jotViewStateProxy.loadJotStateAsynchronously(false,
                                                     with: jotView.bounds.size,
                                                     andScale: UIScreen.main.scale,
                                                     andContext: jotView.context,
                                                     andBufferManager: JotBufferManager.sharedInstance())
        jotView.loadState(jotViewStateProxy)

        // Add a temporary Twitter login button
        let logInButton = TWTRLogInButton(logInCompletion: { session, error in
            if let session = session {
                print("signed in as \(session.userName)")
            } else {
                print("error: \(error?.localizedDescription ?? "unknown error")")
            }
        })
        logInButton.center = self.view.center
        self.view.addSubview(logInButton)
    }

    func subscribeToNotifications() {
        // When our tool changes, update the display
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.updateToolbarDisplay),
                                               name: NSNotification.Name(rawValue: "ToolConfigChanged"),
                                               object: nil)
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

    @IBAction func undo() {
        jotView.undo()
    }

    @IBAction func redo() {
        jotView.redo()
    }

    @IBAction func post(_ sender: AnyObject) {
        // Don't post if we haven't drawn any strokes
        guard jotView.state.everyVisibleStroke().count > 0 else {
            let alert = UIAlertController(
                title: "Your sketch is blank",
                message: "You haven't drawn anything yet, silly!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }

        dismissPopover()

        jotView.exportToImage(onComplete: { (image) in
            let imageData = UIImagePNGRepresentation(image!)

            // If we're not logged into any services, let's just share this using the native iOS dialog
            if let imageData = imageData {
                let vc = UIActivityViewController(activityItems: [imageData], applicationActivities: nil)
                vc.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
                self.present(vc, animated: true, completion: nil)
                return
            }

            // TODO: if we ARE logged into services, we should post to them
        }, withScale: UIScreen.main.scale)
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

    func width(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> CGFloat {
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

    func color(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> UIColor! {
        if AppConfig.shared.tool == .eraser {
            return nil
        }

        return AppConfig.shared.color
    }

    func smoothness(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> CGFloat {
        return 0.75
    }

    func willAddElements(_ elements: [Any]!,
                         to stroke: JotStroke!,
                         fromPreviousElement previousElement: AbstractBezierPathElement!) -> [Any]! {
        return elements
    }

    func willBeginStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> Bool {
        return true
    }

    func willMoveStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
    }

    func willEndStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!, shortStrokeEnding: Bool) {
    }

    func didEndStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
    }

    func willCancel(_ stroke: JotStroke!, withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
    }

    func didCancel(_ stroke: JotStroke!, withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
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
