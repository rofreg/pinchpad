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

    var width: Double = 4.0 {
        didSet { NotificationCenter.default.post(name: Notification.Name(rawValue: "ToolConfigChanged"), object: self) }
    }

    var frameLength: Double = 0.5 {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FrameLengthDidChange"), object: self)
        }
    }

    func toolConfigChanged() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ToolConfigChanged"), object: self)
    }
}
