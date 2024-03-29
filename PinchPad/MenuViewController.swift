//
//  MenuViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/12/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import Foundation
import TMTumblrSDK
import MessageUI
import SafariServices

class MenuViewController: UIViewController {
    @IBOutlet var mainStackView: UIStackView!
    @IBOutlet var tumblrButton: UIButton!
    @IBOutlet var frameDurationLabel: UILabel!
    @IBOutlet var frameLengthStepper: UIStepper!
    @IBOutlet var addFrameButton: UIButton!
    @IBOutlet var viewPreviewButton: UIButton!
    @IBOutlet var undoFrameButton: UIButton!
    @IBOutlet var allowGesturesSwitch: UISwitch!

    let grayButtonColor = UIColor(hex: "999999")
    let tumblrColor = UIColor(hex: "34465D")

    override func viewDidLoad() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MenuViewController.updateGestureViews),
            name: NSNotification.Name(rawValue: "AllowGesturesDidChange"),
            object: nil
        )
        updateGestureViews()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MenuViewController.updateAnimationViews),
            name: NSNotification.Name(rawValue: "AnimationDidChange"),
            object: nil
        )
        updateAnimationViews()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MenuViewController.updateAdvancedOptions),
            name: NSNotification.Name(rawValue: "AuthChanged"),
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        // Resize to fit content
        self.preferredContentSize.height = mainStackView.frame.size.height + 20

        tumblrButton?.titleLabel?.numberOfLines = 0

        addFrameButton.backgroundColor = grayButtonColor
        [viewPreviewButton, undoFrameButton].forEach { (button) in
            button?.layer.borderWidth = 1
            button?.layer.borderColor = grayButtonColor.cgColor
        }
        frameLengthStepper.value = AppConfig.shared.frameLength

        updateAdvancedOptions()
    }

    // MARK: Redrawing subviews

    @objc func updateGestureViews() {
        DispatchQueue.main.async {
            self.allowGesturesSwitch.isOn = AppConfig.shared.allowGestures
        }
    }

    @objc func updateAnimationViews() {
        DispatchQueue.main.async {
            self.addFrameButton.setTitle("Add frame #\(AppConfig.shared.animationFrames.count + 1)", for: .normal)
            let frameDurationString = String(format: "%.1f", AppConfig.shared.frameLength)
            self.frameDurationLabel.text = "Show for\n\(frameDurationString)s"
        }
    }

    @objc func updateAdvancedOptions() {
        if let tumblrUsername = TumblrAccount.username {
            tumblrButton.setTitle("Connected as \(tumblrUsername)", for: .normal)
            tumblrButton.backgroundColor = tumblrColor
        } else {
            tumblrButton.setTitle("Connect to Tumblr", for: .normal)
            tumblrButton.backgroundColor = grayButtonColor
        }
    }

    // MARK: Handling user actions

    @IBAction func clear() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ClearCanvas"), object: self)
    }

    @IBAction func allowGesturesChanged() {
        AppConfig.shared.allowGestures = allowGesturesSwitch.isOn
    }

    @IBAction func frameLengthChange() {
        AppConfig.shared.frameLength = frameLengthStepper.value
    }

    @IBAction func addAnimationFrame() {
        guard let canvasView = AppConfig.shared.canvasView else {
            return
        }

        let canvasImage = canvasView.image()
        var finalResizedImage = canvasImage

        // tl;dr: scale everything down to 1x, which has better compatibility with 3rd-party apps
        // Mastodon: https://docs.joinmastodon.org/user/posting/#media
        // Tumblr: https://www.tumblr.com/docs/en/api/v2#photo-posts
        // To prevent iPad drawings from getting too massive, let's export at a non-Retina resolution
        // We have to manually scale these down – using image(scale:) only changes the in-memory scale of the image
        // You can prove this by calling UIImage(data: canvasImage.pngData!)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        finalResizedImage = UIGraphicsImageRenderer(size: canvasImage.size, format: format).image { _ in
            canvasImage.draw(in: CGRect(origin: .zero, size: canvasImage.size))
         }

        guard let canvasImageData = finalResizedImage.pngData() else {
            return
        }

        AppConfig.shared.animationFrames.append(
            SketchFrame(imageData: canvasImageData, duration: AppConfig.shared.frameLength)
        )
    }

    @IBAction func removeAnimationFrame() {
        if AppConfig.shared.animationFrames.count > 0 {
            AppConfig.shared.animationFrames.removeLast()
        }
    }

    @IBAction func authWithTumblr() {
        if TumblrAccount.isLoggedIn {
            // I guess we're logging out
            let alert = UIAlertController(
                title: "Disconnect Tumblr?",
                message: "Are you sure you want to disconnect your Tumblr account?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Disconnect", style: .default, handler: { (_) in
                TumblrAccount.logOut()
                self.updateAdvancedOptions()
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            TumblrAccount.logIn(presentingFrom: self)
        }
    }

    @IBAction func madeByRofreg() {
        UIApplication.shared.open(URL(string: "https://www.rofreg.com")!)
    }

    @IBAction func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            let version: AnyObject = Bundle.main.infoDictionary!["CFBundleShortVersionString"]! as AnyObject
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            mailVC.setSubject("Feedback for Pinch Pad (v\(version))")
            mailVC.setMessageBody("", isHTML: false)
            mailVC.setToRecipients(["me@rofreg.com"])

            self.present(mailVC, animated: true, completion: nil)
        } else {
            // Show an alert
            let alert = UIAlertController(
                title: "No email account found",
                message: "Whoops, I couldn't find an email account set up on this device! " +
                         "You can send me feedback directly at me@rofreg.com.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension MenuViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension MenuViewController: SFSafariViewControllerDelegate {}
