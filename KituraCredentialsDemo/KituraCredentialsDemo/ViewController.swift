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
        fbLoginButton.loginBehavior = FBSDKLoginBehavior.SystemAccount
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        googleLoginButton.colorScheme = GIDSignInButtonColorScheme.Dark
        
        dataView.text = ""
        signOutButton.hidden = true
        credentialsButton.hidden = true
        
        UserManager.SharedInstance.updateFromUserDefaults()
        switch UserManager.SharedInstance.userAuthenticationState {
        case .signedInWithGoogle:
            if UserManager.SharedInstance.googleUser == nil {
                GIDSignIn.sharedInstance().signInSilently()
            }
        case .signedInWithFacebook:
            if FBSDKAccessToken.currentAccessToken()?.tokenString != nil {
                stopLoading()
            }
        case .signedOut: break
        }
    }
    
    @IBAction func loginTapped(sender: AnyObject) {
        startLoading("Connecting")
    }
    
    @IBAction func signOutButtonPressed(sender: UIButton) {
        UserManager.SharedInstance.signOut()
        loginContainer.hidden = false
        fbLoginButton.hidden = false
        fbLoginButton.setNeedsLayout()
        googleLoginButton.hidden = false
        signOutButton.hidden = true
        credentialsButton.hidden = true
        dataView.text = ""
    }
    
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
    
    /**
     Method to start the loading animation and setup UI for loading
     */
    func startLoading(connectingMessage: String) {
        fbLoginButton.hidden = true
        googleLoginButton.hidden = true
        loadingIndicator.startAnimating()
        loadingIndicator.hidden = false
        connectingLabel.text = connectingMessage
        connectingLabel.hidden = false
    }
    
    /**
     Method to stop the loading animation and setup UI for signed in state
     */
    func stopLoading() {
        loadingIndicator.stopAnimating()
        loadingIndicator.hidden = true
        connectingLabel.hidden = true
        fbLoginButton.hidden = true
        googleLoginButton.hidden = true
        loginContainer.hidden = true
        
        signOutButton.hidden = false
        credentialsButton.hidden = false
    }
    
    
    // Facebook
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if error != nil {
            print("Unable to authenticate with Facebook. Error=\(error!.localizedDescription)")
        }
        else if result.isCancelled {
        }
        else {
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": ""])
            graphRequest.startWithCompletionHandler() { connection, result, error in
                if error != nil {
                    print("Unable to get Facebook user info: \(error!.localizedDescription)")
                }
                else {
                    let fbId = result.valueForKey("id") as! String
                    let fbName = result.valueForKey("name") as! String
                    if(FBSDKAccessToken.currentAccessToken() != nil) {
                        self.signedInAs(fbName, id: fbId, userState: .signedInWithFacebook)
                    } else {
                        print("Unable to get Facebook access token")
                    }
                }
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
    }
    
    
    // Google
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if error != nil {
            print("Unable to get Google user info: \(error!.localizedDescription)")
        }
        else {
            let userId = user.userID
            let name = user.profile.name
            UserManager.SharedInstance.googleUser = user
            self.signedInAs(name, id: userId, userState: .signedInWithGoogle)
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!, withError error: NSError!) {
    }
    
    
    func signedInAs(userName: String, id: String, userState: UserManager.UserAuthenticationState) {
        stopLoading()

        UserManager.SharedInstance.userDisplayName = userName
        UserManager.SharedInstance.uniqueUserID = id
        UserManager.SharedInstance.userAuthenticationState = userState
        NSUserDefaults.standardUserDefaults().setObject(id, forKey: "user_id")
        NSUserDefaults.standardUserDefaults().setObject(userName, forKey: "user_name")
        NSUserDefaults.standardUserDefaults().setObject(userState.rawValue,forKey: "signedInWith")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}
