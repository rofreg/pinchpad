//
//  MenuViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/12/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import Foundation
import TMTumblrSDK

class MenuViewController: UIViewController {
    @IBAction func clear() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ClearCanvas"), object: self)
    }

    @IBAction func authWithTwitter() {
        // TODO: Implement this
        print("Auth with Twitter")
    }

    @IBAction func authWithTumblr() {
        TMAPIClient.sharedInstance().authenticate("pinchpad", from: self) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
    }
}
