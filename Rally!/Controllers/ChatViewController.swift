//
//  ChatViewController.swift
//

import UIKit
import Firebase
import CoreLocation
import MapKit



class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var repLabel: UILabel!
    
    
    let db = Firestore.firestore()
    
    let locationManager = CLLocationManager()
    var civicManager = ApiManager()
    var messages: [Message] = []
    var civicModel = CivicModel(representative: K.FStore.collectionName)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        repLabel.isHidden = true
        
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
                                        if (diff.type == .modified) {
                                            if messageScore <= -5 {
                                                self.db.collection(self.civicModel.representative).document(messageDoc).delete() { err in
                                                    if let err = err {
                                                        print("Error removing document: \(err)")
                                                    } else {
                                                        print("Document successfully removed!")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }}
    
    
    @IBAction func AddItemPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "What do you want your \n representative to work on? \n", message: "\n\n\n\n\n", preferredStyle: .alert)
        alert.view.autoresizesSubviews = true

        let textView = UITextView(frame: CGRect.zero)
        textView.translatesAutoresizingMaskIntoConstraints = false

        let leadConstraint = NSLayoutConstraint(item: alert.view, attribute: .leading, relatedBy: .equal, toItem: textView, attribute: .leading, multiplier: 1.0, constant: -8.0)
        let trailConstraint = NSLayoutConstraint(item: alert.view, attribute: .trailing, relatedBy: .equal, toItem: textView, attribute: .trailing, multiplier: 1.0, constant: 8.0)

        let topConstraint = NSLayoutConstraint(item: alert.view, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .top, multiplier: 1.0, constant: -64.0)
        let bottomConstraint = NSLayoutConstraint(item: alert.view, attribute: .bottom, relatedBy: .equal, toItem: textView, attribute: .bottom, multiplier: 1.0, constant: 64.0)
        alert.view.addSubview(textView)
        NSLayoutConstraint.activate([leadConstraint, trailConstraint, topConstraint, bottomConstraint])
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            print("Cancelling out of add idea")
        }))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { action in
            print("\(String(describing: textView.text))")
            if let messageBody = textView.text, let messageSender = Auth.auth().currentUser?.email, let senderId = Auth.auth().currentUser?.uid  {
                self.db.collection(self.civicModel.representative).addDocument(data:
                                                                        [K.FStore.senderField : messageSender,
                                                                         K.FStore.bodyField : messageBody,
                                                                         K.FStore.dateField : Date().timeIntervalSince1970,
                                                                         K.FStore.scoreField: 1,
                                                                         K.FStore.repField: self.civicModel.representative,
                                                                         K.FStore.upSelected: [senderId : true],
                                                                         K.FStore.downSelected: [senderId : false]
                                                                        ]) { (error) in
                    if let e = error {
                        print("There was an issue saving data to firestore, \(e)")
                    } else {
                        print("Success")
                        
                    }
                }
            }
        }))
        present(alert, animated: true)
            

            
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

//MARK - TableView Extension

extension ChatViewController: UITableViewDataSource, CellDelegate {
    func didTapButton(cell: MessageCell, button: Int) {
        var points = 0
        if let user = Auth.auth().currentUser?.uid,
           let docId = cell.docReferenceLabel.text,
           let rep = cell.repLabel.text {
            let ref = db.collection(rep).document(docId)
            if let indexPath = tableView.indexPath(for: cell) {
                if button == 1 {
                    if cell.upButton.isSelected == true {
                        points = -1
                        cell.upButton.isSelected = false
                        ref.updateData(["\(K.FStore.upSelected).\(user)": false])
                    } else if cell.downButton.isSelected == false {
                        points = 1
                        ref.updateData(["\(K.FStore.upSelected).\(user)": true])
                        cell.upButton.isSelected = true
                    }
                }

             else if button == 0 {
                if cell.downButton.isSelected == true {
                    points = 1
                    cell.downButton.isSelected = false
                    ref.updateData(["\(K.FStore.downSelected).\(user)": false])
                } else if cell.upButton.isSelected == false {
                    points = -1
                    ref.updateData(["\(K.FStore.downSelected).\(user)": true])
                    cell.downButton.isSelected = true
                }
            }
                ref.updateData([K.FStore.scoreField : FieldValue.increment(Int64(points))])
                
       
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
        
            self.tableView.rowHeight = UITableView.automaticDimension;
            self.tableView.estimatedRowHeight = 44.0;
        
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
                cell.upButton.isSelected = true
                cell.upButton.tintColor = UIColor.systemBlue
            case false:
                cell.upButton.isSelected = false
                cell.upButton.tintColor = UIColor.lightGray
            default:
                cell.upButton.isSelected = false
            }
            
            switch message.downSelected[userId] {
            case true:
                cell.downButton.isSelected = true
                cell.downButton.tintColor = UIColor.systemBlue
            case false:
                cell.downButton.isSelected = false
                cell.downButton.tintColor = UIColor.lightGray
            default :
                cell.downButton.isSelected = false
            }
            
        
        
        
        if message.sender == user.email {
            
            cell.messageBubble.backgroundColor = UIColor.white
            //cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightBlue)
            //cell.label.textColor = UIColor(named: K.BrandColors.blue)
            cell.label.textColor = UIColor.black
            cell.messageBubble.backgroundColor = UIColor.white
        }
        else {
            
            //cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.blue)
            //cell.label.textColor = UIColor(named: K.BrandColors.lightBlue)
            cell.messageBubble.backgroundColor = UIColor.white
            cell.label.textColor = UIColor.black
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
        let alert = UIAlertController(title: "Failed to obtain location", message: "The application was unable to obtain your current location, please check your permission settings under Settings -> Privacy -> Location Services", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { action in self.locationManager.requestLocation()
        }))
        

        self.present(alert, animated: true)
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
        if name != nil {
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
            self.repLabel.text = "Representative: \(self.civicModel.representative)"
            self.repLabel.isHidden = false
            print("Inside chatviewcontroller, rep is \(self.civicModel.representative)")
        }
    }
    func didFailWithError(error: Error) {
        print(error)
    }
}



