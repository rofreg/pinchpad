//
//  AppConfig.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/8/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import RealmSwift
import TMTumblrSDK
import Locksmith

enum SketchTool: Int {
    case pen
    case eraser
}

struct SketchFrame {
    let imageData: Data
    let duration: Double
}

class AppConfig {
    // Set up a singleton instance
    static let shared = AppConfig()
    static var realm: Realm {
        return try! Realm()
    }

    var tool: SketchTool = .pen {
        didSet { toolConfigChanged() }
    }

    var color: UIColor = .black {
        didSet { toolConfigChanged() }
    }

    var width: Double {
        get {
            return tool == .eraser ? rawWidth * 2.0 : rawWidth
        }
        set {
            self.rawWidth = newValue
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ToolConfigChanged"), object: self)
        }
    }

    var rawWidth: Double = 4.0

    var frameLength: Double = 0.5 {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AnimationDidChange"), object: self)
        }
    }

    var animation: Data? {
        // TODO: assemble SketchFrames into an image
        return animationFrames.first?.imageData
    }

    var animationFrames: [SketchFrame] = [] {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AnimationDidChange"), object: self)
        }
    }

    private func toolConfigChanged() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ToolConfigChanged"), object: self)
    }
}
