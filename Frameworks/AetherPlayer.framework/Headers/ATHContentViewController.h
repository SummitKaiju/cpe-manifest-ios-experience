//
//  ATHContentViewController.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 2/23/18.
//

#import "ATHOverlayView.h"
#import "ATHContent.h"
#import "ATHViewMode.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import <SceneKit/SceneKit.h>
#import "ATHSceneObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ATHContentViewControllerDelegate <NSObject>
@optional
- (void)didPressBackButton;
- (void)didPressPrimaryAction;
- (void)didTogglePlayback;
- (void)didPlay:(BOOL)onUserRequest;
- (void)didPause:(BOOL)onUserRequest;
- (void)didToggleFullscreen:(BOOL)state;
- (void)playbackStartedAt:(CMTime)time withDuration:(CMTime)duration;
- (void)playbackMovedTo:(CMTime)time withDuration:(CMTime)duration;
- (void)playbackStoppedAt:(CMTime)time withDuration:(CMTime)duration;
- (void)playbackDidReachEnd;
- (void)didHoverObject:(ATHSceneObject*)object;
- (void)didPressObject:(ATHSceneObject*)object;
- (void)didDeselectObjects;
- (void)didOpenVR;
- (void)didCloseVR;
- (void)willSeekTo:(CMTime)time;
- (void)didSeekTo:(CMTime)time;
- (void)didChangeViewMode:(ATHViewMode)mode;

@end

@interface ATHContentViewController : UIViewController <ATHOverlayViewDelegate>
@property (nonatomic, weak, nullable) id<ATHContentViewControllerDelegate> delegate;
@property (nonatomic, readonly, strong) ATHOverlayView *overlayView;
@property (nonatomic, strong) ATHContent *content;
@property (nonatomic, assign) BOOL isEmbedded;
@property (nonatomic, assign) BOOL canGoBack;
- (instancetype)initWithContent:(ATHContent *)content;
- (instancetype)initWithContent:(ATHContent *)content andStartTime:(double)time NS_DESIGNATED_INITIALIZER;
@property (NS_NONATOMIC_IOSONLY, getter=getFullscreen, readonly) ATHOverlayViewFullscreenAction fullscreen;
- (void)requestNumberOfTapsForOverlay:(int)n;
- (void)didPressScene;
- (void)didPressBackButton;
- (void)didPressPrimaryAction;
- (void)didTogglePlayback;
- (void)didToggleFullscreen;
- (void)playbackStartedAt:(CMTime)time withDuration:(CMTime)duration;
- (void)playbackMovedTo:(CMTime)time withDuration:(CMTime)duration;
- (void)playbackStoppedAt:(CMTime)time withDuration:(CMTime)duration;
- (void)playbackDidReachEnd;
- (void)childWillPopAt:(double)time withContent:(ATHContent *)content;

- (void)setRate:(float)rate;
- (void)setPaused;
- (void)setPlayingNormal;

- (void)previewOpened;
- (void)previewClosed;
- (int)previews;

@property (NS_NONATOMIC_IOSONLY, readonly) double currentTime;
@property (NS_NONATOMIC_IOSONLY, readonly) double startTime;
@end
NS_ASSUME_NONNULL_END
