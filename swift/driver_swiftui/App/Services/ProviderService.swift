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
import GoogleRidesharingDriver

private enum RPCConstants {
  /// URL path strings.
  static let providerCreateVehicleURLPath = "/vehicle/new"
  static let providerGetVehicleURLPath = "/vehicle/"
  static let providerGetTripURLPath = "/trip/"

  /// Request parameter keys.
  static let vehicleIDKey = "vehicleId"
  static let backToBackEnabledKey = "backToBackEnabled"
  static let statusKey = "status"
  static let intermediateDestinationIndexKey = "intermediateDestinationIndex"

  /// Response parameter keys.
  static let nameKey = "name"
  static let currentTripsIDsKey = "currentTripsIds"
  static let tripKey = "trip"
  static let tripStatusKey = "tripStatus"

  static let waypointsKey = "waypoints"
  static let locationKey = "location"
  static let pointKey = "point"
  static let latitudeKey = "latitude"
  static let longitudeKey = "longitude"
  static let tripIDKey = "tripId"
  static let waypointTypeKey = "waypointType"

  static let waypointTypePickup = "PICKUP_WAYPOINT_TYPE"
  static let waypointTypeDropoff = "DROP_OFF_WAYPOINT_TYPE"
  static let waypointTypeIntermediateDestination = "INTERMEDIATE_DESTINATION_WAYPOINT_TYPE"

  /// HTTP constants.
  static let httpContentTypeHeaderField = "Content-Type"
  static let httpJSONContentType = "application/json"
  static let httpMethodPOST = "POST"
  static let httpMethodPUT = "PUT"
}

/// Provider-supported trip statuses.
enum ProviderTripStatus: String {
  case new = "NEW"
  case enrouteToPickup = "ENROUTE_TO_PICKUP"
  case arrivedAtPickup = "ARRIVED_AT_PICKUP"
  case enrouteToIntermediateDestination = "ENROUTE_TO_INTERMEDIATE_DESTINATION"
  case arrivedAtIntermediateDestination = "ARRIVED_AT_INTERMEDIATE_DESTINATION"
  case enrouteToDropoff = "ENROUTE_TO_DROPOFF"
  case complete = "COMPLETE"
}

/// Completion handler type definition for the createVehicle process.
typealias CreateVehicleCompletionHandler = (String?, Error?) -> Void

/// Completion handler type definition for the getVehicle process.
typealias GetVehicleCompletionHandler = ([String]?, Error?) -> Void

/// Completion handler type definition for the getTrip process.
typealias GetTripCompletionHandler = (ProviderTripStatus?, [GMTSTripWaypoint]?, Error?) -> Void

/// Completion handler type definition for the updateTrip process.
typealias UpdateTripCompletionHandler = (Error?) -> Void

/// A service that sends requests and receives responses from the provider backend.
class ProviderService {

  enum Error: Swift.Error {
    case missingData
    case missingURL
    case invalidVehicleName
  }

  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  /// Creates a vehicle with the specified back-to-back option.
  func createVehicle(
    vehicleID: String, isBackToBackEnabled: Bool,
    completion: @escaping CreateVehicleCompletionHandler
  ) {
    let requestURL = ProviderUtils.providerURL(path: RPCConstants.providerCreateVehicleURLPath)
    let payloadDict: [String: Any] =
      [
        RPCConstants.vehicleIDKey: vehicleID,
        RPCConstants.backToBackEnabledKey: isBackToBackEnabled,
      ]

    let request = Self.makeJSONRequest(
      url: requestURL, payloadDict: payloadDict, method: RPCConstants.httpMethodPOST)
    let sessionTask = session.dataTask(with: request) { data, _, error in
      guard error == nil else {
        DispatchQueue.main.async {
          completion(nil, error)
        }
        return
      }
      guard let data = data,
        let parsedDictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let vehicleName = parsedDictionary[RPCConstants.nameKey] as? String
      else {
        DispatchQueue.main.async {
          completion(nil, Error.missingData)
        }
        return
      }

      // Provider returns fully qualified vehicle name in this form:
      // 'providers/providerID/vehicles/vehicleID'. So strip the prefix from it.
      guard let vehicleID = vehicleName.components(separatedBy: "/").last else {
        DispatchQueue.main.async {
          completion(nil, Error.invalidVehicleName)
        }
        return
      }

      DispatchQueue.main.async {
        completion(vehicleID, nil)
      }
    }
    sessionTask.resume()
  }

  /// Returns the current trip IDs that are matched with a vehicle.
  func getVehicle(vehicleID: String, completion: @escaping GetVehicleCompletionHandler) {
    guard let requestURL = Self.makeGetVehicleURL(vehicleID: vehicleID) else {
      completion(nil, Error.missingURL)
      return
    }
    let sessionTask = session.dataTask(with: requestURL) { data, _, error in
      guard error == nil else {
        DispatchQueue.main.async {
          completion(nil, error)
        }
        return
      }
      guard let data = data,
        let parsedDictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let currentTripsIDs = parsedDictionary[RPCConstants.currentTripsIDsKey] as? [String]
      else {
        DispatchQueue.main.async {
          completion(nil, Error.missingData)
        }
        return
      }
      DispatchQueue.main.async {
        completion(currentTripsIDs, nil)
      }
    }
    sessionTask.resume()
  }

  /// Returns the trip status and waypoints of a trip.
  func getTrip(tripID: String, completion: @escaping GetTripCompletionHandler) {
    guard let requestURL = Self.makeGetTripURL(tripID: tripID) else {
      completion(nil, nil, Error.missingURL)
      return
    }
    let sessionTask = session.dataTask(with: requestURL) { data, _, error in
      guard error == nil else {
        DispatchQueue.main.async {
          completion(nil, nil, error)
        }
        return
      }
      guard let data = data,
        let parsedDictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let tripJSON = parsedDictionary[RPCConstants.tripKey] as? [String: Any],
        let tripStatusString = tripJSON[RPCConstants.tripStatusKey] as? String,
        let tripStatus = ProviderTripStatus(rawValue: tripStatusString),
        let waypointsJSON = tripJSON[RPCConstants.waypointsKey] as? [[String: Any]],
        let waypoints =
          try? waypointsJSON.map({ try Self.makeWaypoint(waypointJSON: $0, tripID: tripID) })
      else {
        DispatchQueue.main.async {
          completion(nil, nil, Error.missingData)
        }
        return
      }
      DispatchQueue.main.async {
        completion(tripStatus, waypoints, nil)
      }
    }
    sessionTask.resume()
  }

  /// Updates the trip status and optionally the intermediate destination index of a trip.
  func updateTrip(
    tripID: String, status: ProviderTripStatus, intermediateDestinationIndex: Int?,
    completion: @escaping UpdateTripCompletionHandler
  ) {
    guard let requestURL = Self.makeUpdateTripURL(tripID: tripID) else {
      completion(Error.missingURL)
      return
    }
    var payloadDict: [String: Any] = [RPCConstants.statusKey: status.rawValue]
    if let intermediateDestinationIndex = intermediateDestinationIndex {
      payloadDict[RPCConstants.intermediateDestinationIndexKey] = intermediateDestinationIndex
    }

    let request = Self.makeJSONRequest(
      url: requestURL, payloadDict: payloadDict, method: RPCConstants.httpMethodPUT)
    let sessionTask = session.dataTask(with: request) { _, _, error in
      DispatchQueue.main.async {
        completion(error)
      }
    }
    sessionTask.resume()
  }

  /// Creates a `GMTSTripWaypoint` from a waypoint JSON returned by the provider backend.
  private static func makeWaypoint(waypointJSON: [String: Any], tripID: String) throws
    -> GMTSTripWaypoint
  {
    guard let locationJSON = waypointJSON[RPCConstants.locationKey] as? [String: Any],
      let pointJSON = locationJSON[RPCConstants.pointKey] as? [String: Any],
      let latitude = pointJSON[RPCConstants.latitudeKey] as? Double,
      let longitude = pointJSON[RPCConstants.longitudeKey] as? Double,
      let waypointTypeString = waypointJSON[RPCConstants.waypointTypeKey] as? String
    else {
      throw Error.missingData
    }

    let latLng = GMTSLatLng(latitude: latitude, longitude: longitude)
    let terminalLocation = GMTSTerminalLocation(
      point: latLng, label: nil, description: nil, placeID: nil, generatedID: nil,
      accessPointID: nil)

    let waypointType: GMTSTripWaypointType
    switch waypointTypeString {
    case RPCConstants.waypointTypePickup:
      waypointType = .pickUp
    case RPCConstants.waypointTypeDropoff:
      waypointType = .dropOff
    case RPCConstants.waypointTypeIntermediateDestination:
      waypointType = .intermediateDestination
    default:
      waypointType = .unknown
    }

    return GMTSTripWaypoint(
      location: terminalLocation, tripID: tripID, waypointType: waypointType,
      distanceToPreviousWaypointInMeters: 0, eta: 0)
  }

  private static func makeJSONRequest(url: URL, payloadDict: [String: Any], method: String)
    -> URLRequest
  {
    let serializedPayload = try! JSONSerialization.data(withJSONObject: payloadDict)
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue(
      RPCConstants.httpJSONContentType, forHTTPHeaderField: RPCConstants.httpContentTypeHeaderField)
    request.httpBody = serializedPayload
    return request
  }

  private static func makeGetVehicleURL(vehicleID: String) -> URL? {
    let providerURL = ProviderUtils.providerURL(path: RPCConstants.providerGetVehicleURLPath)
    return URL(string: vehicleID, relativeTo: providerURL)
  }

  private static func makeGetTripURL(tripID: String) -> URL? {
    let providerURL = ProviderUtils.providerURL(path: RPCConstants.providerGetTripURLPath)
    return URL(string: tripID, relativeTo: providerURL)
  }

  private static func makeUpdateTripURL(tripID: String) -> URL? {
    let providerURL = ProviderUtils.providerURL(path: RPCConstants.providerGetTripURLPath)
    return URL(string: tripID, relativeTo: providerURL)
  }
}
