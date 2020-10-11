//
//  Constants.swift
//  Flash Chat iOS13
//
//  Created by Jon Goldson on 9/16/20.
//  Copyright © 2020 Angela Yu. All rights reserved.
//

import Foundation

struct K {
    static let appName = "📢RepresentU"
    static let cellIdentifier = "ReusableCell"
    static let cellNibName = "MessageCell"
    static let registerSegue = "RegisterToChat"
    static let loginSegue = "LoginToChat"
    
    struct BrandColors {
        static let purple = "BrandPurple"
        static let lightPurple = "BrandLightPurple"
        static let blue = "BrandBlue"
        static let lightBlue = "BrandLightBlue"
    }
    
    struct FStore {
        static let collectionName = "United States"
        static let senderField = "sender"
        static let bodyField = "body"
        static let dateField = "date"
        static let scoreField = "score"
        static let repField = "representative"
        static let upSelected = "upSelected"
        static let downSelected = "downSelected"
    }
    struct Google {
        static let apiKey = "AIzaSyBObK084FH_wKJ0qb6he98R5AWIQqqB2No"
    }
}
