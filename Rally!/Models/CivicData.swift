//
//  CivicData.swift
//  Flash Chat iOS13
//
//  Created by Jon Goldson on 9/25/20.
//  Copyright © 2020 Angela Yu. All rights reserved.
//

import Foundation

struct CivicData: Decodable{
    
    let officials : [Officials]
    
    struct Officials: Decodable {
        let name: String
        
    }
}
