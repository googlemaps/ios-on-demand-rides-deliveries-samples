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
import GoogleRidesharingConsumer

/// Constants that can be used in the unit test.
struct ProviderTestConstants {
  /// Longitude for testing location.
  static let longitude: Double = -122.4194

  /// Latitude for testing location.
  static let latitude: Double = 37.7749

  /// Api URL for generating a fake URL for  provider service.
  static let apiURL = "fakeURL"

  /// Fake latitude and logitutde for creating a fake location.
  static let latlng = GMTSLatLng(latitude: latitude, longitude: longitude)
}
