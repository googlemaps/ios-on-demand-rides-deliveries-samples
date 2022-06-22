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

#import "GRSDEditVehicleTableViewController.h"
#import "GRSDProviderService.h"

static NSString *const kEditVehicleTitle = @"Edit Vehicle";

static const NSInteger kNumberOfSections = 3;

// TableView Section Titles.
static NSString *const kSupportedTripTypesSectionTitle = @"SUPPORTED TRIP TYPES";
static NSString *const kMaximumCapacitySectionTitle = @"MAXIMUM CAPACITY";

// TableView Cell Identifiers.
static NSString *const kSupportedTripTypesCellID = @"SupportedTripTypesCell";
static NSString *const kMaximumCapacityCellID = @"MaximumCapacityCell";
static NSString *const kBackToBackEnabledCellID = @"BackToBackEnabledCell";

// Cell Text for the different trip types.
static NSString *const kExclusiveTripTypeCellText = @"Exclusive";
static NSString *const kSharedTripTypeCellText = @"Shared";

static NSString *const kBackToBackSwitchLabelText = @"Back to Back Rides";

/** An enumeration of the edit vehicle table view sections. */
typedef NS_ENUM(NSInteger, EditVehicleTableViewSection) {
  EditVehicleTableViewSectionSupportedTripTypes = 0,
  EditVehicleTableViewSectionMaximumCapacity,
  EditVehicleTableViewSectionBackToBackEnabled,
};

/** Custom table view cell used to edit the maximum capacity of a vehicle. */
@interface VehicleMaximumCapacityTableViewCell : UITableViewCell

/** The slider used to specify the maximum capacity. */
@property(nonatomic) UISlider *slider;

@end

/** Custom table view cell used to edit whether the vehicle supports back to back trips. */
@interface VehicleIsBackToBackTableViewCell : UITableViewCell

/** The switch used to toggle whether back to back is enabled. */
@property(nonatomic) UISwitch *isBackToBackEnabledSwitch;

@end

@interface GRSDEditVehicleTableViewController ()
@end

@implementation GRSDEditVehicleTableViewController {
  GRSDVehicleModel *_defaultVehicleModel;
  ProviderSupportedTripType _selectedTripTypes;
  NSUInteger _selectedMaximumCapacity;
  BOOL _selectedIsBackToBackEnabled;
}

- (instancetype)initWithVehicleModel:(GRSDVehicleModel *)vehicleModel {
  self = [super initWithStyle:UITableViewStyleInsetGrouped];
  if (self) {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _defaultVehicleModel = vehicleModel;
    _selectedTripTypes = vehicleModel.supportedTripTypes;
    _selectedMaximumCapacity = vehicleModel.maximumCapacity;
    _selectedIsBackToBackEnabled = vehicleModel.isBackToBackEnabled;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                           target:self
                           action:@selector(didTapNavigationBarButtonCancel)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                           target:self
                           action:@selector(didTapNavigationBarButtonSave)];
  self.navigationItem.title = kEditVehicleTitle;
  [self.tableView registerClass:[UITableViewCell class]
         forCellReuseIdentifier:kSupportedTripTypesCellID];
  [self.tableView registerClass:[VehicleMaximumCapacityTableViewCell class]
         forCellReuseIdentifier:kMaximumCapacityCellID];
  [self.tableView registerClass:[VehicleIsBackToBackTableViewCell class]
         forCellReuseIdentifier:kBackToBackEnabledCellID];
}

- (void)didTapNavigationBarButtonSave {
  GRSDVehicleModel *updatedVehicleModel =
      [[GRSDVehicleModel alloc] initWithVehicleID:_defaultVehicleModel.vehicleID
                                  maximumCapacity:_selectedMaximumCapacity
                               supportedTripTypes:_selectedTripTypes
                              isBackToBackEnabled:_selectedIsBackToBackEnabled];
  if (![updatedVehicleModel isEqual:_defaultVehicleModel]) {
    [_delegate editVehicleTableViewController:self didChangeVehicleFields:updatedVehicleModel];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didTapNavigationBarButtonCancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateTripTypeCell:(UITableViewCell *)tripTypeCell atIndexPath:(NSIndexPath *)indexPath {
  tripTypeCell.accessoryType = UITableViewCellAccessoryNone;
  switch (indexPath.row) {
    case 0:  // Exclusive Trip Type.
      tripTypeCell.textLabel.text = kExclusiveTripTypeCellText;
      tripTypeCell.accessoryType = _selectedTripTypes & ProviderSupportedTripTypeExclusive
                                       ? UITableViewCellAccessoryCheckmark
                                       : UITableViewCellAccessoryNone;
      if (_selectedTripTypes & ProviderSupportedTripTypeExclusive) {
        tripTypeCell.accessoryType = UITableViewCellAccessoryCheckmark;
      }
      break;
    case 1:  // Shared Trip Type.
      tripTypeCell.textLabel.text = kSharedTripTypeCellText;
      tripTypeCell.accessoryType = _selectedTripTypes & ProviderSupportedTripTypeShared
                                       ? UITableViewCellAccessoryCheckmark
                                       : UITableViewCellAccessoryNone;
      break;
  }
}

- (void)updateMaximumCapacityCell:(VehicleMaximumCapacityTableViewCell *)maximumCapacityCell {
  UISlider *slider = maximumCapacityCell.slider;
  slider.minimumValue = 1.f;
  slider.maximumValue = 6.f;
  slider.value = _selectedMaximumCapacity;
  [slider addTarget:self
                action:@selector(maximumCapacitySliderChanged:)
      forControlEvents:UIControlEventValueChanged];
}

- (void)maximumCapacitySliderChanged:(UISlider *)slider {
  _selectedMaximumCapacity = ceil(slider.value);
  [self.tableView headerViewForSection:EditVehicleTableViewSectionMaximumCapacity].textLabel.text =
      [self maximumCapacitySectionTitle];
}

- (NSString *)maximumCapacitySectionTitle {
  return [NSString
      stringWithFormat:@"%@: %ld", kMaximumCapacitySectionTitle, (long)_selectedMaximumCapacity];
}

- (void)updateBackToBackCell:(VehicleIsBackToBackTableViewCell *)backToBackCell {
  UISwitch *backToBackSwitch = backToBackCell.isBackToBackEnabledSwitch;
  [backToBackSwitch setOn:_selectedIsBackToBackEnabled];
  [backToBackSwitch addTarget:self
                       action:@selector(didBackToBackDriverSwitchChange:)
             forControlEvents:UIControlEventValueChanged];
}

- (void)didBackToBackDriverSwitchChange:(UISwitch *)isBackToBackDriverSwitch {
  _selectedIsBackToBackEnabled = isBackToBackDriverSwitch.isOn;
}

#pragma mark - UITableViewControllerDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;
  switch (indexPath.section) {
    case EditVehicleTableViewSectionSupportedTripTypes:
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:kSupportedTripTypesCellID];
      [self updateTripTypeCell:cell atIndexPath:indexPath];
      break;
    case EditVehicleTableViewSectionMaximumCapacity:
      cell = [[VehicleMaximumCapacityTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:kMaximumCapacityCellID];
      [self updateMaximumCapacityCell:(VehicleMaximumCapacityTableViewCell *)cell];
      break;
    case EditVehicleTableViewSectionBackToBackEnabled:
      cell = [[VehicleIsBackToBackTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:kBackToBackEnabledCellID];
      [self updateBackToBackCell:(VehicleIsBackToBackTableViewCell *)cell];
      break;
  }
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case EditVehicleTableViewSectionSupportedTripTypes:
      return kSupportedTripTypesSectionTitle;
    case EditVehicleTableViewSectionMaximumCapacity:
      return [self maximumCapacitySectionTitle];
    default:
      return nil;
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case EditVehicleTableViewSectionSupportedTripTypes:
      return 2;
    case EditVehicleTableViewSectionMaximumCapacity:
    case EditVehicleTableViewSectionBackToBackEnabled:
      return 1;
    default:
      return 0;
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return kNumberOfSections;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (indexPath.section == EditVehicleTableViewSectionSupportedTripTypes) {
    selectedCell.accessoryType = selectedCell.accessoryType == UITableViewCellAccessoryNone
                                     ? UITableViewCellAccessoryCheckmark
                                     : UITableViewCellAccessoryNone;
    _selectedTripTypes ^=
        (indexPath.row == 0 ? ProviderSupportedTripTypeExclusive : ProviderSupportedTripTypeShared);
  }
}

@end

@implementation VehicleMaximumCapacityTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    _slider = [[UISlider alloc] initWithFrame:CGRectZero];
    _slider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_slider];
    UILayoutGuide *cellMargins = self.layoutMarginsGuide;
    [_slider.topAnchor constraintEqualToAnchor:cellMargins.topAnchor].active = YES;
    [_slider.bottomAnchor constraintEqualToAnchor:cellMargins.bottomAnchor].active = YES;
    [_slider.leadingAnchor constraintEqualToAnchor:cellMargins.leadingAnchor].active = YES;
    [_slider.trailingAnchor constraintEqualToAnchor:cellMargins.trailingAnchor].active = YES;
  }
  return self;
}
@end

@implementation VehicleIsBackToBackTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    _isBackToBackEnabledSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    UILabel *switchLabel = [[UILabel alloc] init];
    switchLabel.text = kBackToBackSwitchLabelText;
    UIStackView *switchContainer =
        [[UIStackView alloc] initWithArrangedSubviews:@[ switchLabel, _isBackToBackEnabledSwitch ]];
    switchContainer.alignment = UIStackViewAlignmentCenter;
    [self.contentView addSubview:switchContainer];
    switchContainer.translatesAutoresizingMaskIntoConstraints = NO;
    UILayoutGuide *cellMargins = self.layoutMarginsGuide;
    [switchContainer.topAnchor constraintEqualToAnchor:cellMargins.topAnchor].active = YES;
    [switchContainer.bottomAnchor constraintEqualToAnchor:cellMargins.bottomAnchor].active = YES;
    [switchContainer.leadingAnchor constraintEqualToAnchor:cellMargins.leadingAnchor].active = YES;
    [switchContainer.trailingAnchor constraintEqualToAnchor:cellMargins.trailingAnchor].active =
        YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return self;
}

@end
