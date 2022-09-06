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

#import "GRSDVehicleModel.h"

@implementation GRSDVehicleModel

- (instancetype)initWithVehicleID:(NSString *)vehicleID
                     restaurantID:(NSString *_Nullable)restaurantID
                  maximumCapacity:(NSUInteger)maximumCapacity
               supportedTripTypes:(ProviderSupportedTripType)supportedTripTypes
              isBackToBackEnabled:(BOOL)isBackToBackEnabled {
  self = [super init];
  if (self) {
    _vehicleID = [vehicleID copy];
    _restaurantID = [restaurantID copy];
    _maximumCapacity = maximumCapacity;
    _supportedTripTypes = supportedTripTypes;
    _isBackToBackEnabled = isBackToBackEnabled;
  }
  return self;
}

- (BOOL)isEqual:(id)other {
  if (!other || ![other isKindOfClass:[GRSDVehicleModel class]]) {
    return NO;
  }
  if (self == other) {
    return YES;
  }

  GRSDVehicleModel *otherVehicleModel = (GRSDVehicleModel *)other;
  if (![otherVehicleModel.vehicleID isEqualToString:_vehicleID]) {
    return NO;
  }
  if ((otherVehicleModel.restaurantID != _restaurantID) &&
      ![otherVehicleModel.restaurantID isEqualToString:_restaurantID]) {
    return NO;
  }
  if (otherVehicleModel.supportedTripTypes != _supportedTripTypes) {
    return NO;
  }
  if (otherVehicleModel.maximumCapacity != _maximumCapacity) {
    return NO;
  }
  if (otherVehicleModel.isBackToBackEnabled != _isBackToBackEnabled) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  NSUInteger basePrime = 31;
  NSUInteger result =
      _isBackToBackEnabled ? 3721 : 3761;  // Use different values to represent the b2b states.
  result = (result * basePrime) + (self.vehicleID ? [self.vehicleID hash] : 0);
  result = (result * basePrime) + (self.restaurantID ? [self.restaurantID hash] : 0);
  result = (result * basePrime) + [@(self.maximumCapacity) hash];
  result = (result * basePrime) + [@(self.supportedTripTypes) hash];
  return result;
}

@end
