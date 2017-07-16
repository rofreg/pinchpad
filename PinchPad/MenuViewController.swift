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

class MenuViewController: UIViewController {
    @IBOutlet var mainStackView: UIStackView!
    @IBOutlet var twitterButton: UIButton!
    @IBOutlet var tumblrButton: UIButton!
    @IBOutlet var stepperContainerView: UIView!
    @IBOutlet var addFrameButton: UIButton!
    @IBOutlet var viewPreviewButton: UIButton!
    @IBOutlet var undoFrameButton: UIButton!

    let grayButtonColor = UIColor(hex: "999999")
    let twitterColor = UIColor(hex: "00B0ED")
    let tumblrColor = UIColor(hex: "34465D")

    override func viewWillAppear(_ animated: Bool) {
        // Resize to fit content
        self.preferredContentSize.height = mainStackView.frame.size.height + 20

        twitterButton.titleLabel?.numberOfLines = 0
        tumblrButton.titleLabel?.numberOfLines = 0

        addFrameButton.backgroundColor = grayButtonColor
        [viewPreviewButton, undoFrameButton].forEach { (button) in
            button?.layer.borderWidth = 1
            button?.layer.borderColor = grayButtonColor.cgColor
        }

        updateAdvancedOptions()
    }

    func updateAdvancedOptions() {
        if let twitterUsername = AppConfig.shared.twitterUsername {
            twitterButton.setTitle("Connected as\n\(twitterUsername)", for: .normal)
            twitterButton.backgroundColor = twitterColor
        } else {
            twitterButton.setTitle("Not\nconnected", for: .normal)
            twitterButton.backgroundColor = grayButtonColor
        }

        if let tumblrUsername = AppConfig.shared.tumblrUsername {
            tumblrButton.setTitle("Connected as\n\(tumblrUsername)", for: .normal)
            tumblrButton.backgroundColor = tumblrColor
        } else {
            tumblrButton.setTitle("Not\nconnected", for: .normal)
            tumblrButton.backgroundColor = grayButtonColor
        }
    }

    @IBAction func clear() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ClearCanvas"), object: self)
    }

    @IBAction func authWithTwitter() {
        if AppConfig.shared.twitterUsername != nil {
            // I guess we're logging out
            let alert = UIAlertController(
                title: "Disconnect Twitter?",
                message: "Are you sure you want to disconnect your Twitter account?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Disconnect", style: .default, handler: { (_) in
                let sessionStore = Twitter.sharedInstance().sessionStore
                if let session = sessionStore.session() {
                    sessionStore.logOutUserID(session.userID)
                    self.updateAdvancedOptions()
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            Twitter.sharedInstance().logIn(completion: { (_, _) in
                self.updateAdvancedOptions()
            })
        }
    }

    @IBAction func authWithTumblr() {
        TMAPIClient.sharedInstance().authenticate("pinchpad", from: self) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func madeByRofreg() {
        UIApplication.shared.openURL(URL(string:"https://www.rofreg.com")!)
    }

    @IBAction func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            let version: AnyObject = Bundle.main.infoDictionary!["CFBundleShortVersionString"]! as AnyObject
            let mc = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject("Feedback for Pinch Pad (v\(version))")
            mc.setMessageBody("", isHTML: false)
            mc.setToRecipients(["me@rofreg.com"])

            self.present(mc, animated: true, completion: nil)
        } else {
            // Show an alert
            let alert = UIAlertController(
                title: "No email account found",
                message: "Whoops, I couldn't find an email account set up on this device!" +
                         "You can send me feedback directly at me@rofreg.com.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension MenuViewController : MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}
