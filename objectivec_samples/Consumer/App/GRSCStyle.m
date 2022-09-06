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

#import "GRSCStyle.h"

static const CGFloat kCameraBoundsPadding = 48.0f;

CGFloat GRSCStyleSmallFontSize(void) { return 14.0; }

CGFloat GRSCStyleMediumFontSize(void) { return 18.0; }

UIColor *GRSCStyleDefaultButtonColor(void) {
  return [UIColor colorWithRed:113 / 255.0 green:131 / 255.0 blue:148 / 255.0 alpha:1];
}

UIColor *GRSCStyleLightTextColor(void) {
  return [UIColor colorWithRed:117 / 255.0 green:117 / 255.0 blue:117 / 255.0 alpha:1];
}

UIColor *GRSCStyleDefaultPolylineStokeColor(void) {
  return [UIColor colorWithRed:69 / 255.0 green:151 / 255.0 blue:1.0 alpha:1];
}

UIColor *GRSCStyleTrafficPolylineSpeedTypeNormalColor(void) {
  return [UIColor colorWithRed:44 / 255.0 green:153 / 255.0 blue:255 / 255.0 alpha:1.0];
}

UIColor *GRSCStyleTrafficPolylineSpeedTypeSlowColor(void) { return [UIColor yellowColor]; }

UIColor *GRSCStyleTrafficPolylineSpeedTypeJamColor(void) { return [UIColor redColor]; }

UIColor *GRSCStyleTrafficPolylineSpeedTypeNoDataColor(void) { return [UIColor grayColor]; }

UIEdgeInsets GRSCStyleDefaultMapViewCameraPadding(void) {
  return UIEdgeInsetsMake(kCameraBoundsPadding, kCameraBoundsPadding, kCameraBoundsPadding,
                          kCameraBoundsPadding);
}

CGFloat GRSCBottomPanelHeightSmall(void) { return 15.0f; }
CGFloat GRSCBottomPanelHeightMedium(void) { return 85.0f; }
CGFloat GRSCBottomPanelHeightLarge(void) { return 145.0f; }
