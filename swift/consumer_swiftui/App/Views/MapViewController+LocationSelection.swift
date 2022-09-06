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

import GoogleRidesharingConsumer

var locationSelectionPickupPointKey =
  "locationSelectionPickupPointKey"
var locationSelectionPickupPointMarkerKey =
  "locationSelectionPickupPointMarkerKey"

extension MapViewController {

  var locationSelectionPickupPoint: GMTSTerminalLocation {
    get {
      (objc_getAssociatedObject(self, &locationSelectionPickupPointKey) as? GMTSTerminalLocation)
        ?? GMTSTerminalLocation(
          point: nil, label: nil, description: nil, placeID: nil, generatedID: nil,
          accessPointID: nil)
    }
    set {
      objc_setAssociatedObject(
        self, &locationSelectionPickupPointKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  var locationSelectionPickupPointMarker: GMSMarker {
    get {
      (objc_getAssociatedObject(self, &locationSelectionPickupPointMarkerKey)
        as? GMSMarker) ?? GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    }
    set {
      objc_setAssociatedObject(
        self, &locationSelectionPickupPointMarkerKey, newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  /// Starts all the location selection specific methods.
  func startLocationSelection(pickupLocation: GMTSTerminalLocation) {
    // Get the pickup point from the Location Selection API.
    Task {
      let locationSelectionService = LocationSelectionService()
      do {
        let (locationSelectionPickupPointLatLng, locationSelectionWalkingDistance) =
          try await locationSelectionService.getLocationSelectionPickupPoint(
            searchLocation: pickupLocation)
        self.locationSelectionPickupPoint = GMTSTerminalLocation(
          point: locationSelectionPickupPointLatLng, label: nil, description: nil, placeID: nil,
          generatedID: nil, accessPointID: nil)
        modelData.locationSelectionWalkingDistance = locationSelectionWalkingDistance
        showLocationSelectionPickupPointInMapView()
        getLocationSelectionPickupPointSucceeded()
      } catch LocationSelectionError.missingResponseData {
        getLocationSelectionPickupPointFailed()
        print("Error: Failed to get the location selection response.")
        return
      } catch LocationSelectionError.missingExpectedFields {
        getLocationSelectionPickupPointFailed()
        print("Error: Expected fields not found in the location selection response.")
        return
      }
    }
  }

  /// Displays the location selection pickup point on `mapView` with the given location selection
  /// pickup point latlng.
  private func showLocationSelectionPickupPointInMapView() {
    if let locationSelectionPickupPoint = self.locationSelectionPickupPoint.point {
      self.locationSelectionPickupPointMarker.position = CLLocationCoordinate2D(
        latitude: locationSelectionPickupPoint.latitude,
        longitude: locationSelectionPickupPoint.longitude)
    }
    self.locationSelectionPickupPointMarker.map = mapView
    self.locationSelectionPickupPointMarker.icon = UIImage(named: Self.pickupMarkerIconName)

    modelData.pickupLocation = GMTSTerminalLocation(
      point: self.locationSelectionPickupPoint.point, label: nil, description: nil, placeID: nil,
      generatedID: nil, accessPointID: nil)
  }

  /// Updates UI elements and customer state after successfully getting the location selection
  /// pickup point.
  private func getLocationSelectionPickupPointSucceeded() {
    modelData.customerState = .confirmingLocationSelectionPickupPoint
    modelData.controlButtonLabel = Strings.controlPanelConfirmLocationSelectionPickupPointButtonText
    modelData.staticLabel = Strings.tripInfoViewLocationSelectionStaticText
    modelData.tripInfoLabel =
      Strings.locationSelectionWalkingDistanceTextHead
      + String(format: "%.2f", modelData.locationSelectionWalkingDistance)
      + Strings.locationSelectionWalkingDistanceTextTail
  }

  /// Updates UI elements and customer state for failure of getting the location selection pickup
  /// point due to bad pickup selection.
  private func getLocationSelectionPickupPointFailed() {
    modelData.customerState = .selectingPickup
    modelData.controlButtonLabel = Strings.controlPanelConfirmPickupButtonText
    modelData.staticLabel = Strings.tripInfoViewLocationSelectionFailedStaticText
    modelData.tripInfoLabel = ""
    NotificationCenter.default.post(
      name: .stateDidChange, object: Self.selectPickupNotificationObjectType)
  }
}
