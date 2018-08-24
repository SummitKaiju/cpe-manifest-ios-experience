//
//  ATHControlsView.h
//  AetherPlayer-iOS
//
//  Created by Stefan Vukanić on 3/28/18.
//

#import <UIKit/UIKit.h>

@protocol ATHControlsViewDelegate <NSObject>
@optional
- (void)didBeginSeekingTo:(CGFloat)percentage;
- (void)didSeekTo:(CGFloat)percentage;
- (void)didEndSeekingTo:(CGFloat)percentage;
- (void)didSkipTo:(CGFloat)percentage;
@end

@interface ATHControlsView : UIView <UIGestureRecognizerDelegate>
@property(nonatomic, weak) UIProgressView * _Nullable progressView;
@property(nonatomic, weak, nullable) id<ATHControlsViewDelegate> delegate;
@end
