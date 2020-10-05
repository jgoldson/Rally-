//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapKit



class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    let locationManager = CLLocationManager()
    var civicManager = ApiManager()
    var messages: [Message] = []
    var civicModel = CivicModel(representative: K.FStore.collectionName)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
   
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        civicManager.delegate = self
        
        
        
        tableView.dataSource = self
        
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        
    }
    
    func loadMessages() {
        
        
        
        db.collection(civicModel.representative)
            .order(by: K.FStore.scoreField, descending: true)
            .addSnapshotListener()
            { (querySnapshot, error) in
                if let e = error {
                    print("There was an issue retrieving data from firestore. \(e)")
                } else {
                    //                querySnapshot?.documentChanges.forEach { diff in
                    //                if (diff.type == .added) {
                    if let snapshotDocuments = querySnapshot?.documents {
                        
                        self.messages = []
                        for doc in snapshotDocuments {
                            let data = doc.data()
                            let messageDoc = doc.documentID
                            
                            if let messageSender = data[K.FStore.senderField] as? String,
                               let messageBody = data[K.FStore.bodyField] as? String,
                               let messageScore = data[K.FStore.scoreField] as? Int,
                               let messageUser = Auth.auth().currentUser?.uid,
                               let upSelectionUsers = data[K.FStore.upSelected] as? [String: Bool],
                               let downSelectionUsers = data[K.FStore.downSelected] as? [String: Bool]
                               {
                                let upIsSelected = upSelectionUsers[messageUser] ?? false
                                let downIsSelected = downSelectionUsers[messageUser] ?? false
                                
                                let newMessage = Message(sender: messageSender, body: messageBody, score: messageScore, id: messageDoc, rep: self.civicModel.representative, upSelected: [messageUser: upIsSelected ], downSelected: [messageUser: downIsSelected ])
                                self.messages.append(newMessage)
                                
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    querySnapshot?.documentChanges.forEach { diff in
                                        if (diff.type == .added) {
                                            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }}
    
    @IBAction func sendPressed(_ sender: UIButton) {
        
        
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email, let senderId = Auth.auth().currentUser?.uid  {
            db.collection(civicModel.representative).addDocument(data:
                                                                    [K.FStore.senderField : messageSender,
                                                                     K.FStore.bodyField : messageBody,
                                                                     K.FStore.dateField : Date().timeIntervalSince1970,
                                                                     K.FStore.scoreField: 1,
                                                                     K.FStore.repField: civicModel.representative,
                                                                     K.FStore.upSelected: [senderId : true],
                                                                     K.FStore.downSelected: [senderId : false]
                                                                    ]) { (error) in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                } else {
                    print("Success")
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                    
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    
}



extension ChatViewController: UITableViewDataSource, CellDelegate {
    func didTapButton(cell: MessageCell, button: Int) {
        var points = 0
        if let user = Auth.auth().currentUser?.uid,
           let docId = cell.docReferenceLabel.text,
           let rep = cell.repLabel.text {
            let ref = db.collection(rep).document(docId)
            if let indexPath = tableView.indexPath(for: cell) {
                if button == 1 {
                    if cell.downButton.isEnabled == false {
                        points = 2
                    } else { points = 1 }
                    ref.updateData(["\(K.FStore.upSelected).\(user)": true])
                    ref.updateData(["\(K.FStore.downSelected).\(user)": false])
                    cell.upButton.isEnabled = false
                    cell.downButton.isEnabled = true
                }

             else if button == 0 {
                if cell.upButton.isEnabled == false {
                    points = -2
                } else { points = -1 }
                ref.updateData(["\(K.FStore.downSelected).\(user)": true])
                ref.updateData(["\(K.FStore.upSelected).\(user)": false])
                cell.upButton.isEnabled = true
                cell.downButton.isEnabled = false
            }
            ref.updateData(["score" : FieldValue.increment(Int64(points))])
        }
    }
    }
    
    
    
    
    func getCurrentCellIndexPath(_ sender: UIButton) -> IndexPath? {
        let buttonPosition = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath: IndexPath = tableView.indexPathForRow(at: buttonPosition) {
            return indexPath
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let message = messages[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
            cell.label.text = message.body
            cell.docReferenceLabel.text = message.id
            cell.repLabel.text = message.rep
            cell.scoreLabel.text = String(message.score)
            cell.cellDelegate = self
        
        if let user = Auth.auth().currentUser {
            let userId = user.uid
            
            switch message.upSelected[userId]{
            case true:
                cell.upButton.isEnabled = false
            case false:
                cell.upButton.isEnabled = true
            default:
                cell.upButton.isEnabled = true
            }
            
            switch message.downSelected[userId] {
            case true:
                cell.downButton.isEnabled = false
            case false:
                cell.downButton.isEnabled = true
            default :
                cell.downButton.isEnabled = true
            }
            
        
        
        
        if message.sender == user.email {
            
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightBlue)
            cell.label.textColor = UIColor(named: K.BrandColors.blue)
        }
        else {
            
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.blue)
            cell.label.textColor = UIColor(named: K.BrandColors.lightBlue)
        }
        }
        return cell
    }
    
    
    
    
}

extension ChatViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        let lat = locValue.latitude
        let long = locValue.longitude
        print("locations = \(lat) \(long)")
        let geocoder = CLGeocoder()
        // Create Location
        let location = CLLocation(latitude: lat, longitude: long)
        
        // Geocode Location
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            // Process Response
            if let address = self.processResponse(withPlacemarks: placemarks, error: error){
                //let formatedAddress = address.replacingOccurrences(of: " ", with: "%", options: .literal, range: nil)
                self.civicManager.fetchApiData(address: address)
                
            }
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to obtain location")
    }
    func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) -> String? {
        
        
        if let error = error {
            print("Unable to Reverse Geocode Location (\(error))")
            return nil
            
        } else {
            if let placemarks = placemarks, let placemark = placemarks.first {
                return placemark.compactAddress
                
                
            } else {
                print("No Matching Addresses Found")
                return nil
            }
        }
    }
    
    
}
extension CLPlacemark {
    
    var compactAddress: String? {
        if let name = name {
            var result = ""
            
            if let street = thoroughfare {
                result += "\(street)"
            }
            
            if let city = locality {
                result += " \(city)"
            }
            
            if let state = administrativeArea {
                result += " \(state)"
            }
            
            if let zipCode = postalCode {
                result += " \(zipCode)"
            }
            /*
             if let country = country {
             result += " \(country)"
             }
             */
            
            return result
        }
        
        return nil
    }
    
}

extension ChatViewController: ApiManagerDelegate {
    func didUpdateApi(_ apiManager: ApiManager, civic: CivicModel) {
        DispatchQueue.main.async{
            self.civicModel.representative = civic.representative
            self.loadMessages()
            print("Inside chatviewcontroller, rep is \(self.civicModel.representative)")
        }
    }
    func didFailWithError(error: Error) {
        print(error)
    }
}



