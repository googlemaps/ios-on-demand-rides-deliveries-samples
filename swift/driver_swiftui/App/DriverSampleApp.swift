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

import SwiftUI

@main
struct DriverSampleApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  /// Checks that the API constants have been configured correctly or returns an error message.
  private static let apiConstantsErrorMessage: String? = {
    // A Maps API key must be 39 characters long; start with "AIza"; and consist of upper- and
    // lower-case letters, numbers, hyphens, and underscores.
    if APIConstants.mapsAPIKey.range(
      of: "^AIza[0-9A-Za-z-_]{35}$", options: .regularExpression) == nil
    {
      return "The Maps API Key has not been correctly configured. Please set your Maps API key in "
        + "APIConstants.swift."
    }

    // A Cloud project ID must be 6-30 characters long; consist of lower-case letters, numbers and
    // hyphens; start with a letter; and not end with a hyphen.
    if APIConstants.providerID.range(
      of: "^[a-z][a-z0-9-]{4,28}[a-z0-9]$", options: .regularExpression) == nil
    {
      return "The Provider ID has not been correctly configured. Please set your Provider ID in "
        + "APIConstants.swift."
    }
    return nil
  }()

  var body: some Scene {
    WindowGroup {
      if let apiConstantsErrorMessage = Self.apiConstantsErrorMessage {
        Text(apiConstantsErrorMessage)
      } else {
        ContentView()
      }
    }
  }
}
