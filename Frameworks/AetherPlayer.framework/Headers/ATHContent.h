//
//  ATHContent.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 2/16/18.
//

#import "ATHCallout.h"
#import "ATHLayer.h"
#import "ATHInitialView.h"

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, ATHContentType) {
    ATHContentTypeRegularVideo,
    ATHContentType360Video,
    ATHContentType360Image,
};

@interface ATHContent : NSObject
@property (nonatomic, assign) ATHContentType type;
@property (nonatomic, strong, nullable) NSURL *url;
@property (nonatomic, strong, nullable) NSArray<ATHLayer *> *layers;
@property (nonatomic, strong, nullable) NSArray<ATHCallout *> *callouts;
@property (nonatomic, strong, nullable) ATHInitialView *initialView;
@property (nonatomic, assign) BOOL sync;
@property (nonatomic, assign) BOOL looping;
@property (nonatomic, assign) float anchor;
+ (nullable instancetype)contentFromDictionary:(NSDictionary * _Nullable)dictionary;
+ (nullable instancetype)contentFromIMF:(NSData * _Nullable)imf;
+ (nullable instancetype)contentFromURL:(NSURL * _Nullable)url;

+ (void)contentFromURL:(NSURL * _Nullable)url callback:(void(^ _Nonnull)(ATHContent * _Nullable))callback;

@property (nonatomic, strong, nullable) AVPlayer *player;
@property (nonatomic, strong, nullable) UIImage *image;
- (void)whenReady:(void(^_Nonnull)(void))block;
- (void)forceReady;
- (BOOL)isForced;
@end
