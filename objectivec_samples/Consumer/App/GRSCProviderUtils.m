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

#import "GRSCProviderUtils.h"

#import "GRSCAPIConstants.h"

// HTTP constants.
NSInteger const kGRSCHTTPSuccessCode = 200;
NSString *const kGRSCHTTPMethodPOST = @"POST";
NSString *const kGRSCHTTPMethodPUT = @"PUT";
NSString *const kGRSCHTTPContentTypeHeaderField = @"Content-Type";
NSString *const kGRSCHTTPJSONContentType = @"application/json";
NSString *const kGRSCHTTPGoogleCloudApiKeyHeaderField = @"X-Goog-Api-Key";

// Request parameter keys.
static NSString *const kGRSCLatitudeKey = @"latitude";
static NSString *const kGRSCLongitudeKey = @"longitude";

// Provider error defaults.
static const int kProviderErrorCode = -1;
static NSString *const kGRSCErrorDomain = @"GRSCErrorDomain";

// Error descriptions.
NSString *const kExpectedFieldsNotFoundErrorDescription = @"Expected fields not found in response.";
NSString *const kGRSCUnexpectedJSONClassTypeErrorDescription =
    @"Unexpected class type for JSON response.";
NSString *const kGRSCInvalidRequestURLDescription = @"Invalid request URL.";

/** Returns a dictionary representation of a given LatLng. */
static NSDictionary *_Nonnull GetDictionaryFromLatLng(GMTSLatLng *_Nonnull latLng) {
  return @{
    kGRSCLatitudeKey : @(latLng.latitude),
    kGRSCLongitudeKey : @(latLng.longitude),
  };
}

NSError *GRSCError(NSString *description) {
  NSDictionary<NSErrorUserInfoKey, NSString *> *userInfo = @{
    NSLocalizedDescriptionKey : description,
  };
  return [NSError errorWithDomain:kGRSCErrorDomain code:kProviderErrorCode userInfo:userInfo];
}

NSURL *GRSCProviderURLWithPath(NSString *path) {
  NSURL *baseProviderNSURL = [NSURL URLWithString:kProviderBaseURLString];
  return [NSURL URLWithString:path relativeToURL:baseProviderNSURL];
}

GRSCProviderFieldsDictionary *GRSCGetDictionaryFromJSONData(NSData *data, NSError **error) {
  NSError *JSONParseError;
  id JSONDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                      options:kNilOptions
                                                        error:&JSONParseError];
  NSError *errorToPropagate;
  if (JSONParseError) {
    errorToPropagate = JSONParseError;
  } else if (![JSONDictionary isKindOfClass:[NSDictionary class]]) {
    errorToPropagate = GRSCError(kGRSCUnexpectedJSONClassTypeErrorDescription);
  } else {
    return (GRSCProviderFieldsDictionary *)JSONDictionary;
  }

  if (error) {
    *error = errorToPropagate;
  }
  return nil;
}

NSDictionary *_Nonnull GRSCGetDictionaryFromTerminalLocation(
    GMTSTerminalLocation *_Nonnull location) {
  return GetDictionaryFromLatLng(location.point);
}
