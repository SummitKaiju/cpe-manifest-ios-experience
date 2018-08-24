//
//  MSRotation+CoreMotion.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/14/18.
//
//
//  Rotation+CoreMotion.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//
#if TARGET_OS_IOS
#import "MSRotation.h"

#import <CoreMotion/CoreMotion.h>

@interface MSRotation (CoreMotion)
- (instancetype)initWithCMQuaternion:(CMQuaternion)cmQuaternion;
- (instancetype)initWithCMAttitude:(CMAttitude *)cmAttitude;
- (instancetype)initWithCMDeviceMotion:(CMDeviceMotion *)cmDeviceMotion;
@end

#endif
