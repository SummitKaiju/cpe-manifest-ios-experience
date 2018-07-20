//
//  ATHVideoMaterial.h
//  Pods
//
//  Created by Miloš Žikić on 3/30/18.
//

@import AVFoundation;
@import SceneKit;

@interface ATHVideoMaterial : SCNMaterial
- (instancetype)init:(AVPlayer *)player NS_DESIGNATED_INITIALIZER;
@end
