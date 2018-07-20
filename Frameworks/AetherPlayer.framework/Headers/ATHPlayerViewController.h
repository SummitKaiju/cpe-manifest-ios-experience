//
//  ATHPlayerViewController.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 2/16/18.
//

#import <UIKit/UIKit.h>

#import "ATHContent.h"
#import "ATHViewMode.h"
#import "ATHSceneObject.h"
#import <SceneKit/SceneKit.h>

@interface ATHError : NSObject
@end

NS_ASSUME_NONNULL_BEGIN

@interface ATHPlayerViewController : UINavigationController
@property(nonatomic, assign) BOOL isEmbedded;
+ (ATHPlayerViewController *)playerViewControllerWithContent:(ATHContent *)content;
+ (ATHPlayerViewController *)playerViewControllerWithIMF:(NSData *)imf;
+ (ATHPlayerViewController *)playerViewControllerWithURL:(NSURL *)url;
- (void)startPreloading;
- (void)pushContent:(ATHContent * _Nonnull)content startingAt:(double)time animated:(BOOL)animated;
- (void)pushContent:(ATHContent * _Nonnull)content animated:(BOOL)animated;
- (CMTime)contentDuration;
- (CMTime)currentContentTime;
- (NSURL*)currentContentUrl;
@end

@protocol ATHPlayerViewControllerDelegate <NSObject>
@optional
- (void)player:(ATHPlayerViewController *)player didPlay:(BOOL)onUserRequest;
- (void)player:(ATHPlayerViewController *)player didPause:(BOOL)onUserRequest;
- (void)player:(ATHPlayerViewController *)player didHoverObject:(ATHSceneObject *)sceneObject;
- (void)player:(ATHPlayerViewController *)player didPressObject:(ATHSceneObject *)sceneObject;
- (void)playerDidReachEnd:(ATHPlayerViewController *)player;
- (void)playerWillClose:(ATHPlayerViewController *)player;

- (void)player:(ATHPlayerViewController *)player willSeekTo:(CMTime)time;
- (void)player:(ATHPlayerViewController *)player didSeekTo:(CMTime)time;

- (void)playerWillGoToFullscreen:(ATHPlayerViewController *)player;
- (void)playerWillGoBackFromFullscreen:(ATHPlayerViewController *)player;

- (void)player:(ATHPlayerViewController *)player didChangeViewMode:(ATHViewMode)mode;

- (void)player:(ATHPlayerViewController *)player willDisplayContent:(ATHContent *)content;
- (void)player:(ATHPlayerViewController *)player didDisplayContent:(ATHContent *)content;
- (void)player:(ATHPlayerViewController *)player didFailToDisplayContent:(ATHError *)content;
@end

@interface ATHPlayerViewController ()
@property(nonatomic, weak) id<ATHPlayerViewControllerDelegate> playerViewDelegate;
@end

NS_ASSUME_NONNULL_END
