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
#import "GRSDExpeditorViewController.h"

#import "GRSDBottomPanelView.h"

#import "GRSDProviderService.h"

static CGFloat const kDefaultViewAllTripPanelLineSpacing = 12.0f;
static CGFloat const kDefaultViewAllTripPanelTitleFontSize = 14.0f;
static CGFloat const kDefaultStrokeWidth = 2.0f;
static double const kSecondsinMinute = 60.0;
static int const kTripNumberOffset = 1;
static int32_t const kDefaultZIndex = 10;
static NSString *const kWaypointIntermediateImageName = @"WaypointIntermediate";
static NSString *const kWaypointPickUpImageName = @"WaypointPickUpLocation";
static NSTimeInterval const kDefaultVehiclePollingTimeInterval = 2;
NSString *const kEmptyString = @"";
NSString *const kVehicleImageName = @"Vehicle";
NSString *const kDefaultVehicleLocationPrefix = @"Location: ";
NSString *const kDefaultVehicleStatusPrefix = @"Status: ";
NSString *const kDefaultVehicleEtaPrefix = @"ETA: ";
NSString *const kDefaultVehicleEtaSuffix = @"mins";
NSString *const kDefaultEmptyStatus = @"Not currently on a trip";
NSString *const kDefaultEmptyEta = @"n/a";
NSString *const kTripStatusUnknown = @"Unknown";
NSString *const kTripStatusPickUp = @"Pick up";
NSString *const kTripStatusDropOff = @"Drop off";
NSString *const kTripStatusIntermediateDestination = @"Intermediate Destination";
NSString *const kDefaultBottomPanelActionButtonTitle = @"View All Trips";
NSString *const kDefaultViewFullTripActionButtonTitle = @"View Trip Summary";

static UIColor *ButtonEnabledColor(void) {
  return [UIColor colorWithRed:66 / 255.0 green:133 / 255.0 blue:244 / 255.0 alpha:1];
}

static NSAttributedString *GetViewAllTripsFormattedAttributedString(NSString *allTrips) {
  NSMutableAttributedString *allTripsAttributedString =
      [[NSMutableAttributedString alloc] initWithString:allTrips];
  NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
  [style setLineSpacing:kDefaultViewAllTripPanelLineSpacing];
  [style setLineBreakMode:NSLineBreakByTruncatingTail];
  [allTripsAttributedString addAttribute:NSParagraphStyleAttributeName
                                   value:style
                                   range:NSMakeRange(0, [allTrips length])];
  NSString *firstTrip = [allTrips componentsSeparatedByString:@"\n"][0];
  [allTripsAttributedString
      addAttribute:NSFontAttributeName
             value:[UIFont boldSystemFontOfSize:kDefaultViewAllTripPanelTitleFontSize]
             range:[allTrips rangeOfString:firstTrip]];
  return [allTripsAttributedString copy];
}

static NSString *GetVehicleIDFromVehicleName(NSString *vehicleName) {
  NSArray *vehicleNameStringComponents = [vehicleName componentsSeparatedByString:@"/"];
  NSString *vehicleID = [vehicleNameStringComponents lastObject];
  return vehicleID;
}

static NSString *GetTripStatusStringFromGMTSTripWaypointType(
    GMTSTripWaypointType tripWaypointType) {
  if (tripWaypointType == GMTSTripWaypointTypeUnknown) {
    return kTripStatusUnknown;
  } else if (tripWaypointType == GMTSTripWaypointTypePickUp) {
    return kTripStatusPickUp;
  } else if (tripWaypointType == GMTSTripWaypointTypeDropOff) {
    return kTripStatusDropOff;
  } else {
    return kTripStatusIntermediateDestination;
  }
}

static int DivideTwoIntsRoundingUp(int a, int b) { return (a + b - 1) / b; }

@implementation GRSDExpeditorViewController {
  CLLocationManager *_locationManager;
  GRSDProviderService *_providerService;
  GMSMapView *_mapView;
  GMTSVehicle *_tappedVehicle;
  NSArray<GMTSVehicle *> *_vehicles;
  NSMutableDictionary<NSString *, GMTSVehicle *> *_vehicleNameToVehicleDictionary;
  NSDictionary<NSString *, NSArray<GMTSTripWaypoint *> *> *_vehicleNameToWaypointsDictionary;
  NSDictionary<NSString *, NSNumber *> *_vehicleNameToFirstWaypointEtaDictionary;
  NSMutableDictionary<NSString *, GMSMarker *> *_vehicleNameToMarkersDictionary;
  NSMutableDictionary<NSString *, GMSPolyline *> *_vehicleNameToPolylinesDictionary;
  GRSDBottomPanelView *_bottomPanel;
  GRSDBottomPanelView *_viewAllTripsPanel;
  UIStackView *_contentStackView;
  NSString *_restaurantID;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Request for location permissions.
  _locationManager = [[CLLocationManager alloc] init];
  [_locationManager requestAlwaysAuthorization];
  _providerService = [[GRSDProviderService alloc] init];
  _vehicleNameToVehicleDictionary = [[NSMutableDictionary alloc] init];
  _vehicleNameToMarkersDictionary = [[NSMutableDictionary alloc] init];
  _vehicleNameToPolylinesDictionary = [[NSMutableDictionary alloc] init];
  _vehicleNameToWaypointsDictionary = [[NSDictionary alloc] init];
  _vehicleNameToFirstWaypointEtaDictionary = [[NSDictionary alloc] init];
  _restaurantID = kEmptyString;
  [self setUpContentStackView];
  [self setUpMapView];
  [self setUpBottomPanel];
  [self setUpViewAllTripsPanel];
  [self pollVehicles];
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
  _bottomPanel = [[GRSDBottomPanelView alloc] initWithTitle:kEmptyString
                                                buttonTitle:kDefaultBottomPanelActionButtonTitle
                                               buttonTarget:self
                                               buttonAction:@selector(didTapViewAllTripsButton:)];
  _bottomPanel.hidden = YES;
  _bottomPanel.locationLabel.hidden = NO;
  _bottomPanel.statusLabel.hidden = NO;
  _bottomPanel.etaLabel.hidden = NO;
  _bottomPanel.tripIDLabel.hidden = YES;
  _bottomPanel.actionButton.enabled = YES;
  _bottomPanel.actionButton.backgroundColor = ButtonEnabledColor();
  [_contentStackView addArrangedSubview:_bottomPanel];
}

- (void)setUpViewAllTripsPanel {
  _viewAllTripsPanel =
      [[GRSDBottomPanelView alloc] initWithTitle:kEmptyString
                                     buttonTitle:kDefaultViewFullTripActionButtonTitle
                                    buttonTarget:self
                                    buttonAction:@selector(didTapViewTripSummaryButton:)];
  _viewAllTripsPanel.hidden = YES;
  _viewAllTripsPanel.tripIDLabel.hidden = YES;
  _viewAllTripsPanel.titleLabel.numberOfLines = 0;
  _viewAllTripsPanel.actionButton.enabled = YES;
  _viewAllTripsPanel.actionButton.backgroundColor = ButtonEnabledColor();
  _viewAllTripsPanel.titleLabel.font =
      [UIFont systemFontOfSize:kDefaultViewAllTripPanelTitleFontSize];
  [_contentStackView addArrangedSubview:_viewAllTripsPanel];
}

- (void)pollVehicles {
  [NSTimer scheduledTimerWithTimeInterval:kDefaultVehiclePollingTimeInterval
                                   target:self
                                 selector:@selector(fetchVehicles)
                                 userInfo:nil
                                  repeats:YES];
}

- (void)fetchVehicles {
  [_providerService
      fetchVehiclesWithRestaurantID:_restaurantID
                         completion:^(NSArray<GMTSVehicle *> *_Nullable vehicles,
                                      NSDictionary<NSString *, NSArray<GMTSTripWaypoint *> *>
                                          *_Nullable vehicleNametoWaypointsDictionary,
                                      NSDictionary<NSString *, NSNumber *>
                                          *_Nullable vehicleNametoFirstWaypointEtaDictionary,
                                      NSError *_Nullable error) {
                           [self handleFetchVehiclesResponse:vehicles
                                      vehicleNametoWaypointsDictionary:
                                          vehicleNametoWaypointsDictionary
                               vehicleNametoFirstWaypointEtaDictionary:
                                   vehicleNametoFirstWaypointEtaDictionary
                                                                 error:error];
                         }];
}

/** Handles a response from a fetchVehicles provider request. */
- (void)handleFetchVehiclesResponse:(NSArray<GMTSVehicle *> *)vehicles
           vehicleNametoWaypointsDictionary:
               (NSDictionary<NSString *, NSArray<GMTSTripWaypoint *> *> *_Nullable)
                   vehicleNameToWaypointsDictionary
    vehicleNametoFirstWaypointEtaDictionary:
        (NSDictionary<NSString *, NSNumber *> *_Nullable)vehicleNameToFirstWaypointEtaDictionary
                                      error:(NSError *)error {
  if (error) {
    return;
  }
  _vehicles = vehicles;
  _vehicleNameToWaypointsDictionary = vehicleNameToWaypointsDictionary;
  _vehicleNameToFirstWaypointEtaDictionary = vehicleNameToFirstWaypointEtaDictionary;
  [self displayVehiclesWaypointsAndPolylines];
}

- (void)displayVehiclesWaypointsAndPolylines {
  for (GMTSVehicle *vehicle in _vehicles) {
    if (vehicle.currentTrips != nil && vehicle.currentTrips.count > 0) {
      NSString *tripID = vehicle.currentTrips[0];
      if (tripID != nil && tripID.length > 0) {
        [_providerService fetchTripWithID:tripID
                               completion:^(NSString *_Nullable tripID, GMTSTripStatus tripStatus,
                                            NSArray<GMTSTripWaypoint *> *_Nullable waypoints,
                                            NSMutableArray<GMTSLatLng *> *_Nullable routeList,
                                            NSError *_Nullable error) {
                                 if (error) {
                                   return;
                                 }
                                 [self drawVehicleMarkers:vehicle];
                                 if (routeList != nil) {
                                   [self drawTripPolylineWithRouteList:routeList
                                                            forVehicle:vehicle];
                                 }
                                 if (waypoints != nil && waypoints.count > 0) {
                                   GMTSTripWaypoint *waypoint = waypoints[0];
                                   [self drawWaypointMarkers:waypoint];
                                 }
                               }];
      }
    }
  }
}

- (void)drawTripPolylineWithRouteList:(NSMutableArray<GMTSLatLng *> *)routeList
                           forVehicle:(GMTSVehicle *)vehicle {
  GMSMutablePath *path = [GMSMutablePath path];
  for (GMTSLatLng *latlng in routeList) {
    [path addCoordinate:CLLocationCoordinate2DMake(latlng.latitude, latlng.longitude)];
  }
  GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
  polyline.geodesic = YES;
  polyline.strokeWidth = kDefaultStrokeWidth;
  polyline.strokeColor = [UIColor colorWithRed:44 / 255.0
                                         green:153 / 255.0
                                          blue:255 / 255.0
                                         alpha:1.0];
  polyline.zIndex = kDefaultZIndex;
  if ([_vehicleNameToPolylinesDictionary objectForKey:vehicle.vehicleName]) {
    GMSPolyline *previousPolyline =
        [_vehicleNameToPolylinesDictionary objectForKey:vehicle.vehicleName];
    [self deletePolylineMarkers:previousPolyline];
  }
  polyline.map = _mapView;
  [_vehicleNameToPolylinesDictionary setObject:polyline forKey:vehicle.vehicleName];
}

- (void)deletePolylineMarkers:(GMSPolyline *)polyline {
  polyline.map = nil;
}

- (void)drawVehicleMarkers:(GMTSVehicle *)vehicle {
  GMTSVehicleLocation *vehicleLocation = vehicle.lastLocation;
  CLLocationCoordinate2D vehiclePosition =
      CLLocationCoordinate2DMake(vehicleLocation.latLng.latitude, vehicleLocation.latLng.longitude);
  GMSMarker *vehicleMarker = [GMSMarker markerWithPosition:vehiclePosition];
  vehicleMarker.title = vehicle.vehicleName;
  vehicleMarker.icon = [UIImage imageNamed:kVehicleImageName];
  vehicleMarker.rotation = vehicleLocation.heading;
  [_vehicleNameToVehicleDictionary setObject:vehicle forKey:vehicle.vehicleName];
  if ([_vehicleNameToMarkersDictionary objectForKey:vehicle.vehicleName]) {
    GMSMarker *previousMarker = [_vehicleNameToMarkersDictionary objectForKey:vehicle.vehicleName];
    [self deleteVehicleMarkers:previousMarker];
  }
  vehicleMarker.map = _mapView;
  [_vehicleNameToMarkersDictionary setObject:vehicleMarker forKey:vehicle.vehicleName];
}

- (void)deleteVehicleMarkers:(GMSMarker *)vehicleMarker {
  vehicleMarker.map = nil;
}

/** Draws the current destination waypoint  */
- (void)drawWaypointMarkers:(GMTSTripWaypoint *)waypoint {
  GMTSTerminalLocation *waypointLocation = waypoint.location;
  CLLocationCoordinate2D waypointPosition =
      CLLocationCoordinate2DMake(waypointLocation.point.latitude, waypointLocation.point.longitude);
  GMSMarker *marker = [GMSMarker markerWithPosition:waypointPosition];
  if (waypoint.waypointType == GMTSTripWaypointTypePickUp) {
    marker.icon = [UIImage imageNamed:kWaypointPickUpImageName];
  } else if (waypoint.waypointType == GMTSTripWaypointTypeDropOff) {
    marker.icon = [GMSMarker markerImageWithColor:UIColor.redColor];
  } else if (waypoint.waypointType == GMTSTripWaypointTypeIntermediateDestination) {
    marker.icon = [UIImage imageNamed:kWaypointIntermediateImageName];
  }
  marker.map = _mapView;
}

- (void)didTapViewAllTripsButton:(UIButton *)sender {
  _bottomPanel.hidden = YES;
  _viewAllTripsPanel.hidden = NO;
}

- (void)didTapViewTripSummaryButton:(UIButton *)sender {
  _viewAllTripsPanel.hidden = YES;
  _bottomPanel.hidden = NO;
}

- (void)updateAndDisplayBottomPanel {
  NSString *vehicleID = GetVehicleIDFromVehicleName(_tappedVehicle.vehicleName);
  _bottomPanel.titleLabel.text = vehicleID;

  NSString *latitudeString =
      [NSString stringWithFormat:@"%f", _tappedVehicle.lastLocation.latLng.latitude];
  NSString *longitudeString =
      [NSString stringWithFormat:@"%f", _tappedVehicle.lastLocation.latLng.longitude];
  _bottomPanel.locationLabel.text = [NSString
      stringWithFormat:@"%@%@, %@", kDefaultVehicleLocationPrefix, latitudeString, longitudeString];

  NSArray<GMTSTripWaypoint *> *tripWaypoints =
      _vehicleNameToWaypointsDictionary[_tappedVehicle.vehicleName];
  if ([tripWaypoints count] > 0) {
    NSString *tripStatus =
        GetTripStatusStringFromGMTSTripWaypointType(tripWaypoints[0].waypointType);
    _bottomPanel.statusLabel.text =
        [NSString stringWithFormat:@"%@%@", kDefaultVehicleStatusPrefix, tripStatus];
  } else {
    _bottomPanel.statusLabel.text =
        [NSString stringWithFormat:@"%@%@", kDefaultVehicleStatusPrefix, kDefaultEmptyStatus];
  }

  NSNumber *firstWaypointEta = _vehicleNameToFirstWaypointEtaDictionary[_tappedVehicle.vehicleName];
  NSTimeInterval firstWaypointEtaInSeconds = [firstWaypointEta doubleValue];
  if (firstWaypointEtaInSeconds >= 0) {
    _bottomPanel.etaLabel.text = [NSString
        stringWithFormat:@"%@%d %@", kDefaultVehicleEtaPrefix,
                         DivideTwoIntsRoundingUp(firstWaypointEtaInSeconds, kSecondsinMinute),
                         kDefaultVehicleEtaSuffix];
  } else {
    _bottomPanel.etaLabel.text =
        [NSString stringWithFormat:@"%@%@", kDefaultVehicleEtaPrefix, kDefaultEmptyEta];
  }
  _viewAllTripsPanel.hidden = YES;
  _bottomPanel.hidden = NO;
}

- (void)updateViewFullTripPanel {
  NSArray<GMTSTripWaypoint *> *tripWaypoints =
      _vehicleNameToWaypointsDictionary[_tappedVehicle.vehicleName];
  NSMutableArray<NSString *> *allTrips = [[NSMutableArray alloc] init];
  for (GMTSTripWaypoint *tripWaypoint in tripWaypoints) {
    unsigned long tripNumber = [allTrips count] + kTripNumberOffset;
    NSString *tripType = GetTripStatusStringFromGMTSTripWaypointType(tripWaypoint.waypointType);
    [allTrips addObject:[NSString stringWithFormat:@"%lu. %@:\n %@\n", tripNumber, tripType,
                                                   tripWaypoint.tripID]];
  }
  NSString *allTripsString = [allTrips componentsJoinedByString:kEmptyString];
  _viewAllTripsPanel.titleLabel.attributedText =
      GetViewAllTripsFormattedAttributedString(allTripsString);
}

#pragma mark - GMSMapViewDelegate

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
  _tappedVehicle = _vehicleNameToVehicleDictionary[marker.title];
  if (_tappedVehicle != nil) {
    [self updateAndDisplayBottomPanel];
    [self updateViewFullTripPanel];
    return YES;
  }
  return NO;
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
  _bottomPanel.hidden = YES;
  _viewAllTripsPanel.hidden = YES;
}

#pragma mark - GMSRoadSnappedLocationProviderListener

- (void)locationProvider:(GMSRoadSnappedLocationProvider *)locationProvider
       didUpdateLocation:(CLLocation *)location {
  // Required protocol callback.
}

@end
