//
//  MSRotation.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/14/18.
//

#import <GLKit/GLKit.h>

@interface MSRotation : NSObject

@property (nonatomic, assign) GLKMatrix3 matrix;

@property (NS_NONATOMIC_IOSONLY, getter=getQuaternion) GLKQuaternion quaternion;

+ (MSRotation *)identity;

- (instancetype)initWithMatrix:(GLKMatrix3)matrix NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithQuaternion:(GLKQuaternion)quaternion;
- (instancetype)initWithRadians:(float)radians aroundVector:(GLKVector3)vector;
- (instancetype)initWithX:(float)x;
- (instancetype)initWithY:(float)y;
- (instancetype)initWithZ:(float)z;

- (void)rotateByRadians:(float)radians aroundAxis:(GLKVector3)axis;
- (void)rotateByX:(float)radians;
- (void)rotateByY:(float)radians;
- (void)rotateByZ:(float)radians;
- (void)invert;
- (void)normalize;

- (MSRotation *)rotatedByRadians:(float)radians aroundAxis:(GLKVector3)axis;
- (MSRotation *)rotatedByX:(float)x;
- (MSRotation *)rotatedByY:(float)y;
- (MSRotation *)rotatedByZ:(float)z;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) MSRotation *inverted;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) MSRotation *normalized;

- (MSRotation *)multipliedWith:(MSRotation *)rotation;
- (GLKVector3)multipliedVector:(GLKVector3)vector;

@end

MSRotation *multiply(MSRotation *lhs, MSRotation *rhs);
