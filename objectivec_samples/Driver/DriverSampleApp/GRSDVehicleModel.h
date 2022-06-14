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
#import "GRSDProviderService.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Class used to represent a vehicle model.
 */
@interface GRSDVehicleModel : NSObject

/** The ID of the vehicle. */
@property(nonatomic, readonly) NSString *vehicleID;

/** The maximum capacity of the vehicle. */
@property(nonatomic, readonly) NSUInteger maximumCapacity;

/** The supported trip types. */
@property(nonatomic, readonly) ProviderSupportedTripType supportedTripTypes;

/** Whether the vehicle is enabled for back to back trips. */
@property(nonatomic, readonly) BOOL isBackToBackEnabled;

/**
 * Initializes an instance of this class.
 *
 * @param vehicleID The ID of the vehicle.
 * @param maximumCapacity The maximum capacity of the vehicle.
 * @param supportedTripTypes The supported trip types.
 * @param isBackToBackEnabled Whether the vehicle is enabled for back to back trips.
 */
- (instancetype)initWithVehicleID:(NSString *)vehicleID
                  maximumCapacity:(NSUInteger)maximumCapacity
               supportedTripTypes:(ProviderSupportedTripType)supportedTripTypes
              isBackToBackEnabled:(BOOL)isBackToBackEnabled NS_DESIGNATED_INITIALIZER;

/** Use the designated initializer instead. */
- (null_unspecified instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
