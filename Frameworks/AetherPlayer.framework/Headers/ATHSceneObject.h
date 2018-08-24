//
//  ATHSceneObject.h
//  Pods
//
//  Created by Stefan Vukanić on 4/5/18.
//

#import <Foundation/Foundation.h>

@interface ATHSceneObject : NSObject
@property(nonatomic, assign) NSString *layerName;

+ (ATHSceneObject*)objectWithLayerName:(NSString *)name;
- (instancetype)initWithLayerName:(NSString *)name;
@end
