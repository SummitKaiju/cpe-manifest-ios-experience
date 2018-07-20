//
//  MSPanoramaPanGestureManager.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/15/18.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>

@interface MSPanoramaPanGestureManager : NSObject

@property (nonatomic, weak) SCNNode *rotationNode;

@property (nonatomic, assign) BOOL allowsVerticalRotation;
@property (nonatomic, assign, readonly) BOOL limitsVerticalRotation;
@property (nonatomic, assign, readonly) float minimumVerticalRotationAngle;
@property (nonatomic, assign, readonly) float maximumVerticalRotationAngle;

@property (nonatomic, assign) BOOL allowsHorizontalRotation;
@property (nonatomic, assign, readonly) BOOL limitsHorizontalRotation;
@property (nonatomic, assign, readonly) float minimumHorizontalRotationAngle;
@property (nonatomic, assign, readonly) float maximumHorizontalRotationAngle;

@property (NS_NONATOMIC_IOSONLY, getter=getGestureRecognizer, readonly, strong) UIPanGestureRecognizer *gestureRecognizer;

- (instancetype)initWithRotationNode:(SCNNode *)node NS_DESIGNATED_INITIALIZER;

- (void)limitVerticalRotationWithMin:(float)min andMax:(float)max;
- (void)limitHorizontalRotationWithMin:(float)min andMax:(float)max;
- (void)clearVerticalRotationLimit;
- (void)clearHorizontalRotationLimit;

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender;
    
- (void)stopAnimations;

@end

