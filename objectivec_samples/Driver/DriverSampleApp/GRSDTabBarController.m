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
#import "GRSDTabBarController.h"

#import "GRSDViewController.h"

#import "GRSDExpeditorViewController.h"

static CGFloat kDefaultTabBarBackgroundColor = 230.0f;
static CGFloat kDefaultTabBarSelectedBackgroundColor = 210.0f;
static CGFloat kDefaultRGBNormalizer = 255.0f;
static CGFloat kDefaultAlpha = 1.0f;
static CGFloat kTabBarItemPositionAdjustmentOffSet = 10.0f;
static CGFloat kSelectedTabBarHeight = 83.0f;
static NSString *kSelectedDriverIcon = @"DriverBlue";
static NSString *kUnselectedDriverIcon = @"DriverGray";
static NSString *kSelectedExpeditorIcon = @"ExpeditorBlue";
static NSString *kUnselectedExpeditorIcon = @"ExpeditorGray";

@implementation GRSDTabBarController {
}

- (UIImage *)getBackgroundImageSelectedFromColorForSize:(CGSize)size {
  UIColor *color =
      [UIColor colorWithRed:kDefaultTabBarSelectedBackgroundColor / kDefaultRGBNormalizer
                      green:kDefaultTabBarSelectedBackgroundColor / kDefaultRGBNormalizer
                       blue:kDefaultTabBarSelectedBackgroundColor / kDefaultRGBNormalizer
                      alpha:1];
  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  UIGraphicsBeginImageContext(rect.size);

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.delegate = self;

  UIImage *driverSelected = [UIImage imageNamed:kSelectedDriverIcon];
  UIImage *driverUnselected = [UIImage imageNamed:kUnselectedDriverIcon];
  UIImage *expeditorSelected = [UIImage imageNamed:kSelectedExpeditorIcon];
  UIImage *expeditorUnselected = [UIImage imageNamed:kUnselectedExpeditorIcon];

  self.tabBar.translucent = NO;
  self.tabBar.backgroundColor =
      [UIColor colorWithRed:kDefaultTabBarBackgroundColor / kDefaultRGBNormalizer
                      green:kDefaultTabBarBackgroundColor / kDefaultRGBNormalizer
                       blue:kDefaultTabBarBackgroundColor / kDefaultRGBNormalizer
                      alpha:kDefaultAlpha];
  [self.tabBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
      .active = YES;
  [self.tabBar.heightAnchor constraintEqualToConstant:self.view.safeAreaInsets.bottom].active = YES;

  GRSDViewController *_driverViewController = [[GRSDViewController alloc] init];

  UINavigationController *_driverNavigationController =
      [[UINavigationController alloc] initWithRootViewController:_driverViewController];

  GRSDExpeditorViewController *_expeditorViewController =
      [[GRSDExpeditorViewController alloc] init];

  _driverNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Driver"
                                                                         image:driverUnselected
                                                                 selectedImage:driverSelected];
  _driverNavigationController.tabBarItem.titlePositionAdjustment =
      UIOffsetMake(0, kTabBarItemPositionAdjustmentOffSet);
  _driverNavigationController.tabBarItem.imageInsets =
      UIEdgeInsetsMake(0, 0, -kTabBarItemPositionAdjustmentOffSet, 0);

  _expeditorViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Expeditor"
                                                                      image:expeditorUnselected
                                                              selectedImage:expeditorSelected];
  _expeditorViewController.tabBarItem.titlePositionAdjustment =
      UIOffsetMake(0, kTabBarItemPositionAdjustmentOffSet);
  _expeditorViewController.tabBarItem.imageInsets =
      UIEdgeInsetsMake(0, 0, -kTabBarItemPositionAdjustmentOffSet, 0);

  self.tabBar.selectionIndicatorImage =
      [self getBackgroundImageSelectedFromColorForSize:CGSizeMake(self.tabBar.frame.size.width / 2,
                                                                  kSelectedTabBarHeight)];

  self.viewControllers =
      [NSArray arrayWithObjects:_driverNavigationController, _expeditorViewController, nil];
  [self setSelectedViewController:_driverNavigationController];
}

@end
