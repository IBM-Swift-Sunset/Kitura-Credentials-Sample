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


// Authentication

let credentials = Credentials()

let fbClientId = "Facebook client ID"
let fbCallbackUrl = "serverUrl" + "/login/facebook/callback"
let fbClientSecret = "Facebook client secret"
let googleClientId = "Google client ID"
let googleCallbackUrl = "serverUrl" + "/login/google/callback"
let googleClientSecret = "Google client secret"

let fbCredentials = CredentialsFacebook(clientId: fbClientId, clientSecret: fbClientSecret, callbackUrl: fbCallbackUrl)
let googleCredentials = CredentialsGoogle(clientId: googleClientId, clientSecret: googleClientSecret, callbackUrl: googleCallbackUrl)
credentials.register(plugin: fbCredentials)
credentials.register(plugin: googleCredentials)

credentials.options["failureRedirect"] = "/login"
credentials.options["successRedirect"] = "/private/data"

router.all("/private", middleware: credentials)
router.get("/private/data", handler:
    { request, response, next in
        response.setHeader("Content-Type", value: "text/html; charset=utf-8")
        do {
            if let userProfile = request.userProfile  {
                try response.status(HttpStatusCode.OK).send(
                    "<!DOCTYPE html><html><body>" +
                        "Hello " +  userProfile.displayName + "! You are logged in with " + userProfile.provider + ". This is private!<br>" +
                        "<a href=/logout>Log Out</a>" +
                        "</body></html>\n\n").end()
                next()
                return
            }
            try response.status(HttpStatusCode.OK).send(
                "<!DOCTYPE html><html><body>" +
                    "Welcome! Please <a href=/login>login</a>" +
                "</body></html>\n\n").end()
        }
        catch {}
        next()
})

router.get("/login") { request, response, next in
    response.setHeader("Content-Type", value: "text/html; charset=utf-8")
    do {
        try response.status(HttpStatusCode.OK).send(
            "<!DOCTYPE html><html><body>" +
                "<a href=/login/facebook>Log In with Facebook</a><br>" +
                "<a href=/login/google>Log In with Google</a>" +
            "</body></html>\n\n").end()
    }
    catch {}
    next()
}

router.get("/login/facebook",
           handler: credentials.authenticate(credentialsType: fbCredentials.name))
router.get("/login/google",
           handler: credentials.authenticate(credentialsType: googleCredentials.name))
router.get("/login/facebook/callback",
           handler: credentials.authenticate(credentialsType: fbCredentials.name, failureRedirect: "/login"))
router.get("/login/google/callback",
           handler: credentials.authenticate(credentialsType: googleCredentials.name, failureRedirect: "/login"))


router.get("/logout") { request, response, next in
    credentials.logOut(request: request)
    do {
        try response.redirect("/login")
    }
    catch {
        Log.error("Failed to redirect \(error)")
    }

    next()
}


// Handles any errors that get set
router.error { request, response, next in
    response.setHeader("Content-Type", value: "text/plain; charset=utf-8")
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
    if  response.statusCode == .NOT_FOUND  {
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
let server = HttpServer.listen(port: 8090, delegate: router)

Server.run()
