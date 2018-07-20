//
//  MSDeviceOrientationProvider.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/14/18.
//

#import "MSRotation.h"

#if TARGET_OS_IOS
#import <CoreMotion/CoreMotion.h>

#import "MSDeviceOrientationProvider.h"

@protocol MSDeviceOrientationProvider <NSObject>
- (MSRotation *)deviceOrientationAtTime:(NSTimeInterval)time;
- (BOOL)shouldWaitDeviceOrientationAtTime:(NSTimeInterval)time;
- (BOOL)waitDeviceOrientationAtTime:(NSTimeInterval)time;
- (BOOL)waitDeviceOrientationAtTime:(NSTimeInterval)time timeout:(dispatch_time_t)timeout;
@end

@interface CMMotionManager (DeviceOrientationProvider)
- (MSRotation *)deviceOrientationAtTime:(NSTimeInterval)time;
- (BOOL)shouldWaitDeviceOrientationAtTime:(NSTimeInterval)time;
@end

@interface MSDefaultDeviceOrientationProvider : NSObject <MSDeviceOrientationProvider>
- (instancetype)init;
- (void)deinit;
@end

#endif
