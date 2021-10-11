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

#import "GRSCAuthTokenProvider.h"

#import "GRSCAuthToken.h"
#import "GRSCProviderUtils.h"

// Provider token path String.
static NSString *const kProviderTokenPath = @"token/consumer/";

// Provider response keys.
static NSString *const kProviderResponseTokenExpirationKey = @"expirationTimestamp";
static NSString *const kProviderResponseTokenKey = @"jwt";

// Error descriptions.
static NSString *const kInvalidAuthorizationContextDescription = @"Invalid Authroization Context.";
static NSString *const kTokenNotFoundDescription = @"Token not found in response.";

/** Returns expiration timestamp from JSON response. Will return 0 if expiration is invalid. */
static NSTimeInterval GetExpirationTimestampFromJSONResponse(
    GRSCProviderFieldsDictionary *_Nonnull response) {
  id expirationInMilliseconds = response[kProviderResponseTokenExpirationKey];

  if (expirationInMilliseconds && [expirationInMilliseconds isKindOfClass:[NSNumber class]]) {
    NSTimeInterval expirationInterval = ((NSNumber *)expirationInMilliseconds).doubleValue / 1000.0;
    return expirationInterval;
  }
  return 0;
}

/** Returns an AuthToken object using the token and expiration from the JSON response. */
static GRSCAuthToken *_Nullable GetAuthTokenFromJSONResponse(
    GRSCProviderFieldsDictionary *_Nonnull response, NSError *_Nullable *_Nullable error) {
  NSError *errorToPropagate;
  id token = response[kProviderResponseTokenKey];
  if (!token) {
    errorToPropagate = GRSCError(kTokenNotFoundDescription);
  } else if (![token isKindOfClass:[NSString class]]) {
    errorToPropagate = GRSCError(kGRSCUnexpectedJSONClassTypeErrorDescription);
  } else {
    NSString *tokenString = (NSString *)token;
    NSTimeInterval expiration = GetExpirationTimestampFromJSONResponse(response);
    GRSCAuthToken *authToken = [[GRSCAuthToken alloc] initWithToken:tokenString
                                                         expiration:expiration];
    return authToken;
  }

  if (error) {
    *error = errorToPropagate;
  }

  return nil;
}

/** Returns the full provider URL with the given tripID appended. */
static NSURL *_Nullable GetProviderURLWithTripID(NSString *_Nonnull tripID) {
  NSURL *providerURL = GRSCProviderURLWithPath(kProviderTokenPath);
  return [NSURL URLWithString:tripID relativeToURL:providerURL];
}

@implementation GRSCAuthTokenProvider {
  NSURLSession *_session;
  GRSCAuthToken *_authToken;
  NSString *_lastKnownTripID;
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

- (void)fetchTokenWithContext:(nullable GMTCAuthorizationContext *)authorizationContext
                   completion:(GMTCAuthTokenFetchCompletionHandler)completion {
  // Validate authorization context.
  if (!authorizationContext || !authorizationContext.tripID) {
    NSError *error = GRSCError(kInvalidAuthorizationContextDescription);
    completion(nil, error);
    return;
  }

  // Check if a token is cached and is valid.
  if (_authToken && [_authToken isValid] && _lastKnownTripID &&
      [_lastKnownTripID isEqualToString:authorizationContext.tripID]) {
    completion(_authToken.token, nil);
    return;
  }

  NSURL *requestURL = GetProviderURLWithTripID(authorizationContext.tripID);

  if (!requestURL) {
    completion(nil, GRSCError(kGRSCInvalidRequestURLDescription));
    return;
  }

  NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];

  GRSCProviderResponseHandler tokenResponseHandler =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
          completion(nil, error);
        } else {
          // Process JSON response.
          NSError *JSONError;
          GRSCProviderFieldsDictionary *JSONResponse =
              GRSCGetDictionaryFromJSONData(data, &JSONError);

          if (!JSONResponse || JSONError) {
            completion(nil, JSONError);
          } else {
            _authToken = GetAuthTokenFromJSONResponse(JSONResponse, &JSONError);
            _lastKnownTripID = authorizationContext.tripID;
            completion(_authToken.token, JSONError);
          }
        }
      };

  NSURLSessionDataTask *task = [_session dataTaskWithRequest:request
                                           completionHandler:tokenResponseHandler];
  [task resume];
}

@end
