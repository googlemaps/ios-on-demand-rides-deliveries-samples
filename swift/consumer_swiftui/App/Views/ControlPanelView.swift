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

/// A control panel view containing buttons that control trip status.
struct ControlPanelView: View {
  /// The name for add intermediate destination icon.
  private static let addIntermediateDestinationIcon = "plus"

  /// The `ModelData` containing the primary state of the application.
  @EnvironmentObject var modelData: ModelData
  private let tapButtonAction: () -> Void
  private let tapAddIntermediateDestinationAction: () -> Void

  init(
    tapButtonAction: @escaping () -> Void, tapAddIntermediateDestinationAction: @escaping () -> Void
  ) {
    self.tapButtonAction = tapButtonAction
    self.tapAddIntermediateDestinationAction = tapAddIntermediateDestinationAction
  }

  var body: some View {
    VStack(alignment: .center) {
      HStack(alignment: .center) {
        VStack(alignment: .leading) {
          Group { Text(modelData.staticLabel) + Text(modelData.tripInfoLabel).bold() }
            .frame(width: Style.frameWidth, height: Style.mediumFrameHeight, alignment: .topLeading)
          if modelData.timeToWaypoint != 0 && modelData.remainingDistanceInMeters != 0 {
            Text(
              String.init(
                format: "%.1f min · %.1f mi", modelData.timeToWaypoint,
                modelData.remainingDistanceInMeters)
            )
            .foregroundColor(Style.textColor)
            .font(Font.body.bold())
            .font(.system(size: Style.mediumFontSize))
            .frame(width: Style.frameWidth, height: Style.mediumFrameHeight, alignment: .topLeading)
          }
          if modelData.tripID != "" {
            Text(Strings.tripIDText + modelData.tripID)
              .font(.system(size: Style.smallFontSize)).foregroundColor(Style.textColor)
              .frame(
                width: Style.frameWidth, height: Style.mediumFrameHeight, alignment: .topLeading)
          }
          if modelData.vehicleID != "" {
            Text(Strings.vehicleIDText + modelData.vehicleID)
              .font(.system(size: Style.smallFontSize))
              .foregroundColor(Style.textColor)
              .frame(
                width: Style.frameWidth, height: Style.mediumFrameHeight, alignment: .topLeading)
          }
        }

        if modelData.customerState == .selectingDropoff {
          Button(action: tapAddIntermediateDestinationAction) {
            Image(systemName: ControlPanelView.addIntermediateDestinationIcon).foregroundColor(
              Style.buttonBackgroundColor)
          }.frame(height: Style.mediumFrameHeight, alignment: .topLeading)
        }
      }
      Button(action: tapButtonAction) {
        Text(modelData.controlButtonLabel)
      }
      .buttonStyle(StyledButton())
      .frame(
        alignment: .init(horizontal: .center, vertical: .center))
    }
  }
}

/// The customized button style which includes the tap animation.
private struct StyledButton: ButtonStyle {
  @EnvironmentObject var modelData: ModelData
  func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .foregroundColor(.white)
      .frame(width: Style.frameWidth, height: Style.mediumFrameHeight)
      .background(
        configuration.isPressed
          ? Color.gray : modelData.buttonColor
      )
      .cornerRadius(.infinity)
  }
}

struct ControlPanelView_Previews: PreviewProvider {
  static var previews: some View {
    ControlPanelView(tapButtonAction: {}, tapAddIntermediateDestinationAction: {})
  }
}
