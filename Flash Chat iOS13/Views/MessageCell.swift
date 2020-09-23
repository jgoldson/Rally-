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
    
    var score = 0
    let db = Firestore.firestore()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageBubble.layer.cornerRadius = messageBubble.frame.size.height / 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func upVote(_ sender: UIButton) {
        score += 1
        scoreLabel.text = String(score)
        updateData()
    }
    @IBAction func downVote(_ sender: Any) {
        score -= 1
        scoreLabel.text = String(score)
        updateData()
        
    }
    
    func updateData() {
        db.collection(K.FStore.collectionName).doc(updateData(data:
         [K.FStore.scoreField: score])
    }
}
