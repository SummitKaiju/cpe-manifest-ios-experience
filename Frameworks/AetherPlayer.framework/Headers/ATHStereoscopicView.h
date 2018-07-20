//
//  ATHStereoscopicView.h
//  AetherPlayer-iOS
//
//  Created by Stefan Vukanić on 3/22/18.
//

#import "MSStereoParameters.h"

@import Metal;
@import SceneKit;

@interface ATHStereoscopicView : SCNView <SCNSceneRendererDelegate>
@property (nonatomic, readonly) SCNRenderer *renderer;
@property (nonatomic, weak) id<SCNSceneRendererDelegate> sceneRendererDelegate;
- (instancetype)initWithDevice:(id<MTLDevice>)device parameters:(MSStereoParameters *)stereoParameters scene:(SCNScene *)scene NS_DESIGNATED_INITIALIZER;
@end
