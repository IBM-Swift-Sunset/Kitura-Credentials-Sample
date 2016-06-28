/**
 * Copyright IBM Corporation 2015-2016
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
import Alamofire

/// Manages all user authentication state and calls
class UserManager: NSObject {
    
    enum UserAuthenticationState : String {
        case SignedInWithFacebook
        case SignedInWithGoogle
        case SignedOut
    }
    
    /// Shared instance of user manager
    static let SharedInstance: UserManager = {
        var manager = UserManager()
        return manager
    }()
    
    private override init() {} //This prevents others from using the default '()' initializer for this class.
    
    /// Display name for user
    var userDisplayName: String?
    
    /// Unique user ID
    var uniqueUserID: String?
    
    /// User's authentication state
    var userAuthenticationState = UserAuthenticationState.SignedOut
    
    /// User object received from Google after signing in
    var googleUser: GIDGoogleUser?
    
    
    func updateFromUserDefaults() {
        if let userID = NSUserDefaults.standardUserDefaults().objectForKey("user_id") as? String,
            let userName = NSUserDefaults.standardUserDefaults().objectForKey("user_name") as? String,
            let signedInWith = NSUserDefaults.standardUserDefaults().objectForKey("signedInWith") as? String {
            userAuthenticationState = UserAuthenticationState(rawValue: signedInWith)!
            if  userAuthenticationState == .SignedInWithFacebook {
                userDisplayName = userName
                uniqueUserID = userID
            }
        }
    }
    
    func signOut() {
        userDisplayName = nil
        uniqueUserID = nil
        googleUser = nil
        switch userAuthenticationState {
        case .SignedInWithFacebook:
            FBSDKLoginManager().logOut()
        case .SignedInWithGoogle:
            GIDSignIn.sharedInstance().signOut()
        default: break
        }
        
        userAuthenticationState = .SignedOut
        NSUserDefaults.standardUserDefaults().removeObjectForKey("user_id")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("user_name")
        NSUserDefaults.standardUserDefaults().setObject(String(UserAuthenticationState.SignedOut), forKey: "signedInWith")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func getPrivateData(onSuccess onSuccess: (data: String) -> Void, onFailure: (error: String) -> Void) {
        let url = "http://localhost:8090/private/api/data"
        guard let nsURL = NSURL(string: url) else {
            onFailure(error: "Bad URL")
            return
        }
        
        let mutableURLRequest = NSMutableURLRequest(URL: nsURL)
        mutableURLRequest.HTTPMethod = "GET"
        
        switch UserManager.SharedInstance.userAuthenticationState {
        case .SignedInWithFacebook:
            mutableURLRequest.addValue(FBSDKAccessToken.currentAccessToken().tokenString, forHTTPHeaderField: "access_token")
            mutableURLRequest.addValue("FacebookToken", forHTTPHeaderField: "X-token-type")
            mutableURLRequest.addValue("text/plain", forHTTPHeaderField: "Accept")
            self.sendRequest(mutableURLRequest, onSuccess: onSuccess, onFailure: onFailure)
        case .SignedInWithGoogle:
            UserManager.SharedInstance.googleUser?.authentication.getTokensWithHandler({ (auth, error) in
                guard error == nil else {
                    onFailure(error: "Failed to get Google access token: \(error.localizedDescription)")
                    return
                }
                mutableURLRequest.addValue(auth.accessToken, forHTTPHeaderField: "access_token")
                mutableURLRequest.addValue("GoogleToken", forHTTPHeaderField: "X-token-type")
                self.sendRequest(mutableURLRequest, onSuccess: onSuccess, onFailure: onFailure)
            })
        case .SignedOut:
            onFailure(error: "User not signed in")
        }
    }
    
    private func sendRequest (mutableURLRequest: NSMutableURLRequest, onSuccess: (data: String) -> Void, onFailure: (error: String) -> Void) {
        Alamofire.request(mutableURLRequest).responseString { response in
            guard let responseValue = response.result.value where response.result.isSuccess == true else {
                onFailure(error: "Request failed")
                return
            }
            onSuccess(data: responseValue)
        }
    }
}
