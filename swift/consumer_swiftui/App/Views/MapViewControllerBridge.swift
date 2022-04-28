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

import GoogleMaps
import GoogleRidesharingConsumer
import SwiftUI

/// A SwiftUI view wrapping a `MapViewController`.
struct MapViewControllerBridge: UIViewControllerRepresentable {
  /// The `ModelData` containing the primary state of the application.
  @EnvironmentObject var modelData: ModelData

  /// Lifecycle method for UIViewControllerRepresentable which creates the coordinate object that
  /// allows changes from the contained UIViewController to flow back into the SwiftUI application.
  func makeCoordinator() -> MapCoordinator {
    return MapCoordinator(parent: self)
  }

  /// Lifecycle method for UIViewControllerRepresentable which creates the UIViewController.
  func makeUIViewController(context: Context) -> MapViewController {
    let uiViewController = MapViewController(modelData: modelData)
    uiViewController.mapView.delegate = context.coordinator
    return uiViewController
  }

  /// Lifecycle method for UIViewControllerRepresentable which updates the UIViewController.
  func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
  }
}

/// Class to define the coordinator.
final class MapCoordinator: NSObject, GMTCMapViewDelegate {
  /// Points to the containing MapViewControllerBridge instance.
  private let parent: MapViewControllerBridge
  private var selectedMarker: GMSMarker?

  /// Initalizes the coordinator.
  init(parent: MapViewControllerBridge) {
    self.parent = parent
  }

  /// Callback method from `GMSMapView` for tapping a location on `mapView`.
  func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
    switch parent.modelData.customerState {
    case .initial:
      break
    case .selectingPickup:
      if selectedMarker == nil {
        selectedMarker = GMSMarker()
        selectedMarker?.map = mapView
      }
      selectedMarker?.position = position.target
      selectedMarker?.icon = UIImage(named: MapViewController.pickupMarkerIconName)

      let longitude = position.target.longitude
      let latitude = position.target.latitude
      let latlng = GMTSLatLng(latitude: latitude, longitude: longitude)
      parent.modelData.pickupLocation = GMTSTerminalLocation(
        point: latlng, label: nil, description: nil, placeID: nil, generatedID: nil,
        accessPointID: nil)
      break
    case .selectingDropoff:
      selectedMarker?.position = position.target
      selectedMarker?.icon = GMSMarker.markerImage(with: .red)

      let longitude = position.target.longitude
      let latitude = position.target.latitude
      let latlng = GMTSLatLng(latitude: latitude, longitude: longitude)
      parent.modelData.dropoffLocation = GMTSTerminalLocation(
        point: latlng, label: nil, description: nil, placeID: nil, generatedID: nil,
        accessPointID: nil)
      break
    case .tripPreview:
      break
    case .booking:
      break
    case .journeySharing:
      break
    }
  }
}
