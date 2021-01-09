//
//  Start.h
//  Puz
//
//  Created by Ian Callaghan on 5/28/15.


#import "cocos2d.h"
#import "cocos2d-ui.h"
#import "CCScene.h"
#import "GameCenterManager.h"
//#import "LoopsGK/LoopsGK.h"
#import <GameKit/GameKit.h>
#import <Storekit/Storekit.h>
#import "RMStore.h"


#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

#define RAND_FROM_TO(min,max) (min + arc4random_uniform(max - min + 1))

#define IS_RETINA ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0))
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE5 (!IS_IPAD && [UIScreen mainScreen].bounds.size.height > 480.0f)

#define MAX_STARS   50
#define MAX_DEPTH   200
#define SCALE       128

@interface Start : CCScene <GameCenterManagerDelegate>
{
    int starMoveCount;
    float aa;
    
    float starsX[MAX_STARS];
    float starsY[MAX_STARS];
    float starsZ[MAX_STARS];

    float durationCount;
    float starOpacity;
    
    float logoOpacity;
    
    NSMutableArray *starArray;
    
    int settingsMenuActive;
    int socialMenuActive;
    
    int settingsButtonInMotion;
    int socialButtonInMotion;
    
    OALSimpleAudio *audio;
    
    // Settings stuff
    int sound;
    int music;
    int fbConnect;
    int notifications;
    int fbLikeBonus;

    
    
}


+(Start *)scene;

@end
