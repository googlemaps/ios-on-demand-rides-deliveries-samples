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

#import "GRSCStringUtils.h"

/** Returns whether the given range is valid for the given string. */
static BOOL IsRangeValid(NSRange range, NSString *string) {
  if (range.location == NSNotFound) {
    return NO;
  }

  if ((range.location + range.length) > string.length) {
    return NO;
  }

  return YES;
}

NSAttributedString *_Nonnull GRSCGetPartlyBoldAttributedString(NSString *_Nonnull fullString,
                                                               NSString *_Nonnull substringToBold,
                                                               CGFloat fontSize) {
  NSMutableAttributedString *res = [[NSMutableAttributedString alloc] initWithString:fullString];
  NSRange boldRange = [fullString rangeOfString:substringToBold];

  if (IsRangeValid(boldRange, fullString)) {
    [res addAttribute:NSFontAttributeName
                value:[UIFont boldSystemFontOfSize:fontSize]
                range:boldRange];
  }

  return [res copy];
}

NSString *_Nonnull GRSCGetETAFormattedString(NSTimeInterval timestamp, int32_t distance) {
  NSInteger mins = 0;
  if (timestamp > 0) {
    // Compute time component.
    NSTimeInterval nowTimeIntervalSince1970 = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval delta = timestamp - nowTimeIntervalSince1970;
    long seconds = lroundf(delta);
    mins = (seconds % 3600) / 60;
  }

  double miles = 0;
  if (distance > 0) {
    // Compute distance component.
    NSMeasurement<NSUnitLength *> *distanceInMeters =
        [[NSMeasurement alloc] initWithDoubleValue:distance unit:NSUnitLength.meters];

    NSMeasurement<NSUnitLength *> *distanceInMiles =
        [distanceInMeters measurementByConvertingToUnit:NSUnitLength.miles];
    miles = distanceInMiles.doubleValue;
  }

  return [NSString stringWithFormat:@"%ld mins • %.02f mi", (long)mins, miles];
}
