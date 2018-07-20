//
//  ATH360ContentViewController.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/1/18.
//

#import "ATHContentViewController.h"
#import "ATHSceneKit.h"
#import "ATHRendererView.h"

@interface ATH360ContentViewController : ATHContentViewController <ATHRendererViewDelegate>
@property (nonatomic, assign) BOOL isEmbedded;
@property (nonatomic, readonly, strong) UIView *previewView;
- (NSArray<ATHRenderer *> *)getRenderersStartingFrom:(int)zIndex;
@end
