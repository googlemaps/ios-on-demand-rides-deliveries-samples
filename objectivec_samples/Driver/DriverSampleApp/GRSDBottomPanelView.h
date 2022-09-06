/*
 * Copyright 2020 Google LLC. All rights reserved.
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Class for the bottom panel UI view which includes a title, subtitle, and a button. This view is
 * currently used to display information regarding the current trip for the driver.
 */
@interface GRSDBottomPanelView : UIStackView

/**
 * Initialize by passing the panel title and button attributes.
 *
 * @param title The title for the panel.
 * @param buttonTitle The title for the button.
 * @param buttonTarget The target to be used for the button.
 * @param buttonAction The action to be used for the button.
 */
- (instancetype)initWithTitle:(NSString *)title
                  buttonTitle:(NSString *)buttonTitle
                 buttonTarget:(id)buttonTarget
                 buttonAction:(SEL)buttonAction NS_DESIGNATED_INITIALIZER;

/** Use the designated initializer instead. */
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

/** Label used to display the title for the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *titleLabel;

/** Label used to display the trip ID in the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *tripIDLabel;

/** Label used to display the next trip ID for a b2b trip in the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *nextTripIDLabel;

/** Label used to display the vehicle latitude and longitude in the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *locationLabel;

/** Label used to display the vehicle status in the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *statusLabel;

/** Label used to display the vehicle ETA to the next waypoint in the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *etaLabel;

/** Action button located at the bottom of the panel. */
@property(nonatomic, strong, readonly, nonnull) UIButton *actionButton;

@end

NS_ASSUME_NONNULL_END
