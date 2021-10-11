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
 * Font size for small content.
 */
FOUNDATION_EXTERN CGFloat GRSCStyleSmallFontSize(void);

/**
 * Font size for medium content.
 */
FOUNDATION_EXTERN CGFloat GRSCStyleMediumFontSize(void);

/**
 * Color for default state in buttons
 */
FOUNDATION_EXTERN UIColor *_Nonnull GRSCStyleDefaultButtonColor(void);

/**
 * Light color for static text.
 */
FOUNDATION_EXTERN UIColor *_Nonnull GRSCStyleLightTextColor(void);

/**
 * Default color for polylines.
 */
FOUNDATION_EXTERN UIColor *_Nonnull GRSCStyleDefaultPolylineStokeColor(void);

/**
 * Color for normal traffic speed type.
 */
FOUNDATION_EXTERN UIColor *_Nonnull GRSCStyleTrafficPolylineSpeedTypeNormalColor(void);

/**
 * Color for slow traffic speed type.
 */
FOUNDATION_EXTERN UIColor *_Nonnull GRSCStyleTrafficPolylineSpeedTypeSlowColor(void);

/**
 * Color for traffic jam speed type.
 */
FOUNDATION_EXTERN UIColor *_Nonnull GRSCStyleTrafficPolylineSpeedTypeJamColor(void);

/**
 * Color for no-data speed type.
 */
FOUNDATION_EXTERN UIColor *_Nonnull GRSCStyleTrafficPolylineSpeedTypeNoDataColor(void);

/**
 * Small height for the bottom panel.
 */
FOUNDATION_EXTERN CGFloat GRSCBottomPanelHeightSmall(void);

/**
 * Medium height for the bottom panel.
 */
FOUNDATION_EXTERN CGFloat GRSCBottomPanelHeightMedium(void);

/**
 * Large height for the bottom panel.
 */
FOUNDATION_EXTERN CGFloat GRSCBottomPanelHeightLarge(void);

/**
 * Default padding for the mapview camera.
 */
FOUNDATION_EXTERN UIEdgeInsets GRSCStyleDefaulMapViewCameraPadding(void);
