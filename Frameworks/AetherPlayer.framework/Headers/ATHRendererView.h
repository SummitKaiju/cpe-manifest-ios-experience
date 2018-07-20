//
//  ATHRendererView.h
//  Pods-Aether
//
//  Created by Stefan Vukanić on 3/8/18.
//


#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>

#if TARGET_OS_IOS
#import "MSStereoParameters.h"
#import "MSInterfaceOrientationUpdater.h"
#import <CoreMotion/CoreMotion.h>
#import <Metal/Metal.h>
#import "MSStereoCameraNode.h"
#endif

#import "ATHRenderer.h"

#import "ATHMonoscopicView.h"
#if !TARGET_OS_TV
#import "ATHStereoscopicView.h"
#endif
#import "ATHSceneObject.h"

@protocol ATHRendererViewDelegate <NSObject>
- (void)didHoverObject:(ATHSceneObject*)layer;
- (void)didPressObject:(ATHSceneObject*)layer;
- (void)didDeselectObjects;
- (void)didChangeOrientation:(SCNVector3)angles;
@optional

@end

@interface ATHRendererView : UIView
@property (nonatomic) BOOL VRModeEnabled;
@property (nonatomic, weak) id<ATHRendererViewDelegate> delegate;
@property (nonatomic, weak) id<SCNSceneRendererDelegate> sceneRendererDelegate;
@property (nonatomic) SCNVector3 initialAngles;
@property (nonatomic, weak) UIView *previewView;
@property (nonatomic, strong) NSArray<ATHRenderer *> *renderers;
- (ATHRendererView *)initWithRenderers:(NSArray<ATHRenderer *> *)renderers NS_DESIGNATED_INITIALIZER;
- (void)scenePressed:(CGPoint)location;
@end
