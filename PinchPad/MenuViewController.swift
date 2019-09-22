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
    @IBOutlet var twitterButton: UIButton!
    @IBOutlet var tumblrButton: UIButton!
    @IBOutlet var frameDurationLabel: UILabel!
    @IBOutlet var frameLengthStepper: UIStepper!
    @IBOutlet var addFrameButton: UIButton!
    @IBOutlet var viewPreviewButton: UIButton!
    @IBOutlet var undoFrameButton: UIButton!

    let grayButtonColor = UIColor(hex: "999999")
    let twitterColor = UIColor(hex: "00B0ED")
    let tumblrColor = UIColor(hex: "34465D")

    override func viewDidLoad() {
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

        [twitterButton, tumblrButton].forEach { (button) in
            button?.titleLabel?.numberOfLines = 0
        }

        addFrameButton.backgroundColor = grayButtonColor
        [viewPreviewButton, undoFrameButton].forEach { (button) in
            button?.layer.borderWidth = 1
            button?.layer.borderColor = grayButtonColor.cgColor
        }

        updateAdvancedOptions()
    }

    // MARK: Redrawing subviews

    @objc func updateAnimationViews() {
        DispatchQueue.main.async {
            self.addFrameButton.setTitle("Add frame #\(AppConfig.shared.animationFrames.count + 1)", for: .normal)
            let frameDurationString = String(format: "%.1f", AppConfig.shared.frameLength)
            self.frameDurationLabel.text = "Show for\n\(frameDurationString)s"
        }
    }

    @objc func updateAdvancedOptions() {
        if let twitterUsername = TwitterAccount.username {
            twitterButton.setTitle("Connected as \(twitterUsername)", for: .normal)
            twitterButton.backgroundColor = twitterColor
        } else {
            twitterButton.setTitle("Connect to Twitter", for: .normal)
            twitterButton.backgroundColor = grayButtonColor
        }

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

    @IBAction func frameLengthChange() {
        AppConfig.shared.frameLength = frameLengthStepper.value
    }

    @IBAction func addAnimationFrame() {
        guard let canvasView = AppConfig.shared.canvasView else {
            return
        }

        // To prevent iPad drawings from getting too massive, let's export at a non-Retina resolution
        let scale = (canvasView.frame.width >= 768 ? 1.0 : UIScreen.main.scale)
        guard let canvasImageData = canvasView.image(scale: scale).pngData() else {
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

    @IBAction func authWithTwitter() {
        if TwitterAccount.isLoggedIn {
            // I guess we're logging out
            let alert = UIAlertController(
                title: "Disconnect Twitter?",
                message: "Are you sure you want to disconnect your Twitter account?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Disconnect", style: .default, handler: { (_) in
                TwitterAccount.logOut()
                self.updateAdvancedOptions()
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            TwitterAccount.logIn(presentingFrom: self)
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
