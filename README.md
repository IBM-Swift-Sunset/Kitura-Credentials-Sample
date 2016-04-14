# Kitura-Credentials-Sample
A sample web application for authentication using Kitura-Credentials

![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Summary

This is a sample [Kitura](https://github.com/IBM-Swift/Kitura) application for authentication using [Kitura-Credentials](https://github.com/IBM-Swift/Kitura-Credentials). See instructions for [Installation on OS X ](https://github.com/IBM-Swift/Kitura#installation-os-x) or [Installation on Linux](https://github.com/IBM-Swift/Kitura#installation-linux-apt-based).

## Running Kitura-Credentials-Sample

### Create an application instance on Facebook and Google

This sample application authenticates with Facebook and Google. In order to do that, application instances must be created on Facebook and Google websites.

#### Facebook

1. To create an application instance on Facebook's website, go to  [Facebook developers page](https://developers.facebook.com/apps/) page, and add a new app. Choose `Website` as your platform. Follow the steps to create a new app.

2. Go to Developer dashboard and copy App Id and App Secret to `main.swift`:
```swift
let fbClientId = // Put App Id here
let fbClientSecret = // Put App Secret here
```
3. Configure Facebook callback URL in `main.swift`. It should be your Site URL as you configured it on Facebook plus `/login/facebook/callback`:
```swift
let fbCallbackUrl = // Put your callback URL here
```

##### Google

1. Go to [Google developers console](https://console.developers.google.com/) page, and create  a new project.

2. Go to `Credentials` tab, click `Create credentials` and choose `OAuth client ID`.

3. Tap `Configure consent screen` and fill in the details.

4. Back to `Credentials`, choose `Web application` as your application type. In order to enable callbacks from Google, type your server URL plus `/login/google/callback` in `Authorized redirect URIs` - this is required to make Google authentication work.

5. Now you should see the app you just created in `Credentials` tab. Click on its name, and copy Client ID and Client secret  to `main.swift`:
```swift
let googleClientId = // Put Client Id here
let googleClientSecret = // Put Client Secret here
```
6. Set your Google callback URL in `main.swift`:
```swift
let googleCallbackUrl = // Put your callback URL here
```


### Build and run
1. `make run`

  You should see message _Listening on port 8090_. The result executable is located in `.build/debug` directory: `./.build/debug/KituraCredentialsSample`
2. Open your browser at [http://localhost:8090/private/data](http://localhost:8090/private/data)

## License

This sample app is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
