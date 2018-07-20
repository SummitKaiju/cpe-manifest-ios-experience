//
//  ATHOverlayView.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 2/23/18.
//

#import <UIKit/UIKit.h>
#import "ATHControlsView.h"
#import <AVFoundation/AVFoundation.h>
#if TARGET_OS_TV
#import "ATHSeekBar.h"
#import "TVOverlayButton.h"
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ATHOverlayViewPrimaryAction) {
    ATHOverlayViewPrimaryActionNone,
    ATHOverlayViewPrimaryAction360,
    ATHOverlayViewPrimaryActionCardboard,
    ATHOverlayViewPrimaryActionCloseCardboard,
};

typedef NS_ENUM(NSInteger, ATHOverlayViewFullscreenAction) {
    ATHOverlayViewFullscreenActionNone,
    ATHOverlayViewFullscreenActionFullscreen,
    ATHOverlayViewFullscreenActionCloseFullscreen,
};

#if TARGET_OS_IOS
@protocol ATHOverlayViewDelegate <ATHControlsViewDelegate>
#else
@protocol ATHOverlayViewDelegate <ATHSeekBarDelegate>
#endif
@optional
- (void)didPressBackButton;
- (void)didPressPrimaryAction;
- (void)didTogglePlayback;
- (void)didToggleFullscreen;
@end

@interface ATHOverlayViewChainDelegate : NSObject <ATHOverlayViewDelegate>
- (instancetype)initWith:(id<ATHOverlayViewDelegate> _Nullable)one and:(id<ATHOverlayViewDelegate> _Nullable)two;
@end

#if TARGET_OS_IOS
@interface ATHOverlayView : UIView <ATHControlsViewDelegate>
#else
@interface ATHOverlayView : UIView <ATHSeekBarDelegate>
#endif
@property(nonatomic, weak, nullable) id<ATHOverlayViewDelegate> delegate;
@property(nonatomic) BOOL showBackButton;
@property(nonatomic) ATHOverlayViewPrimaryAction primaryAction;
@property(nonatomic) BOOL showPlaybackUI;
@property(nonatomic) BOOL showFullscreen;
@property(nonatomic) Float64 duration;
@property(nonatomic) Float64 time;
@property(nonatomic) BOOL playing;
@property(nonatomic) BOOL didReachEnd;
@property(nonatomic) BOOL showSpinner;
@property(nonatomic) ATHOverlayViewFullscreenAction fullscreen;
@property (weak, nonatomic, nullable) IBOutlet ATHControlsView *controlsView;

- (BOOL)isProgressFocused;
- (BOOL)isProgressActive;
@end

NS_ASSUME_NONNULL_END
