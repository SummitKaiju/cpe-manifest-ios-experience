//
//  MSRotation+SceneKit.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/14/18.
//

#import "MSRotation.h"

#import <SceneKit/SceneKit.h>

@interface MSRotation (SceneKit)
- (instancetype)initWithSCNQuaternion:(SCNQuaternion)quaternion;
@property (NS_NONATOMIC_IOSONLY, getter=getSCNQuaternion, readonly) SCNQuaternion SCNQuaternion;
- (instancetype)initWithSCNMatrix4:(SCNMatrix4)matrix;
@property (NS_NONATOMIC_IOSONLY, getter=getSCNMatrix4, readonly) SCNMatrix4 SCNMatrix4;
@end
