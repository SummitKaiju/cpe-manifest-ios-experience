//
//  ATHCallout.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 2/16/18.
//

@class ATHContent;

typedef NS_ENUM(NSInteger, ATHCalloutType) {
    ATHCalloutTypeIcon,
    ATHCalloutTypeSceneLink,
};

@interface ATHCallout : NSObject
@property (nonatomic, assign) ATHCalloutType type;
@property (nonatomic, strong, nonnull) ATHContent* content;
@property (nonatomic, assign) BOOL timed;
@property (nonatomic, assign) float from;
@property (nonatomic, assign) float to;
@property (nonatomic, assign) float anchor;
+ (nullable instancetype)calloutFromDictionary:(NSDictionary * _Nullable)dictionary andContentResolver:(ATHContent *(^__nullable)(id))contentResolver;
@end

@interface ATHCallout (Preloading)
- (void)whenReady:(void(^_Nonnull)(void))block;
@end
