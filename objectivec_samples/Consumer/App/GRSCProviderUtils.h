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
 * Description for the GRSC unexpected JSON class type error.
 */
FOUNDATION_EXTERN NSString *_Nonnull const kGRSCUnexpectedJSONClassTypeErrorDescription;

/**
 * Description for the GRSC invalid request error.
 */
FOUNDATION_EXTERN NSString *_Nonnull const kGRSCInvalidRequestURLDescription;

/**
 * Handler type definition used to process responses from the provider server.
 *
 * @param data The data returned by the provider server. Will be nil if the server returns no data.
 * @param response The response from the provider server which includes response headers and
 * other metadata. Will be nil if request fails.
 * @param error The error that occurs when processing the response from the provider. Will be nil if
 * the request succeeds.
 */
typedef void (^GRSCProviderResponseHandler)(NSData *_Nullable data,
                                            NSURLResponse *_Nullable response,
                                            NSError *_Nullable error);

/**
 * Type definition for commonly used dictionary containing provider server fields.
 */
typedef NSDictionary<NSString *, id> GRSCProviderFieldsDictionary;

/**
 * Type definition for commonly used mutable dictionary containing provider server fields.
 */
typedef NSMutableDictionary<NSString *, id> GRSCProviderFieldsMutableDictionary;

/**
 * Returns an instance of NSError with given description.
 *
 * @param description The description for the error.
 */
NSError *_Nonnull GRSCError(NSString *_Nonnull description);

/**
 * Returns an instance of NSURL with the base provider URL and given path. Returns nil if URL is
 * malformed.
 *
 * @param path The path representing the endpoint on the provider.
 */
NSURL *_Nullable GRSCProviderURLWithPath(NSString *_Nonnull path);

/**
 * Returns a dictionary from the given data object. Will return nil if the data is invalid or cannot
 * be serialized to a JSON dictionary.
 *
 * @param data The data object containing JSON serializable data.
 * @param error The error that will be set on failure.
 *
 */
GRSCProviderFieldsDictionary *_Nullable GRSCGetDictionaryFromJSONData(
    NSData *_Nonnull data, NSError *_Nullable *_Nullable error);
