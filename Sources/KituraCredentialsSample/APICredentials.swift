/**
 * Copyright IBM Corporation 2016, 2017
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
import CredentialsFacebook
import CredentialsGoogle
import CredentialsHTTP

import SwiftyJSON

import Foundation

// Non-redirecting authentication

func setupAPI() {
    let apiCredentials = Credentials()
    
    let fbTokenCredentials = CredentialsFacebookToken()
    let googleTokenCredentials = CredentialsGoogleToken()
    apiCredentials.register(plugin: fbTokenCredentials)
    apiCredentials.register(plugin: googleTokenCredentials)
    
    // HTTP plugins, digest is registered first, it should be the one that sets the response headers of rejected requests
    let users = ["John" : "12345", "Mary" : "qwerasdf"]
    let digestCredentials = CredentialsHTTPDigest(userProfileLoader: { userId, callback in
        if let storedPassword = users[userId] {
            callback(UserProfile(id: userId, displayName: userId, provider: "HTTPDigest"), storedPassword)
        }
        else {
            callback(nil, nil)
        }
        }, opaque: "0a0b0c0d", realm: "Kitura-users")
    
    apiCredentials.register(plugin: digestCredentials)
    
    let basicCredentials = CredentialsHTTPBasic(userProfileLoader: { userId, callback in
        if let storedPassword = users[userId] {
            callback(UserProfile(id: userId, displayName: userId, provider: "HTTPBasic"), storedPassword)
        }
        else {
            callback(nil, nil)
        }
    })
    apiCredentials.register(plugin: basicCredentials)
    
    router.all("/private/api", middleware: apiCredentials)
    router.get("/private/api/data", handler:
        { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                try response.format(callbacks: [
                    "text/plain" : { request, response in
                        do {
                            if let userProfile = request.userProfile  {
                                try response.status(.OK).send("Hello " +  userProfile.displayName + "!\nYou are logged in with " + userProfile.provider + ".").end()
                            }
                            else {
                                try response.status(.unauthorized).send("You are not authorized to view this data").end()
                            }
                        }
                        catch {}
                        next()
                    },
                    "text/html" : { request, response in
                        do {
                            if let userProfile = request.userProfile  {
                                try response.status(.OK).send(
                                    "<!DOCTYPE html><html><body>Hello " + userProfile.displayName + "!\nYou are logged in with " + userProfile.provider + ". This is private!<br>" + "</body></html>\n\n").end()
                            }
                            else {
                                try response.status(.unauthorized).send(
                                    "<!DOCTYPE html><html><body>You are not authorized to view this page</body></html>\n\n").end()
                            }
                        }
                        catch {}
                    }])
            }
            catch {}
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
                try response.status(.unauthorized).send(
                    "<!DOCTYPE html><html><body>" +
                        "You are not authorized to view this page" +
                    "</body></html>\n\n").end()
            }
            catch {}
            next()
    })
}
