//
//  AppConfig.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/8/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import PencilKit
import YYImage

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

        let gifEncoder = YYImageEncoder(type: .GIF)
        gifEncoder?.loopCount = 0
        for frame in animationFrames {
            gifEncoder?.addImage(with: frame.imageData, duration: frame.duration)
        }
        return gifEncoder?.encode()
    }

    var animationFrames: [SketchFrame] = [] {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AnimationDidChange"), object: self)
        }
    }
}
