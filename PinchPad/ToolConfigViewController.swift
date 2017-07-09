//
//  ToolConfigViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/8/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import Foundation

class ToolConfigViewController: UIViewController {
    @IBOutlet var previewWindow: UIView!
    @IBOutlet var colorCollectionView: UICollectionView!

    let colors = [UIColor.black, UIColor(hex:"999999"), UIColor(hex:"dddddd"), UIColor(hex:"F2CA42"),
                  UIColor(hex:"00C3A9"), UIColor(hex:"D45354"), UIColor(hex:"2FCAD8"), UIColor(hex:"663300"),
                  UIColor(hex:"af7a56"), UIColor(hex:"ab7dbe"), UIColor(hex:"ff8960"), UIColor(hex:"6e99d4"),
                  UIColor(hex:"4c996e"), UIColor(hex:"dc9bb1")]

    override func viewDidLoad() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ToolConfigViewController.updatePreview),
            name: NSNotification.Name(rawValue: "ToolConfigChanged"),
            object: nil
        )

        previewWindow.layer.borderColor = UIColor(hex: "dddddd").cgColor
        previewWindow.layer.borderWidth = 1
        updatePreview()
    }

    func updatePreview() {
        for subview in previewWindow.subviews {
            subview.removeFromSuperview()
        }

        // Add a preview of the current tool
        let origin = CGPoint(x: previewWindow.frame.size.width / 2, y: previewWindow.frame.size.height / 2)
        let size = CGSize(width: AppConfig.shared.width * 1, height: AppConfig.shared.width * 1)
        let toolPreview = UIView(frame: CGRect(origin: origin, size: size))
        toolPreview.backgroundColor = AppConfig.shared.color
        toolPreview.layer.cornerRadius = size.width / 2.0
        previewWindow.addSubview(toolPreview)

        // If we're in eraser mode, invert the colors
        if AppConfig.shared.tool == .eraser {
            previewWindow.backgroundColor = UIColor.darkGray
            toolPreview.backgroundColor = UIColor.white
        } else {
            previewWindow.backgroundColor = UIColor.white
        }
    }
}

extension ToolConfigViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorCell", for: indexPath)
        cell.backgroundColor = colors[indexPath.row % colors.count]

        let selectedViewTag = 12345

        // Remove the 'selected color' indicator by default
        for subview in cell.subviews where subview.tag == selectedViewTag {
            subview.removeFromSuperview()
        }

        // Then add the 'selected color' indicator if this is actually the active color
        if cell.backgroundColor == AppConfig.shared.color {
            let padding: CGFloat = 2,
                size: CGFloat = cell.frame.width - (padding * 2)

            let selectedView = UIView(frame: CGRect(x: padding, y: padding, width: size, height: size))
            selectedView.layer.borderColor = UIColor.white.cgColor
            selectedView.layer.borderWidth = 2
            selectedView.tag = selectedViewTag
            cell.addSubview(selectedView)
        }

        return cell
    }
}

extension ToolConfigViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AppConfig.shared.color = colors[indexPath.row % colors.count]
        colorCollectionView.reloadData()
    }
}

// Via http://crunchybagel.com/working-with-hex-colors-in-swift-3/
extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0

        var rgbValue: UInt64 = 0

        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff

        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
