//
//  ATHOrientation.h
//  AetherPlayer
//
//  Created by Jovan Erčić on 2/20/18.
//

#import <GLKit/GLKMatrix4.h>

struct ATHOrientation {
    float yaw, pitch, roll;
};

typedef struct ATHOrientation ATHOrientation;

ATHOrientation ATHOrientationMake(GLKMatrix4 matrix);
