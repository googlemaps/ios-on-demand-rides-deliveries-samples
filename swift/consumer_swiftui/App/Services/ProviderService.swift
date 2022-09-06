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

/// A service that provides POST and PUT requests to your server.
class ProviderService {

  enum Error: Swift.Error {
    case missingData
    case missingURL
  }

  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  /// Creates an exclusive trip and returns the trip name.
  func createTrip(
    pickupLocation: GMTSTerminalLocation, dropoffLocation: GMTSTerminalLocation,
    intermediateDestinations: [GMTSTerminalLocation]
  ) async throws -> String {
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

    let request = Self.makeJSONRequest(
      url: requestURL, payloadDict: payloadDict, method: RPCConstants.httpMethodPOST)
    let (data, _) = try await session.data(for: request, delegate: nil)
    guard
      let parsedDictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let tripName = parsedDictionary[RPCConstants.tripNameKey] as? String
    else {
      throw Error.missingData
    }
    return tripName
  }

  /// Cancels an existing trip.
  func cancelTrip(tripID: String) async throws {
    guard let requestURL = getProviderUpdateTripStatusURL(tripID: tripID) else {
      throw Error.missingURL
    }
    let payloadDict =
      [
        RPCConstants.statusKey: RPCConstants.tripStatusCanceled
      ] as [String: Any]
    let request = Self.makeJSONRequest(
      url: requestURL, payloadDict: payloadDict, method: RPCConstants.httpMethodPUT)
    let _ = try await session.data(for: request, delegate: nil)
  }

  static private func makeJSONRequest(url: URL, payloadDict: [String: Any], method: String) -> URLRequest {
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
