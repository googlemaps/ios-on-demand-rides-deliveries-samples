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
import XCTest

@testable import DriverSampleApp

class ProviderServiceTests: XCTestCase {
  private var urlSession: URLSession!
  private var mostRecentRequest: URLRequest?

  override func setUp() {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    urlSession = URLSession(configuration: configuration)
  }

  private func setProviderResponse(jsonObject: Any) {
    let responseData = try! JSONSerialization.data(withJSONObject: jsonObject)
    MockURLProtocol.requestHandler = { request in
      self.mostRecentRequest = request
      let response = HTTPURLResponse(
        url: URL(string: "fakeURL")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, responseData)
    }
  }

  func testCreateVehicle() throws {
    setProviderResponse(jsonObject: [
      "name": "providers/test-provider/vehicles/test-vehicle"
    ])

    let expectation = self.expectation(description: "Vehicle was created")
    let providerService = ProviderService(session: urlSession)
    providerService.createVehicle(vehicleID: "test-vehicle", isBackToBackEnabled: true) {
      vehicleID, error in
      XCTAssertEqual(vehicleID, "test-vehicle")
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)

    let request = try XCTUnwrap(mostRecentRequest)
    XCTAssertEqual(request.url, URL(string: "http://localhost:8080/vehicle/new"))
    XCTAssertEqual(request.httpMethod, "POST")
    let requestHTTPBody = try XCTUnwrap(request.bodyStreamAsJSON() as? NSDictionary)
    XCTAssertEqual(
      requestHTTPBody,
      [
        "vehicleId": "test-vehicle",
        "backToBackEnabled": true,
      ] as NSDictionary)
  }

  func testCreateVehicleFailed() {
    setProviderResponse(jsonObject: [:])

    let expectation = self.expectation(description: "Vehicle was not created successfully")
    let providerService = ProviderService(session: urlSession)
    providerService.createVehicle(vehicleID: "test-vehicle", isBackToBackEnabled: true) {
      vehicleID, error in
      XCTAssertNil(vehicleID)
      XCTAssertNotNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }

  func testGetVehicle() throws {
    setProviderResponse(jsonObject: [
      "currentTripsIds": ["test-trip1", "test-trip2"]
    ])

    let expectation = self.expectation(description: "Vehicle data was received")
    let providerService = ProviderService(session: urlSession)
    providerService.getVehicle(vehicleID: "test-vehicle") { matchedTripIDs, error in
      XCTAssertEqual(matchedTripIDs, ["test-trip1", "test-trip2"])
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)

    let request = try XCTUnwrap(mostRecentRequest)
    XCTAssertEqual(request.url, URL(string: "http://localhost:8080/vehicle/test-vehicle"))
    XCTAssertEqual(request.httpMethod, "GET")
  }

  func testGetTrip() throws {
    setProviderResponse(jsonObject: [
      "trip": [
        "tripStatus": "ENROUTE_TO_PICKUP",
        "waypoints": [
          [
            "location": [
              "point": ["latitude": 1, "longitude": 2]
            ],
            "waypointType": "PICKUP_WAYPOINT_TYPE",
          ],
          [
            "location": [
              "point": ["latitude": 3, "longitude": 4]
            ],
            "waypointType": "INTERMEDIATE_DESTINATION_WAYPOINT_TYPE",
          ],
          [
            "location": [
              "point": ["latitude": 5, "longitude": 6]
            ],
            "waypointType": "DROP_OFF_WAYPOINT_TYPE",
          ],
        ],
      ]
    ])

    let tripID = "test-trip"
    let expectedTripStatus = ProviderTripStatus.enrouteToPickup
    let expectedWaypoints = [
      GMTSTripWaypoint(
        location: GMTSTerminalLocation(
          point: GMTSLatLng(latitude: 1, longitude: 2),
          label: nil, description: nil, placeID: nil, generatedID: nil, accessPointID: nil),
        tripID: tripID,
        waypointType: .pickUp,
        distanceToPreviousWaypointInMeters: 0,
        eta: 0),
      GMTSTripWaypoint(
        location: GMTSTerminalLocation(
          point: GMTSLatLng(latitude: 3, longitude: 4),
          label: nil, description: nil, placeID: nil, generatedID: nil, accessPointID: nil),
        tripID: tripID,
        waypointType: .intermediateDestination,
        distanceToPreviousWaypointInMeters: 0,
        eta: 0),
      GMTSTripWaypoint(
        location: GMTSTerminalLocation(
          point: GMTSLatLng(latitude: 5, longitude: 6),
          label: nil, description: nil, placeID: nil, generatedID: nil, accessPointID: nil),
        tripID: tripID,
        waypointType: .dropOff,
        distanceToPreviousWaypointInMeters: 0,
        eta: 0),
    ]

    let expectation = self.expectation(description: "Trip data was received")
    let providerService = ProviderService(session: urlSession)
    providerService.getTrip(tripID: tripID) { tripStatus, waypoints, error in
      XCTAssertEqual(tripStatus, expectedTripStatus)
      XCTAssertEqual(waypoints, expectedWaypoints)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)

    let request = try XCTUnwrap(mostRecentRequest)
    XCTAssertEqual(request.url, URL(string: "http://localhost:8080/trip/test-trip"))
    XCTAssertEqual(request.httpMethod, "GET")
  }

  func testUpdateTrip() throws {
    setProviderResponse(jsonObject: [:])

    let expectation = self.expectation(description: "Trip was updated")
    let providerService = ProviderService(session: urlSession)
    providerService.updateTrip(
      tripID: "test-trip", status: .enrouteToPickup, intermediateDestinationIndex: nil
    ) { error in
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)

    let request = try XCTUnwrap(mostRecentRequest)
    XCTAssertEqual(request.url, URL(string: "http://localhost:8080/trip/test-trip"))
    XCTAssertEqual(request.httpMethod, "PUT")
    let requestHTTPBody = try XCTUnwrap(request.bodyStreamAsJSON() as? NSDictionary)
    XCTAssertEqual(requestHTTPBody, ["status": "ENROUTE_TO_PICKUP"] as NSDictionary)
  }
}
