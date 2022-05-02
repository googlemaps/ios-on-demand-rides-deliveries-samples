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

import SwiftUI

/// A journey sharing view containing `ControlPanelView` as well as `MapViewControllerBridge`.
struct JourneySharingView: View {
  @EnvironmentObject var modelData: ModelData

  private static let notificationIdentifier = "NotificationIdentifier"

  private static let mapViewIdentifier = "MapView"

  var body: some View {
    VStack(alignment: .center) {
      MapViewControllerBridge()
        .edgesIgnoringSafeArea(.all)
        .accessibilityIdentifier(JourneySharingView.mapViewIdentifier)
      ControlPanelView(
        tapButtonAction: tapButtonAction,
        tapAddIntermediateDestinationAction: tapAddIntermediateDestinationAction)
    }
  }

  private func tapButtonAction() {
    switch modelData.customerState {
    case .initial:
      startPickupSelection()
    case .selectingPickup:
      startDropoffSelection()
    case .selectingDropoff:
      startTripPreview()
    case .tripPreview:
      bookTrip()
    case .booking:
      break
    case .journeySharing:
      cancelTrip()
    }
  }

  private func tapAddIntermediateDestinationAction() {
    modelData.intermediateDestinations.append(modelData.dropoffLocation)
    NotificationCenter.default.post(
      name: .intermediateDestinationDidAdd, object: nil,
      userInfo: nil)
  }

  /// Updates UI elements and customer state when the user indicates pickup location.
  private func startPickupSelection() {
    modelData.controlButtonLabel = Strings.controlPanelConfirmPickupButtonText
    modelData.staticLabel = Strings.tripInfoViewStaticText
    modelData.tripInfoLabel = Strings.selectPickupLocationText
    modelData.customerState = .selectingPickup
    NotificationCenter.default.post(
      name: .stateDidChange, object: MapViewController.selectPickupNotificationObjectType,
      userInfo: nil)
  }

  /// Updates UI elements and customer state when the user indicates drop-off location.
  private func startDropoffSelection() {
    modelData.controlButtonLabel = Strings.controlPanelConfirmDropoffButtonText
    modelData.tripInfoLabel = Strings.selectDropoffLocationText
    modelData.staticLabel = Strings.tripInfoViewStaticText
    modelData.customerState = .selectingDropoff
    modelData.intermediateDestinations.removeAll()
    NotificationCenter.default.post(
      name: .stateDidChange, object: MapViewController.selectDropoffNotificationObjectType,
      userInfo: nil)
  }

  /// Updates UI elements and customer state when the user previews the trip.
  private func startTripPreview() {
    modelData.staticLabel = ""
    modelData.controlButtonLabel = Strings.controlPanelConfirmTripButtonText
    modelData.customerState = .tripPreview
    modelData.tripInfoLabel = ""
    modelData.buttonColor = Color.green
    modelData.customerState = .tripPreview
  }

  /// Sends out a notification and lets `MapViewController` know that the user is booking
  /// a trip now.
  private func bookTrip() {
    NotificationCenter.default.post(
      name: .stateDidChange, object: MapViewController.bookTripNotificationObjectType,
      userInfo: nil)
  }

  /// Sends out a notification and lets `MapViewController` know that a user is cancelling
  /// a trip now.
  private func cancelTrip() {
    NotificationCenter.default.post(
      name: .stateDidChange, object: MapViewController.cancelTripNotificationObjectType,
      userInfo: nil)
  }
}

struct JourneySharingView_Previews: PreviewProvider {
  static var previews: some View {
    JourneySharingView()
  }
}
