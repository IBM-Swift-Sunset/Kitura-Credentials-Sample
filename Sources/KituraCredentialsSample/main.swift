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

// KituraSample shows examples for creating custom routes.

import KituraSys
import KituraNet
import Kitura
import KituraSession
import Credentials
import CredentialsFacebook
import CredentialsGoogle
import CredentialsFacebookToken
import CredentialsGoogleToken
import CredentialsHttp
import LoggerAPI
import HeliumLogger

import SwiftyJSON

#if os(Linux)
    import Glibc
#endif

import Foundation


// All Web apps need a router to define routes
let router = Router()

// Using an implementation for a Logger
Log.logger = HeliumLogger()

router.all(middleware: Session(secret: "Very very secret....."))


// Authentication with session

let pagesCredentials = Credentials()

let fbClientId = "Facebook client ID"
let fbCallbackUrl = "serverUrl" + "/login/facebook/callback"
let fbClientSecret = "Facebook client secret"
let googleClientId = "Google client ID"
let googleCallbackUrl = "serverUrl" + "/login/google/callback"
let googleClientSecret = "Google client secret"

let fbCredentials = CredentialsFacebook(clientId: fbClientId, clientSecret: fbClientSecret, callbackUrl: fbCallbackUrl)
let googleCredentials = CredentialsGoogle(clientId: googleClientId, clientSecret: googleClientSecret, callbackUrl: googleCallbackUrl)
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
                try response.status(.OK).send(
                    "<!DOCTYPE html><html><body>" +
                        "Hello " +  userProfile.displayName + "! You are logged in with " + userProfile.provider + ". This is private!<br>" +
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
        catch {}
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


// Non-redirecting authentication

let apiCredentials = Credentials()

// Token plugins will pass
let fbTokenCredentials = CredentialsFacebookToken()
let googleTokenCredentials = CredentialsGoogleToken()
let credentials = Credentials()
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


// Handles any errors that get set
router.error { request, response, next in
    response.headers["Content-Type"] = "text/html; charset=utf-8"
    do {
        let errorDescription: String
        if let error = response.error {
            errorDescription = "\(error)"
        } else {
            errorDescription = "Unknown error"
        }
        try response.send("Caught the error: \(errorDescription)").end()
    }
    catch {
        Log.error("Failed to send response \(error)")
    }
}

// A custom Not found handler
router.all { request, response, next in
    if  response.statusCode == .notFound  {
        // Remove this wrapping if statement, if you want to handle requests to / as well
        if  request.originalUrl != "/"  &&  request.originalUrl != ""  {
            do {
                try response.send("Route not found in Sample application!").end()
            }
            catch {
                Log.error("Failed to send response \(error)")
            }
        }
    }
    next()
}

// Listen on port 8090
let server = HTTPServer.listen(port: 8090, delegate: router)

Server.run()
