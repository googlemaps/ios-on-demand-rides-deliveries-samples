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

enum RPCConstants {
  /// URL path Strings.
  static let providerCreateTripURLPath = "/trip/new"
  static let providerUpdateTripURLPath = "/trip/"

  /// Request parameter keys.
  static let statusKey = "status"
  static let pickupKey = "pickup"
  static let dropoffKey = "dropoff"
  static let intermediateDestinationsKey = "intermediateDestinations"
  static let latitudeLongitudeKey = "LatLng"
  static let latitudeKey = "latitude"
  static let longitudeKey = "longitude"

  /// Response parameter keys.
  static let tripNameKey = "name"

  /// Trip status.
  static let tripStatusCanceled = "CANCELED"

  /// HTTP constants.
  static let httpContentTypeHeaderField = "Content-Type"
  static let httpJSONContentType = "application/json"
  static let httpMethodPOST = "POST"
  static let httpMethodPUT = "PUT"
}

/// Completion handler type definition for the createTrip process.
typealias CreateTripCompletionHandler = (String?, Error?) -> Void

/// Completion handler type definition for the cancelTrip process.
typealias CancelTripCompletionHandler = (Error?) -> Void

/// A service that provides POST and PUT requests to your server.
class ProviderService: NSObject {

  private let session: URLSession
  init(session: URLSession = .shared) {
    self.session = session
  }

  /// Creates an exclusive single-ride trip.
  func createTrip(
    pickupLocation: GMTSTerminalLocation, dropoffLocation: GMTSTerminalLocation,
    intermediateDestinations: [GMTSTerminalLocation],
    completion: @escaping CreateTripCompletionHandler
  ) {
    let requestURL = ProviderUtils.providerURL(path: RPCConstants.providerCreateTripURLPath)
    let payloadDict =
      [
        RPCConstants.pickupKey: ProviderUtils.formattedParameterOfTerminalLocation(
          location: pickupLocation)
          as [String: Any],
        RPCConstants.dropoffKey: ProviderUtils.formattedParameterOfTerminalLocation(
          location: dropoffLocation)
          as [String: Any],
        RPCConstants.intermediateDestinationsKey:
          ProviderUtils.formattedParameterOfArrayOfTerminalLocations(
            locations: intermediateDestinations),
      ] as [String: Any]

    let request = getJSONRequest(
      url: requestURL, payloadDict: payloadDict, method: RPCConstants.httpMethodPOST)

    let sessionTask = session.dataTask(with: request) {
      data, response, error in
      if error != nil {
        completion(
          nil,
          NSError(domain: "Received invalid vehicle match result", code: 1001, userInfo: nil)
        )
        return
      }
      guard let data = data else {
        completion(nil, NSError(domain: "Received empty data", code: 1000, userInfo: nil))
        return
      }
      guard
        let parsedDictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      else {
        completion(
          nil,
          NSError(domain: "Parsing dictionary failed.", code: 1000, userInfo: nil)
        )
        return
      }
      guard let tripName = parsedDictionary[RPCConstants.tripNameKey] as? String else {
        return
      }
      completion(tripName, nil)
    }
    sessionTask.resume()
  }

  /// Cancels an existing trip.
  func cancelTrip(tripID: String, completion: @escaping CancelTripCompletionHandler) {
    guard
      let requestURL = getProviderUpdateTripStatusURL(tripID: tripID)
    else {
      completion(nil)
      return
    }
    let payloadDict =
      [
        RPCConstants.statusKey: RPCConstants.tripStatusCanceled
      ] as [String: Any]
    let request = getJSONRequest(
      url: requestURL, payloadDict: payloadDict, method: RPCConstants.httpMethodPUT)
    let sessionTask = session.dataTask(
      with: request,
      completionHandler: { data, response, error in
        completion(error)
      }
    )
    sessionTask.resume()
  }

  private func getJSONRequest(url: URL, payloadDict: [String: Any], method: String) -> URLRequest {
    let serializedPayload = try! JSONSerialization.data(withJSONObject: payloadDict)
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue(
      RPCConstants.httpJSONContentType, forHTTPHeaderField: RPCConstants.httpContentTypeHeaderField)
    request.httpBody = serializedPayload
    return request
  }

  private func getProviderUpdateTripStatusURL(tripID: String) -> URL? {
    let providerURL = ProviderUtils.providerURL(path: RPCConstants.providerUpdateTripURLPath)
    return URL(string: tripID, relativeTo: providerURL)
  }

}
