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

class ViewController: UIViewController, FBSDKLoginButtonDelegate, GIDSignInUIDelegate, GIDSignInDelegate {


    
    @IBOutlet weak var connectingLabel: UILabel!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var googleLoginButton: GIDSignInButton!
    
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    
    @IBOutlet weak var credentialsButton: UIButton!
    
    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet weak var dataView: UITextView!
    
    @IBOutlet weak var loginContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fbLoginButton.delegate = self
        fbLoginButton.readPermissions = ["public_profile", "email"]
        fbLoginButton.loginBehavior = FBSDKLoginBehavior.systemAccount
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        googleLoginButton.colorScheme = GIDSignInButtonColorScheme.dark
        
        dataView.text = ""
        signOutButton.isHidden = true
        credentialsButton.isHidden = true
        
        UserManager.SharedInstance.updateFromUserDefaults()
        switch UserManager.SharedInstance.userAuthenticationState {
        case .signedInWithGoogle:
            if UserManager.SharedInstance.googleUser == nil {
                GIDSignIn.sharedInstance().signInSilently()
            }
        case .signedInWithFacebook:
            if FBSDKAccessToken.current()?.tokenString != nil {
                stopLoading()
            }
        case .signedOut: break
        }
    }
    
    @IBAction func loginTapped(_ sender: AnyObject) {
        startLoading("Connecting")
    }
    
    @IBAction func signOutButtonPressed(_ sender: UIButton) {
        UserManager.SharedInstance.signOut()
        loginContainer.isHidden = false
        fbLoginButton.isHidden = false
        fbLoginButton.setNeedsLayout()
        googleLoginButton.isHidden = false
        signOutButton.isHidden = true
        credentialsButton.isHidden = true
        dataView.text = ""
    }
    
    @IBAction func credentialsButtonPressed(_ sender: UIButton) {
        UserManager.SharedInstance.getPrivateData(
            onSuccess: { data in
                self.dataView.text = data
            },
            onFailure: { error in
                self.dataView.text = "Failed to get private data"
                print("Failed to get private data: ", error)
        })
    }
    
    /**
     Method to start the loading animation and setup UI for loading
     */
    func startLoading(_ connectingMessage: String) {
        fbLoginButton.isHidden = true
        googleLoginButton.isHidden = true
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        connectingLabel.text = connectingMessage
        connectingLabel.isHidden = false
    }
    
    /**
     Method to stop the loading animation and setup UI for signed in state
     */
    func stopLoading() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        connectingLabel.isHidden = true
        fbLoginButton.isHidden = true
        googleLoginButton.isHidden = true
        loginContainer.isHidden = true
        
        signOutButton.isHidden = false
        credentialsButton.isHidden = false
    }
    
    // Facebook
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print("Unable to authenticate with Facebook. Error=\(error!.localizedDescription)")
        }
        else if result.isCancelled {
        }
        else {
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": ""])
            graphRequest?.start() { _, result, error in
                print(result)
                if error != nil {
                    print("Unable to get Facebook user info: \(error!.localizedDescription)")
                }
                else if let result = result as? [String:String] {
                    let fbId = result["id"]
                    let fbName = result["name"]
                    if(FBSDKAccessToken.current() != nil) {
                        self.signedInAs(fbName!, id: fbId!, userState: .signedInWithFacebook)
                    } else {
                        print("Unable to get Facebook access token")
                    }
                }
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
    }
    
   
    // Google
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            print("Unable to get Google user info: \(error!.localizedDescription)")
        }
        else {
            let userId = user.userID
            let name = user.profile.name
            UserManager.SharedInstance.googleUser = user
            self.signedInAs(name!, id: userId!, userState: .signedInWithGoogle)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!, withError error: Error!) {
    }
    
    
    func signedInAs(_ userName: String, id: String, userState: UserManager.UserAuthenticationState) {
        stopLoading()

        UserManager.SharedInstance.userDisplayName = userName
        UserManager.SharedInstance.uniqueUserID = id
        UserManager.SharedInstance.userAuthenticationState = userState
        UserDefaults.standard.set(id, forKey: "user_id")
        UserDefaults.standard.set(userName, forKey: "user_name")
        UserDefaults.standard.set(userState.rawValue,forKey: "signedInWith")
        UserDefaults.standard.synchronize()
    }
    
}
