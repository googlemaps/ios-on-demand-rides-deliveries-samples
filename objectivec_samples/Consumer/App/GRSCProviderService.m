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

#import "GRSCProviderService.h"

#import "GRSCProviderUtils.h"

// Provider URL Strings.
static NSString *const kGRSCProviderCreateTripURLString = @"/trip/new";
static NSString *const kGRSCProviderUpdateTripStatusURLString = @"/trip/";

// Request parameter keys.
static NSString *const kGRSCPickupKey = @"pickup";
static NSString *const kGRSCIntermediateDestinationsKey = @"intermediateDestinations";
static NSString *const kGRSCDropoffKey = @"dropoff";
static NSString *const kGRSCLatitudeKey = @"latitude";
static NSString *const kGRSCLongitudeKey = @"longitude";
static NSString *const kGRSCStatusKey = @"status";
static NSString *const kGRSCTripTypeKey = @"tripType";
static NSString *const kGRSCTripTypeExclusiveKey = @"EXCLUSIVE";
static NSString *const kGRSCTripTypeSharedKey = @"SHARED";

// Response parameter keys.
static NSString *const kGRSCTripNameKey = @"name";

// HTTP constants.
static NSInteger const kGRSCHTTPSuccessCode = 200;
static NSString *const kGRSCHTTPMethodPOST = @"POST";
static NSString *const kGRSCHTTPMethodPUT = @"PUT";
static NSString *const kGRSCHTTPContentTypeHeaderField = @"Content-Type";
static NSString *const kGRSCHTTPJSONContentType = @"application/json";

// Error descriptions.
static NSString *const kExpectedFieldsNotFoundErrorDescription =
    @"Expected fields not found in response.";
static NSString *const kFailedToCancelTripErrorDescription = @"Server failed to cancel trip.";

// Trip status.
static NSString *const kGRSCTripStatusCanceled = @"CANCELED";

/** Returns a dictionary representation of a given GMTSLatLng. */
static NSDictionary *_Nonnull GetDictionaryFromGRSLatLng(GMTSLatLng *_Nonnull latLng) {
  return @{
    kGRSCLatitudeKey : @(latLng.latitude),
    kGRSCLongitudeKey : @(latLng.longitude),
  };
}

/** Returns a dictionary representation of a given GMTSTerminalLocation. */
static NSDictionary *_Nonnull GetDictionaryFromTerminalLocation(
    GMTSTerminalLocation *_Nonnull location) {
  GRSCProviderFieldsMutableDictionary *terminalLocationDictionary =
      [GetDictionaryFromGRSLatLng(location.point) mutableCopy];
  return [terminalLocationDictionary copy];
}

/** Returns an array of the intermediate destinations as LatLngs. */
static NSArray *_Nonnull GetLocationsArrayFromIntermediateDestinations(
    NSArray<GMTSTerminalLocation *> *_Nonnull intermediateDestinations) {
  NSMutableArray *locationsArray = [[NSMutableArray alloc] init];
  for (GMTSTerminalLocation *intermediateDestination in intermediateDestinations) {
    [locationsArray addObject:GetDictionaryFromTerminalLocation(intermediateDestination)];
  }
  return locationsArray;
}

/** Returns a JSON formatted NSURLRequest. */
static NSURLRequest *_Nonnull GetJSONRequest(NSURL *_Nonnull URL,
                                             NSDictionary<NSString *, id> *_Nonnull requestBody,
                                             NSString *_Nonnull method) {
  NSData *JSONData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:nil];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
  request.HTTPMethod = method;
  [request setValue:kGRSCHTTPJSONContentType forHTTPHeaderField:kGRSCHTTPContentTypeHeaderField];
  request.HTTPBody = JSONData;
  return request;
}

/** Returns the update trip status provider URL with the given tripID appended. */
static NSURL *_Nullable GetProviderUpdateTripStatusURLWithTripID(NSString *_Nonnull tripID) {
  NSURL *providerURL = GRSCProviderURLWithPath(kGRSCProviderUpdateTripStatusURLString);
  return [NSURL URLWithString:tripID relativeToURL:providerURL];
}

@implementation GRSCProviderService {
  NSURLSession *_session;
}

- (instancetype)init {
  return [self initWithURLSession:[NSURLSession sharedSession]];
}

- (instancetype)initWithURLSession:(NSURLSession *)session {
  self = [super init];
  if (self) {
    _session = session;
  }
  return self;
}

- (void)createTripWithPickup:(nonnull GMTSTerminalLocation *)pickup
    intermediateDestinations:(nonnull NSArray<GMTSTerminalLocation *> *)intermediateDestinations
                     dropoff:(nonnull GMTSTerminalLocation *)dropoff
                isSharedTrip:(BOOL)isSharedTrip
                  completion:(nonnull GRSCCreateTripCompletionHandler)completion {
  NSURL *requestURL = GRSCProviderURLWithPath(kGRSCProviderCreateTripURLString);

  if (!requestURL) {
    completion(nil, GRSCError(kGRSCInvalidRequestURLDescription));
    return;
  }

  GRSCProviderFieldsDictionary *pickupDictionary = GetDictionaryFromTerminalLocation(pickup);
  GRSCProviderFieldsDictionary *dropoffDictionary = GetDictionaryFromTerminalLocation(dropoff);

  NSMutableDictionary<NSString *, id> *requestBody = [[NSMutableDictionary alloc] init];
  [requestBody setObject:pickupDictionary forKey:kGRSCPickupKey];
  [requestBody setObject:dropoffDictionary forKey:kGRSCDropoffKey];

  if (intermediateDestinations && intermediateDestinations.count) {
    NSArray *intermediateDestinationsArray =
        GetLocationsArrayFromIntermediateDestinations(intermediateDestinations);
    [requestBody setObject:intermediateDestinationsArray forKey:kGRSCIntermediateDestinationsKey];
  }

  NSString *tripType = isSharedTrip ? kGRSCTripTypeSharedKey : kGRSCTripTypeExclusiveKey;
  [requestBody setObject:tripType forKey:kGRSCTripTypeKey];

  NSURLRequest *request = GetJSONRequest(requestURL, requestBody, kGRSCHTTPMethodPOST);

  GRSCProviderResponseHandler createTripServerResponseHandler =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
          completion(nil, error);
        } else {
          NSError *JSONError;
          // Process JSON response.
          GRSCProviderFieldsDictionary *responseDictionary =
              GRSCGetDictionaryFromJSONData(data, &JSONError);
          if (JSONError) {
            dispatch_async(dispatch_get_main_queue(), ^{
              completion(nil, JSONError);
            });
            return;
          }
          if (!responseDictionary) {
            dispatch_async(dispatch_get_main_queue(), ^{
              completion(nil, nil);
            });
            return;
          }
          id tripName = responseDictionary[kGRSCTripNameKey];
          if (!tripName) {
            // Could not find tripName or matchID in response
            completion(nil, GRSCError(kExpectedFieldsNotFoundErrorDescription));
            return;
          } else if (![tripName isKindOfClass:[NSString class]]) {
            // Invalid class type for tripName
            completion(nil, GRSCError(kGRSCUnexpectedJSONClassTypeErrorDescription));
            return;
          } else {
            NSString *tripNameString = (NSString *)tripName;
            dispatch_async(dispatch_get_main_queue(), ^{
              completion(tripNameString, nil);
            });
          }
        }
      };

  NSURLSessionDataTask *task = [_session dataTaskWithRequest:request
                                           completionHandler:createTripServerResponseHandler];
  [task resume];
}

- (void)cancelTripWithTripID:(nonnull NSString *)tripID
                  completion:(nonnull GRSCCancelTripCompletionHandler)completion {
  NSURL *requestURL = GetProviderUpdateTripStatusURLWithTripID(tripID);

  if (!requestURL) {
    completion(GRSCError(kGRSCInvalidRequestURLDescription));
    return;
  }

  NSDictionary<NSString *, NSString *> *requestBody =
      @{kGRSCStatusKey : kGRSCTripStatusCanceled};

  NSURLRequest *request = GetJSONRequest(requestURL, requestBody, kGRSCHTTPMethodPUT);

  GRSCProviderResponseHandler cancelTripServerResponseHandler =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
          // Validate HTTP response status code.
          NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
          if (statusCode != kGRSCHTTPSuccessCode) {
            error = GRSCError(kFailedToCancelTripErrorDescription);
          }
        }
        completion(error);
      };

  NSURLSessionDataTask *task = [_session dataTaskWithRequest:request
                                           completionHandler:cancelTripServerResponseHandler];
  [task resume];
}

@end
