//
//  ATHMotionManager.h
//  ATHVideo
//
//  Created by Jared Sinclair on 8/3/16.
//  Copyright © 2016 The New York Times Company. All rights reserved.
//

#import "ATHMotionManagement.h"

@import Foundation;

/**
 A reference implementation of `ATHMotionManagement`. Your host application
 can provide another implementation if so desired.
 
 @seealso `ATHViewController`.
 */
@interface ATHMotionManager : NSObject <ATHMotionManagement>

#pragma mark - Singleton

/**
 The shared, app-wide `ATHMotionManager`.
 */
+ (instancetype)sharedManager;

#pragma mark - Internal
// The following internal state is exposed for testing.

@property (NS_NONATOMIC_IOSONLY, readonly) NSTimeInterval resolvedUpdateInterval;
@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger numberOfObservers;

@end
