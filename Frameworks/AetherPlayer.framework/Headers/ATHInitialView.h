//
//  ATHInitialView.h
//  AetherPlayer-iOS
//
//  Created by Jovan Erčić on 4/4/18.
//

#import <Foundation/Foundation.h>

@interface ATHInitialView : NSObject
@property(nonatomic, assign) float yaw;
@property(nonatomic, assign) float pitch;
@property(nonatomic, assign) float roll;
+ (nullable instancetype)initialViewFromDictionary:(NSDictionary * _Nullable)dictionary;
@end

