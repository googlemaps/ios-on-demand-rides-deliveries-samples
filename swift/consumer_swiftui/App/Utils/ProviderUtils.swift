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

import Foundation
import GoogleRidesharingConsumer

/// Helper methods for `ProviderService` and `AuthTokenProvider`.
enum ProviderUtils {

  /// Base provider URL Strings.
  private static let baseProviderURLString = "http://localhost:8080"

  static func providerURL(path: String) -> URL {
    let baseProviderURL = URL(string: baseProviderURLString)
    return URL(string: path, relativeTo: baseProviderURL)!
  }

  /// Format terminal location to dictionary.
  static func formattedParameterOfTerminalLocation(location: GMTSTerminalLocation)
    -> [String: Double]
  {
    guard let locationPoint = location.point else {
      return [
        RPCConstants.latitudeKey: 0,
        RPCConstants.longitudeKey: 0,
      ]
    }
    return [
      RPCConstants.latitudeKey: locationPoint.latitude,
      RPCConstants.longitudeKey: locationPoint.longitude,
    ]
  }

  /// Format array of terminal location to dictionary.
  static func formattedParameterOfArrayOfTerminalLocations(locations: [GMTSTerminalLocation])
    -> [[String: Double]]
  {
    return locations.map { formattedParameterOfTerminalLocation(location: $0) }
  }
}
