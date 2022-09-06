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

#import "GRSCLocationSelectionService.h"
#import "GRSCAPIConstants.h"
#import "GRSCProviderUtils.h"

// Request parameter keys.
static NSString *const kGRSCSearchLocationKey = @"search_location";
static NSString *const kGRSCLocationPreferencesKey = @"localization_preferences";
static NSString *const kGRSCLanguageCodeKey = @"language_code";
static NSString *const kGRSCRegionCodeKey = @"region_code";
static NSString *const kGRSCMaxResultsKey = @"max_results";
static NSString *const kGRSCOrderByKey = @"order_by";
static NSString *const kGRSCTravelModesKey = @"travel_modes";
static NSString *const kGRSCComputeWalkingEtaKey = @"compute_walking_eta";

// Request parameter value.
static const int kGRSCMaxResultsValue = 1;
static NSString *const kGRSCOrderByValue = @"WALKING_ETA_FROM_SEARCH_LOCATION";
static NSString *const kGRSCTravelModesValue = @"WALKING";
static const BOOL kGRSCComputeWalkingEtaValue = YES;
static NSDictionary *kGRSClocalizationPreferencesValue() {
  return @{@"language_code" : @"en-US", @"region_code" : @"US"};
}

// Response parameter key paths.
static NSString *const kGRSCPickupPointLatitudeKeyPath =
    @"placePickupPointResults.pickupPointResult.pickupPoint.location.latitude";
static NSString *const kGRSCPickupPointLongitudeKeyPath =
    @"placePickupPointResults.pickupPointResult.pickupPoint.location.longitude";
static NSString *const kGRSCWalkingDistanceKeyPath =
    @"placePickupPointResults.pickupPointResult.distanceMeters";

// Location Seleciton API URL Strings.
static NSString *const kGRSCBaseLocationSelectionURLString =
    @"https://locationselection.googleapis.com";
static NSString *const kGRSCLocationSelectionFindPickupPointsForLocation =
    @"/v1beta:findPickupPointsForLocation";

/** Returns an instance of NSURL with the base Location Selection URL and given path. */
static NSURL *GRSCLocationSelectionURLWithPath(NSString *path) {
  NSURL *baseProviderNSURL = [NSURL URLWithString:kGRSCBaseLocationSelectionURLString];
  return [NSURL URLWithString:path relativeToURL:baseProviderNSURL];
}

/** Returns a JSON formatted NSURLRequest with API key access. */
static NSURLRequest *_Nonnull GetJSONRequestWithGoogleCloudApiKey(
    NSURL *_Nonnull URL, NSDictionary<NSString *, id> *_Nonnull requestBody,
    NSString *_Nonnull method, NSString *_Nonnull googleCloudApiKey) {
  NSData *JSONData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:nil];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
  request.HTTPMethod = method;
  [request setValue:kGRSCHTTPJSONContentType forHTTPHeaderField:kGRSCHTTPContentTypeHeaderField];
  [request addValue:googleCloudApiKey forHTTPHeaderField:kGRSCHTTPGoogleCloudApiKeyHeaderField];
  request.HTTPBody = JSONData;
  return request;
}

/** Returns a GMTSLatLng with a given dictionary. */
static GMTSLatLng *_Nonnull GetLatLngFromDictionary(NSDictionary *_Nonnull dict,
                                                    NSString *_Nonnull latitudeKeyPath,
                                                    NSString *_Nonnull longitudeKeyPath) {
  return [[GMTSLatLng alloc]
      initWithLatitude:[[dict valueForKeyPath:latitudeKeyPath][0] doubleValue]
             longitude:[[dict valueForKeyPath:longitudeKeyPath][0] doubleValue]];
}

/**
 * Handler type definition used to process responses from the Location Selection API.
 *
 * @param data The data returned by the Location Selection API. Will be nil if the server returns no
 * data.
 * @param response The response from the Location Selection API which includes response headers and
 * other metadata. Will be nil if request fails.
 * @param error The error that occurs when processing the response from the Location Selection API.
 * Will be nil if the request succeeds.
 */
typedef void (^GRSCLocationSelectionResponseHandler)(NSData *_Nullable data,
                                                     NSURLResponse *_Nullable response,
                                                     NSError *_Nullable error);

@implementation GRSCLocationSelectionService {
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

- (void)
    getLocationSelectionPickupPointWithSearchLocation:(nonnull GMTSTerminalLocation *)searchLocation
                                           completion:
                                               (nonnull
                                                    GRSCGetLocationSelectionPickupPointCompletionHandler)
                                                   completion {
  NSURL *requestURL =
      GRSCLocationSelectionURLWithPath(kGRSCLocationSelectionFindPickupPointsForLocation);

  if (!requestURL) {
    completion(nil, nil, GRSCError(kGRSCInvalidRequestURLDescription));
    return;
  }

  GRSCProviderFieldsDictionary *searchLocationDictionary =
      GRSCGetDictionaryFromTerminalLocation(searchLocation);
  NSDictionary<NSString *, id> *requestBody = @{
    kGRSCSearchLocationKey : searchLocationDictionary,
    kGRSCLocationPreferencesKey : kGRSClocalizationPreferencesValue(),
    kGRSCMaxResultsKey : [NSNumber numberWithInteger:kGRSCMaxResultsValue],
    kGRSCOrderByKey : kGRSCOrderByValue,
    kGRSCTravelModesKey : kGRSCTravelModesValue,
    kGRSCComputeWalkingEtaKey : [NSNumber numberWithBool:kGRSCComputeWalkingEtaValue]
  };
  NSURLRequest *request = GetJSONRequestWithGoogleCloudApiKey(
      requestURL, requestBody, kGRSCHTTPMethodPOST, kLocationSelectionAPIKey);

  GRSCLocationSelectionResponseHandler findLocationSelectionPickupPointServerResponseHandler =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
          completion(nil, nil, error);
          return;
        }
        NSError *JSONError;
        // Process JSON response.
        GRSCProviderFieldsDictionary *responseDictionary =
            GRSCGetDictionaryFromJSONData(data, &JSONError);
        if (JSONError) {
          completion(nil, nil, JSONError);
          return;
        }
        if (!responseDictionary) {
          dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, nil, GRSCError(kExpectedFieldsNotFoundErrorDescription));
          });
          return;
        }
        NSNumber *locationSelectionWalkingDistance =
            [responseDictionary valueForKeyPath:kGRSCWalkingDistanceKeyPath][0];
        GMTSLatLng *locationSelectionPickupPointLatLng = GetLatLngFromDictionary(
            responseDictionary, kGRSCPickupPointLatitudeKeyPath, kGRSCPickupPointLongitudeKeyPath);
        if (!locationSelectionPickupPointLatLng || !locationSelectionWalkingDistance) {
          // Could not find LatLng or WalkingDistance in response
          completion(nil, nil, GRSCError(kExpectedFieldsNotFoundErrorDescription));
          return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
          completion(locationSelectionPickupPointLatLng, locationSelectionWalkingDistance, nil);
        });
      };

  NSURLSessionDataTask *task =
      [_session dataTaskWithRequest:request
                  completionHandler:findLocationSelectionPickupPointServerResponseHandler];
  [task resume];
}

@end
