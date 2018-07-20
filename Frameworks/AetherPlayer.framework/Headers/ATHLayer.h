//
//  ATHLayer.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/2/18.
//

#import "ATH360Rectangle.h"
#import "ATHVideoLayerCues.h"
#import "ATHHoverState.h"
#import "ATHActiveState.h"
#import "ATHPosition.h"

#import "UIColorExtension.h"

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, ATHLayerType) {
    ATHLayerTypeImage,
    ATHLayerTypeVideo,
};

typedef NS_ENUM(NSInteger, ATHLayerTransparency) {
    ATHLayerTransparencyNone,
    ATHLayerTransparencyChromaKey,
    ATHLayerTransparencyMask,
};

@interface ATHLayer : NSObject
@property (nonatomic, assign) ATHLayerType type;
@property (nonatomic, assign, nullable) NSString *layerId;
@property (nonatomic, assign) ATHLayerTransparency transparency;
@property (nonatomic, strong, nullable) NSURL *url;
@property (nonatomic, strong, nullable) NSURL *mask;
@property (nonatomic, strong, nullable) UIColor *maskColor;
@property (nonatomic, strong, nullable) ATHVideoLayerCues *cues;
@property (nonatomic, strong, nullable) ATH360Rectangle *rectangle;
@property (nonatomic, strong, nullable) ATHPosition *position;
@property (nonatomic, strong, nullable) ATHHoverState *hover;
@property (nonatomic, strong, nullable) ATHActiveState *active;
+ (nullable instancetype)layerFromDictionary:(NSDictionary * _Nullable)dictionary;

@property (nonatomic, strong, nullable) AVPlayer *player;
@property (nonatomic, strong, nullable) AVPlayer *maskPlayer;
@property (nonatomic, strong, nullable) UIImage *image;
- (void)whenReady:(void(^_Nonnull)(void))block;
@end
