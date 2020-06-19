//
//  Bridge.m
//  EN
//
//  Created by Robin van Dijke on 19/06/2020.
//

#import <Foundation/Foundation.h>
#import "ENCoreBridge.h"

@import ENCore;

@interface ENCoreBridge() {
    ENAppRoot *_appRoot;
}

@end

@implementation ENCoreBridge
+ (BOOL)isAppRootAvailable {
    return [ENAppRoot class] != nil;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _appRoot = [[ENAppRoot alloc] init];
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

@end
