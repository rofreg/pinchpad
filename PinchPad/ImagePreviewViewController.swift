//
//  ImagePreviewViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 9/2/18.
//  Copyright © 2018 Ryan Laughlin. All rights reserved.
//

import UIKit
import FLAnimatedImage

class ImagePreviewViewController: UIViewController {
    @IBOutlet var imageView: FLAnimatedImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load animation preview
        if AppConfig.shared.animationFrames.count > 0 {
            self.imageView.animatedImage = FLAnimatedImage(animatedGIFData: AppConfig.shared.animation)
        } else {
            // Or just load the current image
            if let canvasView = AppConfig.shared.canvasView {
                self.imageView.image = canvasView.image()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: true, completion: nil)
    }
}
