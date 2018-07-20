//
//  MSStereoParametersProtocol.h
//  AetherPlayer
//
//  Created by Stefan Vukanić on 3/15/18.
//

#import <Foundation/Foundation.h>
#import "MSScreenParameters.h"
#import "MSViewerParameters.h"
#import "MSScreenModel.h"
#import "MSViewerModel.h"
#import "SceneKit/SceneKit.h"
#import "MSEye.h"

@interface MSStereoParameters : NSObject
@property (nonatomic, strong) MSScreenParameters *screen;
@property (nonatomic, strong) MSViewerParameters *viewer;

- (instancetype)init:(MSScreenModel*)screenModel viewerModel:(MSViewerModel*)viewerModel NS_DESIGNATED_INITIALIZER;

- (SCNMatrix4)cameraProjectionTransform:(MSEye)eye nearZ:(float)nearZ farZ:(float)farZ aspectRatio:(float)aspectRatio;
- (SCNMatrix4)cameraProjectionTransform:(MSEye)eye nearZ:(float)nearZ farZ:(float)farZ;

- (SCNMatrix4)distortedProjection:(MSEye)eye;

- (SCNMatrix4) undistortedProjection:(MSEye)eye;

- (SCNMatrix4) convertLeftEyeProjection:(SCNMatrix4)leftEyeProjection for:(MSEye)eye;

- (SCNMatrix4) projectionFromFrustum:(vector_float4)frustum;
- (SCNMatrix4) projectionFromFrustum:(float)left top:(float)top right:(float)right bottom:(float)bottom;

- (CGRect) viewport:(MSEye)eye inBounds:(CGRect)bounds;
- (CGRect) viewport:(MSEye)eye;

- (CGSize) recommendedStereoTextureSize:(CGSize)screenSize;

@property (nonatomic, assign) float verticalLensOffsetFromScreenCenter;
@property (nonatomic, assign) vector_float4 leftEyeVisibleTanAngles;
@property (nonatomic, assign) vector_float4 leftEyeNoLensVisibleTanAngles;
@property (nonatomic, assign) CGRect leftEyeVisibleScreenRect;

@end


