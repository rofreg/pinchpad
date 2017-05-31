//
//  ViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/29/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up a view for drawing
        let jotView = JotView(frame: self.view.frame)
        jotView.delegate = self
        self.view.addSubview(jotView)

        let jotViewStateProxy = JotViewStateProxy()
        jotViewStateProxy.delegate = self
        jotViewStateProxy.loadJotStateAsynchronously(false,
                                                     with: jotView.bounds.size,
                                                     andScale: UIScreen.main.scale,
                                                     andContext: jotView.context,
                                                     andBufferManager: JotBufferManager.sharedInstance())
        jotView.loadState(jotViewStateProxy)
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
        return 2
    }

    func color(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> UIColor! {
        print("color")
        return .black
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
    func didLoadState(_ state: JotViewStateProxy!) {
        print("didLoadState")
    }

    func didUnloadState(_ state: JotViewStateProxy!) {
        print("didUnloadState")
    }

    var jotViewStatePlistPath: String! {
        return "state.plist"
    }

    var jotViewStateInkPath: String! {
        return "ink.png"
    }
}
