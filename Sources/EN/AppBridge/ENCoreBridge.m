/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


#import <Foundation/Foundation.h>
#import "ENCoreBridge.h"

@import ENCore;

@interface ENCoreBridge() {
    NS_AVAILABLE_IOS(13_5)
    ENAppRoot *_appRoot;
}

@end

@implementation ENCoreBridge
+ (BOOL)isAppRootAvailable {
    if (@available(iOS 13.5, *)) {
        return [ENAppRoot class] != nil;
    } else {
        return NO;
    }
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        if (@available(iOS 13.5, *)) {
            _appRoot = [[ENAppRoot alloc] init];
        } else {
            return nil;
        }
        return self;
    }
    
    return nil;
}

- (void)attachToWindow:(UIWindow *)window {
    [_appRoot attachToWindow: window];
}

- (void)start {
    [_appRoot start];
}

- (void)didReceiveRemoteNotification:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    [_appRoot receiveRemoteNotificationWithResponse:response];
    completionHandler();
}

@end
