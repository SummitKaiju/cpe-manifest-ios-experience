//
//  ThrottledDispatch.h
//  AetherPlayer-iOS
//
//  Created by Stefan Vukanić on 3/27/18.
//

#import <Foundation/Foundation.h>

@interface ThrottledDispatch : NSObject
+ (void)runBlock:(void (^)(void))block withIdentifier:(NSString *)identifier throttle:(CFTimeInterval)bufferTime;
@end
