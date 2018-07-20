//
//  ATHCallout.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 2/16/18.
//

typedef NS_ENUM(NSInteger, ATHCalloutType) {
    ATHCalloutTypeIcon,
};

@interface ATHCallout : NSObject
@property (nonatomic, assign) ATHCalloutType type;
@property (nonatomic, strong, nonnull) id content;
@property (nonatomic, assign) BOOL timed;
@property (nonatomic, assign) float from;
@property (nonatomic, assign) float to;
@property (nonatomic, assign) float anchor;
+ (nullable instancetype)calloutFromDictionary:(NSDictionary * _Nullable)dictionary;
@end

@interface ATHCallout (Preloading)
- (void)whenReady:(void(^_Nonnull)(void))block;
@end
