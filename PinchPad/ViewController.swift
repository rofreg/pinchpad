//
//  ViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/29/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var jotView: JotView!
    var jotViewStateProxy: JotViewStateProxy!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up a view for drawing
        jotView = JotView(frame: self.view.frame.insetBy(dx: 0, dy: 32).offsetBy(dx: 0, dy: 32))
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

    func undo() {
        jotView.undo()
    }

    func redo() {
        jotView.redo()
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
