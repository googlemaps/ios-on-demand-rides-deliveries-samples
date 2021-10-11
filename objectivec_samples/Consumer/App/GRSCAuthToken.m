/*
 * Copyright 2021 Google LLC. All rights reserved.
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

#import "GRSCAuthToken.h"

@implementation GRSCAuthToken {
  NSTimeInterval _expiration;
}

- (instancetype)initWithToken:(NSString*)token expiration:(NSTimeInterval)expiration {
  self = [super init];
  if (self) {
    _token = token;
    _expiration = expiration;
  }
  return self;
}

- (BOOL)isValid {
  if (!_token) {
    return NO;
  }

  if (_expiration <= [[NSDate date] timeIntervalSince1970]) {
    return NO;
  }

  return YES;
}

@end
