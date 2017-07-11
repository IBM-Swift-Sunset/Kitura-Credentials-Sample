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


import Foundation
import Kitura
import Credentials
import CredentialsFacebook
import CredentialsGoogle
import LoggerAPI
import HeliumLogger


// Authentication with session

func setupPages() {
    let pagesCredentials = Credentials()
    
    let fbClientId = "Facebook client ID"
    let fbCallbackUrl = "serverUrl" + "/login/facebook/callback"
    let fbClientSecret = "Facebook client secret"
    let googleClientId = "Google client ID"
    let googleCallbackUrl = "serverUrl" + "/login/google/callback"
    let googleClientSecret = "Google client secret"
    
    let fbCredentials = CredentialsFacebook(clientId: fbClientId, clientSecret: fbClientSecret, callbackUrl: fbCallbackUrl, options: ["scope":"email", "userProfileDelegate":CustomUserProfileDelegate(), "fields":"email,id,name,gender"])
    let googleCredentials = CredentialsGoogle(clientId: googleClientId, clientSecret: googleClientSecret, callbackUrl: googleCallbackUrl, options: ["scope":"email profile", "userProfileDelegate":CustomUserProfileDelegate()])
    pagesCredentials.register(plugin: fbCredentials)
    pagesCredentials.register(plugin: googleCredentials)
    
    pagesCredentials.options["failureRedirect"] = "/login"
    pagesCredentials.options["successRedirect"] = "/private/pages/data"
    
    router.all("/private/pages", middleware: pagesCredentials)
    router.get("/private/pages/data", handler:
        { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                if let userProfile = request.userProfile  {
                    var emailString = ""
                    var title = ""
                    if let email = userProfile.emails?[0].value {
                        emailString = " Your email is \(email). "
                    }
                    if let gender = userProfile.extendedProperties["gender"] as? String {
                        title = (gender == "female") ? "Ms " : "Mr "
                    }
                    try response.status(.OK).send(
                        "<!DOCTYPE html><html><body>" +
                            "Hello \(title)" +  userProfile.displayName + "! You are logged in with " + userProfile.provider + ". \(emailString)This is private!<br>" +
                            "<a href=/logout>Log Out</a>" +
                        "</body></html>\n\n").end()
                    next()
                    return
                }
                try response.status(.OK).send(
                    "<!DOCTYPE html><html><body>" +
                        "Welcome! Please <a href=/login>login</a>" +
                    "</body></html>\n\n").end()
            }
            catch {
            }
            next()
    })
    
    router.get("/login") { request, response, next in
        response.headers["Content-Type"] = "text/html; charset=utf-8"
        do {
            try response.status(.OK).send(
                "<!DOCTYPE html><html><body>" +
                    "<a href=/login/facebook>Log In with Facebook</a><br>" +
                    "<a href=/login/google>Log In with Google</a>" +
                "</body></html>\n\n").end()
        }
        catch {}
        next()
    }
    
    router.get("/login/facebook",
               handler: pagesCredentials.authenticate(credentialsType: fbCredentials.name))
    router.get("/login/google",
               handler: pagesCredentials.authenticate(credentialsType: googleCredentials.name))
    router.get("/login/facebook/callback",
               handler: pagesCredentials.authenticate(credentialsType: fbCredentials.name, failureRedirect: "/login"))
    router.get("/login/google/callback",
               handler: pagesCredentials.authenticate(credentialsType: googleCredentials.name, failureRedirect: "/login"))
    
    
    router.get("/logout") { request, response, next in
        pagesCredentials.logOut(request: request)
        do {
            try response.redirect("/login")
        }
        catch {
            Log.error("Failed to redirect \(error)")
        }
        
        next()
    }
}

