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

/// A SwiftUI view wrapping a `MapViewController`.
struct MapViewControllerBridge: UIViewControllerRepresentable {
  /// The `ModelData` containing the primary state of the application.
  @EnvironmentObject var modelData: ModelData

  /// Lifecycle method for UIViewControllerRepresentable which creates the UIViewController.
  func makeUIViewController(context: Context) -> MapViewController {
    return MapViewController(modelData: modelData)
  }

  /// Lifecycle method for UIViewControllerRepresentable which updates the UIViewController.
  func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
  }
}
