//
//  CivicData.swift
//  Flash Chat iOS13
//
//  Created by Jon Goldson on 9/25/20.
//

import Foundation

struct CivicData: Decodable{
    
    let officials : [Officials]
    
    struct Officials: Decodable {
        let name: String
        
    }
}
