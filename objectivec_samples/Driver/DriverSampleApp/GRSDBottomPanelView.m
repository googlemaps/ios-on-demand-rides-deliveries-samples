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

#import "GRSDBottomPanelView.h"

// UI and styling constants.
static const CGFloat kPanelMargin = 16.0f;
static const CGFloat kPanelSpacing = 14.0f;
static const CGFloat kDefaultFontSize = 18.0f;
static const CGFloat kSubtitleFontSize = 14.0f;
static const CGFloat kButtonHeight = 48.0f;
static const CGFloat kButtonCornerRadius = 18.0f;
static UIColor *SubtitleColor(void) {
  return [UIColor colorWithRed:117 / 255.0 green:117 / 255.0 blue:117 / 255.0 alpha:1];
}

/** Returns a styled button to be used for the panel. */
static UIButton *CreateActionButton(void) {
  UIButton *button = [[UIButton alloc] init];
  button.backgroundColor = UIColor.grayColor;
  button.layer.cornerRadius = kButtonCornerRadius;
  button.titleLabel.textAlignment = NSTextAlignmentCenter;
  button.titleLabel.font = [UIFont systemFontOfSize:kDefaultFontSize weight:UIFontWeightMedium];
  [button setTitleColor:UIColor.darkTextColor forState:UIControlStateHighlighted];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  return button;
}

/** Returns a styled label to be used for the panel title. */
static UILabel *CreateTitleLabel(void) {
  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.font = [UIFont boldSystemFontOfSize:kDefaultFontSize];
  titleLabel.numberOfLines = 0;
  return titleLabel;
}

/** Returns a styled label to be used for displaying a trip ID in the panel. */
static UILabel *CreateTripIDLabel(void) {
  UILabel *subtitleLabel = [[UILabel alloc] init];
  subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  subtitleLabel.font = [UIFont systemFontOfSize:kSubtitleFontSize];
  subtitleLabel.textColor = SubtitleColor();
  subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
  subtitleLabel.numberOfLines = 0;
  return subtitleLabel;
}

@implementation GRSDBottomPanelView

- (instancetype)initWithTitle:(NSString *)title
                  buttonTitle:(NSString *)buttonTitle
                 buttonTarget:(id)buttonTarget
                 buttonAction:(SEL)buttonAction {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.backgroundColor = UIColor.whiteColor;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    self.axis = UILayoutConstraintAxisVertical;
    self.spacing = kPanelSpacing;
    self.distribution = UIStackViewDistributionEqualSpacing;
    self.layoutMargins = UIEdgeInsetsMake(kPanelMargin, kPanelMargin, kPanelMargin, kPanelMargin);
    self.layoutMarginsRelativeArrangement = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    _titleLabel = CreateTitleLabel();
    _titleLabel.text = title;
    _tripIDLabel = CreateTripIDLabel();
    _nextTripIDLabel = CreateTripIDLabel();
    _nextTripIDLabel.hidden = YES;
    _actionButton = CreateActionButton();
    [_actionButton.heightAnchor constraintEqualToConstant:kButtonHeight].active = YES;
    [_actionButton addTarget:buttonTarget
                      action:buttonAction
            forControlEvents:UIControlEventTouchUpInside];
    [_actionButton setTitle:[buttonTitle copy] forState:UIControlStateNormal];

    [self addArrangedSubview:_titleLabel];
    [self addArrangedSubview:_tripIDLabel];
    [self addArrangedSubview:_nextTripIDLabel];
    [self addArrangedSubview:_actionButton];
  }
  return self;
}

@end
