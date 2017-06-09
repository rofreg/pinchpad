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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the jotView for drawing
        // For some reason, JotViews don't like to be included via Interface Builder, so we redo ours here
        jotView.removeFromSuperview()
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

        subscribeToNotifications()
    }

    func subscribeToNotifications() {
        // When our tool changes, update the display
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.updateToolbarDisplay),
                                               name: NSNotification.Name(rawValue: "ToolConfigChanged"),
                                               object: nil)
    }

    func updateToolbarDisplay() {
        if AppConfig.sharedInstance.tool == .eraser {
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
        jotView.exportToImage(onComplete: { (image) in
            let imageData = UIImagePNGRepresentation(image!)

            // If we're not logged into any services, let's just share this using the native iOS dialog
            if true {
                let vc = UIActivityViewController(activityItems: [imageData], applicationActivities: nil)
                vc.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
                self.present(vc, animated: true, completion: nil)
                return
            }

            // TODO: if we ARE logged into services, we should post to them

        }, withScale: UIScreen.main.scale)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "EraserSegue" && AppConfig.sharedInstance.tool != .eraser {
            AppConfig.sharedInstance.tool = .eraser
            return false
        } else if identifier == "PencilSegue" && AppConfig.sharedInstance.tool == .eraser {
            AppConfig.sharedInstance.tool = .pen
            return false
        }

        return true
    }

    func clear() {
        jotView.clear(true)
    }
}

extension ViewController: JotViewDelegate {

    func textureForStroke() -> JotBrushTexture! {
        print("textureForStroke")
        return JotDefaultBrushTexture.sharedInstance()
    }

    func stepWidthForStroke() -> CGFloat {
        print("stepWidthForStroke")
        return 2
    }

    func supportsRotation() -> Bool {
        print("supportsRotation")
        return false
    }

    func width(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> CGFloat {
        print("width")

        // change the width based on pressure
        let maxSize = 15.0, minSize = 6.0
        var width = (maxSize + minSize) / 2.0
        width *= Double(coalescedTouch.force)
        print(coalescedTouch.force)
        if width < minSize {
            width = minSize
        }
        if width > maxSize {
            width = maxSize
        }
        return CGFloat(width)
    }

    func color(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> UIColor! {
        print("color")
        return UIColor(white: 0.0, alpha: 0.9)
    }

    func smoothness(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> CGFloat {
        print("smoothness")
        return 0.75
    }

    func willAddElements(_ elements: [Any]!,
                         to stroke: JotStroke!,
                         fromPreviousElement previousElement: AbstractBezierPathElement!) -> [Any]! {
        print("willAddElements")
        return elements
    }

    func willBeginStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> Bool {
        print("willBeginStroke")
        return true
    }

    func willMoveStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
        print("willMoveStroke")
    }

    func willEndStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!, shortStrokeEnding: Bool) {
        print("willEndStroke")
    }

    func didEndStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
        print("didEndStroke")
    }

    func willCancel(_ stroke: JotStroke!, withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
        print("willCancel")
    }

    func didCancel(_ stroke: JotStroke!, withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
        print("didCancel")
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
}
