//
//  MSStereoRenderer.h
//  AetherPlayer
//
//  Created by Stefan Vukanić on 3/14/18.
//

#import "MSEye.h"

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <SceneKit/SceneKit.h>

@interface RendererDelegateProxy: NSObject<SCNSceneRendererDelegate>
@property(nonatomic) MSEye currentRenderingEye;
@property(nonatomic, strong) id<SCNSceneRendererDelegate> forwardingTarget;
- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time;
- (void)renderer:(id<SCNSceneRenderer>)renderer didApplyAnimationsAtTime:(NSTimeInterval)time;
- (void)renderer:(id<SCNSceneRenderer>)renderer didSimulatePhysicsAtTime:(NSTimeInterval)time;
- (void)renderer:(id<SCNSceneRenderer>)renderer willRenderScene:(SCNScene*)scene atTime:(NSTimeInterval)time;
- (void)renderer:(id<SCNSceneRenderer>)renderer didRenderScene:(SCNScene*)scene atTime:(NSTimeInterval)time;
@end

@interface EyeRenderingConfiguration: NSObject
@property(nonatomic, strong) id<MTLTexture> texture;
@property(nonatomic, strong) SCNNode *pointOfView;

- (instancetype)init:(id<MTLTexture>)texture;

@end


@interface MSStereoRenderer : NSObject
@property(nonatomic, weak) id<MTLTexture> outputTexture;
@property(nonatomic, weak) SCNScene *scene;
@property(nonatomic, strong) SCNRenderer *scnRenderer;
@property (nonatomic, weak) id<SCNSceneRendererDelegate> sceneRendererDelegate;


- (instancetype)init:(id<MTLTexture>)outputTexture;
- (SCNNode*)pointOfView:(MSEye)eye;
- (void)setPointOfView:(SCNNode*)pointOfView for:(MSEye)eye;
- (void)render:(NSTimeInterval)time commandQueue:(id<MTLCommandQueue>)queue;
@end


