/**
 * Copyright IBM Corporation 2016
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

import Credentials

public class GoogleUserProfileDelegate: UserProfileDelegate {
    public func userProfileToDictionary(_ userProfile: UserProfile) -> [String:Any] {
        var dictionary = [String:String]()
        dictionary["displayName"] = userProfile.displayName
        dictionary["id"] = userProfile.id
        dictionary["provider"] = userProfile.provider
        dictionary["email"] = userProfile.emails?[0].value
        dictionary["gender"] = userProfile.extendedProperties?["gender"] as? String
        return dictionary
    }
    
    public func identityProviderDictionaryToUserProfile(_ dictionary: [String:Any]) -> UserProfile? {
        if let name = dictionary["name"] as? String,
            let id = dictionary["sub"] as? String,
            let email = dictionary["email"] as? String,
            let gender = dictionary["gender"] as? String {
            let userEmail = UserProfile.UserProfileEmail(value: email, type: "")
            return UserProfile(id: id, displayName: name, provider: "Google", emails: [userEmail], extendedProperties: ["gender":gender])
        }
        return nil
    }
    
    public func dictionaryToUserProfile(_ dictionary: [String:Any]) -> UserProfile? {
        if let name = dictionary["displayName"] as? String,
            let id = dictionary["id"] as? String,
            let email = dictionary["email"] as? String,
            let gender = dictionary["gender"] as? String {
            let userEmail = UserProfile.UserProfileEmail(value: email, type: "")
            return UserProfile(id: id, displayName: name, provider: "Google", emails: [userEmail], extendedProperties: ["gender":gender])
        }
        return nil
    }
}
