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

#import <UIKit/UIKit.h>

@class GRSCBottomPanelView;

/**
 * Delegate for events on GRSCBottomPanelView.
 */
@protocol GRSCBottomPanelDelegate <NSObject>

/**
 * Called when the action button is clicked.
 *
 * @param panel The current instance of the bottom panel view.
 * @param button The action button instance that was clicked.
 */
- (void)bottomPanel:(nonnull GRSCBottomPanelView *)panel
    didTapActionButton:(nonnull UIButton *)button;

/**
 * Called when the add intermediate destination button is clicked.
 *
 * @param panel The current instance of the bottom panel view.
 * @param button The add intermediate destination button instance that was clicked.
 */
- (void)bottomPanel:(nonnull GRSCBottomPanelView *)panel
    didTapAddIntermediateDestinationButton:(nonnull UIButton *)button;

/**
 * Called when the Shared trip type switch is toggled.
 *
 * @param panel The current instance of the bottom panel view.
 * @param sharedTripTypeSwitch The shared trip type switch that was toggled.
 */
- (void)bottomPanel:(nonnull GRSCBottomPanelView *)panel
    didToggleSharedTripTypeSwitch:(nonnull UISwitch *)sharedTripTypeSwitch;

@end

/**
 * Class for custom bottom panel UI view.
 */
@interface GRSCBottomPanelView : UIView

/** The delegate to receive events on UI elements.  */
@property(nonatomic, weak, nullable) id<GRSCBottomPanelDelegate> delegate;

/** Button that appears on the bottom of the panel.  */
@property(nonatomic, strong, readonly, nonnull) UIButton *actionButton;

/** UILabel used to display the title for the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *titleLabel;

/** UILabel used to display the trip ID on the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *tripIDLabel;

/** UILabel used to display the ETA on the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *infoLabel;

/** UILabel used to display the Vehicle ID on the panel. */
@property(nonatomic, strong, readonly, nonnull) UILabel *vehicleIDLabel;

/** Button used to add intermediate destinations for a trip. */
@property(nonatomic, strong, readonly, nonnull) UIButton *addIntermediateDestinationButton;

/** StackView used to display the shared trip type switch and associated label. */
@property(nonatomic, strong, readonly, nonnull) UIStackView *sharedTripTypeSwitchContainer;

/** Hides all labels from the panel. */
- (void)hideAllLabels;

/** Displays all labels on the panel. */
- (void)showAllLabels;

@end
