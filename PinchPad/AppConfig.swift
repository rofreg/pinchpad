//
//  AppConfig.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/8/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import TMTumblrSDK
import Locksmith
import MobileCoreServices
import PencilKit

struct SketchFrame {
    let imageData: Data
    let duration: Double
}

class AppConfig {
    // Set up a singleton instance
    static let shared = AppConfig()

    lazy var canvasView: PKCanvasView? = nil

    var allowGestures: Bool = true {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AllowGesturesDidChange"), object: self)
        }
    }

    var frameLength: Double = 0.5 {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AnimationDidChange"), object: self)
        }
    }

    var animation: Data? {
        if animationFrames.count == 0 {
            return nil
        }

        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]
        let documentsDirectory = NSTemporaryDirectory()
        let url = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("animated.gif")
        let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, animationFrames.count, nil)
        CGImageDestinationSetProperties(destination!, fileProperties as CFDictionary)

        for frame in animationFrames {
            let actualImage = UIImage(data: frame.imageData)
            let duration = [kCGImagePropertyGIFDelayTime as String: frame.duration]
            let frameProperties = [kCGImagePropertyGIFDictionary as String: duration]
            CGImageDestinationAddImage(destination!, actualImage!.cgImage!, frameProperties as CFDictionary)
        }

        if CGImageDestinationFinalize(destination!) {
            return try! Data(contentsOf: url)
        } else {
            return nil
        }
    }

    var animationFrames: [SketchFrame] = [] {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AnimationDidChange"), object: self)
        }
    }
}
