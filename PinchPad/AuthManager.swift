//
//  AuthManager.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 7/17/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import Foundation
import TMTumblrSDK
import Swifter
import SwiftyJSON
import Locksmith
import Keys

protocol PostableAccount {
    static var isLoggedIn: Bool { get }
    static var username: String? { get }
    static func logOut()
    static func post(sketch: Sketch, completion: ((Bool) -> Void)?)
}

extension PostableAccount {
    static func notifyAuthChanged() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "AuthChanged"), object: nil)
    }
}

class TwitterAccount: PostableAccount {
    static var swifter: Swifter {
        let keys = PinchPadKeys()
        return Swifter(consumerKey: keys.twitterConsumerKey, consumerSecret: keys.twitterConsumerSecret)
    }

    static var isLoggedIn: Bool {
        return false
//        return Twitter.sharedInstance().sessionStore.session() != nil
    }

    static var username: String? {
//        if let session = Twitter.sharedInstance().sessionStore.session() as? TWTRSession {
//            return session.userName
//        }
        return nil
    }

    static func logIn(presentingFrom presentingVC: UIViewController) {
        let url = URL(string: "pinchpad://")!
        swifter.authorize(withCallback: url, presentingFrom: presentingVC, success: { credentials, response in
            guard let credentials = credentials else {
                return
            }
            
            print(credentials.key)
            print(credentials.secret)
            print(credentials.screenName)
            print(credentials.userID)
            
            notifyAuthChanged()
        })
    }

    static func logOut() {
//        let sessionStore = Twitter.sharedInstance().sessionStore
//        if let session = sessionStore.session() {
//            sessionStore.logOutUserID(session.userID)
//        }
    }

    static func post(sketch: Sketch, completion: ((Bool) -> Void)?) {
//        Twitter.sharedInstance().postStatus("\(sketch.caption!) #pinchpad",
//                                            imageData: sketch.imageData!) { (success: Bool) in
//            print("Posted to Twitter: \(success)")
//            completion?(success)
//        }
        completion?(false)
    }
}

class TumblrAccount: PostableAccount {
    static var isLoggedIn: Bool {
        return username != nil
    }

    static var username: String? {
        if let dictionary = Locksmith.loadDataForUserAccount(userAccount: "Tumblr") {
            return dictionary["Blog"] as? String
        }
        return nil
    }

    static func logIn() {
        let appDelegate = UIApplication.shared.delegate! as UIApplicationDelegate
        guard let rootViewController = appDelegate.window!!.rootViewController! as? ViewController else {
            return
        }
        rootViewController.dismissPopover()

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
                        try! Locksmith.updateData(data: tumblrInfoToPersist, forUserAccount: "Tumblr")
                        notifyAuthChanged()
                    } else if blogs.count > 1 {
                        // Have the user pick manually if they have 2+ blogs
                        let blogChoiceMenu = UIAlertController(title: "Which blog do you want to post to?",
                                                               message: nil,
                                                               preferredStyle: .alert)

                        // Add a button for each blog choice
                        for blog in blogs {
                            let button = UIAlertAction(title: blog["name"].string!,
                                                       style: .default,
                                                       handler: { (_) -> Void in
                                tumblrInfoToPersist["Blog"] = blog["name"].string!
                                try! Locksmith.updateData(data: tumblrInfoToPersist,
                                                          forUserAccount: "Tumblr")
                                notifyAuthChanged()
                            })
                            blogChoiceMenu.addAction(button)
                        }

                        // Add a cancel button
                        let cancelAction = UIAlertAction(title: "Cancel",
                                                         style: .cancel,
                                                         handler: { (_) -> Void in
                            try! Locksmith.deleteDataForUserAccount(userAccount: "Tumblr")
                        })
                        blogChoiceMenu.addAction(cancelAction)

                        // Display the action sheet
                        rootViewController.present(blogChoiceMenu, animated: true, completion: nil)
                    }
                }
            })
        }
    }

    static func logOut() {
        // Clear Tumblr SDK vars and keychain
        TMAPIClient.sharedInstance().oAuthToken = nil
        TMAPIClient.sharedInstance().oAuthTokenSecret = nil
        try! Locksmith.deleteDataForUserAccount(userAccount: "Tumblr")
    }

    static func post(sketch: Sketch, completion: ((Bool) -> Void)?) {
        let imageFilename = (sketch.imageType == "image/gif" ? "sketch.gif" : "sketch.png")

        TMAPIClient.sharedInstance().photo(username,
                                           imageNSDataArray: [sketch.imageData as Any],
                                           contentTypeArray: [sketch.imageType],
                                           fileNameArray: [imageFilename],
                                           parameters: [
                                             "tags": "pinchpad,hourly comics",
                                             "link": "http://www.pinchpad.com"
                                           ],
                                           callback: { (response: Any?, error: Error?) -> Void in
            // Parse the JSON response to see if we saved correctly
            var success: Bool
            if let dictResponse = response as? [String: AnyObject],
                let _: AnyObject = dictResponse["id"], error == nil {
                success = true
            } else {
                success = false
            }

            print("Posted to Tumblr: \(success)")        // print whether we succeeded
            completion?(success)
        })
    }
}

class AuthManager {
    class var postableAccounts: [PostableAccount] {
        var accounts: [PostableAccount] = []
//        if Twitter.sharedInstance().sessionStore.session() != nil {
//            accounts.append(TwitterAccount())
//        }
        if Locksmith.loadDataForUserAccount(userAccount: "Tumblr") != nil {
            accounts.append(TumblrAccount())
        }
        return accounts
    }
}
