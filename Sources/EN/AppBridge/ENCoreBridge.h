/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#ifndef Bridge_h
#define Bridge_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <BackgroundTasks/BackgroundTasks.h>

@interface ENCoreBridge: NSObject
+ (BOOL)isAppRootAvailable;

- (instancetype)init;

- (void)attachToWindow:(UIWindow *)window;
- (void)start;
- (void)didReceiveRemoteNotification:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler;
- (void)didBecomeActive;
- (void)didEnterForeground;
- (void)didEnterBackground;
- (void)handleBackgroundTask:(BGTask *)task API_AVAILABLE(ios(13.0));

@end

#endif /* Bridge_h */
