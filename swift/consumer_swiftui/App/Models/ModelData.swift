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
import SwiftUI

/// This class represents the state of the currently loaded trip for this user (if any).
/// The trip's state can change based on the user's action during the course of the trip.
final class ModelData: ObservableObject {

  enum CustomerState: String, Hashable, Codable {
    /// Indicates that the `mapView` has not been initialized.
    case unInitialized

    /// Indicates that the `mapView` has been initialized.
    case initialized

    /// Indicates that the customer is selecting their pickup location.
    case selectingPickup

    /// Indicates that the customer is selecting their drop off location.
    case selectingDropoff

    /// Indicates that the customer is previewing their trip.
    case tripPreview

    /// Indicates that the customer is ready to finalize and book their trip.
    case booking

    /// Indicates that the customer is monitoring their on-going trip via Journey Sharing.
    case journeySharing
  }

  /// State representing the current customer status.
  @Published var customerState: CustomerState

  /// Text displayed on the control button in `ControlPanelView`
  @Published var controlButtonLabel: String

  /// Title text at the top of the control panel that describes the trip.
  @Published var tripInfoLabel: String

  /// Text displayed with the control panel title providing more trip details.
  @Published var staticLabel: String

  /// Selected pickup location for currently active trip.
  @Published var pickupLocation: GMTSTerminalLocation

  /// Selected dropoff location for currently active trip.
  @Published var dropoffLocation: GMTSTerminalLocation

  /// Selected intermediate detinations for currently active trip.
  @Published var intermediateDestinations: [GMTSTerminalLocation]

  /// Color of the control button, which can update based on the trip state.
  @Published var buttonColor: Color

  /// The remaining time in minutes to the current waypoint, displayed below the control title.
  @Published var timeToWaypoint: Double

  /// The remaining distance in meters to the current waypoint, displayed below the control title.
  @Published var remainingDistanceInMeters: Double

  /// ID for the current trip.
  @Published var tripID: String

  /// ID for the currently matched vehicle.
  @Published var vehicleID: String

  /// Initializer for an empty `ModelData`.
  init() {
    customerState = .initialized
    controlButtonLabel = Constants.controlPanelRequestRideButtonText
    tripInfoLabel = ""
    staticLabel = ""
    tripID = ""
    timeToWaypoint = 0.0
    remainingDistanceInMeters = 0.0
    vehicleID = ""
    buttonColor = Style.buttonBackgroundColor
    pickupLocation = GMTSTerminalLocation(
      point: nil, label: nil, description: nil, placeID: nil, generatedID: nil, accessPointID: nil)
    dropoffLocation = GMTSTerminalLocation(
      point: nil, label: nil, description: nil, placeID: nil, generatedID: nil, accessPointID: nil)
    intermediateDestinations = []
  }
}
