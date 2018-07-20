//
//  ATHHoverState.h
//  AetherPlayer-iOS
//
//  Created by Jovan Erčić on 3/30/18.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ATHHoverStateType) {
    ATHHoverStateTypeRaise,
};

@interface ATHHoverState : NSObject
@property (nonatomic, assign) ATHHoverStateType type;
+ (nullable instancetype)stateFromDictionary:(NSDictionary * _Nullable)dictionary;
@end
