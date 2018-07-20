//
//  ATHPosition.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 6/5/18.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ATHPositionSide) {
    ATHPositionSideCenter,
    ATHPositionSideTop,
    ATHPositionSideRight,
    ATHPositionSideBottom,
    ATHPositionSideLeft,
};

@interface ATHPosition : NSObject
@property (nonatomic, assign) ATHPositionSide side;
+ (nullable instancetype)positionFromDictionary:(NSDictionary * _Nullable)dictionary;
@end
