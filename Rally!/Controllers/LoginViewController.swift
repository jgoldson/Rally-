//
//  LoginViewController.swift
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    

    @IBAction func loginPressed(_ sender: UIButton) {
        
        if let email = emailTextfield.text, let password = passwordTextfield.text {
        Auth.auth().signIn(withEmail: email, password: password) {  authResult, error in
            if let e = error {
                print(e.localizedDescription)
                self.errorMessage.text = e.localizedDescription
                self.errorMessage.isHidden = false
            } else {
                self.errorMessage.isHidden = true
                self.performSegue(withIdentifier: K.loginSegue, sender: self)
            }
         
        }
        }
    }
    
}
