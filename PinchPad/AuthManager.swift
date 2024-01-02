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
import Keys
import MastodonKit

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

    static func logIn(presentingFrom presentingVC: UIViewController) {
        TMAPIClient.sharedInstance().authenticate("pinchpad", from: presentingVC) { (error) in
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
                        presentingVC.present(blogChoiceMenu, animated: true, completion: nil)
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

class MastodonAccount: PostableAccount {
    static var client: Client {
        let keys = PinchPadKeys()

        return Client(
            baseURL: keys.mastodonBaseUrl,
            accessToken: keys.mastodonAccessToken
        )
    }

    static var isLoggedIn: Bool {
        let keys = PinchPadKeys()

        return !keys.mastodonBaseUrl.isEmpty
    }

    static var username: String? = "pinchpad"

    static func logOut() {
        // No-op
    }

    static func post(sketch: Sketch, completion: ((Bool) -> Void)?) {
        let caption = sketch.caption!
        let media: MediaAttachment

        if sketch.imageType ==  "image/gif" {
            media = .gif(sketch.imageData!)
        } else {
            media = .png(sketch.imageData!)
        }

        client.run(Media.upload(media: media)) { mediaResult in
            if mediaResult.isError {
                print("Posted to Mastodon: false (mediaResult isError)") // print whether we succeeded
                completion?(false)
                return
            }

            let mediaIDs = [mediaResult.value!.id]

            client.run(Statuses.create(status: caption, mediaIDs: mediaIDs), completion: { statusResult in
                print("Posted to Mastodon: \(!statusResult.isError)") // print whether we succeeded
                completion?(!statusResult.isError )
            })
        }
    }
}
