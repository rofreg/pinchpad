//
//  AppDelegate.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 5/29/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import UIKit
import Keys
import TMTumblrSDK
import Locksmith
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var initialLaunch = true
    let keys = PinchPadKeys()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        TMAPIClient.sharedInstance().oAuthConsumerKey = keys.tumblrConsumerKey
        TMAPIClient.sharedInstance().oAuthConsumerSecret = keys.tumblrConsumerSecret

        // Load any existing Tumblr login info
        let dictionary = Locksmith.loadDataForUserAccount(userAccount: "Tumblr")
        if let dict = dictionary, let token = dict["Token"] as? String, let secret = dict["Secret"] as? String {
            TMAPIClient.sharedInstance().oAuthToken = token
            TMAPIClient.sharedInstance().oAuthTokenSecret = secret
        }

        // Sync on any connectivity changes
        let manager = NetworkReachabilityManager(host: "www.apple.com")
        manager?.startListening(onUpdatePerforming: { status in
            switch status {
            case .reachable, .unknown:
                Sketch.syncAll()
            default:
                break
            }
        })

        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle login callbacks from Tumblr
        return TMAPIClient.sharedInstance().handleOpen(url)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Try syncing whenever we re-open the app from the background
        // (If we're launching, .sync() will already get called when we set up the NetworkReachabilityManager)
        if !initialLaunch {
            Sketch.syncAll()
        }

        initialLaunch = false
    }
}
