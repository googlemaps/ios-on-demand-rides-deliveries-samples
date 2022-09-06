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
#import <objc/runtime.h>
#import <GoogleRidesharingConsumer/GoogleRidesharingConsumer.h>
#import "GRSCBottomPanelView.h"
#import "GRSCBottomPanelViewConstants.h"
#import "GRSCLocationSelectionService.h"
#import "GRSCMapViewController+LocationSelection.h"
#import "GRSCProviderService.h"
#import "GRSCStringUtils.h"
#import "GRSCStyle.h"
#import "GRSCUtils.h"

/** Location selection service used to manage request/response of the Location Selection API. */
static GRSCLocationSelectionService *gLocationSelectionService = nil;

@implementation GRSCMapViewController (LocationSelection)

@dynamic locationSelectionPickupPoint;
@dynamic locationSelectionPickupPointMarker;

- (void)setLocationSelectionPickupPoint:(GMTSTerminalLocation *)locationSelectionPickupPoint {
  objc_setAssociatedObject(self, @selector(locationSelectionPickupPoint),
                           locationSelectionPickupPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (GMTSTerminalLocation *)locationSelectionPickupPoint {
  return objc_getAssociatedObject(self, @selector(locationSelectionPickupPoint));
}

- (void)setLocationSelectionPickupPointMarker:
    (GMTSTerminalLocation *)locationSelectionPickupPointMarker {
  objc_setAssociatedObject(self, @selector(locationSelectionPickupPointMarker),
                           locationSelectionPickupPointMarker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (GMSMarker *)locationSelectionPickupPointMarker {
  return objc_getAssociatedObject(self, @selector(locationSelectionPickupPointMarker));
}

- (void)startLocationSelectionWithPickupLocation:(nonnull GMTSTerminalLocation *)pickupLocation
                                      completion:
                                          (nonnull GRSCStartLocationSelectionCompletionHandler)
                                              completion {
  // Get pickup point from the Location Selection API.
  gLocationSelectionService = [[GRSCLocationSelectionService alloc] init];
  [gLocationSelectionService
      getLocationSelectionPickupPointWithSearchLocation:pickupLocation
                                             completion:^(
                                                 GMTSLatLng
                                                     *_Nullable locationSelectionPickupPointLatLng,
                                                 NSNumber
                                                     *_Nullable locationSelectionWalkingDistance,
                                                 NSError *_Nullable error) {
                                               if (error) {
                                                 NSLog(@"Failed to get the Location Selection API "
                                                       @"response with error:%@",
                                                       error.description);
                                                 [self locationSelectionFailed];
                                                 completion(error);
                                                 return;
                                               }
                                               double locationSelectionWalkingDistanceDouble =
                                                   [locationSelectionWalkingDistance doubleValue];
                                               [self
                                                   showLocationSelectionPickupPointWithLatLng:
                                                       locationSelectionPickupPointLatLng
                                                                              walkingDistance:
                                                                                  locationSelectionWalkingDistanceDouble];
                                               completion(nil);
                                             }];
}

/** Shows pickup point in the map view and displays pickup point confirmation. */
- (void)showLocationSelectionPickupPointWithLatLng:(GMTSLatLng *)locationSelectionPickupPointLatLng
                                   walkingDistance:(double)locationSelectionWalkingDistance {
  self.locationSelectionPickupPoint =
      GMTSTerminalLocationFromPoint(locationSelectionPickupPointLatLng);
  [self
      startConfirmPickupPointWithLocationSelectionWalkingDistance:locationSelectionWalkingDistance];
  [self showSelectedPickupLocationInMapView];
  [self showLocationSelectionPickupPointInMapView];
}

/**
 * The location selection failure state. Displays failure of getting the location selection pickup
 * point due to bad pickup selection.
 */
- (void)locationSelectionFailed {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    NSAttributedString *pickupSelectionText = GRSCGetPartlyBoldAttributedString(
        GRSCBottomPanelLocationSelectionFailedTitleText, GRSCBottomPanelPickupLocationText,
        self.bottomPanel.titleLabel.font.pointSize);
    self.bottomPanel.titleLabel.hidden = NO;
    [self.bottomPanel.titleLabel setAttributedText:pickupSelectionText];
    [self.bottomPanel.actionButton setTitle:GRSCBottomPanelConfirmPickupButtonText
                                   forState:UIControlStateNormal];
  });
}

/** Displays location selection pickup point confirmation. */
- (void)startConfirmPickupPointWithLocationSelectionWalkingDistance:
    (double)locationSelectionWalkingDistance {
  NSString *bottomPanelLocationSelectionPickupPointTitleTextMiddle =
      [NSString stringWithFormat:@"%.2f", locationSelectionWalkingDistance];
  NSString *bottomPanelLocationSelectionPickupPointTitleText = [NSString
      stringWithFormat:@"%@%@%@", GRSCBottomPanelLocationSelectionPickupPointTitleTextHead,
                       bottomPanelLocationSelectionPickupPointTitleTextMiddle,
                       GRSCBottomPanelLocationSelectionPickupPointTitleTextTail];
  NSAttributedString *locationSelectionPickupPointText = GRSCGetPartlyBoldAttributedString(
      bottomPanelLocationSelectionPickupPointTitleText, GRSCBottomPanelPickupPointText,
      self.bottomPanel.titleLabel.font.pointSize);

  [self.bottomPanel.titleLabel setAttributedText:locationSelectionPickupPointText];
  [self.bottomPanel.actionButton setTitle:GRSCBottomPanelConfirmPickupPointButtonText
                                 forState:UIControlStateNormal];
}

/** Shows the location selection pickup point in the map view. */
- (void)showLocationSelectionPickupPointInMapView {
  CLLocationCoordinate2D pickupPointPosition = [self.locationSelectionPickupPoint.point coordinate];
  self.locationSelectionPickupPointMarker = [GMSMarker markerWithPosition:pickupPointPosition];
  self.locationSelectionPickupPointMarker.icon = [UIImage imageNamed:@"grc_ic_pickup_selected"];
  self.locationSelectionPickupPointMarker.map = self.mapView;
}

/** Shows the pickup location selected by the user in the map view. */
- (void)showSelectedPickupLocationInMapView {
  CLLocationCoordinate2D selectedPickupPointPosition =
      [self.waypointSelector.selectedPickupLocation.point coordinate];
  self.pickupMarker = [GMSMarker markerWithPosition:selectedPickupPointPosition];
  self.pickupMarker.icon = [UIImage imageNamed:@"grc_ic_wait_pickup_marker"];
  self.pickupMarker.map = self.mapView;
}

@end
