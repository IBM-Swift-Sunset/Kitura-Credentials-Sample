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

// KituraCredentialsSample shows examples for authentication using Kitura-Credentials framework.

import KituraSys
import KituraNet
import Kitura

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

router.get("/hello") { _, response, next in
    do {
        try response.send("Hello, World!").end()
    }
    catch{}
    next()
}

// Listen on port 8090
let server = HttpServer.listen(8090,
    delegate: router)

Server.run()
