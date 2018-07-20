//
//  ATHEventType.h
//  AetherPlayer
//
//  Created by Stefan Vukanić on 6/5/18.
//

#import <Foundation/Foundation.h>

extern const struct ATHEventTypeS{
    __unsafe_unretained NSString* PLAY;
    __unsafe_unretained NSString* PAUSE;
    __unsafe_unretained NSString* END;
    __unsafe_unretained NSString* CLOSE;
    __unsafe_unretained NSString* SEEK;
    __unsafe_unretained NSString* SEEKED;
    __unsafe_unretained NSString* FULLSCREEN;
    __unsafe_unretained NSString* WINDOWED;
    __unsafe_unretained NSString* VIEW_MODE_CHANGE;
    __unsafe_unretained NSString* DISPLAY;
    __unsafe_unretained NSString* DISPLAYED;
    __unsafe_unretained NSString* FAIL;
    __unsafe_unretained NSString* HOVER;
    __unsafe_unretained NSString* INTERACT;
} ATHEventType;

typedef const __unsafe_unretained NSString* ATHEventTypeAlias;
