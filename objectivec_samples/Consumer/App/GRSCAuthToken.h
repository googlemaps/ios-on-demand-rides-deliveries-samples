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

#import <Foundation/Foundation.h>

/**
 * A class used to represent an auth token.
 */
@interface GRSCAuthToken : NSObject

/**
 * Initializes and returns a GRSCAuthToken object using the provided token and expiration.
 *
 * @param token The string representation of the token.
 * @param expiration The interval after which the token will expire.
 */
- (nonnull instancetype)initWithToken:(nullable NSString *)token
                           expiration:(NSTimeInterval)expiration NS_DESIGNATED_INITIALIZER;

/**
 * Use @c initWithToken:expiration instead.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/** String representing the token. */
@property(nonatomic, strong, readonly, nullable) NSString *token;

/**
 * Checks that the AuthToken is Valid. A valid AuthToken is one that has a token
 * which is not expired.
 *
 * @return Whether the AuthToken is valid.
 */
- (BOOL)isValid;

@end
