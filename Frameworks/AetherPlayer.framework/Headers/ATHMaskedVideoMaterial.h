//
//  ATHMaskedVideoMaterial.h
//  Pods
//
//  Created by Miloš Žikić on 3/30/18.
//

#import "ATHVideoMaterial.h"

@interface ATHMaskedVideoMaterial : ATHVideoMaterial
-(instancetype)init:(id)videoContent andMask:(id)maskContent NS_DESIGNATED_INITIALIZER;
@end
