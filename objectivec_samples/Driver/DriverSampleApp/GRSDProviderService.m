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

#import "GRSDProviderService.h"

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "GRSDVehicleModel.h"

static const int kProviderErrorCode = -1;
static NSString *const kGRSDErrorDomain = @"GRSDErrorDomain";

// Used by GMTSAuthorization.
static NSString *const kVehicleServiceToken = @"VehicleServiceToken";

// JSON data keys used and recognized by the sample provider server.
static NSString *const kProviderDataKeyVehicleID = @"vehicleId";
static NSString *const kProviderDataKeyName = @"name";
static NSString *const kProviderDataKeyToken = @"jwt";
static NSString *const kProviderDataKeyTokenExpiration = @"expirationTimestamp";
static NSString *const kProviderDataKeyTripStatus = @"tripStatus";
static NSString *const kProviderDataKeyWaypoints = @"waypoints";
static NSString *const kProviderDataKeyLocation = @"location";
static NSString *const kProviderDataKeyPoint = @"point";
static NSString *const kProviderDataKeyLatitude = @"latitude";
static NSString *const kProviderDataKeyLongitude = @"longitude";
static NSString *const kProviderDataKeyTripID = @"tripId";
static NSString *const kProviderDataKeyStatus = @"status";
static NSString *const kProviderDataKeyIntermediateDestinationIndex =
    @"intermediateDestinationIndex";
static NSString *const kProviderDataKeyTrip = @"trip";
static NSString *const kProviderDataKeyWaypointType = @"waypointType";
static NSString *const kProviderDataKeyCurrentTripIDs = @"currentTripsIds";
static NSString *const kProviderDataKeyBackToBackEnabled = @"backToBackEnabled";
static NSString *const kProviderDataKeyMaximumCapacity = @"maximumCapacity";
static NSString *const kProviderDataKeySupportedTripTypes = @"supportedTripTypes";

// The base URL string for the sample provider server.
static NSString *const kSampleProviderBaseURLString = @"http://localhost:8080/";
static NSString *const kDriverTokenURLPath = @"token/driver/";
static NSString *const kCreateVehicleURLPath = @"vehicle/new";
static NSString *const kGetAvailableTripURLPath = @"trip";
static NSString *const kUpdateTripStatusURLPath = @"trip/";
static NSString *const kBaseVehicleURLPath = @"vehicle/";

// Sample provider supported trip states.
NSString *const GRSDProviderServiceTripStateNew = @"NEW";
NSString *const GRSDProviderServiceTripStatusEnrouteToPickup = @"ENROUTE_TO_PICKUP";
NSString *const GRSDProviderServiceTripStatusArrivedAtPickup = @"ARRIVED_AT_PICKUP";
NSString *const GRSDProviderServiceTripStatusEnrouteToDropoff = @"ENROUTE_TO_DROPOFF";
NSString *const GRSDProviderServiceTripStatusComplete = @"COMPLETE";
NSString *const GRSDProviderServiceTripStatusEnrouteToIntermediateDestination =
    @"ENROUTE_TO_INTERMEDIATE_DESTINATION";
NSString *const GRSDProviderServiceTripStatusArrivedAtIntermediateDestination =
    @"ARRIVED_AT_INTERMEDIATE_DESTINATION";

// Provider waypoint types
static NSString *const kProviderWaypointTypePickup = @"PICKUP_WAYPOINT_TYPE";
static NSString *const kProviderWaypointTypeDropoff = @"DROP_OFF_WAYPOINT_TYPE";
static NSString *const kProviderWaypointTypeIntermediateDestination =
    @"INTERMEDIATE_DESTINATION_WAYPOINT_TYPE";

// Provider supported trip types.
static NSString *const kProviderTripTypeExclusive = @"EXCLUSIVE";
static NSString *const kProviderTripTypeShared = @"SHARED";

// HTTP constants.
static NSInteger const kHTTPStatusOkCode = 200;
static NSString *const kHTTPGETMethod = @"GET";
static NSString *const kHTTPPOSTMethod = @"POST";
static NSString *const kHTTPPUTMethod = @"PUT";

// Error descriptions.
static NSString *const kInvalidAuthorizationContextDescription =
    @"Error reading from authorizationContext.";
static NSString *const kVehicleIDMissingAuthorizationContextDescription =
    @"Vehicle ID missing from authorizationContext.";
static NSString *const kInvalidRequestUrlDescription = @"Invalid request URL.";
static NSString *const kInvalidVehicleNameDescription = @"Invalid vehicle name.";
static NSString *const kErrorCreatingVehicleDescription = @"Error creating vehicle.";
static NSString *const kErrorFetchingTripDescription = @"Error fetching trip.";
static NSString *const kInvalidTripIDDescription = @"Invalid trip ID.";
static NSString *const kErrorUpdatingTripDescription = @"Error updating trip.";
static NSString *const kErrorFetchingVehicleDescription = @"Error fetching vehicle.";
static NSString *const kErrorInvalidResponseDescription = @"Invalid response.";
static NSString *const kErrorUpdatingVehicleDescription = @"Error updating vehicle.";

/**
 * Generates a JSON request based on the passed in method.
 *
 * @param method The method to be used for the request.
 * @param URL The URL to be used for the request.
 * @param payload Payload to be used in the request body.
 */
static NSURLRequest *GenerateJSONRequestWithMethod(NSString *method, NSURL *URL,
                                                   NSDictionary<NSString *, NSString *> *payload) {
  NSData *JSONData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
  request.HTTPMethod = method;
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  request.HTTPBody = JSONData;
  return [request copy];
}

@implementation GRSDProviderService {
  NSString *_lastKnownVehicleID;
  NSTimeInterval _tokenExpiration;
  NSString *_vehicleServiceToken;
}

- (instancetype)init {
  if (self = [super init]) {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:config
                                             delegate:nil
                                        delegateQueue:[NSOperationQueue mainQueue]];
  }
  return self;
}

/** Creates the token URL to the sample provider server. */
static NSURL *GenerateDriverTokenURL(NSString *_Nonnull vehicleID) {
  NSURL *baseURL = [NSURL URLWithString:kSampleProviderBaseURLString];
  NSURL *driverTokenURL = [NSURL URLWithString:kDriverTokenURLPath relativeToURL:baseURL];
  return [NSURL URLWithString:vehicleID relativeToURL:driverTokenURL];
}

/** Generates the create vehicle URL to the sample provider server. */
static NSURL *GenerateCreateVehicleURL() {
  NSURL *baseURL = [NSURL URLWithString:kSampleProviderBaseURLString];
  return [NSURL URLWithString:kCreateVehicleURLPath relativeToURL:baseURL];
}

/** Creates the fetch trip URL to the sample provider server. */
static NSURL *GenerateFetchTripURL(NSString *tripID) {
  NSURL *baseURL = [NSURL URLWithString:kSampleProviderBaseURLString];
  NSURL *fetchURL = [NSURL URLWithString:kUpdateTripStatusURLPath relativeToURL:baseURL];
  return [NSURL URLWithString:tripID relativeToURL:fetchURL];
}

/** Creates the update trip status URL to the sample provider server. */
static NSURL *GenerateUpdateTripStatusURL(NSString *tripID) {
  NSURL *baseURL = [NSURL URLWithString:kSampleProviderBaseURLString];
  NSURL *updateTripStatusURL = [NSURL URLWithString:kUpdateTripStatusURLPath relativeToURL:baseURL];
  return [NSURL URLWithString:tripID relativeToURL:updateTripStatusURL];
}

/** Creates the get vehicle URL to the sample provider server. */
static NSURL *GenerateGetVehicleURL(NSString *vehicleID) {
  NSURL *baseURL = [NSURL URLWithString:kSampleProviderBaseURLString];
  NSURL *fetchURL = [NSURL URLWithString:kBaseVehicleURLPath relativeToURL:baseURL];
  return [NSURL URLWithString:vehicleID relativeToURL:fetchURL];
}

/** Generates the update vehicle URL to the sample provider server. */
static NSURL *GenerateUpdateVehicleURL(NSString *vehicleID) {
  NSURL *baseURL = [NSURL URLWithString:kSampleProviderBaseURLString];
  NSURL *vehicleURL = [NSURL URLWithString:kBaseVehicleURLPath relativeToURL:baseURL];
  return [NSURL URLWithString:vehicleID relativeToURL:vehicleURL];
}

static NSError *GRSDError(NSInteger errorCode, NSString *description) {
  NSDictionary<NSErrorUserInfoKey, NSString *> *userInfo = @{
    NSLocalizedDescriptionKey : description,
  };
  return [NSError errorWithDomain:kGRSDErrorDomain code:errorCode userInfo:userInfo];
}

/** Returns a @c GMTSTripWaypointType from it's string representation. */
static GMTSTripWaypointType GetTripWaypointTypeFromString(NSString *waypointType) {
  if ([waypointType isEqualToString:kProviderWaypointTypePickup]) {
    return GMTSTripWaypointTypePickUp;
  } else if ([waypointType isEqualToString:kProviderWaypointTypeDropoff]) {
    return GMTSTripWaypointTypeDropOff;
  } else if ([waypointType isEqualToString:kProviderWaypointTypeIntermediateDestination]) {
    return GMTSTripWaypointTypeIntermediateDestination;
  } else {
    return GMTSTripWaypointTypeUnknown;
  }
}

/** Returns a @c ProviderSupportedTripType enum from given JSON response. */
static ProviderSupportedTripType GetSupportedTripTypesFromJSONResponse(
    NSDictionary<NSString *, id> *jsonResponse) {
  ProviderSupportedTripType supportedTripTypes = ProviderSupportedTripTypeNone;
  NSArray<NSString *> *vehicleSupportedTripTypesArray =
      jsonResponse[kProviderDataKeySupportedTripTypes];
  if ([vehicleSupportedTripTypesArray containsObject:kProviderTripTypeExclusive]) {
    supportedTripTypes |= ProviderSupportedTripTypeExclusive;
  }
  if ([vehicleSupportedTripTypesArray containsObject:kProviderTripTypeShared]) {
    supportedTripTypes |= ProviderSupportedTripTypeShared;
  }
  return supportedTripTypes;
}

/**
 * Returns a @c GRSDVehicleModel from given JSON response. Will return nil if fields are missing
 * from response.
 */
static GRSDVehicleModel *_Nullable GetVehicleModelFromJSONResponse(
    NSString *vehicleID, NSDictionary<NSString *, id> *jsonResponse) {
  NSNumber *maximumCapacity = jsonResponse[kProviderDataKeyMaximumCapacity];
  id isBackToBackEnabledValue = jsonResponse[kProviderDataKeyBackToBackEnabled];
  if (maximumCapacity && isBackToBackEnabledValue) {
    BOOL isBackToBackEnabled = [isBackToBackEnabledValue boolValue];
    ProviderSupportedTripType supportedTripTypes =
        GetSupportedTripTypesFromJSONResponse(jsonResponse);
    GRSDVehicleModel *createdVehicleModel =
        [[GRSDVehicleModel alloc] initWithVehicleID:vehicleID
                                    maximumCapacity:maximumCapacity.unsignedIntegerValue
                                 supportedTripTypes:supportedTripTypes
                                isBackToBackEnabled:isBackToBackEnabled];
    return createdVehicleModel;
  }
  return nil;
}

/** Returns the string representations of the given @c ProviderSupportedTripType in an array. */
static NSArray<NSString *> *GetSupportedTripTypesArray(
    ProviderSupportedTripType supportedTripTypes) {
  NSMutableArray<NSString *> *result = [[NSMutableArray alloc] init];
  if (supportedTripTypes & ProviderSupportedTripTypeExclusive) {
    [result addObject:kProviderTripTypeExclusive];
  }
  if (supportedTripTypes & ProviderSupportedTripTypeShared) {
    [result addObject:kProviderTripTypeShared];
  }
  return result;
}

/** Returns a dictionary with entries from the given @c GRSDVehicleModel. */
static NSDictionary<NSString *, id> *GetJSONDictionaryFromVehicleModel(
    GRSDVehicleModel *vehicleModel) {
  return @{
    kProviderDataKeyVehicleID : vehicleModel.vehicleID,
    kProviderDataKeyMaximumCapacity : @(vehicleModel.maximumCapacity),
    kProviderDataKeyBackToBackEnabled : @(vehicleModel.isBackToBackEnabled),
    kProviderDataKeySupportedTripTypes :
        GetSupportedTripTypesArray(vehicleModel.supportedTripTypes),
  };
}

/**
 * Returns a @c GRSDVehicleModel from the given data object. Returns nil and updates the given error
 * object if the data is invalid or cannot be serialized to a JSON dictionary.
 *
 * @param data The data object containing JSON serializable data.
 * @param error The error that is set on failure.
 */
static GRSDVehicleModel *_Nullable GetVehicleModelFromResponseData(NSData *data, NSError **error) {
  NSError *JSONParseError;
  id JSONResponse = [NSJSONSerialization JSONObjectWithData:data
                                                    options:kNilOptions
                                                      error:&JSONParseError];
  NSError *errorToPropagate;
  if (JSONParseError) {
    errorToPropagate = JSONParseError;
  } else if (![JSONResponse isKindOfClass:[NSDictionary class]]) {
    errorToPropagate = GRSDError(kProviderErrorCode, kErrorInvalidResponseDescription);
  } else {
    // Get vehicle name from response.
    NSString *vehicleName = JSONResponse[kProviderDataKeyName];
    // Provider returns fully qualified vehicle name in this form:
    // 'providers/providerID/vehicles/vehicleID'. So strip provider ID from it.
    NSString *vehicleID = [vehicleName componentsSeparatedByString:@"/"].lastObject;
    if (!vehicleID) {
      errorToPropagate = GRSDError(kProviderErrorCode, kInvalidVehicleNameDescription);
    } else {
      GRSDVehicleModel *updatedVehicle = GetVehicleModelFromJSONResponse(vehicleID, JSONResponse);
      if (updatedVehicle) {
        return updatedVehicle;
      } else {
        errorToPropagate = GRSDError(kProviderErrorCode, kErrorInvalidResponseDescription);
      }
    }
  }

  if (error) {
    *error = errorToPropagate;
  }
  return nil;
}

/** Returns an array of @c GMTSTripWaypoint objects from a given JSON response. */
static NSArray<GMTSTripWaypoint *> *_Nullable GetTripWaypointsFromJSONResponse(
    NSDictionary<NSString *, id> *response) {
  // Note: Relaxed type and parsing error checks here since this is a sample app.
  NSArray<NSDictionary<NSString *, id> *> *waypointsJSON = response[kProviderDataKeyWaypoints];
  if (!waypointsJSON) {
    return nil;
  }
  NSMutableArray<GMTSTripWaypoint *> *waypoints = [[NSMutableArray alloc] init];
  for (NSDictionary<NSString *, id> *waypointJSON in waypointsJSON) {
    NSString *tripID = waypointJSON[kProviderDataKeyTripID];
    NSDictionary<NSString *, id> *locationJSON = waypointJSON[kProviderDataKeyLocation];
    NSDictionary<NSString *, id> *pointJSON = locationJSON[kProviderDataKeyPoint];
    NSString *waypointTypeString = waypointJSON[kProviderDataKeyWaypointType];
    NSNumber *latitude = pointJSON[kProviderDataKeyLatitude];
    NSNumber *longitude = pointJSON[kProviderDataKeyLongitude];
    GMTSLatLng *latlng = [[GMTSLatLng alloc] initWithLatitude:latitude.doubleValue
                                                    longitude:longitude.doubleValue];
    GMTSTerminalLocation *terminalLocation = [[GMTSTerminalLocation alloc] initWithPoint:latlng
                                                                                   label:nil
                                                                             description:nil
                                                                                 placeID:nil
                                                                             generatedID:nil
                                                                           accessPointID:nil];

    GMTSTripWaypointType waypointType = GetTripWaypointTypeFromString(waypointTypeString);
    GMTSTripWaypoint *waypoint = [[GMTSTripWaypoint alloc] initWithLocation:terminalLocation
                                                                     tripID:tripID
                                                               waypointType:waypointType
                                         distanceToPreviousWaypointInMeters:0
                                                                        ETA:0];
    [waypoints addObject:waypoint];
  }
  return waypoints;
}

- (void)createVehicleWithID:(NSString *)vehicleID
        isBackToBackEnabled:(BOOL)isBackToBackEnabled
                 completion:(GRSDCreateVehicleWithIDHandler)completion {
  if (!completion) {
    NSAssert(NO, @"%s encountered an unexpected nil completion.", __PRETTY_FUNCTION__);
    return;
  }

  if (vehicleID.length == 0) {
    NSString *invalidAuthorizationContextDescription =
        @"Encountered an unexpected invalid parameter (vehicleID).";
    completion(nil, GRSDError(kProviderErrorCode, invalidAuthorizationContextDescription));
    return;
  }

  __weak typeof(self) weakSelf = self;
  void (^handler)(NSData *, NSURLResponse *, NSError *) =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf handleCreateVehicleWithIDResponseWithData:data
                                                   response:response
                                                      error:error
                                                 completion:completion];
      };

  NSDictionary<NSString *, id> *payload = @{
    kProviderDataKeyVehicleID : vehicleID,
    kProviderDataKeyBackToBackEnabled : @(isBackToBackEnabled)
  };
  NSURL *requestURL = GenerateCreateVehicleURL();
  if (!requestURL) {
    completion(nil, GRSDError(kProviderErrorCode, kInvalidRequestUrlDescription));
    return;
  }
  NSURLRequest *request = GenerateJSONRequestWithMethod(kHTTPPOSTMethod, requestURL, payload);
  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
  [task resume];
}

- (void)handleCreateVehicleWithIDResponseWithData:(NSData *)data
                                         response:(NSURLResponse *)response
                                            error:(NSError *)error
                                       completion:(GRSDCreateVehicleWithIDHandler)completion {
  if (error) {
    completion(nil, error);
    return;
  }

  NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
  if (statusCode != kHTTPStatusOkCode) {
    completion(nil, GRSDError(kProviderErrorCode, kErrorCreatingVehicleDescription));
  } else {
    NSError *processResponseError;
    GRSDVehicleModel *vehicleModel = GetVehicleModelFromResponseData(data, &processResponseError);
    completion(vehicleModel, processResponseError);
  }
}

- (void)updateVehicleWithModel:(GRSDVehicleModel *)vehicleModel
                    completion:(GRSDUpdateVehicleHandler)completion {
  if (!completion) {
    NSAssert(NO, @"%s encountered an unexpected nil completion.", __PRETTY_FUNCTION__);
    return;
  }
  if (!vehicleModel) {
    NSString *invalidVehicleModelErrorDescription =
        @"Encountered an unexpected invalid parameter (vehicleModel).";
    completion(nil, GRSDError(kProviderErrorCode, invalidVehicleModelErrorDescription));
    return;
  }

  __weak typeof(self) weakSelf = self;
  void (^handler)(NSData *, NSURLResponse *, NSError *) =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf handleUpdateVehicleResponseWithData:data
                                             response:response
                                                error:error
                                           completion:completion];
      };
  NSDictionary<NSString *, id> *payload = GetJSONDictionaryFromVehicleModel(vehicleModel);
  NSURL *requestURL = GenerateUpdateVehicleURL(vehicleModel.vehicleID);
  if (!requestURL) {
    completion(nil, GRSDError(kProviderErrorCode, kInvalidRequestUrlDescription));
    return;
  }
  NSURLRequest *request = GenerateJSONRequestWithMethod(kHTTPPUTMethod, requestURL, payload);
  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
  [task resume];
}

- (void)handleUpdateVehicleResponseWithData:(NSData *)data
                                   response:(NSURLResponse *)response
                                      error:(NSError *)error
                                 completion:(GRSDUpdateVehicleHandler)completion {
  if (error) {
    completion(nil, error);
    return;
  }
  NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
  if (statusCode != kHTTPStatusOkCode) {
    completion(nil, GRSDError(kProviderErrorCode, kErrorUpdatingVehicleDescription));
    return;
  }
  NSError *processResponseError;
  GRSDVehicleModel *vehicleModel = GetVehicleModelFromResponseData(data, &processResponseError);
  completion(vehicleModel, processResponseError);
}

- (void)fetchTripWithID:(NSString *)tripID completion:(GRSDFetchTripHandler)completion {
  if (!completion) {
    NSAssert(NO, @"%s encountered an unexpected nil completion.", __PRETTY_FUNCTION__);
    return;
  }
  if (tripID.length == 0) {
    NSString *kTripIDMissingDescription = @"Encountered an unexpected invalid parameter (tripID).";
    completion(nil, nil, nil, GRSDError(kProviderErrorCode, kTripIDMissingDescription));
    return;
  }

  __weak typeof(self) weakSelf = self;
  void (^handler)(NSData *, NSURLResponse *, NSError *) =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf handleFetchTripResponseWithData:data
                                         response:response
                                            error:error
                                       completion:completion];
      };

  NSURL *requestURL = GenerateFetchTripURL(tripID);
  if (!requestURL) {
    completion(nil, nil, nil, GRSDError(kProviderErrorCode, kInvalidRequestUrlDescription));
    return;
  }

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
  request.HTTPMethod = kHTTPGETMethod;
  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];

  [task resume];
}

- (void)handleFetchTripResponseWithData:(NSData *)data
                               response:(NSURLResponse *)response
                                  error:(NSError *)error
                             completion:(GRSDFetchTripHandler)completion {
  if (error) {
    completion(nil, nil, nil, error);
    return;
  }

  NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
  if (statusCode != kHTTPStatusOkCode) {
    completion(nil, nil, nil, GRSDError(kProviderErrorCode, kErrorFetchingTripDescription));
    return;
  }
  // The provider sends empty data if there's no available trip.
  if (data.length == 0) {
    completion(nil, nil, nil, nil);
    return;
  }

  // Write response to JSON object.
  NSError *jsonParseError;
  NSDictionary<NSString *, id> *jsonResponse =
      [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonParseError];
  if (jsonParseError) {
    completion(nil, nil, nil, jsonParseError);
    return;
  }

  // Get all the trip info from response.
  NSDictionary<NSString *, id> *tripResponse = jsonResponse[kProviderDataKeyTrip];

  // Get the trip name from trip response.
  NSString *fullTripName = tripResponse[kProviderDataKeyName];
  // Provider returns fully qualified trip name in this form:
  // 'providers/providerID/trips/tripID', so strip trip ID from it.
  NSString *tripID = [fullTripName componentsSeparatedByString:@"/"].lastObject;
  if (!tripID) {
    completion(nil, nil, nil, GRSDError(kProviderErrorCode, kInvalidTripIDDescription));
    return;
  }
  NSString *tripStatus = tripResponse[kProviderDataKeyTripStatus];
  NSArray<GMTSTripWaypoint *> *waypoints = GetTripWaypointsFromJSONResponse(tripResponse);

  completion(tripID, tripStatus, [waypoints copy], nil);
}

- (void)updateTripWithStatus:(NSString *)newStatus
                          tripID:(NSString *)tripID
    intermediateDestinationIndex:(NSNumber *)intermediateDestinationIndex
                      completion:(GRSDUpdateTripHandler)completion {
  if (!completion) {
    NSAssert(NO, @"%s encountered an unexpected nil completion.", __PRETTY_FUNCTION__);
    return;
  }

  if (tripID.length == 0 || newStatus.length == 0) {
    NSString *kUnexpectedNilParamDescription = @"Encountered an unexpected invalid parameter.";
    completion(nil, GRSDError(kProviderErrorCode, kUnexpectedNilParamDescription));
    return;
  }
  __weak typeof(self) weakSelf = self;
  void (^handler)(NSData *, NSURLResponse *, NSError *) =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf handleUpdateTripResponseWithData:data
                                          response:response
                                             error:error
                                        completion:completion];
      };
  NSMutableDictionary<NSString *, id> *payload = [[NSMutableDictionary alloc] init];
  [payload setObject:newStatus forKey:kProviderDataKeyStatus];
  if (intermediateDestinationIndex) {
    [payload setObject:intermediateDestinationIndex
                forKey:kProviderDataKeyIntermediateDestinationIndex];
  }
  NSURL *requestURL = GenerateUpdateTripStatusURL(tripID);
  NSURLRequest *request = GenerateJSONRequestWithMethod(@"PUT", requestURL, payload);
  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
  [task resume];
}

- (void)handleUpdateTripResponseWithData:(NSData *)data
                                response:(NSURLResponse *)response
                                   error:(NSError *)error
                              completion:(GRSDUpdateTripHandler)completion {
  if (error) {
    completion(nil, error);
    return;
  }
  NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
  if (statusCode != kHTTPStatusOkCode) {
    completion(nil, GRSDError(kProviderErrorCode, kErrorUpdatingTripDescription));
    return;
  }

  // Write response to JSON object.
  NSError *jsonParseError;
  NSDictionary<NSString *, id> *jsonResponse =
      [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonParseError];
  if (jsonParseError) {
    completion(nil, jsonParseError);
    return;
  }

  // Get the trip name from response.
  NSString *fullTripName = jsonResponse[kProviderDataKeyName];
  // Provider returns fully qualified trip name in this form:
  // 'providers/providerID/trips/name', so strip trip name from it.
  NSString *tripID = [fullTripName componentsSeparatedByString:@"/"].lastObject;
  if (tripID.length == 0) {
    completion(nil, GRSDError(kProviderErrorCode, kInvalidTripIDDescription));
  } else {
    completion(tripID, nil);
  }
}

- (void)fetchVehicleWithID:(NSString *)vehicleID
                completion:(nonnull GRSDFetchVehicleHandler)completion {
  if (!completion) {
    NSAssert(NO, @"%s encountered an unexpected nil completion.", __PRETTY_FUNCTION__);
    return;
  }
  if (!vehicleID || vehicleID.length == 0) {
    NSString *kVehicleIDMissingDescription =
        @"Encountered an unexpected invalid parameter (vehicleID).";
    completion(nil, nil, GRSDError(kProviderErrorCode, kVehicleIDMissingDescription));
    return;
  }

  __weak typeof(self) weakSelf = self;
  void (^handler)(NSData *, NSURLResponse *, NSError *) =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf handleFetchVehicleResponseWithData:data
                                            response:response
                                               error:error
                                          completion:completion];
      };

  NSURL *requestURL = GenerateGetVehicleURL(vehicleID);
  if (!requestURL) {
    completion(nil, nil, GRSDError(kProviderErrorCode, kInvalidRequestUrlDescription));
    return;
  }

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
  request.HTTPMethod = kHTTPGETMethod;
  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                               completionHandler:handler];
  [task resume];
}

- (void)handleFetchVehicleResponseWithData:(NSData *)data
                                  response:(NSURLResponse *)response
                                     error:(NSError *)error
                                completion:(GRSDFetchVehicleHandler)completion {
  if (error) {
    completion(nil, nil, error);
    return;
  }

  NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
  if (statusCode != kHTTPStatusOkCode) {
    completion(nil, nil, GRSDError(kProviderErrorCode, kErrorFetchingVehicleDescription));
    return;
  }

  // The provider sends empty data if this vehicle doesn't exist.
  if (data.length == 0) {
    completion(nil, nil, nil);
    return;
  }

  // Write response to JSON object.
  NSError *jsonParseError;
  NSDictionary<NSString *, id> *jsonResponse =
      [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonParseError];
  if (jsonParseError) {
    completion(nil, nil, jsonParseError);
    return;
  }

  NSArray *currentTripIDs = jsonResponse[kProviderDataKeyCurrentTripIDs];
  NSArray<GMTSTripWaypoint *> *waypoints = GetTripWaypointsFromJSONResponse(jsonResponse);
  completion(currentTripIDs, waypoints, nil);
}

#pragma mark - GMTDAuthorization

- (void)fetchTokenWithContext:(nullable GMTDAuthorizationContext *)authorizationContext
                   completion:(nonnull GMTDAuthTokenFetchCompletionHandler)completion {
  // Validate authorization context.
  if (!authorizationContext) {
    completion(nil, GRSDError(kProviderErrorCode, kInvalidAuthorizationContextDescription));
    return;
  }

  // Validate vehicle ID from context.
  NSString *vehicleID = (NSString *)authorizationContext.vehicleID;
  if (!vehicleID) {
    completion(nil,
               GRSDError(kProviderErrorCode, kVehicleIDMissingAuthorizationContextDescription));
    return;
  }

  // Clear cached tokens if vehicle ID has changed.
  if (![_lastKnownVehicleID isEqual:vehicleID]) {
    _tokenExpiration = 0.0;
    _vehicleServiceToken = nil;
  }
  _lastKnownVehicleID = vehicleID;

  // Clear cached tokens if they have expired.
  if ([[NSDate date] timeIntervalSince1970] > _tokenExpiration) {
    _vehicleServiceToken = nil;
  }

  // Use cached token if found.
  if (_vehicleServiceToken) {
    NSString *cachedToken = _vehicleServiceToken;
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(cachedToken, nil);
    });
    return;
  }

  // Fetch new token if there's not a cached one.
  NSURL *requestURL = GenerateDriverTokenURL(vehicleID);
  if (!requestURL) {
    completion(nil, GRSDError(kProviderErrorCode, kInvalidRequestUrlDescription));
    return;
  }

  __weak __typeof(self) weakSelf = self;
  void (^tokenResponseHandler)(NSData *, NSURLResponse *, NSError *) =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf handleTokenResponseData:data
                                 response:response
                                    error:error
                               completion:completion];
      };

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
  request.HTTPMethod = kHTTPGETMethod;
  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                               completionHandler:tokenResponseHandler];
  [task resume];
}

- (void)handleTokenResponseData:(NSData *)data
                       response:(NSURLResponse *)response
                          error:(NSError *)error
                     completion:(nonnull GMTDAuthTokenFetchCompletionHandler)completion {
  if (error) {
    completion(nil, error);
  } else {
    // Write response to JSON object.
    NSError *jsonParseError;
    NSDictionary<NSString *, id> *jsonResponse =
        [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonParseError];
    if (jsonParseError) {
      completion(nil, jsonParseError);
      return;
    }

    // Get token from response.
    NSString *token = jsonResponse[kProviderDataKeyToken];
    if ([token length] == 0) {
      NSString *invalidTokenDescription = @"No valid token returned in response.";
      completion(nil, GRSDError(kProviderErrorCode, invalidTokenDescription));
      return;
    }

    // Save token and expiration date for caching purposes.
    _vehicleServiceToken = token;
    NSNumber *expirationData = jsonResponse[kProviderDataKeyTokenExpiration];
    if (expirationData) {
      NSTimeInterval expirationTime = ((NSNumber *)expirationData).doubleValue;
      _tokenExpiration = [[NSDate date] timeIntervalSince1970] + expirationTime;
    }

    completion(token, nil);
  }
}

@end
