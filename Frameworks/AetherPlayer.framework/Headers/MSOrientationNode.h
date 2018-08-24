//
//  MSOrientationNode.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/14/18.
//

#if TARGET_OS_IOS
    #import "MSDeviceOrientationProvider.h"
    #import "MSInterfaceOrientationProvider.h"
#else
    #import "MSRotation.h"
#endif

#import <SceneKit/SceneKit.h>

@interface MSOrientationNode : SCNNode
@property(nonatomic, strong) SCNNode *pointOfView;
@property(nonatomic, assign) CGFloat fieldOfView;

#if TARGET_OS_IOS
@property(nonatomic, strong) id<MSDeviceOrientationProvider> deviceOrientationProvider;
@property(nonatomic, strong) id<MSInterfaceOrientationProvider> interfaceOrientationProvider;
#endif

@property(nonatomic, strong, readonly) SCNNode *userRotationNode;
@property(nonatomic, strong, readonly) SCNNode *deviceOrientationNode;
@property(nonatomic, strong, readonly) SCNNode *interfaceOrientationNode;

- (void)updateDeviceOrientation;
- (void)updateDeviceOrientationAtTime:(NSTimeInterval)time;
- (void)updateInterfaceOrientation;
- (void)updateInterfaceOrientationAtTime:(NSTimeInterval)time;
- (void)resetRotation;
- (void)resetRotation:(BOOL)animated completionHandler:(void(^)(void))handler;
- (void)setNeedsResetRotation:(BOOL)animated;

@end

MSRotation *multiply(MSRotation *lhs, MSRotation *rhs);
