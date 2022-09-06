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
#import <UIKit/UIKit.h>
#import <GoogleRidesharingConsumer/GoogleRidesharingConsumer.h>

/**
 * Completion handler type definition for the getLocationSelectionPickupPointWithSearchLocation
 * process.
 *
 * @param locationSelectionPickupPointLatLng The latitude and longitude of the Location Selection
 * API pickup point.
 * @param locationSelectionWalkingDistance The walking distance between the Location Selection API
 * pickup point and the selected pickup location.
 * @param error The error that occurs when processing the response from the Location Selection API.
 * Will be nil if response succeeds.
 */
typedef void (^GRSCGetLocationSelectionPickupPointCompletionHandler)(
    GMTSLatLng *_Nullable locationSelectionPickupPointLatLng,
    NSNumber *_Nullable locationSelectionWalkingDistance, NSError *_Nullable error);

/**
 * Service used to interact with the location selection server.
 */
@interface GRSCLocationSelectionService : NSObject

/**
 * Gets a single location selection pickup point based on the lowest walking ETA from the response
 * of the Location Selection API.
 *
 * @param searchLocation The pickup location selected by user.
 * @param completion The block executed when a response from the provider is received.
 */
- (void)
    getLocationSelectionPickupPointWithSearchLocation:(nonnull GMTSTerminalLocation *)searchLocation
                                           completion:
                                               (nonnull
                                                    GRSCGetLocationSelectionPickupPointCompletionHandler)
                                                   completion;

/**
 * Initializes and returns a GRSCLocationSelectionService object using the provided NSURLSession for
 * network calls.
 *
 * @param session The Session used for NSURLSessionDataTask.
 */
- (nullable instancetype)initWithURLSession:(nonnull NSURLSession *)session
    NS_DESIGNATED_INITIALIZER;

@end
