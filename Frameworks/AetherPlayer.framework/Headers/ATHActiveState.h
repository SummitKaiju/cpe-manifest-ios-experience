//
//  ATHActiveState.h
//  AetherPlayer-iOS
//
//  Created by Jovan Erčić on 3/30/18.
//

#import <Foundation/Foundation.h>
@import UIKit;
@import AVFoundation;

typedef NS_ENUM(NSInteger, ATHActiveStateType) {
    ATHActiveStateTypeImage,
    ATHActiveStateTypeVideo,
    ATHActiveStateTypeLink,
};

@class ATHContent;

@interface ATHActiveState : NSObject
@property (nonatomic, assign) ATHActiveStateType type;
@property (nonatomic, strong, nullable) NSURL *url;
@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, strong, nullable) AVPlayer *player;
@property (nonatomic, strong, nullable) ATHContent *content;
+ (nullable instancetype)stateFromDictionary:(NSDictionary * _Nullable)dictionary andContentResolver:(ATHContent *(^__nullable)(id))contentResolver;
- (void)whenReady:(void(^_Nonnull)(void))block;
@end
