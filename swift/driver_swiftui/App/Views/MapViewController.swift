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

import CoreLocation
import GoogleMaps
import GoogleRidesharingDriver
import UIKit

/// A view controller wrapping a `GMSMapView`.
class MapViewController: UIViewController, CLLocationManagerDelegate, GMSNavigatorListener,
  GMTDVehicleReporterListener
{

  /// Whether to use simulated location for testing purposes. If false, the real device location is
  /// used. This should be set to false before testing this app in the real world.
  private static let isSimulatingLocation = true

  /// Coordinates of San Francisco used as the initial driver location for testing purposes.
  private static let sanFranciscoCoordinates = CLLocationCoordinate2D(
    latitude: 37.7749295, longitude: -122.4194155)

  /// How often to fetch vehicle data from the provider backend in seconds.
  private static let pollFetchVehicleTimeInterval: TimeInterval = 2

  /// The `ModelData` containing the primary state of the application.
  private let modelData: ModelData

  /// A service that sends requests and receives responses from the provider backend.
  private let providerService = ProviderService()

  /// A `locationManager` for checking the user's location permission status.
  private lazy var locationManager = CLLocationManager()

  /// A Driver SDK object that listens to Navigation SDK updates and reports them to Fleet Engine.
  private var vehicleReporter: GMTDVehicleReporter?

  /// A boolean indicating whether the vehicle is online and tracked by Fleet Engine.
  private var isVehicleOnline = false

  /// A `Timer` that periodically fetches the vehicle data from the provider backend.
  private var pollFetchVehicleTimer: Timer?

  /// A boolean indicating whether there's a fetch vehicle request in progress.
  private var isFetchVehicleInProgress = false

  private lazy var mapView: GMSMapView = {
    let mapView = GMSMapView(frame: CGRect.zero)
    mapView.settings.compassButton = true
    mapView.settings.myLocationButton = true
    return mapView
  }()

  init(modelData: ModelData) {
    self.modelData = modelData
    super.init(nibName: nil, bundle: nil)

    NotificationCenter.default.addObserver(
      self, selector: #selector(didTapControlPanelButton), name: .didTapControlPanelButton,
      object: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    super.loadView()
    view = mapView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    showTermsAndConditions()
  }

  /// Shows the dialog for the Nav SDK terms and conditions to the user.
  private func showTermsAndConditions() {
    GMSNavigationServices.showTermsAndConditionsDialogIfNeeded(
      withCompanyName: Strings.companyName
    ) { [weak self] termsAccepted in
      // Enable navigation only after the user has accepted the Terms and Conditions.
      // Both navigator and roadSnappedLocationProvider return nil if the user has not
      // accepted the Terms and Conditions dialog.
      if termsAccepted {
        self?.setUpDriver()
      } else {
        self?.showTermsAndConditionsDeniedAlert()
      }
    }
  }

  /// Shows a dialog to the user explaining that the terms must be accepted in order to use the app.
  private func showTermsAndConditionsDeniedAlert() {
    let alert = UIAlertController(
      title: Strings.termsAndConditionsDeniedAlertTitle,
      message: Strings.termsAndConditionsDeniedAlertMessage,
      preferredStyle: .alert)
    alert.addAction(
      UIAlertAction(title: Strings.okButtonText, style: .default) { [weak self] _ in
        self?.showTermsAndConditions()
      })
    present(alert, animated: true, completion: nil)
  }

  private func setUpDriver() {
    checkLocationPermission()

    mapView.isNavigationEnabled = true
    mapView.cameraMode = .following
    mapView.navigator?.sendsBackgroundNotifications = true
    mapView.navigator?.add(self)
    mapView.roadSnappedLocationProvider?.allowsBackgroundLocationUpdates = true

    if Self.isSimulatingLocation {
      // Simulate the driver location at a fixed coordinate for testing purposes,
      mapView.locationSimulator?.simulateLocation(at: Self.sanFranciscoCoordinates)
    }

    createVehicle()
  }

  private func checkLocationPermission() {
    switch locationManager.authorizationStatus {
    case .notDetermined:
      locationManager.delegate = self
      locationManager.requestAlwaysAuthorization()
    case .denied, .restricted:
      let alert = UIAlertController(
        title: Strings.locationPermissionDeniedOrRestrictedAlertTitle,
        message: Strings.locationPermissionDeniedOrRestrictedAlertMessage,
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: Strings.okButtonText, style: .default))
      present(alert, animated: true, completion: nil)
    default:
      break
    }
  }

  private func createVehicle() {
    Task {
      let randomVehicleID = String(format: "iOS-%@", UUID().uuidString)
      guard
        let vehicleID = try? await providerService.createVehicle(
          vehicleID: randomVehicleID, isBackToBackEnabled: true)
      else {
        showCreateVehicleFailureAlert()
        return
      }
      handleCreateVehicle(vehicleID: vehicleID)
    }
  }

  private func showCreateVehicleFailureAlert() {
    let alert = UIAlertController(
      title: Strings.createVehicleFailureAlertTitle,
      message: Strings.createVehicleFailureAlertMessage,
      preferredStyle: .alert)
    alert.addAction(
      UIAlertAction(title: Strings.okButtonText, style: .default) { [weak self] _ in
        self?.createVehicle()
      })
    present(alert, animated: true, completion: nil)
  }

  private func handleCreateVehicle(vehicleID: String) {
    guard let navigator = mapView.navigator else { return }
    let driverContext = GMTDDriverContext(
      accessTokenProvider: AuthTokenProvider(), providerID: APIConstants.providerID,
      vehicleID: vehicleID, navigator: navigator)
    guard let driverAPI = GMTDRidesharingDriverAPI(driverContext: driverContext) else { return }

    modelData.vehicleID = vehicleID
    let vehicleReporter = driverAPI.vehicleReporter
    vehicleReporter.add(self)

    if let roadSnappedLocationProvider = mapView.roadSnappedLocationProvider {
      // Set VehicleReporter as a listener to Navigation SDK updates.
      roadSnappedLocationProvider.add(vehicleReporter)

      // Start location updates so the Fleet Engine starts to receive location updates.
      roadSnappedLocationProvider.stopUpdatingLocation()
      roadSnappedLocationProvider.startUpdatingLocation()
    }

    // Enable location tracking for the driver.
    vehicleReporter.locationTrackingEnabled = true

    // Set the vehicle to be online so that it is visible for consumers.
    vehicleReporter.update(.online)
    self.vehicleReporter = vehicleReporter
  }

  private func pollFetchVehicle() {
    pollFetchVehicleTimer = Timer.scheduledTimer(
      timeInterval: Self.pollFetchVehicleTimeInterval, target: self,
      selector: #selector(fetchVehicle), userInfo: nil, repeats: true)
  }

  @objc private func fetchVehicle() {
    guard let vehicleID = modelData.vehicleID else { return }

    // If there's a fetch vehicle request in progress, cancel this one.
    guard !isFetchVehicleInProgress else { return }

    // Stop polling if there's already a current and next trip assigned.
    if modelData.tripID != nil && modelData.nextTripID != nil {
      pollFetchVehicleTimer?.invalidate()
      pollFetchVehicleTimer = nil
      return
    }

    isFetchVehicleInProgress = true
    Task {
      guard let matchedTripIDs = try? await providerService.getVehicle(vehicleID: vehicleID)
      else {
        isFetchVehicleInProgress = false
        return
      }
      isFetchVehicleInProgress = false
      handleFetchVehicle(matchedTripIDs: matchedTripIDs)
    }
  }

  private func handleFetchVehicle(matchedTripIDs: [String]) {
    // Keep polling if there are no trips found for this vehicle.
    guard !matchedTripIDs.isEmpty else { return }

    // Stop polling as trip data has been found for this vehicle.
    pollFetchVehicleTimer?.invalidate()
    pollFetchVehicleTimer = nil

    // Update current trip ID to the first trip ID in the assigned trips list.
    if modelData.tripID == nil {
      modelData.driverState = .new
      modelData.tripID = matchedTripIDs[0]
      handleNewTrip()
    }
    if matchedTripIDs.count >= 2 {
      modelData.nextTripID = matchedTripIDs[1]
    }
  }

  private func handleNewTrip() {
    guard let tripID = modelData.tripID else { return }

    Task {
      // Fetch trip details for the current trip ID.
      guard let (_, waypoints) = try? await providerService.getTrip(tripID: tripID) else { return }
      modelData.waypoints = waypoints
      setNextWaypointAsTheDestination()

      // Reset intermediate destinations index.
      modelData.intermediateDestinationIndex = 0
    }
  }

  @objc private func didTapControlPanelButton(notification: Notification) {
    if modelData.isEnrouteToWaypoint {
      updateTripStatusToArrivedAtWaypoint()
    } else {
      updateTripStatusToEnrouteToWaypoint()
    }
  }

  private func updateTripStatusToArrivedAtWaypoint() {
    guard let waypoint = modelData.waypoints?.first else { return }
    modelData.isEnrouteToWaypoint = false

    // Upon arrival, remove the first waypoint from the list.
    modelData.waypoints?.removeFirst()

    if Self.isSimulatingLocation {
      mapView.locationSimulator?.isPaused = true
    }
    switch waypoint.waypointType {
    case .pickUp:
      updateTrip(status: .arrivedAtPickup)
      modelData.driverState = .arrivedAtPickup
      setNextWaypointAsTheDestination()
    case .intermediateDestination:
      updateTrip(status: .arrivedAtIntermediateDestination)
      modelData.driverState = .arrivedAtIntermediateDestination
      setNextWaypointAsTheDestination()
      modelData.intermediateDestinationIndex += 1
    case .dropOff:
      updateTrip(status: .complete)
      if Self.isSimulatingLocation {
        mapView.locationSimulator?.stopSimulation()
      }
      mapView.navigator?.clearDestinations()

      // If a next trip is available, switch to that trip.
      if let nextTripID = modelData.nextTripID {
        modelData.driverState = .new
        modelData.tripID = nextTripID
        modelData.nextTripID = nil
        handleNewTrip()
      } else {
        modelData.driverState = .tripComplete
        // Wait 5 seconds to start polling for a new trip.
        // Note: This timer is optional and it's used in this app for demonstration purposes.
        perform(#selector(startPollingForTrip), with: nil, afterDelay: 5)
      }
    default:
      break
    }
  }

  private func updateTripStatusToEnrouteToWaypoint() {
    guard let waypoint = modelData.waypoints?.first else { return }
    modelData.isEnrouteToWaypoint = true

    startNavigation()
    switch waypoint.waypointType {
    case .pickUp:
      updateTrip(status: .enrouteToPickup)
      modelData.driverState = .enrouteToPickup
    case .intermediateDestination:
      updateTrip(
        status: .enrouteToIntermediateDestination,
        intermediateDestinationIndex: modelData.intermediateDestinationIndex)
      modelData.driverState = .enrouteToIntermediateDestination
    case .dropOff:
      updateTrip(status: .enrouteToDropoff)
      modelData.driverState = .enrouteToDropoff

      // Start polling for new trips as the vehicle is back-to-back enabled.
      pollFetchVehicle()
    default:
      break
    }
  }

  private func updateTrip(status: ProviderTripStatus, intermediateDestinationIndex: Int? = nil) {
    Task {
      guard let tripID = modelData.tripID else { return }
      try? await providerService.updateTrip(
        tripID: tripID, status: status, intermediateDestinationIndex: intermediateDestinationIndex
      )
    }
  }

  @objc private func startPollingForTrip() {
    modelData.driverState = .idle
    modelData.tripID = nil
    modelData.nextTripID = nil

    // Poll the provider to fetch the current vehicle state.
    pollFetchVehicle()
  }

  private func setNextWaypointAsTheDestination() {
    guard let coordinate = modelData.waypoints?.first?.location?.point?.coordinate(),
      let navWaypoint = GMSNavigationWaypoint(location: coordinate, title: "")
    else {
      return
    }
    mapView.navigator?.setDestinations([navWaypoint]) { _ in
    }
  }

  private func startNavigation() {
    // Start turn-by-turn guidance along the current route.
    mapView.navigator?.isGuidanceActive = true
    mapView.cameraMode = .following

    if Self.isSimulatingLocation {
      // Simulate vehicle progress along the route for testing purposes.
      if let locationSimulator = mapView.locationSimulator {
        locationSimulator.isPaused = false
        locationSimulator.simulateLocationsAlongExistingRoute()
      }
    }
  }

  // MARK: - CLLocationManagerDelegate

  func locationManagerDidChangeAuthorization(_ locationManager: CLLocationManager) {
    checkLocationPermission()
  }

  // MARK: - GMSNavigatorListener

  func navigator(_ navigator: GMSNavigator, didArriveAt waypoint: GMSNavigationWaypoint) {
    // Handle the driver did arrive at a waypoint.
  }

  // MARK: - GMTDVehicleReporterListener

  func vehicleReporter(
    _ vehicleReporter: GMTDVehicleReporter, didSucceed vehicleUpdate: GMTDVehicleUpdate
  ) {
    // This event informs that the backend services successfully received the vehicle location and
    // state update.
    if vehicleUpdate.vehicleState == .online {
      if !isVehicleOnline {
        isVehicleOnline = true

        // Poll the provider to fetch a trip match.
        pollFetchVehicle()
      }
    }
  }

  func vehicleReporter(
    _ vehicleReporter: GMTDVehicleReporter, didFail vehicleUpdate: GMTDVehicleUpdate,
    withError error: Error
  ) {
    // Vehicle update failed.
  }
}

extension Notification.Name {
  static let didTapControlPanelButton = Notification.Name("didTapControlPanelButton")
}
