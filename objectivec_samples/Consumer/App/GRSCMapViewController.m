/*
 * Copyright 2021 Google LLC. All rights reserved.
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

#import "GRSCMapViewController.h"

#import <GoogleRidesharingConsumer/GoogleRidesharingConsumer.h>
#import "GRSCBottomPanelView.h"
#import "GRSCBottomPanelViewConstants.h"
#import "GRSCProviderService.h"
#import "GRSCStringUtils.h"
#import "GRSCStyle.h"
#import "GRSCUtils.h"
#import "GRSCWaypointSelector.h"

@interface GRSCMapViewController () <GMTCMapViewDelegate,
                                     GRSCBottomPanelDelegate,
                                     GMTCTripModelSubscriber>

@end

// Pickup selector image name.
static NSString *const kPickupSelectedImageName = @"grc_ic_pickup_selected";

// Intermediate destination point image name.
static NSString *const kIntermediateDestinationImageName = @"grc_ic_intermediate_destination_point";

// Default mapview camera location.
static CGFloat const kGMTSCDefaultCameraLatitude = 37.7749;
static CGFloat const kGMTSCDefaultCameraLongitude = -122.4194;

// Camera zoom level.
static CGFloat const kGMTSCDefaultZoomLevel = 13.0;

/** An enumeration of possible customer states for the mapview. */
typedef NS_ENUM(NSUInteger, GRSCMapViewCustomerState) {
  /** A state indicating that the mapview has not been initialized. */
  GRSCMapViewCustomerStateUninitialized,
  /** A state indicating that the mapview has been initialized. */
  GRSCMapViewCustomerStateInitialized,
  /** A state indicating that the customer is selecting their pickup location. */
  GRSCMapViewCustomerStateSelectingPickup,
  /** A state indicating that the customer is selecting their drop off location. */
  GRSCMapViewCustomerStateSelectingDropoff,
  /** A state indicating that the customer is previewing their trip. */
  GRSCMapViewCustomerStateTripPreview,
  /** A state indicating that the customer is ready to finalize and book their trip. */
  GRSCMapViewCustomerStateBooking,
  /** A state indicating that the customer is monitoring their on-going trip via Journey Sharing. */
  GRSCMapViewCustomerStateJourneySharing,
};

@implementation GRSCMapViewController {
  /** The map view that is used as the base view. */
  GMTCMapView *_mapView;
  /** Panel view below map used to control state. */
  GRSCBottomPanelView *_bottomPanel;
  /** Height constraint used for the bottomPanel. */
  NSLayoutConstraint *_bottomPanelHeightConstraint;
  /** Provider service used to manage trip operations. */
  GRSCProviderService *_providerService;
  /** The current state of the mapview. */
  GRSCMapViewCustomerState _mapViewCustomerState;
  /** The current GMTCJourneySharingSession.  */
  GMTCJourneySharingSession *_journeySharingSession;
  /** The name of the last trip that was created. */
  NSString *_lastTripName;
  /** The waypoint selector that will be used for pickup and drop off selection. */
  GRSCWaypointSelector *_waypointSelector;
  /** The time to arrival at the current waypoint. */
  NSTimeInterval _timeToWaypoint;
  /** The remaining distance in meters to the current waypoint.*/
  int32_t _remainingDistanceInMeters;
  /** The marker used to represent the pickup point.*/
  GMSMarker *_pickupMarker;
  /** The marker used to represent the drop off point. */
  GMSMarker *_dropoffMarker;
  /** The updated pickup location. */
  GMTSTerminalLocation *_updatedPickupLocation;
  /** The updated dropoff location. */
  GMTSTerminalLocation *_updatedDropoffLocation;
  /** Polyline used to display a path during trip preview. */
  GMSPolyline *_tripPreviewPolyline;
  /** Marker used to represent the dropoff point of a previous trip during a back-to-back case. */
  GMSMarker *_previousTripDropoffMarker;
  /** Whether the trip being booked is a shared trip. */
  BOOL _isTripShared;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  _mapView = [[GMTCMapView alloc] init];
  _mapView.delegate = self;
  _mapView.translatesAutoresizingMaskIntoConstraints = NO;

  [self.view addSubview:_mapView];
  [self setMapViewConstraints];

  _waypointSelector = [[GRSCWaypointSelector alloc] initWithMapView:_mapView];

  _bottomPanel = [[GRSCBottomPanelView alloc] init];
  _bottomPanel.delegate = self;
  _bottomPanel.translatesAutoresizingMaskIntoConstraints = NO;
  _bottomPanel.titleLabel.hidden = YES;
  [_bottomPanel.actionButton setTitle:GRSCBottomPanelRequestRideButtonText
                             forState:UIControlStateNormal];

  [self.view addSubview:_bottomPanel];
  [self setBottomPanelConstrains];
  _providerService = [[GRSCProviderService alloc] init];

  // Persist the mapview location to San Francisco.
  [self resetMapViewCamera];

  // Sets the style customization for the route polylines.
  [self setPolylineCustomization];

  GMTSLatLng *initialPickupPoint =
      [[GMTSLatLng alloc] initWithLatitude:kGMTSCDefaultCameraLatitude
                                 longitude:kGMTSCDefaultCameraLongitude];
  _updatedPickupLocation = GMTSTerminalLocationFromPoint(initialPickupPoint);
  _updatedDropoffLocation = GMTSTerminalLocationFromPoint(nil);
  _isTripShared = NO;
}

- (void)setMapViewConstraints {
  UIView *rootView = self.view;
  [_mapView.leftAnchor constraintEqualToAnchor:rootView.leftAnchor].active = YES;
  [_mapView.rightAnchor constraintEqualToAnchor:rootView.rightAnchor].active = YES;
  [_mapView.topAnchor constraintEqualToAnchor:rootView.topAnchor].active = YES;
}

/** Called when the mapview has been initialized. */
- (void)mapViewDidInitialize:(GMTCMapView *)mapview {
  _mapViewCustomerState = GRSCMapViewCustomerStateInitialized;
}

- (void)setBottomPanelConstrains {
  UIView *rootView = self.view;
  [_bottomPanel.leftAnchor constraintEqualToAnchor:rootView.leftAnchor].active = YES;
  [_bottomPanel.rightAnchor constraintEqualToAnchor:rootView.rightAnchor].active = YES;
  [_bottomPanel.bottomAnchor constraintEqualToAnchor:rootView.bottomAnchor].active = YES;
  [_bottomPanel.topAnchor constraintEqualToAnchor:_mapView.bottomAnchor].active = YES;
  _bottomPanelHeightConstraint =
      [NSLayoutConstraint constraintWithItem:_bottomPanel
                                   attribute:NSLayoutAttributeHeight
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:rootView
                                   attribute:NSLayoutAttributeHeight
                                  multiplier:.12
                                    constant:GRSCBottomPanelHeightSmall()];

  _bottomPanelHeightConstraint.active = YES;
}

- (void)setPolylineCustomization {
  GMTCConsumerMapStyleCoordinator *consumerMapStyleCoordinator =
      [_mapView consumerMapStyleCoordinator];

  GMTCMutablePolylineStyleOptions *mutablePolylineOptions =
      [[GMTCMutablePolylineStyleOptions alloc] init];

  // Enable traffic aware polylines and set custom colors for traffic.
  mutablePolylineOptions.isTrafficEnabled = YES;
  [mutablePolylineOptions setTrafficColorForSpeed:GMTSSpeedTypeNormal
                                            color:GRSCStyleTrafficPolylineSpeedTypeNormalColor()];
  [mutablePolylineOptions setTrafficColorForSpeed:GMTSSpeedTypeSlow
                                            color:GRSCStyleTrafficPolylineSpeedTypeSlowColor()];
  [mutablePolylineOptions setTrafficColorForSpeed:GMTSSpeedTypeTrafficJam
                                            color:GRSCStyleTrafficPolylineSpeedTypeJamColor()];
  [mutablePolylineOptions setTrafficColorForSpeed:GMTSSpeedTypeNoData
                                            color:GRSCStyleTrafficPolylineSpeedTypeNoDataColor()];

  [consumerMapStyleCoordinator setPolylineStyleOptions:mutablePolylineOptions
                                          polylineType:GMTCPolylineTypeActiveRoute];
}

/** Resets the mapview camera to the default location and zoom. */
- (void)resetMapViewCamera {
  GMSCameraPosition *cameraPosition =
      [GMSCameraPosition cameraWithLatitude:kGMTSCDefaultCameraLatitude
                                  longitude:kGMTSCDefaultCameraLongitude
                                       zoom:kGMTSCDefaultZoomLevel];
  [_mapView setCamera:cameraPosition];
}

/** Updates the bottom panel height constraint and animates the layout change. */
- (void)setBottomPanelHeight:(CGFloat)height
         animationCompletion:(void (^_Nullable)(BOOL finished))animationCompletion {
  if (_bottomPanelHeightConstraint.constant == height) {
    animationCompletion(YES);
    return;
  }

  [UIView animateWithDuration:0.30f
                   animations:^() {
                     _bottomPanelHeightConstraint.constant = height;
                     [self.view layoutIfNeeded];
                   }
                   completion:animationCompletion];
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
  GMTSLatLng *mapCenterLocation = [GMTSLatLng latLngFromCoordinate:_mapView.camera.target];
  switch (_mapViewCustomerState) {
    case GRSCMapViewCustomerStateSelectingPickup:
      _updatedPickupLocation = GMTSTerminalLocationFromPoint(mapCenterLocation);
      break;
    case GRSCMapViewCustomerStateSelectingDropoff:
      _updatedDropoffLocation = GMTSTerminalLocationFromPoint(mapCenterLocation);
      break;
    default:
      break;
  }
}

/** Displays pickup confirmation and selects default pickup location. */
- (void)startPickupSelection {
  NSAttributedString *pickupSelectionText = GRSCGetPartlyBoldAttributedString(
      GRSCBottomPanelSelectPickupLocationTitleText, GRSCBottomPanelPickupLocationText,
      _bottomPanel.titleLabel.font.pointSize);

  _bottomPanel.titleLabel.hidden = NO;
  [_bottomPanel.titleLabel setAttributedText:pickupSelectionText];
  [_bottomPanel.actionButton setTitle:GRSCBottomPanelConfirmPickupButtonText
                             forState:UIControlStateNormal];

  __weak __typeof(self) weakSelf = self;
  [self setBottomPanelHeight:GRSCBottomPanelHeightMedium()
         animationCompletion:^(BOOL finished) {
           [weakSelf startPickupSelectionInMapView];
         }];
}

/** Starts pickup selection state in mapview and selects default pickup location. */
- (void)startPickupSelectionInMapView {
  _mapViewCustomerState = GRSCMapViewCustomerStateSelectingPickup;
  [_waypointSelector startPickupSelection];
}

/** Displays drop-off confirmation and selects default drop-off location. */
- (void)startDropoffSelection {
  _mapViewCustomerState = GRSCMapViewCustomerStateSelectingDropoff;
  NSAttributedString *dropoffSelectionText = GRSCGetPartlyBoldAttributedString(
      GRSCBottomPanelSelectDropoffLocationTitleText, GRSCBottomPanelDropoffLocationText,
      _bottomPanel.titleLabel.font.pointSize);

  [_bottomPanel.titleLabel setAttributedText:dropoffSelectionText];
  [_bottomPanel.actionButton setTitle:GRSCBottomPanelConfirmDropoffButtonText
                             forState:UIControlStateNormal];
  _bottomPanel.addIntermediateDestinationButton.hidden = NO;

  [_waypointSelector stopPickupSelection];
  [_waypointSelector startDropoffSelection];
}

/** Displays trip confirmation view. */
- (void)startTripBooking {
  _bottomPanel.titleLabel.hidden = YES;
  _bottomPanel.addIntermediateDestinationButton.hidden = YES;
  _bottomPanel.actionButton.backgroundColor = UIColor.systemGreenColor;
  [_bottomPanel.actionButton setTitle:GRSCBottomPanelConfirmTripButtonText
                             forState:UIControlStateNormal];
  __weak __typeof(self) weakSelf = self;
  [self setBottomPanelHeight:GRSCBottomPanelHeightMedium()
         animationCompletion:^(BOOL finished) {
           [weakSelf startTripBookingInMapView];
         }];
}

/** Starts tripBooking state in mapview. */
- (void)startTripBookingInMapView {
  _mapViewCustomerState = GRSCMapViewCustomerStateBooking;
  [_waypointSelector stopDropoffSelection];

  if (!_waypointSelector.selectedPickupLocation || !_waypointSelector.selectedDropoffLocation) {
    return;
  }

  _bottomPanel.sharedTripTypeSwitchContainer.hidden = NO;

  CLLocationCoordinate2D pickupPosition =
      [_waypointSelector.selectedPickupLocation.point coordinate];
  _pickupMarker = [GMSMarker markerWithPosition:pickupPosition];
  _pickupMarker.icon = [UIImage imageNamed:kPickupSelectedImageName];
  _pickupMarker.map = _mapView;

  CLLocationCoordinate2D dropoffPosition =
      [_waypointSelector.selectedDropoffLocation.point coordinate];
  _dropoffMarker = [GMSMarker markerWithPosition:dropoffPosition];
  _dropoffMarker.icon = [GMSMarker markerImageWithColor:UIColor.redColor];
  _dropoffMarker.map = _mapView;

  [self drawTripPreviewPolyline];
  [self centerMapViewCamera];
}

/** Draws a preview polyline from pickup to dropoff. */
- (void)drawTripPreviewPolyline {
  GMTSLatLng *pickupLocation = _waypointSelector.selectedPickupLocation.point;
  GMTSLatLng *dropoffLocation = _waypointSelector.selectedDropoffLocation.point;
  if (!pickupLocation || !dropoffLocation) {
    return;
  }

  // Clear out existing polyline.
  [self removeTripPreviewPolyline];

  // Add a path from pickup -> intermediate destinations (if any) -> dropoff.
  // This is a straight line and not the actual route since it's only for preview.
  GMSMutablePath *path = [GMSMutablePath path];
  [path addCoordinate:[pickupLocation coordinate]];

  // Add any intermediate destinations.
  for (GMTSTerminalLocation *intermediateLocation in _waypointSelector
           .selectedIntermediateDestinations) {
    [path addCoordinate:[intermediateLocation.point coordinate]];
  }

  // Add final dropoff point.
  [path addCoordinate:[dropoffLocation coordinate]];

  // Add path to preview polyline and draw on current map.
  _tripPreviewPolyline = [GMSPolyline polylineWithPath:path];
  _tripPreviewPolyline.geodesic = YES;
  _tripPreviewPolyline.strokeWidth = 8.0;
  _tripPreviewPolyline.strokeColor = GRSCStyleDefaultPolylineStokeColor();
  _tripPreviewPolyline.map = _mapView;
}

/** Removes the trip preview polyline from the map. */
- (void)removeTripPreviewPolyline {
  _tripPreviewPolyline.map = nil;
  _tripPreviewPolyline = nil;
}

/** Centers the mapview camera around the key points(tripPreviewPolyline, pickup, dropoff). */
- (void)centerMapViewCamera {
  GMSCoordinateBounds *bounds;

  // If trip preview polyline is currently drawn, add to bounds.
  if (_tripPreviewPolyline) {
    bounds = [[GMSCoordinateBounds alloc] initWithPath:_tripPreviewPolyline.path];
  } else {
    bounds = [[GMSCoordinateBounds alloc] init];
  }

  // Add bounds for pickup and dropoff locations if they exist.
  if (_waypointSelector.selectedPickupLocation) {
    bounds = [bounds includingCoordinate:_waypointSelector.selectedPickupLocation.point.coordinate];
  }
  if (_waypointSelector.selectedIntermediateDestinations) {
    for (GMTSTerminalLocation *intermediateDestination in _waypointSelector
             .selectedIntermediateDestinations) {
      bounds = [bounds includingCoordinate:intermediateDestination.point.coordinate];
    }
  }
  if (_waypointSelector.selectedDropoffLocation) {
    bounds =
        [bounds includingCoordinate:_waypointSelector.selectedDropoffLocation.point.coordinate];
  }

  // Update camera if the bounds contains valid points.
  if ([bounds isValid]) {
    GMSCameraPosition *updatedCameraPosition =
        [_mapView cameraForBounds:bounds insets:GRSCStyleDefaulMapViewCameraPadding()];
    if (updatedCameraPosition) {
      _mapView.camera = updatedCameraPosition;
    }
  }
}

/** Books a new trip by creating it and updating the UI with trip status. */
- (void)bookNewTrip {
  [self createTrip];
}

/** Starts displaying the new trip. */
- (void)startNewTrip {
  __weak __typeof(self) weakSelf = self;
  [self setBottomPanelHeight:GRSCBottomPanelHeightMedium()
         animationCompletion:^(BOOL finished) {
           [weakSelf showNewTripPanel];
         }];
}

/** Updates the bottom panel to show the new trip. */
- (void)showNewTripPanel {
  _bottomPanel.titleLabel.hidden = NO;
  _bottomPanel.tripIDLabel.hidden = NO;
  _bottomPanel.titleLabel.text = GRSCBottomPanelWaitingForDriverMatchTitleText;
  _bottomPanel.sharedTripTypeSwitchContainer.hidden = YES;

  _bottomPanel.actionButton.backgroundColor = GRSCStyleDefaultButtonColor();
  [_bottomPanel.actionButton setTitle:GRSCBottomPanelCancelRideButtonText
                             forState:UIControlStateNormal];

  NSString *tripID = _journeySharingSession.tripModel.currentTrip.tripID;
  NSString *tripIDDisplayString = [NSString stringWithFormat:@"TripID: %@", tripID];
  _bottomPanel.tripIDLabel.text = tripIDDisplayString;
}

/**
 * Starts an in progress trip and sets the panel title to the given title.
 *
 * @param title A string that represents the title for the bottom panel.
 */
- (void)startInProgressTripWithTitle:(NSString *)title {
  __weak __typeof(self) weakSelf = self;
  [self setBottomPanelHeight:GRSCBottomPanelHeightLarge()
         animationCompletion:^(BOOL finished) {
           [weakSelf showTripDetailsPanel];
         }];
  _bottomPanel.titleLabel.text = title;
}

/** Updates the bottom panel to show the full details of a trip. */
- (void)showTripDetailsPanel {
  [_bottomPanel showAllLabels];
  _bottomPanel.actionButton.backgroundColor = GRSCStyleDefaultButtonColor();
  [_bottomPanel.actionButton setTitle:GRSCBottomPanelCancelRideButtonText
                             forState:UIControlStateNormal];

  NSString *tripID = _journeySharingSession.tripModel.currentTrip.tripID;
  NSString *tripIDDisplayString = [NSString stringWithFormat:@"Trip ID: %@", tripID];
  _bottomPanel.tripIDLabel.text = tripIDDisplayString;

  NSString *vehicleID = _journeySharingSession.tripModel.currentTrip.vehicleID;
  NSString *vehicleIDDisplayString = [NSString stringWithFormat:@"Vehicle ID: %@", vehicleID];
  _bottomPanel.vehicleIDLabel.text = vehicleIDDisplayString;
}

/** Updates the info label with the ETA information on the bottom panel. */
- (void)updateETA {
  if (_remainingDistanceInMeters >= 0 && _timeToWaypoint >= 0) {
    NSString *ETAString = GRSCGetETAFormattedString(_timeToWaypoint, _remainingDistanceInMeters);
    _bottomPanel.infoLabel.text = ETAString;
  }
}

/** Resets the bottom panel to the default state. */
- (void)resetPanelState {
  [_bottomPanel hideAllLabels];
  _bottomPanel.sharedTripTypeSwitchContainer.hidden = YES;
  __weak __typeof(self) weakSelf = self;
  [self setBottomPanelHeight:GRSCBottomPanelHeightSmall()
         animationCompletion:^(BOOL finished) {
           [weakSelf resetPanelUI];
         }];
}

/** Resets the bottom panel UI elements to their default state. */
- (void)resetPanelUI {
  _bottomPanel.actionButton.hidden = NO;
  _bottomPanel.actionButton.backgroundColor = GRSCStyleDefaultButtonColor();
  [_bottomPanel.actionButton setTitle:GRSCBottomPanelRequestRideButtonText
                             forState:UIControlStateNormal];
}

/** Creates a new trip and updates the mapview state on trip creation. */
- (void)createTrip {
  GMTSTerminalLocation *pickupLocation = _waypointSelector.selectedPickupLocation;
  GMTSTerminalLocation *dropoffLocation = _waypointSelector.selectedDropoffLocation;
  NSArray<GMTSTerminalLocation *> *intermediateDestinations =
      _waypointSelector.selectedIntermediateDestinations;

  [_providerService createTripWithPickup:pickupLocation
                intermediateDestinations:intermediateDestinations
                                 dropoff:dropoffLocation
                            isSharedTrip:_isTripShared
                              completion:^(NSString *_Nullable tripName, NSError *_Nullable error) {
                                if (!error) {
                                  [self setActiveTrip:tripName];
                                } else {
                                  NSLog(@"Failed to create trip with error:%@", error.description);
                                }
                              }];
}

/** Sets the active trip in the mapview. */
- (void)setActiveTrip:(NSString *)tripName {
  // Remove all markers from the map.
  // Consumer SDK will add relevant markers for the trip so we can remove preview markers.
  [_mapView clear];

  // Update local state.
  _mapViewCustomerState = GRSCMapViewCustomerStateJourneySharing;
  _lastTripName = [tripName copy];
  [self removeWaypointMarkers];
  [self removeTripPreviewPolyline];

  // Start Trip Model.
  GMTCTripModel *tripModel = [self currentTripModel];
  [tripModel registerSubscriber:self];

  // Start JourneySharing Session.
  _journeySharingSession = [[GMTCJourneySharingSession alloc] initWithTripModel:tripModel];
  [_mapView showMapViewSession:_journeySharingSession];
}

/** Returns TripModel from the last created trip. Will be nil if a trip is not available. */
- (nullable GMTCTripModel *)currentTripModel {
  if (!_lastTripName) {
    return nil;
  }
  GMTCTripService *tripService = [GMTCServices sharedServices].tripService;
  return [tripService tripModelForTripName:_lastTripName];
}

/** Called when the action button of the bottom panel is clicked. Determines action from state. */
- (void)bottomPanel:(nonnull GRSCBottomPanelView *)panel
    didTapActionButton:(nonnull UIButton *)button {
  _mapView.allowCameraAutoUpdate = YES;

  switch (_mapViewCustomerState) {
    case GRSCMapViewCustomerStateInitialized:
      [self startPickupSelection];
      break;
    case GRSCMapViewCustomerStateSelectingPickup:
      [self startDropoffSelection];
      break;
    case GRSCMapViewCustomerStateSelectingDropoff:
      [self startTripBooking];
      break;
    case GRSCMapViewCustomerStateBooking:
      [self bookNewTrip];
      break;
    case GRSCMapViewCustomerStateTripPreview:
    case GRSCMapViewCustomerStateUninitialized:
    case GRSCMapViewCustomerStateJourneySharing:
      [self endCurrentTrip];
      break;
  }
}

- (void)bottomPanel:(GRSCBottomPanelView *)panel
    didTapAddIntermediateDestinationButton:(UIButton *)button {
  [_waypointSelector addIntermediateDestination];
}

- (void)bottomPanel:(GRSCBottomPanelView *)panel
    didToggleSharedTripTypeSwitch:(UISwitch *)sharedTripTypeSwitch {
  _isTripShared = [sharedTripTypeSwitch isOn];
}

/** Ends the current controller from the trip model. */
- (void)stopCurrentTripModel {
  GMTCTripModel *tripModel = [self currentTripModel];
  [tripModel unregisterSubscriber:self];
}

/** Handles a trip with a completed state. */
- (void)handleTripCompletion {
  [_bottomPanel hideAllLabels];
  __weak __typeof(self) weakSelf = self;
  [self setBottomPanelHeight:GRSCBottomPanelHeightMedium()
         animationCompletion:^(BOOL finished) {
           [weakSelf showTripCompleteState];
           [weakSelf endCompletedTrip];
         }];
}

/** Ends monitoring a completed trip. */
- (void)endCompletedTrip {
  // End trip monitoring after 5 seconds. Will go back to the initial request ride screen.
  dispatch_after(  // go/dispatch-after-considered-harmful
      dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self endCurrentTrip];
      });
}

/** Updates the bottom panel to show the details of a completed trip. */
- (void)showTripCompleteState {
  _remainingDistanceInMeters = 0;
  _timeToWaypoint = 0;
  [self removeWaypointMarkers];
  [self updateETA];
  [self showTripDetailsPanel];
  _bottomPanel.actionButton.hidden = YES;
  _bottomPanel.titleLabel.text = GRSCBottomPanelTripCompleteTitleText;
}

/** Ends the current trip by resetting state and unregistering the current model. */
- (void)endCurrentTrip {
  if (_journeySharingSession) {
    [_mapView hideMapViewSession:_journeySharingSession];
  }
  [self stopCurrentTripModel];
  [self resetPanelState];
  [self removeWaypointMarkers];
  [self resetMapViewCamera];
  _lastTripName = nil;
  _journeySharingSession = nil;
  _isTripShared = NO;
}

/** Removes the pickup and drop off markers from the mapview. */
- (void)removeWaypointMarkers {
  _pickupMarker.map = nil;
  _dropoffMarker.map = nil;
  _pickupMarker = nil;
  _dropoffMarker = nil;
}

/** Removes the previous trip's dropoff marker from the mapview. */
- (void)removePreviousTripDropoffMarkerFromMap {
  _previousTripDropoffMarker.map = nil;
  _previousTripDropoffMarker = nil;
}

#pragma mark GMTCTripModelSubscriber

/** Called when the current trip status has been updated. */
- (void)tripModel:(GMTCTripModel *)tripModel didUpdateTripStatus:(enum GMTSTripStatus)tripStatus {
  switch (tripStatus) {
    case GMTSTripStatusComplete:
      [self handleTripCompletion];
      break;
    case GMTSTripStatusCanceled:
      [self endCurrentTrip];
      break;
    case GMTSTripStatusNew:
      [self startNewTrip];
      break;
    case GMTSTripStatusEnrouteToPickup:
      [self startInProgressTripWithTitle:GRSCBottomPanelEnrouteToPickupTitleText];
      [self removePreviousTripDropoffMarkerFromMap];
      break;
    case GMTSTripStatusArrivedAtPickup:
      [self startInProgressTripWithTitle:GRSCBottomPanelArrivedAtPickupTitleText];
      break;
    case GMTSTripStatusEnrouteToDropoff:
      [self startInProgressTripWithTitle:GRSCBottomPanelEnrouteToDropoffTitleText];
      break;
    case GMTSTripStatusArrivedAtIntermediateDestination:
      [self startInProgressTripWithTitle:GRSCBottomPanelArrivedAtIntermediateDestinationTitleText];
      break;
    case GMTSTripStatusEnrouteToIntermediateDestination:
      [self startInProgressTripWithTitle:GRSCBottomPanelEnrouteToIntermediateDestinationTitleText];
      break;
    case GMTSTripStatusUnknown:
      break;
  }
}

- (void)tripModel:(GMTCTripModel *)tripModel didFailUpdateTripWithError:(NSError *)error {
  NSLog(@"Failed to update trip with error: %@", error.description);
}

/** Called when the remaining distance to the current waypoint has been updated. */
- (void)tripModel:(GMTCTripModel *)tripModel
    didUpdateActiveRouteRemainingDistance:(int32_t)activeRouteRemainingDistance {
  _remainingDistanceInMeters = activeRouteRemainingDistance;
  [self updateETA];
}

/** Called when the ETA to the waypoint has been updated. */
- (void)tripModel:(GMTCTripModel *)tripModel
    didUpdateETAToNextWaypoint:(NSTimeInterval)nextWaypointETA {
  _timeToWaypoint = nextWaypointETA;
  [self updateETA];
}

/** Called when the current trip model state has been updated. */
- (void)tripModel:(GMTCTripModel *)tripModel
    didUpdateSessionState:(enum GMTCTripModelState)modelState {
  if (modelState == GMTCTripModelStateInactive) {
    [tripModel unregisterSubscriber:self];
  }
}

/**
 * Updates the panel to reflect assigned driver is finishing another trip
 * and displays a marker for previous trip dropoff.
 */
- (void)handleOtherTripWaypoint:(GMTSTripWaypoint *)waypoint {
  _bottomPanel.titleLabel.text = GRSCBottomPanelDriverCompletingAnotherTripTitleText;

  // Add new marker for previous trip waypoint.
  [self removePreviousTripDropoffMarkerFromMap];
  _previousTripDropoffMarker = [GMSMarker markerWithPosition:waypoint.location.point.coordinate];
  _previousTripDropoffMarker.map = _mapView;
  _previousTripDropoffMarker.icon = [UIImage imageNamed:kIntermediateDestinationImageName];
}

/** Called when the list of remaining waypoint has been updated. */
- (void)tripModel:(GMTCTripModel *)tripModel
    didUpdateRemainingWaypoints:(NSArray<GMTSTripWaypoint *> *)remainingWaypoints {
  if (!remainingWaypoints || !remainingWaypoints.count) return;
  GMTSTrip *currentTrip = tripModel.currentTrip;
  GMTSTripWaypoint *currentWaypoint = remainingWaypoints.firstObject;
  if (![currentWaypoint.tripID isEqualToString:currentTrip.tripID]) {
    [self handleOtherTripWaypoint:currentWaypoint];
  }
}

@end
