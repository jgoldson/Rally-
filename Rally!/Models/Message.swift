//
//  Message.swift
//  Flash Chat iOS13
//
//  Created by Jon Goldson on 9/16/20.
//

import Foundation
import Firebase

struct Message {
    let sender: String
    let body: String
    let score: Int
    let id: String
    let rep: String
    
    let upSelected: [String: Bool]
    let downSelected: [String: Bool]

}
