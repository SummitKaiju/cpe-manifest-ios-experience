//
//  NSArrayExtensions.h
//  AetherPlayer-iOS
//
//  Created by Jovan Erčić on 3/26/18.
//

#import <Foundation/Foundation.h>

@interface NSArray<__covariant ObjectType> (NSArrayExtensions)
- (void)forEach:(void(^)(id))f;
@end
