//
//  ATHAVPlayerView.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/1/18.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ATHAVPlayerView : UIView
- (instancetype)initWithPlayer:(AVPlayer *)player NS_DESIGNATED_INITIALIZER;
- (AVPlayer *)player;
@end
