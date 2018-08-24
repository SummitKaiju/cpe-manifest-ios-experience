//
//  ATHRenderer.h
//  Pods-Aether
//
//  Created by Stefan Vukanić on 3/8/18.
//

#import "ATHLayer.h"

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@interface ATHRenderer : NSObject
@property (nonatomic, assign) BOOL isHover;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, strong, readonly) ATHLayer *layer;
@property (nonatomic, strong, readonly) SCNNode *node;
@property (nonatomic) SCNSphere *sphere;
@property (nonatomic) SCNMaterial *material;
@property (nonatomic, readonly) CGSize optimalSize;
@property (nonatomic, readonly) BOOL isInteractive;
- (instancetype)initWithLayer:(ATHLayer*)layer andRadius:(CGFloat)radius;
@end
