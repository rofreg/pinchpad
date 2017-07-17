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
    dynamic var image: Data?
    dynamic var caption: String?
    dynamic var syncStarted: Date?
}
