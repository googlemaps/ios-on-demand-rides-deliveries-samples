/*
 * Copyright 2022 Google LLC. All rights reserved.
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
#import "GRSDVehicleModel.h"

NS_ASSUME_NONNULL_BEGIN

@class GRSDEditVehicleTableViewController;

/** Protocol for responding to vehicle field changes. */
@protocol GRSDEditVehicleTableViewControllerDelegate

/**
 * Called when the vehicle fields have changed.
 *
 * @param controller The current instance of the edit vehicle controller.
 * @param vehicleModel The vehicle model with updated vehicle fields.
 */
- (void)editVehicleTableViewController:(GRSDEditVehicleTableViewController *)controller
                didChangeVehicleFields:(GRSDVehicleModel *)vehicleModel;

@end

/** Controller used to edit vehicle fields. */
@interface GRSDEditVehicleTableViewController
    : UITableViewController <UITableViewDataSource, UITableViewDelegate>

/** Delegate to notify after vehicle fields have changed. */
@property(nonatomic, weak, nullable) id<GRSDEditVehicleTableViewControllerDelegate> delegate;

/**
 * Initializes an instance of this class.
 *
 * @param vehicleModel Default values for the vehicle fields.
 */
- (instancetype)initWithVehicleModel:(GRSDVehicleModel *)vehicleModel;

@end

NS_ASSUME_NONNULL_END
