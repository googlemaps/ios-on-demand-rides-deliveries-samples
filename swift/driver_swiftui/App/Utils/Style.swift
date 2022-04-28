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

import Foundation
import SwiftUI

/// Constants for styling the user interface.
enum Style {
  /// Padding for the Vehicle ID label.
  static let vehicleIDPadding = EdgeInsets(top: 10, leading: 20, bottom: 0, trailing: 20)

  /// Font size for small content.
  static let smallFontSize = 14.0

  /// Medium height for the element frame.
  static let mediumFrameHeight = 35.0

  /// Light color for static text.
  static let textColor = Color(red: 117 / 255, green: 117 / 255, blue: 117 / 255)

  /// Height for buttons.
  static let buttonHeight = 44.0

  /// Foreground color for buttons.
  static let buttonForegroundColor = Color.white

  /// Background color for the default state in buttons.
  static let buttonBackgroundColor = Color(red: 66 / 255, green: 133 / 255, blue: 244 / 255)

  /// Background color for the pressed state in buttons.
  static let buttonPressedBackgroundColor = Color.gray
}
