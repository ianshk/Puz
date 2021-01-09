//
//  Screenshot.m
//  Puz
//
//  Created by Ian Callaghan on 8/30/15.


#import "Screenshot.h"

@implementation Screenshot


- (CCRenderTexture*)screenGrab:(CCNode*)startNode
{
    CCRenderTexture* rtx = [CCRenderTexture renderTextureWithWidth:SCREEN_WIDTH height:SCREEN_HEIGHT];
    
    [rtx begin];
    [startNode visit];
    [rtx end];
    
    // save as file as PNG
    // NOTE: using saveBuffer without format will write the file as JPG which are painfully slow to load on iOS!
  //  [rtx saveBuffer:[self screenshotPathForFile:filename] format: ];
    
    return rtx;
}


@end
