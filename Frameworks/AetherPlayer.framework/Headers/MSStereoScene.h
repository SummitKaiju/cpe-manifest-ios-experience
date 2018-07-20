//
//  MSStereoScene.h
//  AetherPlayer
//
//  Created by Stefan Vukanić on 3/14/18.
//


#import <SceneKit/SceneKit.h>
#import <Metal/Metal.h>
#import "MSStereoParameters.h"

@interface MSStereoScene : SCNScene
@property(nonatomic, weak) MSStereoParameters *stereoParameters;
@property(nonatomic, weak) id<MTLTexture> stereoTexture;
@property(nonatomic, strong) SCNNode *pointOfView;
@property(nonatomic, strong) SCNNode *meshNode;

-(instancetype)initWithCameraNode:(SCNNode*)cameraNode;
- (void)computeMeshPoints:(SCNVector3*)vertices texcoord:(CGPoint*)texcoord count:(NSInteger)count parameters:(MSStereoParameters*)parameters andWidth:(NSInteger)width andHeight:(NSInteger)height;
- (void)computeMeshColors:(SCNVector3*)colors count:(NSInteger)size andWidth:(NSInteger)width andHeight:(NSInteger)height;
- (void)computeMeshIndices:(int16_t*)colors count:(NSInteger)size andWidth:(NSInteger)width andHeight:(NSInteger)height;
@end

