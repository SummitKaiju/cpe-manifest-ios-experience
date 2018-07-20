//
//  MSInterfaceOrientationUpdater.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/14/18.
//

#import "MSOrientationNode.h"

#import <UIKit/UIKit.h>

@interface MSInterfaceOrientationUpdater : NSObject
@property (nonatomic, weak) MSOrientationNode *orientationNode;
- (instancetype)initWithOrientationNode:(MSOrientationNode *)orientationNode NS_DESIGNATED_INITIALIZER;
- (void)deinit;
- (void)updateInterfaceOrientation;
- (void)updateInterfaceOrientationWith:(id<UIViewControllerTransitionCoordinator>)transitionCoordinator;
- (void)startAutomaticInterfaceOrientationUpdates;
- (void)stopAutomaticInterfaceOrientationUpdates;
@end
