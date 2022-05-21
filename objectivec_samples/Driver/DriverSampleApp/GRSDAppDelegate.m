/*
 * Copyright 2020 Google LLC. All rights reserved.
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

#import "GRSDAppDelegate.h"

#import <GoogleMaps/GoogleMaps.h>

#import <GoogleRidesharingDriver/GoogleRidesharingDriver.h>
#import "GRSDAPIConstants.h"
#import "GRSDViewController.h"

@implementation GRSDAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<NSString *, __kindof NSObject *> *)launchOptions {
  [GMSServices provideAPIKey:kMapsAPIKey];

  // Register for notifications so that the SDK can post directions notifications when the app is
  // running in the background.
  UIUserNotificationSettings *userNotificationSettings =
      [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil];
  [[UIApplication sharedApplication] registerUserNotificationSettings:userNotificationSettings];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  GRSDViewController *driverViewController = [[GRSDViewController alloc] init];

  UINavigationController *navigationController =
      [[UINavigationController alloc] initWithRootViewController:driverViewController];
  _window.rootViewController = navigationController;
  [self.window makeKeyAndVisible];

  return YES;
}

@end
