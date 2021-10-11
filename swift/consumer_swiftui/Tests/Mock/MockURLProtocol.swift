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

/// A Mock URLProtocol class that help serve the preserved response data to
/// URLRequest during testing.
class MockURLProtocol: URLProtocol {

  /// Handler to test the request and return mock response
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

  override class func canInit(with request: URLRequest) -> Bool {
    /// Handle all types of requests
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    /// Required to be implemented here. Just return what is passed
    return request
  }

  override func startLoading() {
    guard let handler = MockURLProtocol.requestHandler else {
      fatalError("Handler is unavailable.")
    }

    do {
      // 2. Call handler with received request and capture the tuple of response and data.
      let (response, data) = try handler(request)

      // 3. Send received response to the client.
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

      if let data = data {
        // 4. Send received data to the client.
        client?.urlProtocol(self, didLoad: data)
      }

      // 5. Notify request has been finished.
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      // 6. Notify received error.
      client?.urlProtocol(self, didFailWithError: error)
    }
  }
  override func stopLoading() {
    /// Required to be implemented. Do nothing here.
  }
}

extension URLRequest {

  func bodySteamAsJSON() -> Any? {

    guard let bodyStream = self.httpBodyStream else { return nil }
    bodyStream.open()

    // Will read 16 chars per iteration. Can use bigger buffer if needed
    let bufferSize: Int = 16
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    var dat = Data()

    while bodyStream.hasBytesAvailable {
      let readDat = bodyStream.read(buffer, maxLength: bufferSize)
      dat.append(buffer, count: readDat)
    }

    buffer.deallocate()
    bodyStream.close()

    do {
      return try JSONSerialization.jsonObject(
        with: dat, options: JSONSerialization.ReadingOptions.allowFragments)
    } catch {
      print(error.localizedDescription)
      return nil
    }
  }
}
