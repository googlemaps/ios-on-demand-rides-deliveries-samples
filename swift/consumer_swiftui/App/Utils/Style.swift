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

/// Constants that can be used in the sample app.
enum Style {
  /// The length for the element frame width.
  static let frameWidth = UIScreen.main.bounds.width * 0.8

  /// Small height for the element frame.
  static let smallFrameHeight = 20.0

  /// Medium height for the element frame.
  static let mediumFrameHeight = 35.0

  /// Large height for the element frame.
  static let largeFrameHeight = 60.0

  /// Font size for small content.
  static let smallFontSize = 14.0

  /// Font size for medium content.
  static let mediumFontSize = 18.0

  /// Light color for static text.
  static let textColor = Color.init(red: 117 / 255, green: 117 / 255, blue: 117 / 255)

  /// Color for default state in buttons
  static let buttonBackgroundColor = Color.init(red: 113 / 255, green: 131 / 255, blue: 148 / 255)
}
