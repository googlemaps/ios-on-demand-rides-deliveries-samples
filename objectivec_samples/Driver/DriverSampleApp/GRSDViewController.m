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

/**
 * Whether to use simulated location for testing purposes. If NO, the real device location is used.
 * This should be set to NO before testing this app in the real world.
 */
static BOOL kIsSimulatingLocation = YES;
static NSString *kDefaultRestaurantID = @"";

/** Coordinates to be used for setting driver location when in simulator. */
static const CLLocationCoordinate2D kSanFranciscoCoordinates = {37.7749295, -122.4194155};

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
static const CGFloat kDefaultErrorMessageLabelAnimationAlpha = 0.0f;
static const CGFloat kDefaultErrorMessageSpacing = 8.0f;
static const CGFloat kDefaultErrorMessageCornerRadius = 8.0f;
static const float kDefaultErrorMessageLabelInitialAlpha = 1.0;
static const float kDefaultErrorMessageAutoFadeOutDuration = 10.0;

/** Returns a styled message label. */
static UILabel *CreateErrorMessageLabel(void) {
  UILabel *messageLabel = [[UILabel alloc] init];
  messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
  messageLabel.textColor = UIColor.redColor;
  messageLabel.backgroundColor = [UIColor whiteColor];
  messageLabel.numberOfLines = 0;
  messageLabel.textAlignment = NSTextAlignmentCenter;
  messageLabel.layer.cornerRadius = kDefaultErrorMessageCornerRadius;
  messageLabel.clipsToBounds = YES;
  messageLabel.hidden = YES;

  return messageLabel;
}

/**
 * Callback block definition of creating a driver.
 *
 * @param driverCreated Whether the driver was created.
 */
typedef void (^GRSDCreateDriverHandler)(BOOL driverCreated);

/**
 * Callback block definition of fetching a trip status.
 *
 * @param tripStatus The status of the trip.
 */
typedef void (^GRSDFetchTripStatusHandler)(GMTSTripStatus tripStatus);

// Constants for bottom panel trip status.
static NSString *const kTripIDLabel = @"Trip ID";
static NSString *const kMatchedTripsIDLabelText = @"Matched Trips";
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
static NSString *const kTripCompletePanelTitle = @"Trip completed";

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
static NSString *const kNavigationControllerTitle = @"Driver";
static NSString *const kVehicleIDPrefix = @"Vehicle ID: ";

@implementation GRSDViewController {
  CLLocationManager *_locationManager;
  /** View to hold the map and bottom panel views. */
  UIStackView *_contentStackView;
  /** The map view that is used as the base view. */
  GMSMapView *_mapView;
  /** Panel view used to control driver actions. */
  GRSDBottomPanelView *_bottomPanel;
  GRSDProviderService *_providerService;
  GMTDVehicleReporter *_vehicleReporter;
  NSTimer *_pollFetchVehicleTimer;
  BOOL _isFetchVehicleInProgress;
  NSArray<GMTSTripWaypoint *> *_waypoints;
  NSString *_currentTripID;
  GMTSTripStatus _currentTripStatus;
  BOOL _isVehicleOnline;
  GRSDVehicleModel *_currentVehicleModel;
  NSMutableDictionary<NSString *, NSNumber *> *_tripIDToCurrentIntermediateDestinationIndex;
  NSArray<NSString *> *_matchedTripIDs;
  BOOL _shouldAutoDrive;
  UILabel *_errorMessageLabel;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];

  // Request for location permissions.
  _locationManager = [[CLLocationManager alloc] init];
  [_locationManager requestAlwaysAuthorization];

  _providerService = [[GRSDProviderService alloc] init];

  _tripIDToCurrentIntermediateDestinationIndex = [[NSMutableDictionary alloc] init];
  _shouldAutoDrive = NO;

  [self setUpNavigationBar];
  [self setUpContentStackView];
  [self setUpMapView];
  [self showTermsAndConditionsAndSetUpDriver];
  _errorMessageLabel = CreateErrorMessageLabel();
  [self.view addSubview:_errorMessageLabel];
  [self anchorDisplayMessageLabel:_errorMessageLabel];
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

#pragma mark - Error message functions

- (void)displayAutoFadeOutErrorMessage:(NSString *)message {
  [self displayErrorMessage:message withDuration:kDefaultErrorMessageAutoFadeOutDuration];
}

// A duration of <=0 signifies a display of forever.
- (void)displayErrorMessage:(NSString *)message withDuration:(NSTimeInterval)duration {
  _errorMessageLabel.text = message;
  _errorMessageLabel.alpha = kDefaultErrorMessageLabelInitialAlpha;
  _errorMessageLabel.hidden = NO;
  if (duration > DBL_EPSILON) {
    [UIView animateWithDuration:duration
        animations:^{
          _errorMessageLabel.alpha = kDefaultErrorMessageLabelAnimationAlpha;
        }
        completion:^(BOOL finished) {
          _errorMessageLabel.hidden = YES;
        }];
  }
}

- (void)anchorDisplayMessageLabel:(UILabel *)label {
  [NSLayoutConstraint activateConstraints:@[
    [label.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    [label.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor
                                        constant:kDefaultErrorMessageSpacing],
    [label.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor
                                         constant:-kDefaultErrorMessageSpacing]
  ]];
}

#pragma mark - Private helpers

- (void)setUpNavigationBar {
  [self.navigationController.navigationBar setTitleTextAttributes:@{
    NSFontAttributeName : [UIFont systemFontOfSize:kDefaultFontSize],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  }];
  self.navigationController.navigationBar.barTintColor = DefaultNavigationBarColor();
  self.navigationController.navigationBar.translucent = NO;
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                           target:self
                           action:@selector(didTapNavigationBarButtonEditVehicle)];
}

- (void)didTapNavigationBarButtonEditVehicle {
  if (_currentVehicleModel) {
    GRSDEditVehicleTableViewController *editVehicleController =
        [[GRSDEditVehicleTableViewController alloc] initWithVehicleModel:_currentVehicleModel];
    editVehicleController.delegate = self;
    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:editVehicleController];
    [self presentViewController:navigationController animated:YES completion:nil];
  } else {
    NSLog(@"Error: Vehicle must be created before editing.");
  }
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

  // Bottom panel that shows the current trip ID and a button to update the current trip status.
  _bottomPanel =
      [[GRSDBottomPanelView alloc] initWithTitle:kNewTripPanelTitle
                                     buttonTitle:kNewTripButtonTitle
                                    buttonTarget:self
                                    buttonAction:@selector(didTapUpdateTripStatusButton:)];
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
  if (kIsSimulatingLocation) {
    // Simulate the driver location at a fixed coordinate for testing purposes.
    [_mapView.locationSimulator simulateLocationAtCoordinate:kSanFranciscoCoordinates];
  }

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
             restaurantID:kDefaultRestaurantID
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

  if (!vehicleModel || vehicleModel.vehicleID.length == 0) {
    completion(NO);
    return;
  }
  _currentVehicleModel = vehicleModel;

  self.title =
      [NSString stringWithFormat:@"%@%@", kVehicleIDPrefix, _currentVehicleModel.vehicleID];
  self.navigationController.title = kNavigationControllerTitle;

  // Set up Driver SDK.
  GRSDProviderService *providerService = _providerService;
  if (!providerService) {
    completion(NO);
    return;
  }

  GMTDDriverContext *driverContext =
      [[GMTDDriverContext alloc] initWithAccessTokenProvider:providerService
                                                  providerID:kProviderID
                                                   vehicleID:_currentVehicleModel.vehicleID
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

- (void)updateVehicleWithModel:(GRSDVehicleModel *)vehicleModel {
  [_providerService
      updateVehicleWithModel:vehicleModel
                  completion:^(GRSDVehicleModel *_Nullable vehicleModel, NSError *_Nullable error) {
                    if (error) {
                      [self displayAutoFadeOutErrorMessage:
                                [NSString
                                    stringWithFormat:
                                        @"Error: Update Vehicle Model failed: Vehicle Model: %@. ",
                                        error.localizedDescription]];
                      return;
                    }
                    _currentVehicleModel = vehicleModel;
                  }];
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

  _isFetchVehicleInProgress = YES;

  __weak typeof(self) weakSelf = self;
  [_providerService fetchVehicleWithID:_currentVehicleModel.vehicleID
                            completion:^(NSArray<NSString *> *_Nullable matchedTripIds,
                                         NSArray<GMTSTripWaypoint *> *_Nullable waypoints,
                                         NSError *_Nullable error) {
                              [weakSelf handleFetchVehicleResponseWithMatchedTripIds:matchedTripIds
                                                                           waypoints:waypoints
                                                                               error:error];
                            }];
};

/* Handles a response from a fetchVehicle provider request. */
- (void)handleFetchVehicleResponseWithMatchedTripIds:(NSArray<NSString *> *)matchedTripIDs
                                           waypoints:(NSArray<GMTSTripWaypoint *> *)waypoints
                                               error:(NSError *)error {
  _isFetchVehicleInProgress = NO;
  if (error || !matchedTripIDs || !matchedTripIDs.count || !waypoints.count) {
    _matchedTripIDs = nil;
    _waypoints = nil;
    return;
  }

  GMTSTripWaypoint *firstWaypoint = waypoints[0];
  if (![_waypoints[0] isEqual:firstWaypoint]) {
    _waypoints = waypoints;
    [self stopNavigation];
    [self setNextWaypointAsTheDestination];
  }

  if (![_currentTripID isEqualToString:firstWaypoint.tripID]) {
    _currentTripID = firstWaypoint.tripID;
    __weak typeof(self) weakSelf = self;
    [self fetchStatusForCurrentTripWithCompletion:^(GMTSTripStatus tripStatus) {
      typeof(self) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      if (tripStatus != GMTSTripStatusUnknown) {
        _currentTripStatus = tripStatus;
        if (_currentTripStatus == GMTSTripStatusNew) {
          // Guard against action button being clicked before destination is reached for SHARED
          // pool.
          [self stopNavigation];
          strongSelf->_shouldAutoDrive = NO;
        } else if (_currentTripStatus == GMTSTripStatusEnrouteToDropoff) {
          strongSelf->_shouldAutoDrive = YES;
        }
        [strongSelf updateViewsForCurrentTripStatus];
      }
    }];
  }

  // Update bottom panel if other trips are assigned to this vehicle.
  _matchedTripIDs = matchedTripIDs;
  if (matchedTripIDs.count > 1) {
    NSString *matchedTripsDisplayText = [matchedTripIDs componentsJoinedByString:@"\n"];
    _bottomPanel.nextTripIDLabel.text =
        [NSString stringWithFormat:@"%@: %@", kMatchedTripsIDLabelText, matchedTripsDisplayText];
    _bottomPanel.nextTripIDLabel.hidden = NO;
  } else {
    _bottomPanel.nextTripIDLabel.hidden = YES;
  }
}

/** Fetches the latest status for the current trip. */
- (void)fetchStatusForCurrentTripWithCompletion:(GRSDFetchTripStatusHandler)completion {
  __weak typeof(self) weakSelf = self;
  [_providerService
      fetchTripWithID:_currentTripID
           completion:^(NSString *_Nullable tripID, GMTSTripStatus tripStatus,
                        NSArray<GMTSTripWaypoint *> *_Nullable waypoints,
                        NSMutableArray<GMTSLatLng *> *_Nullable routeList,
                        NSError *_Nullable error) {
             typeof(self) strongSelf = weakSelf;
             if (!strongSelf) {
               return;
             }
             if (error) {
               NSLog(@"Failed to get trip details with error: %@", error);
               completion(GMTSTripStatusUnknown);
               return;
             }

             // Process intermediate destinations if trip has them and has not been seen before.
             if (![strongSelf->_tripIDToCurrentIntermediateDestinationIndex objectForKey:tripID] &&
                 waypoints.count > 2) {
               [strongSelf->_tripIDToCurrentIntermediateDestinationIndex
                   setObject:[NSNumber numberWithInt:0]
                      forKey:tripID];
             }
             completion(tripStatus);
           }];
}

/** Updates the UI to reflect a trip with status NEW. */
- (void)displayNewTripStatus {
  _bottomPanel.titleLabel.text = kNewTripPanelTitle;
  [_bottomPanel.actionButton setTitle:kNewTripButtonTitle forState:UIControlStateNormal];
  [self setNextWaypointAsTheDestination];
}

/** Updates the UI to reflect a trip with status ENROUTE_TO_PICKUP. */
- (void)displayEnrouteToPickupStatus {
  _bottomPanel.titleLabel.text = kEnrouteToPickupPanelTitle;
  [_bottomPanel.actionButton setTitle:kEnrouteToPickupButtonTitle forState:UIControlStateNormal];
}

/** Updates the UI to reflect a trip with status ARRIVED_AT_PICKUP. */
- (void)displayArrivedAtPickupStatus {
  _bottomPanel.titleLabel.text = kArrivedAtPickupPanelTitle;
  GMTSTripStatus nextTripStatus = [self nextStatusForCurrentTrip];
  NSString *actionButtonTitle = nextTripStatus == GMTSTripStatusEnrouteToIntermediateDestination
                                    ? kDriveToIntermediateStopButtonTitle
                                    : kDriveToDropoffButtonTitle;
  [_bottomPanel.actionButton setTitle:actionButtonTitle forState:UIControlStateNormal];
}

/** Updates the UI to reflect a trip with status ENROUTE_TO_INTERMEDIATE_DESTINATION. */
- (void)displayEnrouteToIntermediateDestinationStatus {
  _bottomPanel.titleLabel.text = kEnrouteToIntermediateDestinationPanelTitle;
  [_bottomPanel.actionButton setTitle:kEnrouteToIntermediateDestinationButtonTitle
                             forState:UIControlStateNormal];
}

/** Updates the UI to reflect a trip with status ARRIVED_AT_INTERMEDIATE_DESTINATION. */
- (void)displayArrivedIntermediateDestinationStatus {
  _bottomPanel.titleLabel.text = kArrivedAtIntermediateDestinationPanelTitle;
  GMTSTripStatus nextTripStatus = [self nextStatusForCurrentTrip];
  NSString *actionButtonTitle = nextTripStatus == GMTSTripStatusEnrouteToIntermediateDestination
                                    ? kDriveToIntermediateStopButtonTitle
                                    : kDriveToDropoffButtonTitle;
  [_bottomPanel.actionButton setTitle:actionButtonTitle forState:UIControlStateNormal];
}

/** Updates the UI to reflect a trip with status ENROUTE_TO_DROPOFF. */
- (void)displayEnrouteToDropoffStatus {
  _bottomPanel.titleLabel.text = kEnrouteToDropoffPanelTitle;
  [_bottomPanel.actionButton setTitle:kEnrouteToDropoffButtonTitle forState:UIControlStateNormal];
}

/** Updates the UI to reflect a trip with status COMPLETE. */
- (void)displayTripCompleteStatus {
  _bottomPanel.titleLabel.text = kTripCompletePanelTitle;
  _bottomPanel.actionButton.hidden = YES;
}

/** Updates the UI to reflect the current trip status. */
- (void)updateViewsForCurrentTripStatus {
  if (_bottomPanel) {
    _bottomPanel.hidden = NO;
    _bottomPanel.actionButton.hidden = NO;
  } else {
    [self setUpBottomPanel];
  }
  _bottomPanel.tripIDLabel.text =
      [NSString stringWithFormat:@"%@: %@", kTripIDLabel, _currentTripID];

  switch (_currentTripStatus) {
    case GMTSTripStatusNew:
      [self displayNewTripStatus];
      break;
    case GMTSTripStatusEnrouteToPickup:
      [self displayEnrouteToPickupStatus];
      break;
    case GMTSTripStatusArrivedAtPickup:
      [self displayArrivedAtPickupStatus];
      break;
    case GMTSTripStatusEnrouteToIntermediateDestination:
      [self displayEnrouteToIntermediateDestinationStatus];
      break;
    case GMTSTripStatusArrivedAtIntermediateDestination:
      [self displayArrivedIntermediateDestinationStatus];
      break;
    case GMTSTripStatusEnrouteToDropoff:
      [self displayEnrouteToDropoffStatus];
      break;
    case GMTSTripStatusComplete:
      [self displayTripCompleteStatus];
      break;
    case GMTSTripStatusUnknown:
    case GMTSTripStatusCanceled:
      break;
  }
}

/** Returns the next status for the current trip. */
- (GMTSTripStatus)nextStatusForCurrentTrip {
  GMTSTripWaypoint *nextWaypoint = [self nextWaypointForCurrentTrip];
  switch (_currentTripStatus) {
    case GMTSTripStatusNew:
      return GMTSTripStatusEnrouteToPickup;
    case GMTSTripStatusEnrouteToPickup:
      return GMTSTripStatusArrivedAtPickup;
    case GMTSTripStatusArrivedAtPickup:
      return (nextWaypoint &&
              nextWaypoint.waypointType == GMTSTripWaypointTypeIntermediateDestination)
                 ? GMTSTripStatusEnrouteToIntermediateDestination
                 : GMTSTripStatusEnrouteToDropoff;
    case GMTSTripStatusEnrouteToIntermediateDestination:
      return GMTSTripStatusArrivedAtIntermediateDestination;
    case GMTSTripStatusArrivedAtIntermediateDestination:
      return (nextWaypoint &&
              nextWaypoint.waypointType == GMTSTripWaypointTypeIntermediateDestination)
                 ? GMTSTripStatusEnrouteToIntermediateDestination
                 : GMTSTripStatusEnrouteToDropoff;
    case GMTSTripStatusEnrouteToDropoff:
    case GMTSTripStatusComplete:
      return GMTSTripStatusComplete;
    case GMTSTripStatusCanceled:
      return GMTSTripStatusCanceled;
    case GMTSTripStatusUnknown:
      return GMTSTripStatusUnknown;
  }
}

/** Returns the next waypoint for the current trip. */
- (GMTSTripWaypoint *)nextWaypointForCurrentTrip {
  BOOL foundFirstWaypoint = NO;
  for (GMTSTripWaypoint *tripWaypoint in _waypoints) {
    if ([_currentTripID isEqualToString:tripWaypoint.tripID]) {
      if (foundFirstWaypoint) {
        return tripWaypoint;
      }
      foundFirstWaypoint = YES;
    }
  }
  return nil;
}

/** Sets the next navigation destination to the first available waypoint. */
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

- (void)handleSetDestinationsResponseWithRouteStatus:(GMSRouteStatus)routeStatus {
  if (routeStatus == GMSRouteStatusOK) {
    // Enable the trip status button once the route is generated.
    _bottomPanel.actionButton.enabled = YES;
    _bottomPanel.actionButton.backgroundColor = ButtonEnabledColor();
    if (_shouldAutoDrive) {
      [self startNavigation];
    }
  } else {
    NSString *errorMessage =
        [NSString stringWithFormat:@"Error generating route - Route Status: %ld. ", routeStatus];
    if (routeStatus != GMSRouteStatusCanceled) {
      [self displayAutoFadeOutErrorMessage:errorMessage];
    }
    NSLog(@"%@", errorMessage);
  }
}

- (void)updateTripWithStatus:(GMTSTripStatus)newStatus
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

- (void)stopNavigation {
  if (kIsSimulatingLocation) {
    _mapView.locationSimulator.paused = YES;
  }
  [_mapView.navigator clearDestinations];
}

- (void)handleUpdateTripResponseWithStatus:(GMTSTripStatus)newStatus
                                    tripID:(NSString *)tripID
                                     error:(NSError *)error {
  if (error) {
    [self displayAutoFadeOutErrorMessage:[NSString
                                             stringWithFormat:@"Handle Update Trip Response With "
                                                              @"Status - Update Failed:  Error: %@",
                                                              error.localizedDescription]];
    return;
  }

  if (![tripID isEqual:_currentTripID]) {
    return;
  }

  _currentTripStatus = newStatus;
  if (_currentTripStatus == GMTSTripStatusComplete) {
    [self stopNavigation];
    // Note: This timer is optional and it's used in this app for demonstration purposes.
    [NSTimer scheduledTimerWithTimeInterval:5
                                     target:self
                                   selector:@selector(endCurrentVehicleSession)
                                   userInfo:nil
                                    repeats:NO];
  }
  [self updateViewsForCurrentTripStatus];
}

- (void)endCurrentVehicleSession {
  if (_matchedTripIDs.count) {
    return;
  }

  _currentTripID = nil;

  // Hide bottom panel while driver waits for a new trip.
  _bottomPanel.hidden = YES;
}

- (void)startNavigation {
  // Start turn-by-turn guidance along the current route.
  _mapView.navigator.guidanceActive = YES;
  _mapView.navigator.sendsBackgroundNotifications = YES;
  _mapView.cameraMode = GMSNavigationCameraModeFollowing;

  if (kIsSimulatingLocation) {
    // Simulate vehicle progress along the route for testing purposes.
    if (_mapView.locationSimulator.isPaused) {
      _mapView.locationSimulator.paused = NO;
    }
    [_mapView.locationSimulator simulateLocationsAlongExistingRoute];
  }
}

- (nullable NSNumber *)processIntermediateDestinationIndexForStatus:(GMTSTripStatus)status {
  NSNumber *intermediateDestinationIndex = nil;
  if (status == GMTSTripStatusEnrouteToIntermediateDestination) {
    intermediateDestinationIndex = _tripIDToCurrentIntermediateDestinationIndex[_currentTripID];
  } else if (status == GMTSTripStatusArrivedAtIntermediateDestination) {
    NSNumber *currentIndex = _tripIDToCurrentIntermediateDestinationIndex[_currentTripID];
    _tripIDToCurrentIntermediateDestinationIndex[_currentTripID] =
        [NSNumber numberWithInt:[currentIndex intValue] + 1];
  }
  return intermediateDestinationIndex;
}

- (void)didTapUpdateTripStatusButton:(UIButton *)sender {
  GMTSTripStatus nextTripStatus = [self nextStatusForCurrentTrip];
  _shouldAutoDrive = NO;

  if (nextTripStatus == GMTSTripStatusEnrouteToIntermediateDestination ||
      nextTripStatus == GMTSTripStatusEnrouteToDropoff) {
    [_mapView.navigator clearDestinations];
    _shouldAutoDrive = YES;
    _bottomPanel.actionButton.enabled = NO;
    _bottomPanel.actionButton.backgroundColor = UIColor.grayColor;
  } else if (nextTripStatus == GMTSTripStatusEnrouteToPickup ||
             nextTripStatus == GMTSTripStatusEnrouteToIntermediateDestination) {
    [self startNavigation];
  }

  NSNumber *intermediateDestinationIndex =
      [self processIntermediateDestinationIndexForStatus:nextTripStatus];
  [self updateTripWithStatus:nextTripStatus
      intermediateDestinationIndex:intermediateDestinationIndex];
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
  NSString *headerString = @"Vehicle Reporter - Vehicle update failed. Error: ";
  NSString *bodyString = error.localizedDescription;
  if (@available(iOS 14.5, *)) {
    for (NSError *underlyingError in error.underlyingErrors) {
      bodyString =
          [bodyString stringByAppendingFormat:@" %@", underlyingError.localizedDescription];
    }
  }
  [self displayAutoFadeOutErrorMessage:[NSString stringWithFormat:@"%@%@", headerString, bodyString]];
  NSLog(@"%@%@", headerString, bodyString);
}

#pragma mark - GMSNavigatorListener

- (void)navigator:(GMSNavigator *)navigator didArriveAtWaypoint:(GMSNavigationWaypoint *)waypoint {
  NSLog(@"GMSNavigatorListener - didArriveAtWaypoint: Latitude %f, Longitude %f",
        waypoint.coordinate.latitude, waypoint.coordinate.longitude);
}

#pragma mark - GRSDEditVehicleTableViewControllerDelegate

- (void)editVehicleTableViewController:(GRSDEditVehicleTableViewController *)controller
                didChangeVehicleFields:(GRSDVehicleModel *)vehicleModel {
  [self updateVehicleWithModel:vehicleModel];
}

@end
