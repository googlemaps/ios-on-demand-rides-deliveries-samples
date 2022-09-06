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
  /// Control panel button text for the request ride state.
  static let controlPanelRequestRideButtonText = "REQUEST RIDE"

  /// Control panel button text for the confirm pickup state.
  static let controlPanelConfirmPickupButtonText = "CONFIRM PICKUP"

  /// Control panel button text for the confirm location selection pickup point state.
  static let controlPanelConfirmLocationSelectionPickupPointButtonText = "CONFIRM PICKUP POINT"

  /// Control panel button text for the confirm dropoff state.
  static let controlPanelConfirmDropoffButtonText = "CONFIRM DROPOFF"

  /// Control panel button text for the confirm trip state.
  static let controlPanelConfirmTripButtonText = "CONFIRM TRIP"

  /// Control panel button text for the cancel trip state.
  static let controlPanelCancelTripButtonText = "CANCEL TRIP"

  /// Pick up location text for the trip info view.
  static let selectPickupLocationText = "pickup location"

  /// The head of the location selection walking distance text for the trip info view.
  static let locationSelectionWalkingDistanceTextHead = "Walk "

  /// The tail of the location selection walking distance text for the trip info view.
  static let locationSelectionWalkingDistanceTextTail = " meters to meet your driver."

  /// Drop off location text for the trip info view.
  static let selectDropoffLocationText = "drop-off location"

  /// Vehicle ID text for the trip view.
  static let vehicleIDText = "Vehicle ID: "

  /// Trip ID text for the trip view.
  static let tripIDText = "Trip ID: "

  /// Static text displayed on trip info view for the user selecting pickup and drop off location
  /// states.
  static let tripInfoViewUserSelectLocationStaticText = "Choose a "

  /// Static text displayed on trip info view for the location selection state.
  static let tripInfoViewLocationSelectionStaticText =
    "We found you the nearest available pickup point!\n"

  /// Static text displayed on trip info view for the location selection failure state.
  static let tripInfoViewLocationSelectionFailedStaticText =
    "No available pickup point nearby.\nPlease select another pickup location."

  /// Text displayed on control panel state label for waiting for a new trip state.
  static let waitingForDriverMatchTitleText = "Waiting for driver match"

  /// Text displayed on control panel state label for enroute to pickup state.
  static let enrouteToPickupTitleText = "Driver is arriving at pickup"

  /// Text displayed on control panel state label for driver completing another trip state.
  static let completeLastTripTitleText = "Driver is completing another trip"

  /// Text displayed on control panel state label for waiting for arrived at pickup state.
  static let arrivedAtPickupTitleText = "Driver is at pickup"

  /// Text displayed on control panel state label for enroute to intermediate destination state.
  static let enrouteToIntermediateDestinationTitleText = "Driving to intermediate stop"

  /// Text displayed on control panel state label for arrived at intermediate destination state.
  static let arrivedAtIntermediateDestinationTitleText = "Arrived at intermediate stop"

  /// Text displayed on control panel state label for waiting for enroute to dropoff state.
  static let enrouteToDropoffTitleText = "Driving to dropoff"

  /// Text displayed on control panel state label for waiting for trip completed state.
  static let tripCompleteTitleText = "Trip Complete"
}
