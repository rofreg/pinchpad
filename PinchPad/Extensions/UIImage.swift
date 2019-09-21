//
//  UIImage.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 9/21/19.
//  Copyright © 2019 Ryan Laughlin. All rights reserved.
//

import Foundation

extension UIImage {
    func withBackground(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, scale)

        guard let ctx = UIGraphicsGetCurrentContext() else { return self }
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: size)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        ctx.draw(cgImage!, in: rect)

        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
