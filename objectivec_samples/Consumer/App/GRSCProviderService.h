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

#import <UIKit/UIKit.h>

#import <GoogleRidesharingConsumer/GoogleRidesharingConsumer.h>

/**
 * Completion handler type definition for the createTripWithPickup process.
 *
 * @param tripName The trip name for the created trip. Will be nil if trip failed to be created.
 * @param error The error that occurs when processing the response from the provider. Will be nil if
 * trip creation succeeds.
 */
typedef void (^GRSCCreateTripCompletionHandler)(NSString *_Nullable tripName,
                                                NSError *_Nullable error);

/**
 * Completion handler type definition for the cancelTripWithTripID process.
 *
 * @param error The error that occurs when processing the response from the provider. Will be nil if
 * trip cancellation succeeds.
 */
typedef void (^GRSCCancelTripCompletionHandler)(NSError *_Nullable error);

/**
 * Service used to interact with provider server.
 */
@interface GRSCProviderService : NSObject

/**
 * Creates an exclusive single ride trip.
 *
 * @param pickup The pickup location for the trip.
 * @param intermediateDestinations The intermediate destinations for the trip if any. Will be empty
 * if trip does not have intermediate destinations.
 * @param dropoff The dropoff location for the trip.
 * @param completion The block executed when a response from the provider is received.
 */
- (void)createTripWithPickup:(nonnull GMTSTerminalLocation *)pickup
    intermediateDestinations:(nonnull NSArray<GMTSTerminalLocation *> *)intermediateDestinations
                     dropoff:(nonnull GMTSTerminalLocation *)dropoff
                  completion:(nonnull GRSCCreateTripCompletionHandler)completion;

/**
 * Cancels an existing Trip.
 *
 * @param tripID The ID for the trip to be cancelled.
 * @param completion The block executed when a response from the provider is received.
 */
- (void)cancelTripWithTripID:(nonnull NSString *)tripID
                  completion:(nonnull GRSCCancelTripCompletionHandler)completion;

/**
 * Initializes and returns a GRSCProviderService object using the provided NSURLSession for
 * network calls.
 *
 * @param session The Session used for NSURLSessionDataTask
 */
- (nullable instancetype)initWithURLSession:(nonnull NSURLSession *)session
    NS_DESIGNATED_INITIALIZER;

@end
