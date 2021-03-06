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
import UIKit

/// A view controller wrapping a `GMSMapView`.
class MapViewController: UIViewController, GMTCMapViewDelegate, GMTCTripModelSubscriber {
  /// Notification object type when seleting a pickup location.
  static let selectPickupNotificationObjectType = "selectingPickup"

  /// Notification object type when seleting a dropoff location.
  static let selectDropoffNotificationObjectType = "selectingDropoff"

  /// Notification object type when booking a trip.
  static let bookTripNotificationObjectType = "bookTrip"

  /// Notification object type when cancelling a trip.
  static let cancelTripNotificationObjectType = "cancelTrip"

  /// Conversion constant from seconds to minutes.
  private static let secondsPerMinute = 60.0

  /// Conversion constant from meters to miles.
  private static let metersPerMile = 1609.0

  /// The name for pickup selection marker.
  static let pickupMarkerIconName = "grc_ic_wait_pickup_marker"

  /// The name for intermediate destination marker.
  static let intermediateDestinationMarkerIconName = "gmtc_ic_multidestination_point"

  /// The `ModelData` containing the primary state of the application.
  private let modelData: ModelData

  // MARK: - MapView variables

  var mapView: GMTCMapView {
    return self.uiView
  }

  /// Marker indicating the tentative pickup/intermediate/dropoff location.
  private var selectedMarker: GMSMarker?

  /// Marker indicating the confirmed pickup location.
  private lazy var pickupMarker = GMSMarker()

  /// Markers indicating the confirmed intermediate locations.
  private lazy var intermediateDestinationMarkers = [GMSMarker()]

  private lazy var previousTripDropoffMarker = GMSMarker()

  private var journeySharingSession: GMTCJourneySharingSession?

  private lazy var uiView: GMTCMapView = {
    let uiView = GMTCMapView(frame: CGRect.zero)
    uiView.camera = .sanFrancisco
    uiView.translatesAutoresizingMaskIntoConstraints = false
    uiView.delegate = self
    return uiView
  }()

  // MARK: - Current trip variables

  private var tripName: String = ""

  init(modelData: ModelData) {
    self.modelData = modelData
    super.init(nibName: nil, bundle: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(consumerStateUpdate), name: .stateDidChange, object: nil)

    NotificationCenter.default.addObserver(
      self, selector: #selector(intermediateDestinationAdded), name: .intermediateDestinationDidAdd,
      object: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    super.loadView()
    pickupMarker = GMSMarker()
    previousTripDropoffMarker = GMSMarker()
    setPolylineCustomization()
    self.view = uiView
  }

  private func setPolylineCustomization() {
    let consumerMapStyleCoordinator = mapView.consumerMapStyleCoordinator
    let polylineOptions = GMTCMutablePolylineStyleOptions()

    polylineOptions.isTrafficEnabled = true
    polylineOptions.setTrafficColorFor(.normal, color: Style.trafficPolylineSpeedTypeNormalColor)
    polylineOptions.setTrafficColorFor(.slow, color: Style.trafficPolylineSpeedTypeSlowColor)
    polylineOptions.setTrafficColorFor(
      .trafficJam, color: Style.trafficPolylineSpeedTypeTrafficJamColor)
    polylineOptions.setTrafficColorFor(.noData, color: Style.trafficPolylineSpeedTypeNoDataColor)

    consumerMapStyleCoordinator.setPolylineStyleOptions(polylineOptions, polylineType: .activeRoute)
  }

  // MARK: - Requests to server methods

  /// Creates a new trip when receiving "Book Trip" notification.
  private func bookTrip() {
    Task {
      let providerService = ProviderService()
      guard
        let tripName = try? await providerService.createTrip(
          pickupLocation: modelData.pickupLocation, dropoffLocation: modelData.dropoffLocation,
          intermediateDestinations: modelData.intermediateDestinations
        )
      else {
        return
      }
      modelData.customerState = .booking
      setActiveTrip(tripName: tripName)
      modelData.buttonColor = .green
    }
  }

  /// Cancels a trip when receiving "Cancel Trip" notification.
  private func cancelTrip() {
    Task {
      let providerService = ProviderService()
      do {
        try await providerService.cancelTrip(tripID: modelData.tripID)
      } catch {
        return
      }
      let tripService = GMTCServices.shared().tripService
      let tripModel = tripService.tripModel(forTripName: tripName)
      tripModel?.unregisterSubscriber(self)
      modelData.customerState = .initial
      guard let currentJourneySharingSession = journeySharingSession else { return }
      uiView.hide(currentJourneySharingSession)
      resetPanelView()
    }
  }

  // MARK: - Control panel update methods

  /// Resets labels on the `ControlPanelView`.
  private func resetPanelView() {
    modelData.timeToWaypoint = 0
    modelData.remainingDistanceInMeters = 0
    modelData.tripID = ""
    modelData.vehicleID = ""
    modelData.tripInfoLabel = Strings.controlPanelRequestRideButtonText
    modelData.controlButtonLabel = Strings.controlPanelRequestRideButtonText
  }

  /// Removes pickup marker on `mapView`.
  private func resetMarkers() {
    pickupMarker.map = nil
    pickupMarker = GMSMarker()
    for intermediateDestinationMarker in intermediateDestinationMarkers {
      intermediateDestinationMarker.map = nil
    }
    intermediateDestinationMarkers = []
    previousTripDropoffMarker.map = nil
    previousTripDropoffMarker = GMSMarker()
  }

  /// Sets and displays the tentative pickup location on `mapView` at a given `location`.
  private func setPickupLocation(_ location: CLLocationCoordinate2D) {
    if selectedMarker == nil {
      selectedMarker = GMSMarker()
      selectedMarker?.map = mapView
    }
    selectedMarker?.position = location
    selectedMarker?.icon = UIImage(named: Self.pickupMarkerIconName)

    let latLng = GMTSLatLng(latitude: location.latitude, longitude: location.longitude)
    modelData.pickupLocation = GMTSTerminalLocation(
      point: latLng, label: nil, description: nil, placeID: nil, generatedID: nil,
      accessPointID: nil)
  }

  /// Sets and displays the tentative dropoff location on `mapView` at a given `location`.
  private func setDropoffLocation(_ location: CLLocationCoordinate2D) {
    selectedMarker?.position = location
    selectedMarker?.icon = GMSMarker.markerImage(with: .red)

    let latLng = GMTSLatLng(latitude: location.latitude, longitude: location.longitude)
    modelData.dropoffLocation = GMTSTerminalLocation(
      point: latLng, label: nil, description: nil, placeID: nil, generatedID: nil,
      accessPointID: nil)
  }

  /// Sets the active trip in the `mapView`.
  private func setActiveTrip(tripName: String) {
    modelData.customerState = .journeySharing
    self.tripName = tripName
    let tripService = GMTCServices.shared().tripService
    guard let tripModel = tripService.tripModel(forTripName: tripName) else { return }
    tripModel.register(self)
    self.journeySharingSession = GMTCJourneySharingSession(tripModel: tripModel)
    guard let currentJourneysharingSession = self.journeySharingSession else { return }
    self.uiView.show(currentJourneysharingSession)
  }

  private func updateTripInfo() {
    guard let currentJourneySharingSession = journeySharingSession else { return }
    modelData.vehicleID =
      (currentJourneySharingSession.tripModel.currentTrip?.vehicleID ?? "") as String
    guard let tripID = currentJourneySharingSession.tripModel.currentTrip?.tripID() else {
      return
    }
    modelData.tripID = tripID
  }

  // MARK: - GMTCMapViewDelegate

  /// Callback method from `GMSMapView` when the map becomes idle after animations have completed.
  func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
    switch modelData.customerState {
    case .selectingPickup:
      setPickupLocation(position.target)
    case .selectingDropoff:
      setDropoffLocation(position.target)
    default:
      break
    }
  }

  // MARK: - GMTCTripModelSubscriber

  func tripModel(_ tripModel: GMTCTripModel, didUpdate tripStatus: GMTSTripStatus) {
    switch tripStatus {
    case .new:
      resetMarkers()
      modelData.tripInfoLabel = Strings.waitingForDriverMatchTitleText
      modelData.controlButtonLabel = Strings.controlPanelCancelTripButtonText
      modelData.buttonColor = Style.buttonBackgroundColor
      updateTripInfo()
    case .enrouteToPickup:
      resetMarkers()
      modelData.tripInfoLabel = Strings.enrouteToPickupTitleText
      updateTripInfo()
    case .arrivedAtPickup:
      modelData.tripInfoLabel = Strings.arrivedAtPickupTitleText
      updateTripInfo()
    case .enrouteToIntermediateDestination:
      modelData.tripInfoLabel = Strings.enrouteToIntermediateDestinationTitleText
      updateTripInfo()
    case .arrivedAtIntermediateDestination:
      modelData.tripInfoLabel = Strings.arrivedAtIntermediateDestinationTitleText
      updateTripInfo()
    case .enrouteToDropoff:
      modelData.tripInfoLabel = Strings.enrouteToDropoffTitleText
      updateTripInfo()
    case .complete:
      modelData.tripInfoLabel = Strings.tripCompleteTitleText
      updateTripInfo()
      modelData.controlButtonLabel = ""
      resetMarkers()
      let waitSeconds = 4.0
      DispatchQueue.main.asyncAfter(deadline: .now() + waitSeconds) { [weak self] in
        guard let strongSelf = self else { return }
        let tripService = GMTCServices.shared().tripService
        let tripModel = tripService.tripModel(forTripName: strongSelf.tripName)
        tripModel?.unregisterSubscriber(strongSelf)
        strongSelf.modelData.customerState = .initial
        guard let currentJourneySharingSession = strongSelf.journeySharingSession else { return }
        strongSelf.uiView.hide(currentJourneySharingSession)
        strongSelf.resetPanelView()
      }
      break
    case .canceled:
      break
    case .unknown:
      break
    @unknown default:
      break
    }
  }

  func tripModel(
    _ tripModel: GMTCTripModel,
    didUpdateActiveRouteRemainingDistance activeRouteRemainingDistance: Int32
  ) {
    modelData.remainingDistanceInMeters =
      Double(activeRouteRemainingDistance) / Double(MapViewController.metersPerMile)
  }

  func tripModel(
    _ tripModel: GMTCTripModel, didUpdateETAToNextWaypoint nextWaypointETA: TimeInterval
  ) {
    let delta = nextWaypointETA - Date().timeIntervalSince1970
    modelData.timeToWaypoint = delta / MapViewController.secondsPerMinute
  }

  func tripModel(_ tripModel: GMTCTripModel, didUpdate sessionState: GMTCTripModelState) {
    guard sessionState == .inactive else { return }
    tripModel.unregisterSubscriber(self)
  }

  func tripModel(
    _ tripModel: GMTCTripModel, didUpdateRemaining remainingWaypoints: [GMTSTripWaypoint]?
  ) {
    let currentTrip = tripModel.currentTrip
    guard let currentTripWaypoint = remainingWaypoints?.first else { return }
    if currentTrip?.tripID() != currentTripWaypoint.tripID {
      previousTripDropoffMarker.map = self.mapView
      previousTripDropoffMarker.icon = UIImage(
        named: MapViewController.intermediateDestinationMarkerIconName)
      guard let latitude = currentTripWaypoint.location?.point?.latitude else { return }
      guard let longitude = currentTripWaypoint.location?.point?.longitude else { return }
      previousTripDropoffMarker.position = CLLocationCoordinate2D(
        latitude: latitude, longitude: longitude)
      modelData.tripInfoLabel = Strings.completeLastTripTitleText
    }
  }

  // MARK: - Notification control center

  @objc private func consumerStateUpdate(notification: Notification) {
    guard let updateConsumerState = notification.object as? String else { return }
    if updateConsumerState == Self.selectPickupNotificationObjectType {
      setPickupLocation(mapView.camera.target)
    } else if updateConsumerState == Self.selectDropoffNotificationObjectType {
      // Show the pickup marker once the user has confirmed the pickup location.
      guard let point = modelData.pickupLocation.point else { return }
      pickupMarker.map = mapView
      pickupMarker.icon = UIImage(named: Self.pickupMarkerIconName)
      pickupMarker.position = CLLocationCoordinate2D(
        latitude: point.latitude, longitude: point.longitude)

      setDropoffLocation(mapView.camera.target)
    } else if updateConsumerState == Self.bookTripNotificationObjectType {
      bookTrip()
    } else if updateConsumerState == Self.cancelTripNotificationObjectType {
      cancelTrip()
    }
  }

  @objc private func intermediateDestinationAdded(notification: Notification) {
    for intermediateDestination in modelData.intermediateDestinations {
      let intermediateMarker = GMSMarker()
      intermediateMarker.map = self.mapView
      intermediateMarker.icon = UIImage(
        named: MapViewController.intermediateDestinationMarkerIconName)
      guard let latitude = intermediateDestination.point?.latitude else { return }
      guard let longitude = intermediateDestination.point?.longitude else { return }
      intermediateMarker.position = CLLocationCoordinate2D(
        latitude: latitude, longitude: longitude)
      intermediateDestinationMarkers.append(intermediateMarker)
    }
  }
}

extension GMSCameraPosition {
  fileprivate static let sanFrancisco = GMSCameraPosition.camera(
    withLatitude: 37.7749, longitude: -122.4194,
    zoom: Float(13))
}

extension Notification.Name {
  static let stateDidChange = Notification.Name("stateDidChange")
  static let intermediateDestinationDidAdd = Notification.Name("intermediateDestinationDidAdd")
}
