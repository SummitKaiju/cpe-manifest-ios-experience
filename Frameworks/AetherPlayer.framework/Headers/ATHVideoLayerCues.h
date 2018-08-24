//
//  ATHVideoLayerCues.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/9/18.
//

@interface ATHVideoLayerCues : NSObject
@property (nonatomic, assign) float hover;
@property (nonatomic, assign) float action;
+ (nullable instancetype)cuesFromDictionary:(NSDictionary * _Nullable)dictionary;
@end
