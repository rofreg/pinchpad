//
//  Sketch.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 7/17/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import Foundation
import RealmSwift

final class Sketch: Object {
    @objc dynamic var createdAt = Date()
    @objc dynamic var imageData: Data?
    @objc dynamic var imageType = "image/png"
    @objc dynamic var caption: String?
    @objc dynamic var twitterSyncStarted: Date? // TODO: remove this from Realm
    @objc dynamic var twitterSyncCompleted: Date? // TODO: remove this from Realm
    @objc dynamic var tumblrSyncStarted: Date?
    @objc dynamic var tumblrSyncCompleted: Date?
    @objc dynamic var mastodonSyncStarted: Date?
    @objc dynamic var mastodonSyncCompleted: Date?

    class func syncAll() {
        // If we're not logged in to any services, don't even try
        if !TumblrAccount.isLoggedIn && !MastodonAccount.isLoggedIn {
            return
        }

        // Otherwise, try to sync all outstanding Sketches
        let realm = try! Realm()
        realm.objects(Sketch.self).sorted(byKeyPath: "createdAt").forEach { (sketch) in
            sketch.post()
        }
    }

    func post() {
        if TumblrAccount.isLoggedIn {
            postToTumblr()
        }
        if MastodonAccount.isLoggedIn {
            postToMastodon()
        }
    }

    func postToTumblr() {
        // Don't double-post if we're already trying to sync
        // (unless that sync attempt is more than 30 seconds old)
        let thirtySecondsAgo = Date().addingTimeInterval(-30)
        guard tumblrSyncStarted == nil || tumblrSyncStarted! < thirtySecondsAgo else {
            print("Skipping sync attempt (Tumblr post already in progress)")
            return
        }
        guard tumblrSyncCompleted == nil else {
            print("Skipping sync attempt (Tumblr post already completed at \(tumblrSyncCompleted!))")
            return
        }

        // Claim this record for syncing
        let realm = try! Realm()
        try! realm.write { self.tumblrSyncStarted = Date() }

        // Let's actually post this image!
        let sketchRef = ThreadSafeReference(to: self)
        TumblrAccount.post(sketch: self) { (success) in
            let realm = try! Realm()
            guard let sketch = realm.resolve(sketchRef) else {
                // We couldn't reload the Sketch object for some reason
                return
            }

            if success {
                // Mark this sync as complete if successful
                try! realm.write { sketch.tumblrSyncCompleted = Date() }
                sketch.deleteIfComplete()
            } else {
                // Clear this sync attempt
                try! realm.write { sketch.tumblrSyncStarted = nil }
            }
        }
    }

    func postToMastodon() {
        // Don't double-post if we're already trying to sync
        // (unless that sync attempt is more than 30 seconds old)
        let thirtySecondsAgo = Date().addingTimeInterval(-30)
        guard mastodonSyncStarted == nil || mastodonSyncStarted! < thirtySecondsAgo else {
            print("Skipping sync attempt (Mastodon post already in progress)")
            return
        }
        guard mastodonSyncCompleted == nil else {
            print("Skipping sync attempt (Mastodon post already completed at \(mastodonSyncCompleted!))")
            return
        }

        // Claim this record for syncing
        let realm = try! Realm()
        try! realm.write { self.mastodonSyncStarted = Date() }

        // Let's actually post this image!
        let sketchRef = ThreadSafeReference(to: self)
        MastodonAccount.post(sketch: self) { (success) in
            let realm = try! Realm()
            guard let sketch = realm.resolve(sketchRef) else {
                // We couldn't reload the Sketch object for some reason
                return
            }

            if success {
                // Mark this sync as complete if successful
                try! realm.write { sketch.mastodonSyncCompleted = Date() }
                sketch.deleteIfComplete()
            } else {
                // Clear this sync attempt
                try! realm.write { sketch.mastodonSyncStarted = nil }
            }
        }
    }

    func deleteIfComplete() {
        if TumblrAccount.isLoggedIn && tumblrSyncCompleted == nil {
            return
        }
        if MastodonAccount.isLoggedIn && mastodonSyncCompleted == nil {
            return
        }
        if self.isInvalidated {
            // Looks like this record was already deleted
            return
        }

        // We've completed posting to all services, so let's delete this Sketch from the local database
        let realm = try! Realm()
        try! realm.write { realm.delete(self) }
    }
}
