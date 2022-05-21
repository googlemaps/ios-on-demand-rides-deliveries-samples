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
#import <UIKit/UIKit.h>

/**
 * Creates Text that is partly bold.
 *
 * @param fullString The string containing both the regular section and the section to be bolded.
 * @param substringToBold The substring containing the section of the fullString to be bolded.
 * @param fontSize The font size for the resulting string.
 *
 * @return An attributed String which is composed of the @c fullString with the @c substringToBold
 * substring bolded. Will return the @c fullString without applying any attributes if
 * @c substringToBold is not a valid substring in @c fullString.
 */

NSAttributedString *_Nonnull GRSCGetPartlyBoldAttributedString(NSString *_Nonnull fullString,
                                                               NSString *_Nonnull substringToBold,
                                                               CGFloat fontSize);

/**
 * Creates a string representation of the ETA from given distance and time to arrival.
 *
 * @param timestamp The interval representing the timestamp to arrival in seconds.
 * @param distance The distance from the destination in meters.
 *
 * @return Formatted string composed of the time and distance in ETA format. Time in minutes
 * and distance in miles.
 */
NSString *_Nonnull GRSCGetETAFormattedString(NSTimeInterval timestamp, int32_t distance);
