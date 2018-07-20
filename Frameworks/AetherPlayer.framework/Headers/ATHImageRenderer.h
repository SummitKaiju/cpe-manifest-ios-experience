//
//  ATHImageRenderer.h
//  Pods-Aether
//
//  Created by Stefan Vukanić on 3/8/18.
//

#import "ATHRenderer.h"

@import UIKit;

@interface ATHImageRenderer : ATHRenderer

@property (nonatomic, strong) id (^openPreview)(UIView *);
@property (nonatomic, strong) void (^closePreview)(id);

- (void)setPreviewView:(UIView*)container;
- (void)updatePosition:(SCNVector3)position andSceneSize:(CGSize)size;

@end
