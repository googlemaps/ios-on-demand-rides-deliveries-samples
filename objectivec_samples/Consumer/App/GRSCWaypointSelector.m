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

#import "GRSCWaypointSelector.h"

#import "GRSCUtils.h"

// Waiting for pickup selector image name.
static NSString *const kWaitingForPickupImageName = @"grc_ic_wait_pickup_marker";

// Intermediate destination point image name.
static NSString *const kIntermediateDestinationImageName = @"grc_ic_intermediate_destination_point";

@implementation GRSCWaypointSelector {
  /** The map view that is used to display waypoints. */
  GMTCMapView *_mapView;
  /** The view representing the pickup selector. */
  UIImageView *_pickupSelectorView;
  /** The view represening the dropoff selector. */
  UIImageView *_dropoffSelectorView;
}

- (instancetype)initWithMapView:(GMTCMapView *)mapView {
  self = [super init];
  if (self) {
    _mapView = mapView;
    _selectedIntermediateDestinations = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)startPickupSelection {
  if (!_pickupSelectorView) {
    UIImage *image = [UIImage imageNamed:kWaitingForPickupImageName];
    _pickupSelectorView = [[UIImageView alloc] initWithImage:image];
    _pickupSelectorView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  [_mapView addSubview:_pickupSelectorView];
  [_pickupSelectorView.bottomAnchor constraintEqualToAnchor:_mapView.centerYAnchor].active = YES;
  [_pickupSelectorView.centerXAnchor constraintEqualToAnchor:_mapView.centerXAnchor].active = YES;
}

- (void)stopPickupSelection {
  GMTSLatLng *mapCenterLocation = [GMTSLatLng latLngFromCoordinate:_mapView.camera.target];
  GMTSTerminalLocation *pickupLocation = GMTSTerminalLocationFromPoint(mapCenterLocation);
  _selectedPickupLocation = pickupLocation;
  [_pickupSelectorView removeFromSuperview];
}

- (void)startDropoffSelection {
  if (!_dropoffSelectorView) {
    UIImage *image = [GMSMarker markerImageWithColor:UIColor.redColor];
    _dropoffSelectorView = [[UIImageView alloc] initWithImage:image];
  }
  [_mapView addSubview:_dropoffSelectorView];
  _dropoffSelectorView.translatesAutoresizingMaskIntoConstraints = NO;
  [_dropoffSelectorView.bottomAnchor constraintEqualToAnchor:_mapView.centerYAnchor].active = YES;
  [_dropoffSelectorView.centerXAnchor constraintEqualToAnchor:_mapView.centerXAnchor].active = YES;
}

- (void)stopDropoffSelection {
  GMTSLatLng *mapCenterLocation = [GMTSLatLng latLngFromCoordinate:_mapView.camera.target];
  GMTSTerminalLocation *dropoffLocation = GMTSTerminalLocationFromPoint(mapCenterLocation);
  _selectedDropoffLocation = dropoffLocation;
  [_dropoffSelectorView removeFromSuperview];
}

- (void)addIntermediateDestination {
  GMTSLatLng *mapCenterLocation = [GMTSLatLng latLngFromCoordinate:_mapView.camera.target];
  GMTSTerminalLocation *intermediateDestinationLocation =
      GMTSTerminalLocationFromPoint(mapCenterLocation);
  [_selectedIntermediateDestinations addObject:intermediateDestinationLocation];

  // Add marker for intermediate destination.
  GMSMarker *marker = [[GMSMarker alloc] init];
  marker.icon = [UIImage imageNamed:kIntermediateDestinationImageName];
  marker.position = [intermediateDestinationLocation.point coordinate];
  marker.map = _mapView;
}

@end
