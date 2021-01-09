//
//  Menu.h
//  Puz
//
//  Created by Ian Callaghan on 6/1/15.
//

#import "cocos2d.h"
#import "cocos2d-ui.h"
#import "CCScene.h"
#import "Flurry.h"

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define RAND_FROM_TO(min,max) (min + arc4random_uniform(max - min + 1))

#define IS_RETINA ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0))
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE5 (!IS_IPAD && [UIScreen mainScreen].bounds.size.height > 480.0f)

#define MENU_HEIGHT 5
#define MENU_WIDTH  4

#define PAGES       7

#define MAX_DEPTH   200
#define SCALE       128

#define MAX_LEVELS  120

@interface Menu : CCScene
{
    CCScrollView *scrollView;
    NSMutableArray *menuNodes;
    
    int currentPage;
    int previousPage; // only draw dots if page has changed
    
    // Stars
    
    int starMoveCount;
    float aa;
    
    float starsX[MAX_STARS];
    float starsY[MAX_STARS];
    float starsZ[MAX_STARS];
    
    float durationCount;
    float starOpacity;
    
    NSMutableArray *starArray;
    NSMutableArray *menuDots;
    
    // Parsed level data
    unsigned char starData[120];
    unsigned char lockedData[120];
    unsigned short bestData[120];
    
    int starCount;
    
    OALSimpleAudio *audio;
    
    // Settings stuff
    int sound;
    int music;
    int fbConnect;
    int notifications;
    int fbLikeBonus;
    
    int scrolling;
    
}


+(Menu *)scene;



@end
