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

// Provider error defaults.
static const int kProviderErrorCode = -1;
static NSString *const kGRSCErrorDomain = @"GRSCErrorDomain";

// Provider URL Strings.
static NSString *const kGRSCBaseProviderURLString = @"http://localhost:8080";

// Error descriptions.
NSString *const kGRSCUnexpectedJSONClassTypeErrorDescription =
    @"Unexpected class type for JSON response.";
NSString *const kGRSCInvalidRequestURLDescription = @"Invalid request URL.";

NSError *GRSCError(NSString *description) {
  NSDictionary<NSErrorUserInfoKey, NSString *> *userInfo = @{
    NSLocalizedDescriptionKey : description,
  };
  return [NSError errorWithDomain:kGRSCErrorDomain code:kProviderErrorCode userInfo:userInfo];
}

NSURL *GRSCProviderURLWithPath(NSString *path) {
  NSURL *baseProviderNSURL = [NSURL URLWithString:kGRSCBaseProviderURLString];
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
