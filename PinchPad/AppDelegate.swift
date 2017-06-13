//
//  AppDelegate.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/29/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import UIKit
import Firebase
import Keys
import TMTumblrSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let keys = PinchPadKeys()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Twitter.sharedInstance().start(withConsumerKey: keys.twitterConsumerKey,
                                       consumerSecret: keys.twitterConsumerSecret)
        TMAPIClient.sharedInstance().oAuthConsumerKey = keys.tumblrConsumerKey
        TMAPIClient.sharedInstance().oAuthConsumerSecret = keys.tumblrConsumerSecret

        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle login callbacks from Twitter and Tumblr
        return TMAPIClient.sharedInstance().handleOpen(url) ||
            Twitter.sharedInstance().application(app, open: url, options: options)
    }
}
