//
//  MSInterfaceOrientationProvider.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 3/14/18.
//

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>


@protocol MSInterfaceOrientationProvider <NSObject>
- (UIInterfaceOrientation)interfaceOrientationAtTime:(NSTimeInterval)time;
@end

@interface UIApplication (InterfaceOrientationProvider)
- (UIInterfaceOrientation)interfaceOrientationAtTime:(NSTimeInterval)time;
@end

@interface MSDefaultInterfaceOrientationProvider : NSObject <MSInterfaceOrientationProvider>
- (UIInterfaceOrientation)interfaceOrientationAtTime:(NSTimeInterval)time;
@end

#endif
