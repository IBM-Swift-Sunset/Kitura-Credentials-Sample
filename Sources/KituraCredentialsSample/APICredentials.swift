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


import Kitura
import Credentials
import CredentialsFacebookToken
import CredentialsGoogleToken
import CredentialsHttp


// Non-redirecting authentication

func setupAPI() {
    let apiCredentials = Credentials()
    
    // Token plugins will pass
    let fbTokenCredentials = CredentialsFacebookToken()
    let googleTokenCredentials = CredentialsGoogleToken()
    apiCredentials.register(plugin: fbTokenCredentials)
    apiCredentials.register(plugin: googleTokenCredentials)
    
    // HTTP plugins, digest is registered first, it should be the one that sets the response headers of rejected requests
    let users = ["John" : "12345", "Mary" : "qwerasdf"]
    let digestCredentials = CredentialsHttpDigest(userProfileLoader: { userId, callback in
        if let storedPassword = users[userId] {
            callback(userProfile: UserProfile(id: userId, displayName: userId, provider: "HttpDigest"), password: storedPassword)
        }
        else {
            callback(userProfile: nil, password: nil)
        }
        }, realm: "Kitura-users", opaque: "0a0b0c0d")
    
    apiCredentials.register(plugin: digestCredentials)
    
    let basicCredentials = CredentialsHttpBasic(userProfileLoader: { userId, callback in
        if let storedPassword = users[userId] {
            callback(userProfile: UserProfile(id: userId, displayName: userId, provider: "HttpBasic"), password: storedPassword)
        }
        else {
            callback(userProfile: nil, password: nil)
        }
    })
    apiCredentials.register(plugin: basicCredentials)
    
    router.all("/private/api", middleware: apiCredentials)
    router.get("/private/api/data", handler:
        { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                if let userProfile = request.userProfile  {
                    try response.status(.OK).send(
                        "<!DOCTYPE html><html><body>" +
                            "Hello " +  userProfile.displayName + "! You are logged in with " + userProfile.provider + ". This is private!<br>" +
                        "</body></html>\n\n").end()
                    next()
                    return
                }
                try response.status(.OK).send(
                    "<!DOCTYPE html><html><body>" +
                        "You are not authorized to view this page" +
                    "</body></html>\n\n").end()
            }
            catch {}
            next()
    })
    
    
    // Only HTTP basic is registered, the authentication should be basic here
    let apiBasicCredentials = Credentials()
    apiBasicCredentials.register(plugin: basicCredentials)
    
    router.all("/private/basic/api", middleware: apiBasicCredentials)
    router.get("/private/basic/api/data", handler:
        { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                if let userProfile = request.userProfile  {
                    try response.status(.OK).send(
                        "<!DOCTYPE html><html><body>" +
                            "Hello " +  userProfile.displayName + "! You are logged in with " + userProfile.provider + ". This is private!<br>" +
                        "</body></html>\n\n").end()
                    next()
                    return
                }
                try response.status(.OK).send(
                    "<!DOCTYPE html><html><body>" +
                        "You are not authorized to view this page" +
                    "</body></html>\n\n").end()
            }
            catch {}
            next()
    })
}
