//
//  TWTRComposer+ProgrammaticPost.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 6/4/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import TwitterKit
import SwiftyJSON

extension Twitter {
    func postStatus(_ statusText: String, imageData: Data, completion: @escaping (_ success: Bool) -> Void) {
        // Some code based on https://twittercommunity.com/t/upload-images-with-swift/28410/7

        guard let twUserID = Twitter.sharedInstance().sessionStore.session()?.userID else {
            print("Something went wrong, we're not logged in to Twitter")
            return
        }

        var error: NSError?
        let twAPIClient = TWTRAPIClient(userID: twUserID)
        let twUploadRequest = twAPIClient.urlRequest(withMethod: "POST",
                                                     url: "https://upload.twitter.com/1.1/media/upload.json",
                                                     parameters: ["media": imageData.base64EncodedString(options: [])],
                                                     error: &error)

        // First, upload the image
        twAPIClient.sendTwitterRequest(twUploadRequest) { (_, uploadResultData, uploadConnectionError) -> Void in
            // If we encountered any errors, print to the log and return
            if let e = uploadConnectionError ?? error {
                print("Error uploading image: \(e)")
                return completion(false)
            }

            // Parse result from JSON
            guard let rawData = uploadResultData,
                let json = JSON(data: rawData).dictionaryObject,
                let media_id = json["media_id_string"] as? String else {
                print("Invalid JSON response: \(String(describing: uploadResultData))")
                return completion(false)
            }

            // We uploaded our image successfully! Now post a status with a link to the image.
            let twStatusRequest = twAPIClient.urlRequest(withMethod: "POST",
                                                         url: "https://api.twitter.com/1.1/statuses/update.json",
                                                         parameters: ["status": statusText, "media_ids": media_id],
                                                         error: &error)
            twAPIClient.sendTwitterRequest(twStatusRequest) { (_, _, statusConnectionError) -> Void in
                if let e = statusConnectionError ?? error {
                    print("Error posting status: \(e)")
                    return completion(false)
                }

                completion(true)
            }
        }
    }
}
