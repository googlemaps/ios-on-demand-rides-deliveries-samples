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

#import "GRSCBottomPanelView.h"
#import "GRSCBottomPanelViewConstants.h"
#import "GRSCStyle.h"

// UI view style constants.
static const CGFloat kHeaderContentViewTopOffset = 16.0f;
static const CGFloat kLabelContentViewTopOffset = 10.0f;

// Add Intermediate Destination image name.
static NSString *const kAddIntermediateDestinationImageName = @"grc_ic_add";

/** Creates a UIButton with style attributes. */
static UIButton *CreateActionButton(void) {
  UIButton *button = [[UIButton alloc] init];
  button.backgroundColor = GRSCStyleDefaultButtonColor();
  button.layer.cornerRadius = 18;
  [button.titleLabel setTextAlignment:NSTextAlignmentCenter];
  [button setTitleColor:UIColor.darkTextColor forState:UIControlStateHighlighted];
  return button;
}

/** Creates a UIButton used to add intermediate destinations. */
static UIButton *CreateAddIntermediateDestinationButton(void) {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  UIImage *addIntermediateDestinationImage =
      [[UIImage imageNamed:kAddIntermediateDestinationImageName]
          imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [button setImage:addIntermediateDestinationImage forState:UIControlStateNormal];
  button.tintColor = GRSCStyleDefaultButtonColor();
  button.translatesAutoresizingMaskIntoConstraints = NO;
  return button;
}

/** Creates a vertical stackview with style attributes. */
static UIStackView *CreateVerticalStackView(void) {
  UIStackView *stackView = [[UIStackView alloc] init];
  stackView.axis = UILayoutConstraintAxisVertical;
  stackView.distribution = UIStackViewDistributionFill;
  stackView.alignment = UIStackViewAlignmentLeading;
  stackView.spacing = 5;
  return stackView;
}

/** Creates a title stackview with style attributes. */
static UIStackView *CreateTitleStackView(void) {
  UIStackView *stackView = [[UIStackView alloc] init];
  stackView.axis = UILayoutConstraintAxisHorizontal;
  stackView.alignment = UIStackViewAlignmentCenter;
  return stackView;
}

/** Creates a UILabel with style attributes. */
static UILabel *CreateUILabel(void) {
  UILabel *label = [[UILabel alloc] init];
  label.font = [UIFont systemFontOfSize:GRSCStyleSmallFontSize()];
  label.textColor = GRSCStyleLightTextColor();
  label.hidden = YES;
  label.numberOfLines = 0;
  return label;
}

/** Creates a @c UISwitch for enabling Shared trip type. */
static UISwitch *CreateSharedTripTypeSwitch(void) {
  UISwitch *tripTypeSwitch = [[UISwitch alloc] init];
  [tripTypeSwitch setOn:NO];
  return tripTypeSwitch;
}

/** Creates a @c UILabel for the Shared trip type. */
static UILabel *CreateSharedTripTypeLabel(void) {
  UILabel *label = [[UILabel alloc] init];
  label.font = [UIFont systemFontOfSize:GRSCStyleMediumFontSize()];
  label.numberOfLines = 0;
  label.text = GRSCBottomPanelSharedTripTypeLabelText;
  return label;
}

/** Creates a @c UIStackView for the Shared trip type switch and label. */
static UIStackView *CreateSharedTripTypeContainer(void) {
  UIStackView *container = [[UIStackView alloc] init];
  container.alignment = UIStackViewAlignmentCenter;
  container.hidden = YES;
  container.distribution = UIStackViewDistributionFill;
  return container;
}

@implementation GRSCBottomPanelView

- (instancetype)init {
  self = [super init];

  if (self) {
    self.backgroundColor = UIColor.whiteColor;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    _actionButton = CreateActionButton();
    _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_actionButton];
    [_actionButton.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:.85].active =
        YES;
    [_actionButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
    [_actionButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-50].active =
        YES;
    [_actionButton addTarget:self
                      action:@selector(didTapActionButton:)
            forControlEvents:UIControlEventTouchUpInside];

    // Add header view for title and info labels.
    UIStackView *headerView = CreateVerticalStackView();
    [self addSubview:headerView];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView.topAnchor constraintEqualToAnchor:self.topAnchor
                                         constant:kHeaderContentViewTopOffset]
        .active = YES;
    [headerView.leadingAnchor constraintEqualToAnchor:_actionButton.leadingAnchor].active = YES;
    [headerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;

    UIStackView *titleStackView = CreateTitleStackView();
    [headerView addArrangedSubview:titleStackView];
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:GRSCStyleMediumFontSize()];
    _titleLabel.hidden = YES;
    titleStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [titleStackView.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor].active = YES;
    [titleStackView.trailingAnchor constraintEqualToAnchor:_actionButton.trailingAnchor].active =
        YES;
    [titleStackView addArrangedSubview:_titleLabel];

    _addIntermediateDestinationButton = CreateAddIntermediateDestinationButton();
    [_addIntermediateDestinationButton addTarget:self
                                          action:@selector(didTapAddIntermediateDestinationButton:)
                                forControlEvents:UIControlEventTouchUpInside];
    _addIntermediateDestinationButton.hidden = YES;
    [titleStackView addArrangedSubview:_addIntermediateDestinationButton];

    UISwitch *sharedTripTypeSwitch = CreateSharedTripTypeSwitch();
    UILabel *switchLabel = CreateSharedTripTypeLabel();
    [sharedTripTypeSwitch addTarget:self
                             action:@selector(didToggleSharedTripTypeSwitch:)
                   forControlEvents:UIControlEventValueChanged];

    _sharedTripTypeSwitchContainer = CreateSharedTripTypeContainer();
    [_sharedTripTypeSwitchContainer addArrangedSubview:switchLabel];
    [_sharedTripTypeSwitchContainer addArrangedSubview:sharedTripTypeSwitch];

    [titleStackView addArrangedSubview:_sharedTripTypeSwitchContainer];

    _infoLabel = CreateUILabel();
    _infoLabel.font = [UIFont systemFontOfSize:GRSCStyleMediumFontSize() weight:UIFontWeightMedium];
    [headerView addArrangedSubview:_infoLabel];

    // Add content view for trip ID and vehicle ID labels.
    UIStackView *labelContentView = CreateVerticalStackView();
    [self addSubview:labelContentView];
    labelContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [labelContentView.topAnchor constraintEqualToAnchor:headerView.bottomAnchor
                                               constant:kLabelContentViewTopOffset]
        .active = YES;
    [labelContentView.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor].active = YES;
    [labelContentView.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor].active =
        YES;

    _tripIDLabel = CreateUILabel();
    [labelContentView addArrangedSubview:_tripIDLabel];

    _vehicleIDLabel = CreateUILabel();
    [labelContentView addArrangedSubview:_vehicleIDLabel];
  }
  return self;
}

- (void)didTapActionButton:(UIButton *)sender {
  [self.delegate bottomPanel:self didTapActionButton:sender];
}

- (void)didTapAddIntermediateDestinationButton:(UIButton *)sender {
  [self.delegate bottomPanel:self didTapAddIntermediateDestinationButton:sender];
}

- (void)didToggleSharedTripTypeSwitch:(UISwitch *)sharedTripTypeSwitch {
  [self.delegate bottomPanel:self didToggleSharedTripTypeSwitch:sharedTripTypeSwitch];
}

- (void)hideAllLabels {
  _titleLabel.hidden = YES;
  _infoLabel.hidden = YES;
  _tripIDLabel.hidden = YES;
  _vehicleIDLabel.hidden = YES;
}

- (void)showAllLabels {
  _titleLabel.hidden = NO;
  _infoLabel.hidden = NO;
  _tripIDLabel.hidden = NO;
  _vehicleIDLabel.hidden = NO;
}

@end
