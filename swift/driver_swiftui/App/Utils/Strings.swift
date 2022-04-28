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

/// Strings that can be used in the sample app.
enum Strings {
  /// Company name to be used in the Nav SDK terms and conditions dialog.
  static let companyName = "Sample App Company"

  /// Title for the dialog to show when the terms and conditions are not accepted.
  static let termsAndConditionsDeniedAlertTitle = "Terms And Conditions Not Accepted"

  /// Message for the dialog to show when the terms and conditions are not accepted.
  static let termsAndConditionsDeniedAlertMessage =
    "The terms and conditions must be accepted in order to use the app."

  /// Title for the dialog to show when the location permission is denied or restricted.
  static let locationPermissionDeniedOrRestrictedAlertTitle =
    "Location Permission Denied or Restricted"

  /// Message for the dialog to show when the location permission is denied or restricted.
  static let locationPermissionDeniedOrRestrictedAlertMessage =
    "App will not function unless location permission is granted."

  /// Title for the dialog to show when the createVehicle request fails.
  static let createVehicleFailureAlertTitle = "Unable to Create Vehicle"

  /// Message for the dialog to show when the createVehicle request fails.
  static let createVehicleFailureAlertMessage =
    "An error occured while connecting to the provider backend."

  /// Text on the button to close the dialog.
  static let okButtonText = "OK"

  /// Vehicle ID text for the trip view.
  static let vehicleIDText = "Vehicle ID: "

  /// Current trip ID text for the trip view.
  static let tripIDText = "Trip ID: "

  /// Next trip ID text for the trip view.
  static let nextTripIDText = "Next Trip ID: "

  /// Text displayed on the driver state label in the control panel.
  enum controlPanelDriverStateText {
    static let new = "New trip"
    static let enrouteToPickup = "Picking up rider"
    static let arrivedAtPickup = "Arrived at pickup"
    static let enrouteToIntermediateDestination = "Driving to intermediate stop"
    static let arrivedAtIntermediateDestination = "Arrived at intermediate stop"
    static let enrouteToDropoff = "Dropping off rider"
    static let tripComplete = "Trip completed"
  }

  /// Text displayed on the button in the control panel.
  enum controlPanelButtonText {
    static let enrouteToPickup = "Start Navigation"
    static let arrivedAtPickup = "Arrived at Pickup"
    static let enrouteToIntermediateDestination = "Drive to Intermediate Stop"
    static let arrivedAtIntermediateDestination = "Arrived at Intermediate Stop"
    static let enrouteToDropoff = "Drive to Dropoff"
    static let tripComplete = "Complete Trip"
  }
}
