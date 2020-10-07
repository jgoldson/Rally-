//
//  RegisterViewController.swift
//

import UIKit
import Firebase

class RegisterViewController: UIViewController {

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    
    
    
    @IBAction func registerPressed(_ sender: UIButton) {
        
        if let email = emailTextfield.text, let password = passwordTextfield.text {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let e = error {
                print(e.localizedDescription)
                self.errorMessage.isHidden = false
                self.errorMessage.text = String(e.localizedDescription)
            } else {
                self.errorMessage.isHidden = true
                self.performSegue(withIdentifier: K.registerSegue, sender: self)
                
            }
    
        }
    }
    }
}


