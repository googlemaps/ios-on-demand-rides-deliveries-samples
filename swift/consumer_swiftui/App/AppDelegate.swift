/*
 * Copyright 2022 Google LLC. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import GoogleMaps
import GoogleRidesharingConsumer

// BEGIN_INTERNAL
private let apiKey = "YOUR_API_KEY"
private let providerID = "YOUR_PROVIDER_ID"
// END_INTERNAL
// EXTERNAL: #error("Register for API Key and insert here. Then delete this line.")
// EXTERNAL: let apiKey = ""

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    GMSServices.provideAPIKey(apiKey)
    GMTCServices.setAccessTokenProvider(AuthTokenProvider(), providerID: providerID)
    return true
  }
}
