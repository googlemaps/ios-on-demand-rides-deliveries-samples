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

#import <Foundation/Foundation.h>

#import <GoogleRidesharingConsumer/GoogleRidesharingConsumer.h>

/**
 * A class used to handle waypoint selection on a given mapView.
 */
@interface GRSCWaypointSelector : NSObject
/**
 * Initializes and returns a GRSCWaypointSelector object using the provided map view.
 *
 * @param mapView The map view used for drawing pickup points.
 */
- (nonnull instancetype)initWithMapView:(nonnull GMTCMapView *)mapView NS_DESIGNATED_INITIALIZER;

/**
 * Use @c initWithMapView instead.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/** @c GMTSTerminalLocation representing the selected pickup location. */
@property(nonatomic, strong, readonly, nullable) GMTSTerminalLocation *selectedPickupLocation;

/** @c GMTSTerminalLocation representing the selected drop off location. */
@property(nonatomic, strong, readonly, nullable) GMTSTerminalLocation *selectedDropoffLocation;

/**
 * An array of @c GMTSTerminalLocation objects representing the selected intermediate destinations.
 * Will be empty if no intermediate destinations were selected.
 */
@property(nonatomic, strong, readonly, nonnull)
    NSMutableArray<GMTSTerminalLocation *> *selectedIntermediateDestinations;

/** Starts the pickup selection state which adds the pickup marker to the map. */
- (void)startPickupSelection;

/** Stops the pickup selection state and removes the pickup marker from the map. */
- (void)stopPickupSelection;

/** Starts the drop off selection state which adds the drop off marker to the map. */
- (void)startDropoffSelection;

/** Stops the drop off selection state and removes the drop off marker from the map. */
- (void)stopDropoffSelection;

/** Adds an intermediate destination to the map. */
- (void)addIntermediateDestination;

@end
