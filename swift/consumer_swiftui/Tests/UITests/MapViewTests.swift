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

import XCTest

@testable import ConsumerSampleApp

class UITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["testing"]
    app.launch()
  }

  func testSelectingPickupAndDropoffLocation() throws {
    let map = app.otherElements.matching(identifier: "MapView").element(boundBy: 0)
    app.buttons["REQUEST RIDE"].tap()
    XCTAssert(app.buttons["CONFIRM PICKUP"].exists)
    map.swipeDown()
    map.swipeRight()
    XCTAssert(
      app.staticTexts["Choose a pickup location"]
        .waitForExistence(timeout: 0.5))
    app.buttons["CONFIRM PICKUP"].tap()
    // Tests that the location selection fails with bad selected pickup location.
    XCTAssert(app.buttons["CONFIRM PICKUP"].waitForExistence(timeout: 2))
    let locationSelectionFailedPredicate = NSPredicate(
      format: "label BEGINSWITH 'No available pickup point nearby'")
    var locationSelectionElement = app.staticTexts.element(
      matching: locationSelectionFailedPredicate)
    XCTAssert(locationSelectionElement.waitForExistence(timeout: 2))
    map.swipeUp()
    map.swipeRight()
    app.buttons["CONFIRM PICKUP"].tap()
    // Tests that the location selection succeeds with reasonable selected pickup location
    XCTAssert(app.buttons["CONFIRM PICKUP POINT"].waitForExistence(timeout: 2))
    let locationSelectionSucceededPredicate = NSPredicate(
      format: "label BEGINSWITH 'We found you the nearest available pickup point!'")
    locationSelectionElement = app.staticTexts.element(
      matching: locationSelectionSucceededPredicate)
    XCTAssert(locationSelectionElement.waitForExistence(timeout: 2))
    map.swipeLeft()
    app.buttons["CONFIRM PICKUP POINT"].tap()
    XCTAssert(app.buttons["CONFIRM DROPOFF"].exists)
    map.swipeRight()
    XCTAssert(app.staticTexts["Choose a drop-off location"].waitForExistence(timeout: 0.5))
    app.buttons["CONFIRM DROPOFF"].tap()
    XCTAssert(app.buttons["CONFIRM TRIP"].waitForExistence(timeout: 0.5))
  }
}
