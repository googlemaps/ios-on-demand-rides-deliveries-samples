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
import GoogleRidesharingDriver

/// Provides auth tokens to the Driver SDK to communicate with Fleet Engine.
class AuthTokenProvider: NSObject, GMTDAuthorization {
  private struct AuthToken {
    let token: String
    let expiration: TimeInterval
    let vehicleID: String
  }

  private enum Error: Swift.Error {
    case missingAuthorizationContext
    case missingData
    case missingURL
  }

  private static let tokenPath = "token/driver/"
  private static let tokenKey = "jwt"
  private static let tokenExpirationKey = "expirationTimestamp"

  /// Cached token.
  private var authToken: AuthToken?

  func fetchToken(
    with authorizationContext: GMTDAuthorizationContext?,
    completion: @escaping GMTDAuthTokenFetchCompletionHandler
  ) {
    guard let authorizationContext = authorizationContext else {
      completion(nil, Error.missingAuthorizationContext)
      return
    }
    let vehicleID = authorizationContext.vehicleID

    // Check if a token is cached and is valid.
    if let authToken = authToken,
      authToken.expiration > Date().timeIntervalSince1970 && authToken.vehicleID == vehicleID
    {
      completion(authToken.token, nil)
      return
    }

    let tokenURL = ProviderUtils.providerURL(path: Self.tokenPath)
    guard let tokenURLWithVehicleID = URL(string: vehicleID, relativeTo: tokenURL) else {
      completion(nil, Error.missingURL)
      return
    }

    let request = URLRequest(url: tokenURLWithVehicleID)
    let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
      guard let strongSelf = self else { return }
      guard error == nil else {
        completion(nil, error)
        return
      }
      guard let data = data,
        let fetchData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let token = fetchData[Self.tokenKey] as? String,
        let expirationInMilliseconds = fetchData[Self.tokenExpirationKey] as? Int
      else {
        completion(nil, Error.missingData)
        return
      }

      strongSelf.authToken = AuthToken(
        token: token,
        expiration: Double(expirationInMilliseconds) / 1000.0,
        vehicleID: vehicleID)
      completion(token, nil)
    }
    task.resume()
  }
}
