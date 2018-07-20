//
//  MSStereoCameraNode.h
//  AetherPlayer
//
//  Created by Stefan Vukanić on 3/15/18.
//

#import <SceneKit/SceneKit.h>
#import "MSStereoParameters.h"
#import "MSEye.h"
#import "MSCategoryBitMask.h"

@interface MSStereoCameraNode : SCNNode
@property (nonatomic, weak) MSStereoParameters *stereoParameters;
@property (nonatomic, assign) float nearZ;
@property (nonatomic, assign) float farZ;

@property (nonatomic, strong) NSMutableDictionary<NSNumber*, SCNNode*>* pointOfViews;

- (instancetype)init:(MSStereoParameters*)paramters;
- (SCNNode*)pointOfView:(NSNumber*)eye;
@end
