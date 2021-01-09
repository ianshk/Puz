//
//  Screenshot.h
//  Puz
//
//  Created by Ian Callaghan on 8/30/15.
//


#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "cocos2d-ui.h"

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

@interface Screenshot : NSObject
{
    
}

- (CCRenderTexture*)screenGrab:(CCNode*)startNode;

@end
