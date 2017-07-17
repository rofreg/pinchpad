//
//  AuthManager.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 7/17/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import Foundation
import TMTumblrSDK
import SwiftyJSON
import Locksmith

enum AuthManagerService: Int {
    case twitter
    case tumblr
}

class AuthManager {
    class func logInToTwitter() {
        // Present Twitter login modal
        Twitter.sharedInstance().logIn(completion: { (_, _) -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AuthChanged"), object: nil)
        })
    }

    class func logInToTumblr() {
        let appDelegate = UIApplication.shared.delegate! as UIApplicationDelegate
        let rootViewController = appDelegate.window!!.rootViewController! as UIViewController
        rootViewController.dismiss(animated: true, completion: nil)

        TMAPIClient.sharedInstance().authenticate("pinchpad", from: rootViewController) { (error) in
            // If there was an error, print it and return
            if let error = error {
                print(error)
                return
            }

            // Otherwise, we need to figure out which specific blog we're posting to
            // To do this, we'll need to fetch user info for the current user
            TMAPIClient.sharedInstance().userInfo({ (result, _) in
                var tumblrInfoToPersist: [String: String] = [:]  // Init an empty dict
                tumblrInfoToPersist["Token"] = TMAPIClient.sharedInstance().oAuthToken
                tumblrInfoToPersist["Secret"] = TMAPIClient.sharedInstance().oAuthTokenSecret

                // Which specific blog should we post to?
                if let blogs = JSON(result!)["user"]["blogs"].array {
                    if blogs.count == 1 {
                        // Automatically select the user's first blog
                        tumblrInfoToPersist["Blog"] = blogs[0]["name"].string!
                        try? Locksmith.updateData(data: tumblrInfoToPersist, forUserAccount: "Tumblr")
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "AuthChanged"), object: nil)
                    } else if blogs.count > 1 {
                        // Have the user pick manually if they have 2+ blogs
                        let blogChoiceMenu = UIAlertController(title: "Which blog do you want to post to?",
                                                               message: nil,
                                                               preferredStyle: .actionSheet)

                        // Add a button for each blog choice
                        for blog in blogs {
                            let button = UIAlertAction(title: blog["name"].string!,
                                                       style: .default,
                                                       handler: { (_) -> Void in
                                tumblrInfoToPersist["Blog"] = blog["name"].string!
                                try? Locksmith.updateData(data: tumblrInfoToPersist,
                                                          forUserAccount: "Tumblr")
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AuthChanged"),
                                                                object: nil)
                            })
                            blogChoiceMenu.addAction(button)
                        }

                        // Add a cancel button
                        let cancelAction = UIAlertAction(title: "Cancel",
                                                         style: .cancel,
                                                         handler: { (_) -> Void in
                            try? Locksmith.deleteDataForUserAccount(userAccount: "Tumblr")
                        })
                        blogChoiceMenu.addAction(cancelAction)

                        // Display the action sheet
                        rootViewController.present(blogChoiceMenu, animated: true, completion: nil)
                    }
                }
            })
        }
    }
}
