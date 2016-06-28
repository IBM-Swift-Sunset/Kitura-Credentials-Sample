/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/


import UIKit

class CredentialsViewController: UIViewController {
    
    @IBOutlet weak var credentialsButton: UIButton!
    
    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet weak var dataView: UITextView!
    
    @IBAction func credentialsButtonPressed(sender: UIButton) {
        UserManager.SharedInstance.getPrivateData(
            onSuccess: { data in
                self.dataView.text = data
            },
            onFailure: { error in
                self.dataView.text = "Failed to get private data"
                print("Failed to get private data: ", error)
        })
    }
    
    @IBAction func signOutPressed(sender: UIButton) {
        UserManager.SharedInstance.signOut()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataView.text = ""
    }
}