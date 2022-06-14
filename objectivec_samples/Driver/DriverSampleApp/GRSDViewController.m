/*
 * Copyright 2020 Google LLC. All rights reserved.
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

#import "GRSDViewController.h"

#import <CoreLocation/CoreLocation.h>

#import <GoogleRidesharingDriver/GoogleRidesharingDriver.h>
#import "GRSDAPIConstants.h"
#import "GRSDBottomPanelView.h"
#import "GRSDProviderService.h"
#import "GRSDVehicleModel.h"

/** Coordinates to be used for setting driver location when in simulator. */
static const CLLocationCoordinate2D kSanFranciscoCoordinates = {37.7749295, -122.4194155};

/** Enum representing all available trip states. */
typedef NS_ENUM(NSInteger, GRSDTripState) {
  GRSDTripStateNew = 0,
  GRSDTripStateEnrouteToPickup,
  GRSDTripStateArrivedAtPickup,
  GRSDTripStateEnrouteToIntermediateDestination,
  GRSDTripStateArrivedAtIntermediateDestination,
  GRSDTripStateEnrouteToDropoff,
  GRSDTripStateComplete,
};

/** Default font name for the application. */
static NSString *const kDefaultFontName = @"Arial";

/** Default font size for the application. */
static const float kDefaultFontSize = 12.0;

/** Returns the default background color for the navigation bar. */
static UIColor *DefaultNavigationBarColor(void) {
  return [UIColor colorWithRed:74 / 255.0 green:97 / 255.0 blue:118 / 255.0 alpha:1];
}

// UI and styling constants.
static UIColor *ButtonEnabledColor(void) {
  return [UIColor colorWithRed:66 / 255.0 green:133 / 255.0 blue:244 / 255.0 alpha:1];
}
static UIColor *PanelSeparatorColor(void) {
  return [UIColor colorWithRed:0 / 255.0 green:0 / 255.0 blue:0 / 255.0 alpha:0.24];
}

/**
 * Callback block definition of creating a driver.
 *
 * @param driverCreated Whether the driver was created.
 */
typedef void (^GRSDCreateDriverHandler)(BOOL driverCreated);

// Constants for bottom panel trip states.
static NSString *const kTripIDLabel = @"Trip ID";
static NSString *const kBackToBackNextTripIDLabel = @"Next Trip ID";
static NSString *const kNewTripPanelTitle = @"New trip";
static NSString *const kNewTripButtonTitle = @"Start Navigation";
static NSString *const kEnrouteToPickupPanelTitle = @"Picking up rider";
static NSString *const kEnrouteToIntermediateDestinationPanelTitle =
    @"Driving to intermediate stop";
static NSString *const kEnrouteToPickupButtonTitle = @"Arrived at pickup";
static NSString *const kArrivedAtPickupPanelTitle = @"Arrived at pickup";
static NSString *const kArrivedAtIntermediateDestinationPanelTitle =
    @"Arrived at intermediate stop";
static NSString *const kDriveToDropoffButtonTitle = @"Drive to dropoff";
static NSString *const kDriveToIntermediateStopButtonTitle = @"Drive to intermediate stop";
static NSString *const kEnrouteToDropoffPanelTitle = @"Dropping off rider";
static NSString *const kEnrouteToDropoffButtonTitle = @"Complete trip";
static NSString *const kEnrouteToIntermediateDestinationButtonTitle =
    @"Arrived at intermediate stop";
static NSString *const kCompletedTripPanelTitle = @"Trip completed";
static NSString *const kCompletedTripButtonTitle = @"Trip completed";

// Strings for the 'Terms And Conditions Not Accepted' alert.
static NSString *const kTermsAndConditionsDeniedAlertTitle = @"Terms And Conditions Not Accepted";
static NSString *const kTermsAndConditionsDeniedAlertDescription =
    @"The terms and conditions must be accepted in order to use the app.";
static NSString *const kTermsAndConditionsDeniedAlertOKTitle = @"OK";

// Strings for the 'Driver creation' failed alert.
static NSString *const kDriverCreationFailedAlertTitle = @"Unable to Create Vehicle";
static NSString *const kDriverCreationFailedAlertDescription =
    @"An error occured while connecting to the provider backend.";
static NSString *const kDriverCreationFailedAlertRetryTitle = @"Retry";

@implementation GRSDViewController {
  CLLocationManager *_locationManager;
  /** View to hold the map and bottom panel views. */
  UIStackView *_contentStackView;
  /** The map view that is used as the base view. */
  GMSMapView *_mapView;
  /** Panel view used to control driver actions. */
  GRSDBottomPanelView *_bottomPanel;
  GRSDProviderService *_providerService;
  NSString *_currentVehicleID;
  GMTDVehicleReporter *_vehicleReporter;
  NSTimer *_pollFetchVehicleTimer;
  BOOL _isFetchVehicleInProgress;
  NSMutableArray<GMTSTripWaypoint *> *_waypoints;
  NSString *_currentTripID;
  GRSDTripState _currentTripState;
  BOOL _isVehicleOnline;
  NSUInteger _currentIntermediateDestinationIndex;
  NSString *_backToBackNextTripID;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];

  // Request for location permissions.
  _locationManager = [[CLLocationManager alloc] init];
  [_locationManager requestAlwaysAuthorization];

  _providerService = [[GRSDProviderService alloc] init];

  [self setUpNavigationBar];
  [self setUpContentStackView];
  [self setUpMapView];
  [self showTermsAndConditionsAndSetUpDriver];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  if (_pollFetchVehicleTimer) {
    [_pollFetchVehicleTimer invalidate];
    _pollFetchVehicleTimer = nil;
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  if (_pollFetchVehicleTimer) {
    [_pollFetchVehicleTimer invalidate];
    _pollFetchVehicleTimer = nil;
  }
}

#pragma mark - Private helpers

- (void)setUpNavigationBar {
  [self.navigationController.navigationBar setTitleTextAttributes:@{
    NSFontAttributeName : [UIFont fontWithName:kDefaultFontName size:kDefaultFontSize],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  }];
  self.navigationController.navigationBar.barTintColor = DefaultNavigationBarColor();
  self.navigationController.navigationBar.translucent = NO;
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

- (void)setUpContentStackView {
  // Stack view that hold the map and bottom panel.
  _contentStackView = [[UIStackView alloc] init];
  _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
  _contentStackView.axis = UILayoutConstraintAxisVertical;
  [self.view addSubview:_contentStackView];
  [_contentStackView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor]
      .active = YES;
  [_contentStackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [_contentStackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
  [_contentStackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
}

- (void)setUpMapView {
  // Set up the Navigation SDK.
  _mapView = [[GMSMapView alloc] init];

  // Set current instance as a listener to Navigation SDK updates.
  [_mapView.navigator addListener:self];
  [_mapView.roadSnappedLocationProvider addListener:self];

  _mapView.delegate = self;
  _mapView.translatesAutoresizingMaskIntoConstraints = NO;
  _mapView.settings.compassButton = YES;
  _mapView.settings.myLocationButton = YES;
  [_contentStackView addArrangedSubview:_mapView];
}

- (void)setUpBottomPanel {
  // Add a separator on top of the bottom panel.
  UIView *separator = [[UIView alloc] init];
  separator.backgroundColor = PanelSeparatorColor();
  separator.translatesAutoresizingMaskIntoConstraints = NO;
  [separator.heightAnchor constraintEqualToConstant:1].active = YES;
  [_contentStackView addArrangedSubview:separator];

  // Bottom panel that shows the current trip ID and a button to update the current trip state.
  _bottomPanel =
      [[GRSDBottomPanelView alloc] initWithTitle:kNewTripPanelTitle
                                     buttonTitle:kNewTripButtonTitle
                                    buttonTarget:self
                                    buttonAction:@selector(didTapUpdateTripStateButton:)];
  _bottomPanel.actionButton.enabled = NO;
  [_contentStackView addArrangedSubview:_bottomPanel];
}

- (void)showTermsAndConditionsAndSetUpDriver {
  // Show the dialog for the Terms and Conditions and only enable navigation after the user’s
  // acceptance.
  __weak typeof(self) weakSelf = self;

  GMSTermsResponseCallback termsAndConditionsCallback = ^(BOOL termsAccepted) {
    typeof(self) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (!termsAccepted) {
      [strongSelf showTermsAndConditionsDeniedAlert];
      return;
    }
    GMSMapView *mapView = strongSelf->_mapView;
    // Enable navigation only after the user has accepted the Terms and Conditions.
    // Both navigator and roadSnappedLocationProvider return nil if the user has not
    // accepted the Terms and Conditions dialog.
    mapView.navigationEnabled = YES;
    mapView.cameraMode = GMSNavigationCameraModeFollowing;
    mapView.settings.compassButton = YES;
    mapView.navigator.sendsBackgroundNotifications = YES;

    [mapView.roadSnappedLocationProvider addListener:strongSelf];
    [mapView.navigator addListener:strongSelf];
    mapView.roadSnappedLocationProvider.allowsBackgroundLocationUpdates = YES;

    [strongSelf setUpDriver];
  };

  [GMSNavigationServices
      showTermsAndConditionsDialogIfNeededWithCompanyName:@"Sample App Company"
                                                 callback:termsAndConditionsCallback];
}

- (void)showTermsAndConditionsDeniedAlert {
  // Show a warning dialog to the user explaining that the terms and conditions need to be accepted
  // in order to use the app.
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:kTermsAndConditionsDeniedAlertTitle
                                          message:kTermsAndConditionsDeniedAlertDescription
                                   preferredStyle:UIAlertControllerStyleAlert];
  __weak typeof(self) weakSelf = self;
  UIAlertAction *okAction =
      [UIAlertAction actionWithTitle:kTermsAndConditionsDeniedAlertOKTitle
                               style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *action) {
                               [weakSelf showTermsAndConditionsAndSetUpDriver];
                             }];
  [alert addAction:okAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)setUpDriver {
  // Simulate the driver location at a fixed coordinate.
  // Note: The locationSimulator allows the user location to be simulated for testing purposes, and
  // references to it should be removed before testing this app in the real world.
  [_mapView.locationSimulator simulateLocationAtCoordinate:kSanFranciscoCoordinates];

  _isVehicleOnline = NO;

  __weak typeof(self) weakSelf = self;
  [self createDriver:^(BOOL driverCreated) {
    typeof(self) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (driverCreated) {
      // Enable location tracking for the driver.
      strongSelf->_vehicleReporter.locationTrackingEnabled = YES;
      // Set driver to be online so that it is visible for consumers.
      [strongSelf->_vehicleReporter updateVehicleState:GMTDVehicleStateOnline];
    } else {
      [strongSelf promptToRetryDriverSetup];
    }
  }];
}

- (void)promptToRetryDriverSetup {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:kDriverCreationFailedAlertTitle
                                          message:kDriverCreationFailedAlertDescription
                                   preferredStyle:UIAlertControllerStyleAlert];

  __weak typeof(self) weakSelf = self;
  UIAlertAction *retryAction = [UIAlertAction actionWithTitle:kDriverCreationFailedAlertRetryTitle
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                        [weakSelf setUpDriver];
                                                      }];
  [alert addAction:retryAction];

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)createDriver:(GRSDCreateDriverHandler)completion {
  __weak typeof(self) weakSelf = self;
  NSString *randomVehicleID = [NSString stringWithFormat:@"iOS-%@", [NSUUID UUID].UUIDString];
  // Create a vehicle with b2b support enabled by default.
  [_providerService
      createVehicleWithID:randomVehicleID
      isBackToBackEnabled:YES
               completion:^(GRSDVehicleModel *_Nullable vehicleModel, NSError *_Nullable error) {
                 [weakSelf handleCreateVehicleWithModel:vehicleModel
                                                  error:error
                                             completion:completion];
               }];
}

- (void)handleCreateVehicleWithModel:(GRSDVehicleModel *)vehicleModel
                               error:(NSError *)error
                          completion:(GRSDCreateDriverHandler)completion {
  if (error) {
    NSLog(@"Failed to create vehicle: %@", error.localizedDescription);
    completion(NO);
    return;
  }

  if (!vehicleModel) {
    return;
  }

  NSString *vehicleID = vehicleModel.vehicleID;

  if (vehicleID.length == 0) {
    completion(NO);
    return;
  }

  _currentVehicleID = vehicleID;
  self.title = [NSString stringWithFormat:@"Vehicle ID: %@", vehicleID];

  // Set up Driver SDK.
  GRSDProviderService *providerService = _providerService;
  if (!providerService) {
    completion(NO);
    return;
  }

  GMTDDriverContext *driverContext =
      [[GMTDDriverContext alloc] initWithAccessTokenProvider:providerService
                                                  providerID:kProviderID
                                                   vehicleID:vehicleID
                                                   navigator:_mapView.navigator];
  GMTDRidesharingDriverAPI *driverAPI =
      [[GMTDRidesharingDriverAPI alloc] initWithDriverContext:driverContext];

  _vehicleReporter = driverAPI.vehicleReporter;
  [_vehicleReporter addListener:self];

  // Set VehicleReporter as a listener to Navigation SDK updates.
  [_mapView.roadSnappedLocationProvider addListener:_vehicleReporter];

  // Start location updates so the GMTDFleetEngine starts to receive location updates.
  [_mapView.roadSnappedLocationProvider stopUpdatingLocation];
  [_mapView.roadSnappedLocationProvider startUpdatingLocation];
  completion(YES);
}

/* Starts polling for vehicle details. */
- (void)pollFetchVehicle {
  _pollFetchVehicleTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                            target:self
                                                          selector:@selector(fetchVehicle)
                                                          userInfo:nil
                                                           repeats:YES];
}

/* Fetches details for the current vehicle ID. */
- (void)fetchVehicle {
  // If there's a fetch vehicle request in flight, cancel this one.
  if (_isFetchVehicleInProgress) {
    return;
  }

  // Stop polling if there's already a current and next trip assigned.
  if (_currentTripID && _backToBackNextTripID) {
    [_pollFetchVehicleTimer invalidate];
    return;
  }

  _isFetchVehicleInProgress = YES;

  __weak typeof(self) weakSelf = self;
  [_providerService fetchVehicleWithID:_currentVehicleID
                            completion:^(NSArray<NSString *> *_Nullable matchedTripIds,
                                         NSError *_Nullable error) {
                              [weakSelf handleFetchVehicleResponseWithMatchedTripIds:matchedTripIds
                                                                               error:error];
                            }];
};

/* Handles a response from a fetchVehicle provider request. */
- (void)handleFetchVehicleResponseWithMatchedTripIds:(NSArray<NSString *> *)matchedTripIDs
                                               error:(NSError *)error {
  _isFetchVehicleInProgress = NO;
  if (error || !matchedTripIDs || !matchedTripIDs.count) {
    // Keep polling if there are no trips found for this vehicle.
    return;
  }
  // Stop polling as trip data has been found for this vehicle.
  [_pollFetchVehicleTimer invalidate];

  // Update current trip ID to the first trip ID in the assigned trips list.
  if (!_currentTripID) {
    _currentTripID = [matchedTripIDs[0] copy];
    _currentTripState = GRSDTripStateNew;
    [self handleNewTrip];
  }
  if (matchedTripIDs.count == 2) {
    _backToBackNextTripID = [matchedTripIDs[1] copy];
    _bottomPanel.nextTripIDLabel.text =
        [NSString stringWithFormat:@"%@: %@", kBackToBackNextTripIDLabel, _backToBackNextTripID];
    _bottomPanel.nextTripIDLabel.hidden = NO;
  }
}

/* Displays the new trip details in the bottom panel. */
- (void)displayNewTrip {
  if (_bottomPanel) {
    _bottomPanel.hidden = NO;
    _bottomPanel.actionButton.hidden = NO;
    _bottomPanel.titleLabel.text = kNewTripPanelTitle;
    [_bottomPanel.actionButton setTitle:kNewTripButtonTitle forState:UIControlStateNormal];
  } else {
    [self setUpBottomPanel];
  }
  _bottomPanel.tripIDLabel.text =
      [NSString stringWithFormat:@"%@: %@", kTripIDLabel, _currentTripID];
}

/* Handles a new trip by displaying the trip ID and updating waypoints. */
- (void)handleNewTrip {
  __weak typeof(self) weakSelf = self;

  // Fetch trip details for the current Trip ID.
  [_providerService fetchTripWithID:_currentTripID
                         completion:^(NSString *_Nullable tripID, NSString *_Nullable tripStatus,
                                      NSArray<GMTSTripWaypoint *> *_Nullable waypoints,
                                      NSError *_Nullable error) {
                           if (error) {
                             NSLog(@"Failed to get trip details with error: %@", error);
                             return;
                           }
                           [weakSelf handleFetchTripWithWaypoints:waypoints];
                         }];

  // Reset intermediate destinations index.
  _currentIntermediateDestinationIndex = 0;
}

- (void)handleFetchTripWithWaypoints:(NSArray<GMTSTripWaypoint *> *)waypoints {
  _waypoints = [waypoints mutableCopy];
  [self displayNewTrip];
  [self setNextWaypointAsTheDestination];
}

/* Sets the next navigation destination to the first available waypoint. */
- (void)setNextWaypointAsTheDestination {
  if (!_waypoints || !_waypoints.count) {
    return;
  }

  GMTSTripWaypoint *tripWaypoint = [_waypoints firstObject];
  GMSNavigationWaypoint *navWaypoint =
      [[GMSNavigationWaypoint alloc] initWithLocation:tripWaypoint.location.point.coordinate
                                                title:@""];
  NSArray<GMSNavigationWaypoint *> *destination = @[ navWaypoint ];

  __weak typeof(self) weakSelf = self;
  [_mapView.navigator setDestinations:destination
                             callback:^(GMSRouteStatus routeStatus) {
                               [weakSelf handleSetDestinationsResponseWithRouteStatus:routeStatus];
                             }];
}

/**
 * Returns the button title to display for the next destination which can be dropoff or intermediate
 * stop.
 */
- (nullable NSString *)getActionButtonTitleForNextDestination {
  if (!_waypoints || !_waypoints.count) {
    NSLog(@"Error: No waypoints available.");
    return nil;
  }

  if (_waypoints[0].waypointType == GMTSTripWaypointTypeIntermediateDestination) {
    return kDriveToIntermediateStopButtonTitle;
  }

  return kDriveToDropoffButtonTitle;
}

- (void)handleSetDestinationsResponseWithRouteStatus:(GMSRouteStatus)routeStatus {
  if (routeStatus == GMSRouteStatusOK) {
    // Enable the trip state button once the route is generated.
    _bottomPanel.actionButton.enabled = YES;
    _bottomPanel.actionButton.backgroundColor = ButtonEnabledColor();
  } else {
    NSLog(@"Error generating route.");
  }
}

- (void)updateTripWithStatus:(NSString *)newStatus
    intermediateDestinationIndex:(NSNumber *)intermediateDestinationIndex {
  __weak typeof(self) weakSelf = self;
  [_providerService updateTripWithStatus:newStatus
                                  tripID:_currentTripID
            intermediateDestinationIndex:intermediateDestinationIndex
                              completion:^(NSString *tripID, NSError *error) {
                                [weakSelf handleUpdateTripResponseWithStatus:newStatus
                                                                      tripID:tripID
                                                                       error:error];
                              }];
}

- (void)handleUpdateTripResponseWithStatus:(NSString *)newStatus
                                    tripID:(NSString *)tripID
                                     error:(NSError *)error {
  if (error) {
    return;
  }

  if (![tripID isEqual:_currentTripID]) {
    return;
  }

  if ([newStatus isEqual:GRSDProviderServiceTripStatusEnrouteToPickup]) {
    _currentTripState = GRSDTripStateEnrouteToPickup;
  }
  if ([newStatus isEqual:GRSDProviderServiceTripStatusArrivedAtPickup]) {
    _currentTripState = GRSDTripStateArrivedAtPickup;
  }
  if ([newStatus isEqual:GRSDProviderServiceTripStatusEnrouteToIntermediateDestination]) {
    _currentTripState = GRSDTripStateEnrouteToIntermediateDestination;
  }
  if ([newStatus isEqual:GRSDProviderServiceTripStatusArrivedAtIntermediateDestination]) {
    _currentTripState = GRSDTripStateArrivedAtIntermediateDestination;
  }
  if ([newStatus isEqual:GRSDProviderServiceTripStatusEnrouteToDropoff]) {
    _currentTripState = GRSDTripStateEnrouteToDropoff;
  }
  if ([newStatus isEqual:GRSDProviderServiceTripStatusComplete]) {
    _currentTripState = GRSDTripStateComplete;

    // if a next trip is available, switch to that trip.
    if (_backToBackNextTripID) {
      _currentTripID = [_backToBackNextTripID copy];
      _currentTripState = GRSDTripStateNew;
      _backToBackNextTripID = nil;
      _bottomPanel.nextTripIDLabel.hidden = YES;
      [self handleNewTrip];
    } else {
      // Wait 5 seconds to start polling for a new trip.
      // Note: This timer is optional and it's used in this app for demonstration purposes.
      [NSTimer scheduledTimerWithTimeInterval:5
                                       target:self
                                     selector:@selector(startPollingForTrip)
                                     userInfo:nil
                                      repeats:NO];
    }
  }
}

- (void)startPollingForTrip {
  _currentTripID = nil;
  _backToBackNextTripID = nil;

  // Hide bottom panel while driver waits for a new trip.
  _bottomPanel.hidden = YES;

  // Poll the provider to fetch the current vehicle state.
  [self pollFetchVehicle];
}

- (void)changeToEnrouteToPickupState {
  // Update bottom panel UI to reflect the "Enroute to pick-up" trip state.
  _bottomPanel.titleLabel.text = kEnrouteToPickupPanelTitle;
  [_bottomPanel.actionButton setTitle:kEnrouteToPickupButtonTitle forState:UIControlStateNormal];

  // Start navigation and update trip state with the provider.
  [self startNavigation];
  [self updateTripWithStatus:GRSDProviderServiceTripStatusEnrouteToPickup
      intermediateDestinationIndex:nil];
}

- (void)changeToArrivedAtPickupState {
  // Update bottom panel UI to reflect the "Arrived at pick-up" trip state.
  _bottomPanel.titleLabel.text = kArrivedAtPickupPanelTitle;

  NSString *buttonTitle = [self getActionButtonTitleForNextDestination];
  if (buttonTitle) {
    [_bottomPanel.actionButton setTitle:buttonTitle forState:UIControlStateNormal];
  }

  // Update trip state with the provider.
  [self updateTripWithStatus:GRSDProviderServiceTripStatusArrivedAtPickup
      intermediateDestinationIndex:nil];

  // Disable button until the route is generated by the navigator.
  _bottomPanel.actionButton.enabled = NO;
  _bottomPanel.actionButton.backgroundColor = UIColor.grayColor;

  // Set the destination to the next available waypoint.
  [self setNextWaypointAsTheDestination];
}

/**
 * Changes to the enroute to next stop state. Next stop could be an intermediate destination or the
 * final dropoff.
 */
- (void)changeToEnrouteToNextStopState {
  if (!_waypoints || !_waypoints.count) {
    NSLog(@"Error: No waypoints found to route to.");
    return;
  }

  if (_waypoints[0].waypointType == GMTSTripWaypointTypeIntermediateDestination) {
    [self changeToEnrouteToIntermediateDestinationState];
  } else {
    [self changeToEnrouteToDropoffState];
  }
}

- (void)changeToEnrouteToIntermediateDestinationState {
  // Update bottom panel UI to reflect the "Enroute to intermediate destination" trip state.
  _bottomPanel.titleLabel.text = kEnrouteToIntermediateDestinationPanelTitle;
  [_bottomPanel.actionButton setTitle:kEnrouteToIntermediateDestinationButtonTitle
                             forState:UIControlStateNormal];

  // Start navigation and update trip state with the provider.
  [self startNavigation];
  [self updateTripWithStatus:GRSDProviderServiceTripStatusEnrouteToIntermediateDestination
      intermediateDestinationIndex:[NSNumber
                                       numberWithInteger:_currentIntermediateDestinationIndex]];
}

- (void)changeToArrivedAtIntermediateDestinationState {
  // Update bottom panel UI to reflect the "Arrived at Intermediate Destination" trip state.
  _bottomPanel.titleLabel.text = kArrivedAtIntermediateDestinationPanelTitle;

  NSString *buttonTitle = [self getActionButtonTitleForNextDestination];
  if (buttonTitle) {
    [_bottomPanel.actionButton setTitle:buttonTitle forState:UIControlStateNormal];
  }

  // Update trip state with the provider.
  [self updateTripWithStatus:GRSDProviderServiceTripStatusArrivedAtIntermediateDestination
      intermediateDestinationIndex:nil];

  // Disable button until the route is generated by the navigator.
  _bottomPanel.actionButton.enabled = NO;
  _bottomPanel.actionButton.backgroundColor = UIColor.grayColor;

  // Set the destination to the next available waypoint.
  [self setNextWaypointAsTheDestination];
  _currentIntermediateDestinationIndex++;
}

- (void)changeToEnrouteToDropoffState {
  // Update bottom panel UI to reflect the "Enroute to drop-off" trip state.
  _bottomPanel.titleLabel.text = kEnrouteToDropoffPanelTitle;
  [_bottomPanel.actionButton setTitle:kEnrouteToDropoffButtonTitle forState:UIControlStateNormal];

  // Start navigation and update trip state with the provider.
  [self startNavigation];
  [self updateTripWithStatus:GRSDProviderServiceTripStatusEnrouteToDropoff
      intermediateDestinationIndex:nil];

  // Start polling for new trips as the vehicle is b2b enabled.
  [self pollFetchVehicle];
}

- (void)changeToTripCompleteState {
  // Update bottom panel UI to reflect the "Complete" trip state.
  _bottomPanel.titleLabel.text = kCompletedTripPanelTitle;
  _bottomPanel.actionButton.hidden = YES;

  // Stop navigation.
  [_mapView.locationSimulator stopSimulation];
  [_mapView.navigator clearDestinations];

  // Update trip state with the provider.
  [self updateTripWithStatus:GRSDProviderServiceTripStatusComplete
      intermediateDestinationIndex:nil];
}

- (void)startNavigation {
  // Start turn-by-turn guidance along the current route.
  _mapView.navigator.guidanceActive = YES;
  _mapView.navigator.sendsBackgroundNotifications = YES;
  _mapView.cameraMode = GMSNavigationCameraModeFollowing;

  // Simulate vehicle progress along the route.
  // Note: The locationSimulator allows the user location to be simulated for testing purposes, and
  // references to it should be removed before testing this app in the real world.
  if (_mapView.locationSimulator.isPaused) {
    _mapView.locationSimulator.paused = NO;
  }
  [_mapView.locationSimulator simulateLocationsAlongExistingRoute];
}

- (void)didTapUpdateTripStateButton:(UIButton *)sender {
  // Based on the current trip state, transition to the next trip state following this order:
  // `NewTrip` -> `EnrouteToPickup` -> `ArrivedAtPickup` ->
  // 'EnrouteToIntermediateDestination'(Optional) -> 'ArrivedAtIntermediateDestination'(Optional)
  // `EnrouteToDropoff` -> `TripComplete`.
  switch (_currentTripState) {
    case GRSDTripStateNew:
      [self changeToEnrouteToPickupState];
      break;
    case GRSDTripStateEnrouteToPickup:
      [self updateStateAfterDestinationArrival];
      [self changeToArrivedAtPickupState];
      break;
    case GRSDTripStateArrivedAtPickup:
      [self changeToEnrouteToNextStopState];
      break;
    case GRSDTripStateEnrouteToIntermediateDestination:
      [self updateStateAfterDestinationArrival];
      [self changeToArrivedAtIntermediateDestinationState];
      break;
    case GRSDTripStateArrivedAtIntermediateDestination:
      [self changeToEnrouteToNextStopState];
      break;
    case GRSDTripStateEnrouteToDropoff:
      [self updateStateAfterDestinationArrival];
      [self changeToTripCompleteState];
      break;
    case GRSDTripStateComplete:
      break;
  }
}

/* Pop the first waypoint from the list after arriving to a destination. Also stop the location
 * simulator */
- (void)updateStateAfterDestinationArrival {
  // Upon arrival, remove the top waypoint from the list.
  // Waypoints are added in order so should never have the case where you remove the wrong waypoint.
  if (_waypoints && _waypoints.count) {
    [_waypoints removeObjectAtIndex:0];
  }
  _mapView.locationSimulator.paused = YES;
}

#pragma mark - GMSRoadSnappedLocationProviderListener

- (void)locationProvider:(GMSRoadSnappedLocationProvider *)locationProvider
       didUpdateLocation:(CLLocation *)location {
  // Required protocol callback.
}

#pragma mark - GMTDVehicleReporterListener

- (void)vehicleReporter:(GMTDVehicleReporter *)vehicleReporter
    didSucceedVehicleUpdate:(GMTDVehicleUpdate *)vehicleUpdate {
  // This event informs that the backend services successfully received the vehicle location and
  // state update.
  if (vehicleUpdate.vehicleState == GMTDVehicleStateOnline) {
    NSLog(@"Vehicle is online");
    if (!_isVehicleOnline) {
      _isVehicleOnline = YES;

      // Poll the provider to fetch a trip match.
      [self pollFetchVehicle];
    }
  } else {
    NSLog(@"Vehicle is offline");
  }
}

- (void)vehicleReporter:(GMTDVehicleReporter *)vehicleReporter
    didFailVehicleUpdate:(GMTDVehicleUpdate *)vehicleUpdate
               withError:(NSError *)error {
  NSString *bodyString =
      [NSString stringWithFormat:@"Vehicle State: %ld. Location: %@",
                                 (long)vehicleUpdate.vehicleState, vehicleUpdate.location];
  if (error) {
    bodyString =
        [NSString stringWithFormat:@"Error: %@. %@", error.localizedDescription, bodyString];
  }
  NSLog(@"Vehicle Reporter - Vehicle update failed:  %@", bodyString);
}

#pragma mark - GMSNavigatorListener

- (void)navigator:(GMSNavigator *)navigator didArriveAtWaypoint:(GMSNavigationWaypoint *)waypoint {
  NSLog(@"GMSNavigatorListener - didArriveAtWaypoint: Latitude %f, Longitude %f",
        waypoint.coordinate.latitude, waypoint.coordinate.longitude);
}

@end
