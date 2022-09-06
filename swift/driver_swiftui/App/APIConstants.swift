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

/// Constants for accessing APIs.
enum APIConstants {
  /// The Google Maps API key matching the bundle ID of this app.
  static let mapsAPIKey = "YOUR_API_KEY"

  /// The Project ID of the Google Cloud Project used to call the Fleet Engine APIs.
  static let providerID = "YOUR_PROVIDER_ID"

  /// The base URL for requests to the provider.
  static let providerBaseURLString = "http://localhost:8080"
}
