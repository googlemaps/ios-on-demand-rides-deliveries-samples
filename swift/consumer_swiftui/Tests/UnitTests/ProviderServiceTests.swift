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

class ProviderServiceTests: XCTestCase {

  private let pickupLocation = GMTSTerminalLocation(
    point: ProviderTestConstants.latlng, label: nil, description: nil, placeID: nil,
    generatedID: nil, accessPointID: nil)
  private let dropoffLocation = GMTSTerminalLocation(
    point: ProviderTestConstants.latlng, label: nil, description: nil, placeID: nil,
    generatedID: nil, accessPointID: nil)
  private let intermediateDestination = GMTSTerminalLocation(
    point: ProviderTestConstants.latlng, label: nil, description: nil, placeID: nil,
    generatedID: nil, accessPointID: nil)
  private let expectedURL = "http://localhost:8080/trip/new"
  private let expectedHttpMethod = "POST"
  private let expectedTripName = "fakeTripName"
  private let expectedHttpbodyWithIntermediateDestinations: NSDictionary = [
    "dropoff": ["latitude": 37.7749, "longitude": -122.4194],
    "intermediateDestinations": [["latitude": 37.7749, "longitude": -122.4194]],
    "pickup": ["latitude": 37.7749, "longitude": -122.4194],
  ]
  private let expectedHttpbodyWithoutIntermediateDestinations: NSDictionary = [
    "dropoff": ["latitude": 37.7749, "longitude": -122.4194],
    "intermediateDestinations": [],
    "pickup": ["latitude": 37.7749, "longitude": -122.4194],
  ]

  var providerService: ProviderService!
  var urlSession: URLSession!
  var expectation: XCTestExpectation!
  var url = URL(string: ProviderTestConstants.apiURL)!

  override func setUp() {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    urlSession = URLSession(configuration: configuration)
    expectation = expectation(description: "Expectation")
  }

  func testCreateTripWithIntermediateDestinationsSuccessfully() {
    let providerService = ProviderService(session: urlSession)
    let jsonString = """
      {
         "name": "fakeTripName",
      }
      """

    let data = jsonString.data(using: .utf8)
    var mostRecentRequest: URLRequest?
    mostRecentRequest = nil

    MockURLProtocol.requestHandler = { request in
      mostRecentRequest = request
      let response = HTTPURLResponse(
        url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, data)
    }

    providerService.createTrip(
      pickupLocation: pickupLocation, dropoffLocation: dropoffLocation,
      intermediateDestinations: [intermediateDestination]
    ) {
      tripName, error in
      if let jsonBody = mostRecentRequest!.bodySteamAsJSON() {
        let testedJsonBodyString = jsonBody as! NSDictionary
        XCTAssertEqual(testedJsonBodyString, self.expectedHttpbodyWithIntermediateDestinations)
      }
      XCTAssertEqual(mostRecentRequest?.url, URL(string: self.expectedURL))
      XCTAssertEqual(mostRecentRequest?.httpMethod, self.expectedHttpMethod)
      if tripName != nil {
        XCTAssertEqual(tripName, self.expectedTripName)
        self.expectation.fulfill()
      }
    }
    wait(for: [self.expectation], timeout: 1.0)
  }

  func testCreateTripWithoutIntermediateDestinationsSuccessfully() {
    let providerService = ProviderService(session: urlSession)
    let jsonString = """
      {
         "name": "fakeTripName",
      }
      """

    let data = jsonString.data(using: .utf8)
    var mostRecentRequest: URLRequest?
    mostRecentRequest = nil

    MockURLProtocol.requestHandler = { request in
      mostRecentRequest = request
      let response = HTTPURLResponse(
        url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, data)
    }

    providerService.createTrip(
      pickupLocation: pickupLocation, dropoffLocation: dropoffLocation,
      intermediateDestinations: []
    ) {
      tripName, error in
      if let jsonBody = mostRecentRequest!.bodySteamAsJSON() {
        let testedJsonBodyString = jsonBody as! NSDictionary
        XCTAssertEqual(testedJsonBodyString, self.expectedHttpbodyWithoutIntermediateDestinations)
      }
      XCTAssertEqual(mostRecentRequest?.url, URL(string: self.expectedURL))
      XCTAssertEqual(mostRecentRequest?.httpMethod, self.expectedHttpMethod)
      if tripName != nil {
        XCTAssertEqual(tripName, self.expectedTripName)
        self.expectation.fulfill()
      }
    }
    wait(for: [self.expectation], timeout: 1.0)
  }

  func testCreateTripFailedWithIntermediateDestinations() {
    let providerService = ProviderService(session: urlSession)

    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, nil)
    }

    providerService.createTrip(
      pickupLocation: pickupLocation, dropoffLocation: dropoffLocation,
      intermediateDestinations: [intermediateDestination]
    ) {
      tripName, error in
      if error != nil {
        self.expectation.fulfill()
      }
    }
    wait(for: [self.expectation], timeout: 1.0)
  }

  func testCreateTripFailedWithoutIntermediateDestinations() {
    let providerService = ProviderService(session: urlSession)

    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, nil)
    }

    providerService.createTrip(
      pickupLocation: pickupLocation, dropoffLocation: dropoffLocation,
      intermediateDestinations: []
    ) {
      tripName, error in
      if error != nil {
        self.expectation.fulfill()
      }
    }
    wait(for: [self.expectation], timeout: 1.0)
  }

  func testCancelledTripSuccess() {
    let providerService = ProviderService(session: urlSession)

    MockURLProtocol.requestHandler = { request in
      let response = HTTPURLResponse(
        url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, nil)
    }

    providerService.cancelTrip(tripID: "fakeTripID") {
      error in
      if error == nil {
        self.expectation.fulfill()
      }
    }
    wait(for: [self.expectation], timeout: 1.0)
  }
}
