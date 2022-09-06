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
import XCTest

@testable import ConsumerSampleApp

class LocationServiceTests: XCTestCase {

  /// Default search location for the location selection request.
  private let searchLocation = GMTSTerminalLocation(
    point: ProviderTestConstants.latlng, label: nil, description: nil, placeID: nil,
    generatedID: nil, accessPointID: nil)

  /// Stub location selection response dictionary keys.
  private let stubLocationSelectionPlacePickupPointResultsKey = "placePickupPointResults"
  private let stubLocationSelectionPickupPointResultKey = "pickupPointResult"
  private let stubLocationSelectionDistanceMetersKey = "distanceMeters"
  private let stubLocationSelectionPickupPointKey = "pickupPoint"
  private let stubLocationSelectionLocationKey = "location"
  private let stubLocationSelectionLatitudeKey = "latitude"
  private let stubLocationSelectionLongitudeKey = "longitude"

  /// Stub location selection response dictionary values.
  private let stubLocationSelectionLatitude = 37.8078994
  private let stubLocationSelectionLongitude = -122.4184659
  private let stubLocationSelectionWalkingDistance = 22.027035
  private var stubLocationSelectionLatLng: GMTSLatLng {
    return GMTSLatLng(
      latitude: stubLocationSelectionLatitude, longitude: stubLocationSelectionLongitude)
  }

  /// Stub location selection response dictionary.
  private var stubLocationSelectionResponseDict: NSDictionary {
    return [
      stubLocationSelectionPlacePickupPointResultsKey: [
        [
          stubLocationSelectionPickupPointResultKey: [
            stubLocationSelectionDistanceMetersKey: stubLocationSelectionWalkingDistance,
            stubLocationSelectionPickupPointKey: [
              stubLocationSelectionLocationKey: [
                stubLocationSelectionLatitudeKey: stubLocationSelectionLatitude,
                stubLocationSelectionLongitudeKey: stubLocationSelectionLongitude,
              ]
            ],
          ]
        ]
      ]
    ]
  }

  /// Mock URL session.
  private var urlSession: URLSession!
  private let url = URL(string: ProviderTestConstants.apiURL)!

  override func setUp() {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    urlSession = URLSession(configuration: configuration)
  }

  /// Tests that the expected location selection pickup point (latlng and walking distance) is
  /// successfully returned for the valid search location input.
  func testGetLocationSelectionPickupPointSuccessfully() async throws {
    let locationSelectionService = LocationSelectionService(session: urlSession)
    let data = try JSONSerialization.data(
      withJSONObject: stubLocationSelectionResponseDict)
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, data)
    }
    let (locationSelectionPickupPointLatLng, locationSelectionWalkingDistance) =
      try await locationSelectionService.getLocationSelectionPickupPoint(
        searchLocation: searchLocation)
    XCTAssertEqual(locationSelectionPickupPointLatLng, stubLocationSelectionLatLng)
    XCTAssertEqual(locationSelectionWalkingDistance, stubLocationSelectionWalkingDistance)
  }

  /// Tests that an error occurs when the Location Selection API response is invalid.
  func testGetLocationSelectionPickupPointForInvalidResponse() async throws {
    let locationSelectionService = LocationSelectionService(session: urlSession)
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, nil)
    }
    do {
      let (_, _) = try await locationSelectionService.getLocationSelectionPickupPoint(
        searchLocation: searchLocation)
    } catch LocationSelectionError.missingResponseData {
      return
    }
    XCTFail("Error: Failed to get the location selection response.")
  }

  /// Tests that an error occurs when the fields of the Location Selection API response are invalid.
  func testGetLocationSelectionPickupPointErrorForInvalidResponseFields() async throws {
    let locationSelectionService = LocationSelectionService(session: urlSession)
    let stubLocationSelectionResponseDictWithInvalidFields = ["invalidKey": ""]
    let data = try JSONSerialization.data(
      withJSONObject: stubLocationSelectionResponseDictWithInvalidFields)
    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, data)
    }
    do {
      let (_, _) = try await locationSelectionService.getLocationSelectionPickupPoint(
        searchLocation: searchLocation)
    } catch LocationSelectionError.missingExpectedFields {
      return
    }
    XCTFail("Error: Expected fields not found in the location selection response.")
  }
}
