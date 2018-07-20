//
//  ATH360Rectangle.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/2/18.
//

#import <Foundation/Foundation.h>

@interface ATH360Rectangle : NSObject
@property(nonatomic, assign) float x;
@property(nonatomic, assign) float y;
@property(nonatomic, assign) float z;
@property(nonatomic, assign) float width;
@property(nonatomic, assign) float height;
@property(nonatomic, assign) float yaw;
@property(nonatomic, assign) float pitch;
@property(nonatomic, assign) float roll;
+ (nullable instancetype)rectangleFromDictionary:(NSDictionary * _Nullable)dictionary;
@end
