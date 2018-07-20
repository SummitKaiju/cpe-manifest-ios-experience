//
//  ATHChromaVideoMaterial.h
//  Pods
//
//  Created by Miloš Žikić on 3/30/18.
//

#import "ATHVideoMaterial.h"

@interface ATHChromaVideoMaterial : ATHVideoMaterial
-(instancetype)init:(id)videoContent andChromaColor:(UIColor *)chromaColor NS_DESIGNATED_INITIALIZER;
@end
