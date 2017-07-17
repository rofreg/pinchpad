//
//  AppConfig.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/8/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

enum SketchTool: Int {
    case pen
    case eraser
}

class AppConfig {
    // Set up a singleton instance
    static let shared = AppConfig()

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

    var animation: UIImage? {
        return nil
    }

    var animationFrames: [SketchFrame] = [] {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AnimationDidChange"), object: self)
        }
    }

    var twitterUsername: String? {
        if let session = Twitter.sharedInstance().sessionStore.session() as? TWTRSession {
            return session.userName
        }
        return nil
    }

    var tumblrUsername: String? {
        return nil
    }

    private func toolConfigChanged() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ToolConfigChanged"), object: self)
    }
}

struct SketchFrame {
    let imageData: Data
    let duration: Double
}
