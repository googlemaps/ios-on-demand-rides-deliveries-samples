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

class ProviderUtilsTests: XCTestCase {

  private let testLocation = GMTSTerminalLocation(
    point: ProviderTestConstants.latlng, label: nil, description: nil, placeID: nil,
    generatedID: nil, accessPointID: nil)

  private let expectedTerminalLocationDictionary = [
    "longitude": ProviderTestConstants.longitude, "latitude": ProviderTestConstants.latitude,
  ]

  func testGenerateProviderURL() throws {
    let testPath = "/test/path"
    let resultURL = ProviderUtils.providerURL(path: testPath)

    XCTAssertEqual(resultURL.port, 8080)
    XCTAssertEqual(resultURL.host, "localhost")
    XCTAssertEqual(resultURL.path, testPath)
  }

  func testFormattedParameterOfTerminalLocation() throws {
    let testedTerminalLocationDictionary = ProviderUtils.formattedParameterOfTerminalLocation(
      location: testLocation)
    XCTAssertEqual(testedTerminalLocationDictionary, expectedTerminalLocationDictionary)
  }

  func testFormattedParameterOfArrayOfTerminalLocations() throws {
    let testedTerminalLocationDictionary =
      ProviderUtils.formattedParameterOfArrayOfTerminalLocations(locations: [
        testLocation
      ])
    XCTAssertEqual(testedTerminalLocationDictionary, [expectedTerminalLocationDictionary])
  }
}
