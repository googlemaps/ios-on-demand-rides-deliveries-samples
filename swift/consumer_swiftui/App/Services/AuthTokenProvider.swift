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

/// Provides a service that sends request and receives response from provider server.
class AuthTokenProvider: NSObject, GMTCAuthorization {

  private struct AuthToken {
    let token: String
    let expiration: TimeInterval
    let tripID: String
  }

  private enum AccessTokenError: Error {
    case missingAuthorizationContext
    case missingData
    case missingURL
  }

  private static let tokenPath = "token/consumer/"
  private static let tokenKey = "jwt"
  private static let tokenExpirationKey = "expirationTimestamp"

  /// Cached token.
  private var authToken: AuthToken?

  func fetchToken(
    with authorizationContext: GMTCAuthorizationContext?,
    completion: @escaping GMTCAuthTokenFetchCompletionHandler
  ) {
    guard let authorizationContext = authorizationContext else {
      completion(nil, AccessTokenError.missingAuthorizationContext)
      return
    }
    let tripID = authorizationContext.tripID

    // Check if a token is cached and is valid.
    if let authToken = authToken,
      authToken.expiration > Date().timeIntervalSince1970 && authToken.tripID == tripID
    {
      completion(authToken.token, nil)
      return
    }

    let tokenURL = ProviderUtils.providerURL(path: Self.tokenPath)
    guard let tokenURLWithTripID = URL(string: tripID, relativeTo: tokenURL) else {
      completion(nil, AccessTokenError.missingURL)
      return
    }

    let request = URLRequest(url: tokenURLWithTripID)
    let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
      guard let strongSelf = self else { return }
      guard let data = data,
        let fetchData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let token = fetchData[Self.tokenKey] as? String,
        let expirationInMilliseconds = fetchData[Self.tokenExpirationKey] as? Int
      else {
        completion(nil, AccessTokenError.missingData)
        return
      }

      strongSelf.authToken = AuthToken(
        token: token,
        expiration: Double(expirationInMilliseconds) / 1000.0,
        tripID: tripID)
      completion(token, nil)
    }
    task.resume()
  }
}
