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

#import <Foundation/Foundation.h>

#import <GoogleRidesharingDriver/GoogleRidesharingDriver.h>

NS_ASSUME_NONNULL_BEGIN

/** Sample provider supported trip states. */
FOUNDATION_EXTERN NSString *const GRSDProviderServiceTripStateNew;
FOUNDATION_EXTERN NSString *const GRSDProviderServiceTripStatusEnrouteToPickup;
FOUNDATION_EXTERN NSString *const GRSDProviderServiceTripStatusArrivedAtPickup;
FOUNDATION_EXTERN NSString *const GRSDProviderServiceTripStatusEnrouteToIntermediateDestination;
FOUNDATION_EXTERN NSString *const GRSDProviderServiceTripStatusArrivedAtIntermediateDestination;
FOUNDATION_EXTERN NSString *const GRSDProviderServiceTripStatusEnrouteToDropoff;
FOUNDATION_EXTERN NSString *const GRSDProviderServiceTripStatusComplete;

/** Enum that represents the possible trip types a vehicle can support. */
typedef NS_OPTIONS(NSUInteger, ProviderSupportedTripType) {
  ProviderSupportedTripTypeNone = 0,              // => 00000000
  ProviderSupportedTripTypeExclusive = (1 << 0),  // => 00000001
  ProviderSupportedTripTypeShared = (1 << 1)      // => 00000010
};

@class GRSDVehicleModel;

/**
 * An implementation of GRSAuthorization which provides authorization tokens for FleetEngine.
 */
@interface GRSDProviderService : NSObject <GMTDAuthorization>

/** Session used for NSURLSessionDataTask. Exposed for testing only. */
@property(nonatomic, strong, nullable) NSURLSession *session;

/**
 * Callback block definition of creating a vehicle.
 *
 * @param vehicleModel The model representing the created vehicle. It is nil if there's an error
 * creating a driver with the provider.
 * @param error Error when creating a driver with the provider. It is nil if creating a driver with
 * the provider succeeds.
 */
typedef void (^GRSDCreateVehicleWithIDHandler)(GRSDVehicleModel *_Nullable vehicleModel,
                                               NSError *_Nullable error);
/**
 * Callback block definition for fetching trip details.
 *
 * @param tripID The trip ID to fetch details for. It is nil if there's an error fetching trip
 * details from the provider.
 * @param tripStatus The trip status associated with the trip. It is nil if there's an error
 * fetching trip details from the provider.
 * @param waypoints The waypoints associated with the trip.
 * @param error Error when fetching trip details from the provider. It is nil if fetching trip
 * details from the provider succeeds.
 */
typedef void (^GRSDFetchTripHandler)(NSString *_Nullable tripID, NSString *_Nullable tripStatus,
                                     NSArray<GMTSTripWaypoint *> *_Nullable waypoints,
                                     NSError *_Nullable error);

/**
 * Callback block definition of updating a match.
 *
 * @param tripID The trip ID associated with the vehicle ID. It is nil if there's an error
 * updating a match with the provider, or if the returned result doesn't currently contain a trip
 * name.
 * @param error Error when updating a match from the provider. It is nil if updating a match with
 * the provider succeeds, or if the returned result doesn't currently contain a trip name.
 */
typedef void (^GRSDUpdateTripHandler)(NSString *_Nullable tripID, NSError *_Nullable error);

/**
 * Callback block definition for fetching a vehicle
 *
 * @param matchedTripIDs The list of matched trip IDs for this vehicle.
 * @param error Error when fetching a vehicle from the provider. It is nil if fetching a vehicle
 * succeeds.
 */
typedef void (^GRSDFetchVehicleHandler)(NSArray<NSString *> *_Nullable matchedTripIDs,
                                        NSError *_Nullable error);

/**
 * Creates a new vehicle with the provider.
 *
 * @param vehicleID The vehicle ID associated with the driver.
 * @param isBackToBackEnabled Whether the vehicle should be enabled for back-to-back trips.
 * @param completion The block executed when the request finishes.
 */
- (void)createVehicleWithID:(NSString *)vehicleID
        isBackToBackEnabled:(BOOL)isBackToBackEnabled
                 completion:(GRSDCreateVehicleWithIDHandler)completion;

/**
 * Fetches trip details for the given trip ID.
 *
 * @param tripID The ID for the trip to query.
 * @param completion The block executed when the request finishes.
 */
- (void)fetchTripWithID:(NSString *)tripID completion:(GRSDFetchTripHandler)completion;

/**
 * Fetches a vehicle for the given ID.
 *
 * @param vehicleID The ID of the vehicle to fetch
 * @param completion The block executed when the request finishes.
 */
- (void)fetchVehicleWithID:(NSString *)vehicleID completion:(GRSDFetchVehicleHandler)completion;

/**
 * Updates a trip to a new status.
 *
 * @param newTripStatus The new status for the trip.
 * @param tripID The trip ID associated with the driver.
 * @param intermediateDestinationIndex The index for the intermediate destination being updated.
 * It is nil if no intermediate destinations are being updated.
 * @param completion The block executed when the request finishes.
 */
- (void)updateTripWithStatus:(NSString *)newTripStatus
                          tripID:(NSString *)tripID
    intermediateDestinationIndex:(NSNumber *_Nullable)intermediateDestinationIndex
                      completion:(GRSDUpdateTripHandler)completion;

@end

NS_ASSUME_NONNULL_END
