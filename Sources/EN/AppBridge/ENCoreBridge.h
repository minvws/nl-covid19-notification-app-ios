//
//  Bridge.h
//  EN
//
//  Created by Robin van Dijke on 19/06/2020.
//

#ifndef Bridge_h
#define Bridge_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ENCoreBridge: NSObject
+ (BOOL)isAppRootAvailable;

- (instancetype)init;

- (void)attachToWindow:(UIWindow *)window;
- (void)start;

@end

#endif /* Bridge_h */
