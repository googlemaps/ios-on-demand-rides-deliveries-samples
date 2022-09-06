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

#import <Foundation/Foundation.h>
#import <GoogleRidesharingConsumer/GoogleRidesharingConsumer.h>
#import "GRSCMapViewController+Protected.h"

/**
 * Completion handler type definition for the startLocationSelectionWithPickupLocation process.
 *
 * @param error The error that occurs when processing the response from the Location Selection API.
 * Will be nil if the request succeeds.
 */
typedef void (^GRSCStartLocationSelectionCompletionHandler)(NSError *_Nullable error);

/**
 * A category of GRSCMapViewController, used to handle location selection in bottom
 * panel, display location selection pickup point in base map view, and handle request/response of
 * the Location Selection API.
 */
@interface GRSCMapViewController (LocationSelection)

/** The pickup point provided by the Location Selection API. */
@property(nonatomic, strong, nullable) GMTSTerminalLocation *locationSelectionPickupPoint;

/** The marker used to represent the location selection pickup point. */
@property(nonatomic, strong, nullable) GMSMarker *locationSelectionPickupPointMarker;

/**
 * Starts all the location selection specific methods.
 *
 * @param pickupLocation The pickup location selected by the user.
 * @param completion The completion handler for the startLocationSelectionWithPickupLocation
 * process.
 */
- (void)startLocationSelectionWithPickupLocation:(nonnull GMTSTerminalLocation *)pickupLocation
                                      completion:
                                          (nonnull GRSCStartLocationSelectionCompletionHandler)
                                              completion;

@end
