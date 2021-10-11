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

#import "GRSCAppDelegate.h"

#import <GoogleRidesharingConsumer/GoogleRidesharingConsumer.h>
#import "GRSCAuthTokenProvider.h"
#import "GRSCMapViewController.h"

static NSString *const kAPIKey = @"YOUR_API_KEY";
static NSString *const kProviderId = @"YOUR_PROVIDER_ID";

@implementation GRSCAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GMSServices provideAPIKey:kAPIKey];

  [GMTCServices setAccessTokenProvider:[[GRSCAuthTokenProvider alloc] init]
                           providerID:kProviderId];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  GRSCMapViewController *mapviewControler = [[GRSCMapViewController alloc] init];

  [self.window setRootViewController:mapviewControler];
  [self.window makeKeyAndVisible];

  return YES;
}

@end
