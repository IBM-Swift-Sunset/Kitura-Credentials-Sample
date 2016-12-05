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

class UserManager: NSObject {
    
    enum UserAuthenticationState : String {
        case signedInWithFacebook
        case signedInWithGoogle
        case signedOut
    }
    
    /// Shared instance of user manager
    static let SharedInstance: UserManager = {
        var manager = UserManager()
        return manager
    }()
    
    fileprivate override init() {} //This prevents others from using the default '()' initializer for this class.
    
    /// Display name for user
    var userDisplayName: String?
    
    /// Unique user ID
    var uniqueUserID: String?
    
    /// User's authentication state
    var userAuthenticationState = UserAuthenticationState.signedOut
    
    /// User object received from Google after signing in
    var googleUser: GIDGoogleUser?
    
    
    func updateFromUserDefaults() {
        if let userID = UserDefaults.standard.object(forKey: "user_id") as? String,
            let userName = UserDefaults.standard.object(forKey: "user_name") as? String,
            let signedInWith = UserDefaults.standard.object(forKey: "signedInWith") as? String {
            userAuthenticationState = UserAuthenticationState(rawValue: signedInWith)!
            if  userAuthenticationState == .signedInWithFacebook {
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
        case .signedInWithFacebook:
            FBSDKLoginManager().logOut()
        case .signedInWithGoogle:
            GIDSignIn.sharedInstance().signOut()
        default: break
        }
        
        userAuthenticationState = .signedOut
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "user_name")
        UserDefaults.standard.set(String(describing: UserAuthenticationState.signedOut), forKey: "signedInWith")
        UserDefaults.standard.synchronize()
    }
    
    func getPrivateData(onSuccess: @escaping (_ data: String) -> Void, onFailure: @escaping (_ error: String) -> Void) {
        let url = "http://localhost:8090/private/api/data"
        guard let nsURL = URL(string: url) else {
            onFailure("Bad URL")
            return
        }
        
        var mutableURLRequest = URLRequest(url: nsURL)
        mutableURLRequest.httpMethod = "GET"
        
        switch UserManager.SharedInstance.userAuthenticationState {
        case .signedInWithFacebook:
            mutableURLRequest.addValue(FBSDKAccessToken.current().tokenString, forHTTPHeaderField: "access_token")
            mutableURLRequest.addValue("FacebookToken", forHTTPHeaderField: "X-token-type")
            mutableURLRequest.addValue("text/plain", forHTTPHeaderField: "Accept")
            self.sendRequest(mutableURLRequest, onSuccess: onSuccess, onFailure: onFailure)
        case .signedInWithGoogle:
            UserManager.SharedInstance.googleUser?.authentication.getTokensWithHandler({ (auth, error) in
                guard error == nil else {
                    onFailure("Failed to get Google access token: \(error?.localizedDescription)")
                    return
                }
                mutableURLRequest.addValue((auth?.accessToken)!, forHTTPHeaderField: "access_token")
                mutableURLRequest.addValue("GoogleToken", forHTTPHeaderField: "X-token-type")
                self.sendRequest(mutableURLRequest, onSuccess: onSuccess, onFailure: onFailure)
            })
        case .signedOut:
            onFailure("User not signed in")
        }
    }
    
    fileprivate func sendRequest (_ mutableURLRequest: URLRequest, onSuccess: @escaping (_ data: String) -> Void, onFailure: @escaping (_ error: String) -> Void) {
        Alamofire.request(mutableURLRequest as URLRequestConvertible).responseString { response in
            guard let responseValue = response.result.value, response.result.isSuccess == true else {
                onFailure("Request failed")
                return
            }
            onSuccess(responseValue)
        }
    }
}
