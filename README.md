# On-Demand Rides and Deliveries iOS Samples

This repository contains source code of the following samples.

1. Driver SDK sample, available in two languages:
   - Swift: in `swift/driver_swiftui` directory.
   - Objective-C: in `objectivec_samples/Driver` directory.
2. Consumer SDK sample, available in two languages:
   - Swift: in `swift/consumer_swiftui` directory.
   - Objective-C: in `objectivec_samples/Consumer` directory.

You can use the following guide to build and run a basic consumer and driver app integrated with the On-demand Rides and Deliveries Solution backend services. After completing this guide, you should have an app that can display an active trip, respond to trip updates, and handle trip errors.

Note: Before building your app, you need to have your provider services in place including vehicle to consumer matching functionality. Specifically, you need the Cloud Project ID unique to the service provider the consumer app supports.

## Prerequisites
1. Please fully complete [Getting Started with Fleet Engine](https://developers.google.com/maps/documentation/transportation-logistics/on-demand-rides-deliveries-solution/trip-order-progress/fleet-engine)
2. Please make sure the [provider backend](https://github.com/googlemaps/java-on-demand-rides-deliveries-stub-provider)
is up and running.
3. To access the CocoaPods of Consumer and Driver SDKs, please make sure to be a member of the
Google group [google-maps-odrd-access-external](https://groups.google.com/a/google.com/g/google-maps-odrd-access-external).
5. Please authenticate by visiting https://cpdc-eap.googlesource.com/new-password
and setting up a git cookie.
6. Install CocoaPods on the development machine

    ```shell
    sudo gem install cocoapods
    ```

    Refer to the
    [CocoaPods Getting Started guide](https://guides.cocoapods.org/using/getting-started.html)
    for more details.


## Get started
After all prerequisites are met:

1.  Open a terminal and go to the directory containing the Podfile:

    ```shell
    cd <path-to-project>
    ```

1.  Run the `pod install` command. This installs the pods specified in the
    Podfile, along with any dependencies they have.

    ```shell
    pod install
    ```

1.  Close Xcode, and then open (double-click) your project's `.xcworkspace` file
    to launch Xcode. From this time onwards, you must use the `.xcworkspace` file
    to open the project, *not* the `.xcodeproj` file.

1.  Follow the
    [Getting an API Key guide](https://developers.google.com/maps/documentation/ios-sdk/get-api-key)
    to add your Maps API key to your app.

    - For Swift, update `mapsAPIKey` in `APIConstants.swift` for both Consumer
      and Driver.

    - For Objective-C, update `kMapsAPIKey` in `GRSCAPIConstants.m` for the
      Consumer app and in `GRSDAPIConstants.m` for the Driver app.

1.  Add the Provider ID to your app. The Provider ID is the Project ID of the
    Google Cloud Project that contains the service account used to call the
    Fleet Engine APIs.

    - For Swift, update `providerID` in `APIConstants.swift` for both Consumer
      and Driver.

    - For Objective-C, update `kProviderID` in `GRSCAPIConstants.m` for the
      Consumer app and in `GRSDAPIConstants.m` for the Driver app.

Then the project should run normally.

## License

```
Copyright 2022 Google, Inc.

Licensed to the Apache Software Foundation (ASF) under one or more contributor
license agreements.  See the NOTICE file distributed with this work for
additional information regarding copyright ownership.  The ASF licenses this
file to you under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License.  You may obtain a copy of
the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
License for the specific language governing permissions and limitations under
the License.
```
