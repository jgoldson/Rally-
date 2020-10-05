//
//  CivicManager.swift
//  Flash Chat iOS13
//
//  Created by Jon Goldson on 9/25/20.
//  Copyright © 2020 Angela Yu. All rights reserved.
//

import Foundation
import CoreLocation

protocol ApiManagerDelegate {
    func didUpdateApi(_ apiManager: ApiManager, civic: CivicModel)
    func didFailWithError(error: Error)
}

struct ApiManager {
    let apiURL = "https://www.googleapis.com/civicinfo/v2/representatives?key=\(K.Google.apiKey)"
    
    var delegate: ApiManagerDelegate?
    
    func fetchApiData(cityName: String) {
        let urlString = "\(apiURL)&q=\(cityName)"
        performRequest(with: urlString)
    }
    
    func fetchApiData(address: String) {
        
        let urlString = "\(apiURL)&address=\(String(describing: address))&roles=legislatorLowerBody&includeOffices=true"
        print(urlString)
        performRequest(with: urlString)
    }
    
    func performRequest(with urlString: String) {
        if let urlStringFormat = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed){
            if let url = URL(string: urlStringFormat) {
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: url) { (data, response, error) in
                    if error != nil {
                        self.delegate?.didFailWithError(error: error!)
                        return
                    }
                    if let safeData = data {
                        if let civic = self.parseJSON(safeData) {
                            self.delegate?.didUpdateApi(self, civic: civic)
                        }
                    }
                }
                task.resume()
            }
        }
    }
    
    func parseJSON(_ civicData: Data) -> CivicModel? {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(CivicData.self, from: civicData)
            let name = decodedData.officials[0].name
            let civic = CivicModel(representative: name)
            print("The name of your rep is \(civic)")
            return civic
            
        } catch {
            delegate?.didFailWithError(error: error)
            return nil
        }
    }
    
    
    
}
