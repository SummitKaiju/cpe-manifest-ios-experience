//
//  ATHVideoRenderer.h
//  Pods-Aether
//
//  Created by Stefan Vukanić on 3/8/18.
//

#import "ATHRenderer.h"
#import "ATHLayer.h"

@import AVFoundation;

@interface ATHVideoRenderer : ATHRenderer

- (void) pause;
- (void) play;

@end
