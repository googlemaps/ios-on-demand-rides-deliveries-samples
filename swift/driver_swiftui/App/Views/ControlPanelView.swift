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

/// A control panel view containing a driver state label, trip ID labels, and a control button.
struct ControlPanelView: View {
  /// The `ModelData` containing the primary state of the application.
  @EnvironmentObject var modelData: ModelData

  var body: some View {
    VStack(alignment: .leading) {
      Text(driverStateText()).bold()
        .frame(height: Style.mediumFrameHeight, alignment: .topLeading)
      if let tripID = modelData.tripID {
        Text(Strings.tripIDText + tripID)
          .font(.system(size: Style.smallFontSize))
          .foregroundColor(Style.textColor)
          .frame(height: Style.mediumFrameHeight, alignment: .topLeading)
      }
      if let nextTripID = modelData.nextTripID {
        Text(Strings.nextTripIDText + nextTripID)
          .font(.system(size: Style.smallFontSize))
          .foregroundColor(Style.textColor)
          .frame(height: Style.mediumFrameHeight, alignment: .topLeading)
      }
      if let waypoints = modelData.waypoints, !waypoints.isEmpty {
        Button(action: tapButtonAction) {
          Text(buttonText())
        }
        .buttonStyle(StyledButton())
      }
    }
    .padding()
  }

  private func tapButtonAction() {
    NotificationCenter.default.post(name: .didTapControlPanelButton, object: nil)
  }

  /// Text for label in the control panel displaying the current driver state.
  private func driverStateText() -> String {
    switch modelData.driverState {
    case .new:
      return Strings.controlPanelDriverStateText.new
    case .enrouteToPickup:
      return Strings.controlPanelDriverStateText.enrouteToPickup
    case .arrivedAtPickup:
      return Strings.controlPanelDriverStateText.arrivedAtPickup
    case .enrouteToIntermediateDestination:
      return Strings.controlPanelDriverStateText.enrouteToIntermediateDestination
    case .arrivedAtIntermediateDestination:
      return Strings.controlPanelDriverStateText.arrivedAtIntermediateDestination
    case .enrouteToDropoff:
      return Strings.controlPanelDriverStateText.enrouteToDropoff
    case .tripComplete:
      return Strings.controlPanelDriverStateText.tripComplete
    default:
      return ""
    }
  }

  /// Text for the button in the control panel.
  private func buttonText() -> String {
    guard let waypoint = modelData.waypoints?.first else { return "" }
    if modelData.isEnrouteToWaypoint {
      switch waypoint.waypointType {
      case .pickUp:
        return Strings.controlPanelButtonText.arrivedAtPickup
      case .intermediateDestination:
        return Strings.controlPanelButtonText.arrivedAtIntermediateDestination
      case .dropOff:
        return Strings.controlPanelButtonText.tripComplete
      default:
        return ""
      }
    } else {
      switch waypoint.waypointType {
      case .pickUp:
        return Strings.controlPanelButtonText.enrouteToPickup
      case .intermediateDestination:
        return Strings.controlPanelButtonText.enrouteToIntermediateDestination
      case .dropOff:
        return Strings.controlPanelButtonText.enrouteToDropoff
      default:
        return ""
      }
    }
  }
}

/// The customized button style.
private struct StyledButton: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(Style.buttonForegroundColor)
      .frame(maxWidth: .infinity, minHeight: Style.buttonHeight)
      .background(
        configuration.isPressed ? Style.buttonPressedBackgroundColor : Style.buttonBackgroundColor
      )
      .cornerRadius(.infinity)
  }
}

struct ControlPanelView_Previews: PreviewProvider {
  static var previews: some View {
    ControlPanelView()
  }
}
