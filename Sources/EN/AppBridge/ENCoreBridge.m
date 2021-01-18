/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


#import <Foundation/Foundation.h>
#import "ENCoreBridge.h"
#import <dlfcn.h>

@interface ENCoreBridge() {
    id _appRoot;
}

@end

@implementation ENCoreBridge
+ (BOOL)isAppRootAvailable {
    if (@available(iOS 12.5, *)) {
        return YES;
    } else {
        return NO;
    }
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        if ([[self class] isAppRootAvailable]) {
            [self loadENCore];
        } else {
            return nil;
        }
        return self;
    }
    
    return nil;
}

- (void)loadENCore {
    void * handle = dlopen("ENCore.framework/ENCore", RTLD_NOW);
    if (handle != NULL) {
        Class appRootClass = NSClassFromString(@"ENCore.ENAppRoot");
        _appRoot = [[appRootClass alloc] init];
    }
}

- (void)attachToWindow:(UIWindow *)window {
    [_appRoot attachToWindow: window];
}

- (void)start {
    [_appRoot performSelector:@selector(start)];
}

- (void)didReceiveRemoteNotification:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selector = @selector(receiveRemoteNotificationWithResponse:);
    
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_appRoot performSelector:selector withObject:response];
    
    #pragma clang diagnostic pop
    
    completionHandler();
}

- (void)didBecomeActive {
    [_appRoot didBecomeActive];
}

- (void)didEnterForeground {
    [_appRoot didEnterForeground];
}

- (void)didEnterBackground {
    [_appRoot didEnterBackground];
}

- (void)handleBackgroundTask:(BGTask *)task API_AVAILABLE(ios(13.0)) {
    #pragma clang diagnostic push
    
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selector = @selector(handleWithBackgroundTask:);
    
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_appRoot performSelector:selector withObject:task];
    
    #pragma clang diagnostic pop
}

@end
