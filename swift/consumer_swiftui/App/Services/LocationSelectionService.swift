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

private enum RPCLocationSelectionConstants {

  /// HTTP constant.
  static let httpGoogleCloudAPIKeyHeaderField = "X-Goog-Api-Key"

  /// Request parameter keys.
  static let searchLocationKey = "search_location"
  static let locationPreferencesKey = "localization_preferences"
  static let maxResultsKey = "max_results"
  static let orderByKey = "order_by"
  static let travelModesKey = "travel_modes"
  static let computeWalkingEtaKey = "compute_walking_eta"

  /// Request parameter values.
  static let maxResultsValue = 1
  static let orderByValue = "WALKING_ETA_FROM_SEARCH_LOCATION"
  static let travelModesValue = "WALKING"
  static let computeWalkingEtaValue = true
  static let localizationPreferencesValueDict = ["language_code": "en-US", "region_code": "US"]

  /// Location Selection API URL Strings.
  static let baseLocationSelectionURLString = "https://locationselection.googleapis.com"
  static let locationSelectionFindPickupPointsForLocation =
    "/v1beta:findPickupPointsForLocation"
}

enum LocationSelectionError: Swift.Error {
  case missingResponseData
  case missingExpectedFields
}

/// A struct for parsing the serialized Location Selection API response dictionary.
private struct LocationSelectionParsedResponse {
  let latLng: GMTSLatLng
  let walkingDistance: Double

  init?(parsedDictionary: [String: Any]) {
    guard let placePickupPointResultsArray = parsedDictionary["placePickupPointResults"] as? [Any],
      let placePickupPointResult = placePickupPointResultsArray.first as? [String: Any],
      let pickupPointResult = placePickupPointResult["pickupPointResult"] as? [String: Any],
      let pickupPoint = pickupPointResult["pickupPoint"] as? [String: Any],
      let location = pickupPoint["location"] as? [String: Any],
      let latitude = location["latitude"] as? Double,
      let longitude = location["longitude"] as? Double,
      let distanceMeters = pickupPointResult["distanceMeters"] as? Double
    else {
      return nil
    }
    latLng = GMTSLatLng(latitude: latitude, longitude: longitude)
    walkingDistance = distanceMeters
  }
}

/// A service used to interact with the location selection server.
class LocationSelectionService {

  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  /// Gets a single location selection pickup point based on the lowest walking ETA from the response of the Location Selection API.
  ///
  /// - Parameter searchLocation: The pickup location selected by the user.
  /// - Returns: The latlng and the walking distance of the Location Selection API response.
  func getLocationSelectionPickupPoint(searchLocation: GMTSTerminalLocation) async throws -> (
    locationSelectionPickupPointLatLng: GMTSLatLng, locationSelectionWalkingDistance: Double
  ) {
    let requestURL = Self.makeLocationSelectionURL(
      path: RPCLocationSelectionConstants.locationSelectionFindPickupPointsForLocation)
    var searchLocationDict = [String: Any]()
    if let searchLocationLatLng = searchLocation.point {
      searchLocationDict = [
        RPCConstants.latitudeKey: searchLocationLatLng.latitude,
        RPCConstants.longitudeKey: searchLocationLatLng.longitude,
      ]
    }
    let payloadDict =
      [
        RPCLocationSelectionConstants.searchLocationKey: searchLocationDict,
        RPCLocationSelectionConstants.locationPreferencesKey: RPCLocationSelectionConstants
          .localizationPreferencesValueDict,
        RPCLocationSelectionConstants.maxResultsKey: RPCLocationSelectionConstants.maxResultsValue,
        RPCLocationSelectionConstants.orderByKey: RPCLocationSelectionConstants.orderByValue,
        RPCLocationSelectionConstants.travelModesKey: RPCLocationSelectionConstants
          .travelModesValue,
        RPCLocationSelectionConstants.computeWalkingEtaKey: RPCLocationSelectionConstants
          .computeWalkingEtaValue,
      ] as [String: Any]

    let request = Self.makeJSONRequest(
      url: requestURL, payloadDict: payloadDict, method: RPCConstants.httpMethodPOST,
      googleCloudAPIKey: APIConstants.locationSelectionAPIKey)
    let (data, _) = try await session.data(for: request, delegate: nil)
    guard
      let parsedDictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      throw LocationSelectionError.missingResponseData
    }
    let response = LocationSelectionParsedResponse(parsedDictionary: parsedDictionary)
    guard
      let response = response
    else {
      throw LocationSelectionError.missingExpectedFields
    }
    return (response.latLng, response.walkingDistance)
  }

  /// Returns a JSON formatted URLRequest with Google Cloud API key access.
  ///
  /// - Parameters:
  ///   - url: The URL for the HTTP request.
  ///   - payloadDict: The dictionary for the HTTP request body.
  ///   - method: The HTTP method.
  ///   - googleCloudAPIKey: The Google Cloud API key.
  /// - Returns: A JSON request made with the input parameters.
  private static func makeJSONRequest(
    url: URL, payloadDict: [String: Any], method: String, googleCloudAPIKey: String
  ) -> URLRequest {
    var request = URLRequest(url: url)
    if let serializedPayload = try? JSONSerialization.data(withJSONObject: payloadDict) {
      request.httpBody = serializedPayload
    } else {
      print("Error: Invalid HTTP body for the JSON request.")
    }
    request.httpMethod = method
    request.addValue(
      RPCConstants.httpJSONContentType, forHTTPHeaderField: RPCConstants.httpContentTypeHeaderField)
    request.addValue(
      APIConstants.locationSelectionAPIKey,
      forHTTPHeaderField: RPCLocationSelectionConstants.httpGoogleCloudAPIKeyHeaderField)
    return request
  }

  /// Returns an instance of NSURL with the base Location Selection URL and given path.
  ///
  /// - Parameter path: The path for the Location Selection API.
  /// - Returns: An instance of NSURL with the base Location Selection URL and given path.
  private static func makeLocationSelectionURL(path: String) -> URL {
    let baseLocationSelectionURL = URL(
      string: RPCLocationSelectionConstants.baseLocationSelectionURLString)
    return URL(string: path, relativeTo: baseLocationSelectionURL)!
  }
}
