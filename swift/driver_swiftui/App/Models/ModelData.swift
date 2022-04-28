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
import SwiftUI

/// The state of the driver and their assigned trip (if any).
final class ModelData: ObservableObject {

  enum DriverState {
    /// Indicates that the driver is not on any trip.
    case idle

    /// Indicates that the driver has been newly assigned a trip.
    case new

    /// Indicates that the driver is on their way to the pickup point.
    case enrouteToPickup

    /// Indicates that the driver has arrived at the pickup point.
    case arrivedAtPickup

    /// Indicates that the driver is on their way to an intermediate destination.
    case enrouteToIntermediateDestination

    /// Indicates that the driver has arrived at an intermediate destination.
    case arrivedAtIntermediateDestination

    /// Indicates that the driver is on their way to the dropoff point.
    case enrouteToDropoff

    /// Indicates that the driver has dropped off the rider and the trip is complete.
    case tripComplete
  }

  /// ID for the current vehicle.
  @Published var vehicleID: String?

  /// ID for the current matched trip.
  @Published var tripID: String?

  /// ID for the next matched trip.
  @Published var nextTripID: String?

  /// Waypoints of the current trip.
  @Published var waypoints: [GMTSTripWaypoint]?

  /// The current driver state.
  @Published var driverState: DriverState = .idle

  /// A boolean indicating whether the driver is moving to a waypoint.
  @Published var isEnrouteToWaypoint = false

  /// The current intermediate destination index for a multi-destination trip.
  @Published var intermediateDestinationIndex = 0
}
