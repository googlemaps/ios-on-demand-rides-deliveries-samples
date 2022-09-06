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

#import <GoogleRidesharingConsumer/GoogleRidesharingConsumer.h>
#import "GRSCBottomPanelView.h"
#import "GRSCMapViewController.h"
#import "GRSCWaypointSelector.h"

/**
 * A category header of GRSCMapViewController used to declare properties that are used between the
 * map view controller and its category.
 */
@interface GRSCMapViewController ()

/** The map view used as the base view. */
@property(nonatomic, nullable) GMTCMapView *mapView;

/** The panel view below map used to control state. */
@property(nonatomic, nullable) GRSCBottomPanelView *bottomPanel;

/** The marker used to represent the user-selected pickup point. */
@property(nonatomic, nullable) GMSMarker *pickupMarker;

/** The waypoint selector used for the pickup and drop off selection. */
@property(nonatomic, nullable) GRSCWaypointSelector *waypointSelector;

@end
