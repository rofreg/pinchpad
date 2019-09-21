//
//  PKCanvasView.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 9/21/19.
//  Copyright © 2019 Ryan Laughlin. All rights reserved.
//

import PencilKit

extension PKCanvasView {
    func image(scale: CGFloat = UIScreen.main.scale) -> UIImage {
        return drawing.image(from: bounds, scale: UIScreen.main.scale).withBackground(color: .white)
    }
}
