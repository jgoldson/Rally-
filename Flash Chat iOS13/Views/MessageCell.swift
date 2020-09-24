//
//  MessageCell.swift
//  Flash Chat iOS13
//
//  Created by Jon Goldson on 9/16/20.
//  Copyright © 2020 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var messageBubble: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var docReferenceLabel: UILabel!
    
    var upVoteSelected = false
    var downVoteSelected = false
    let db = Firestore.firestore()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageBubble.layer.cornerRadius = messageBubble.frame.size.height / 5
        docReferenceLabel.isHidden = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func upVote(_ sender: UIButton) {
        
            if let docId = docReferenceLabel.text {
                if downVoteSelected == true {
                    db.collection(K.FStore.collectionName).document(docId).updateData(["score" : FieldValue.increment(Int64(1))])
                    downVoteSelected = false
                }
                if upVoteSelected == false {
                    db.collection(K.FStore.collectionName).document(docId).updateData(["score" : FieldValue.increment(Int64(1))])         }
                    upVoteSelected = true
            }
        }
    
    @IBAction func downVote(_ sender: Any) {
        
        
        if let docId = docReferenceLabel.text {
            if upVoteSelected == true {
                db.collection(K.FStore.collectionName).document(docId).updateData(["score" : FieldValue.increment(Int64(-1))])
                upVoteSelected = false
            }
            if downVoteSelected == false {
                db.collection(K.FStore.collectionName).document(docId).updateData(["score" : FieldValue.increment(Int64(-1))])
                downVoteSelected = true
            }

        }
    }
/* Commenting out updateData function as replaced with increment
    func updateData() {
        print(docReferenceLabel.text)
        if let docId = docReferenceLabel.text {
            db.collection(K.FStore.collectionName).document(docId).updateData([K.FStore.scoreField: score])
        }
    }

    func getScore(docId: String) -> Int {
        
        let docRef = db.collection(K.FStore.collectionName).document(docId)
        docRef.getDocument { (document, error) in
            self.score = document?.get("score") as! Int
                
                
            }
        print(score)
        return score
        }
        
    */
    
}
