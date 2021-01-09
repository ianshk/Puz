
#import "cocos2d.h"
#import "cocos2d-ui.h"
#import <Storekit/Storekit.h>
#import <GameKit/GameKit.h>

// Unity ads
#import <UnityAds/UnityAds.h>


#import "GameCenterManager.h"
#import "RMStore.h"

//---------------------------------------------------------------------------------------------------------------------

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define RAND_FROM_TO(min,max) (min + arc4random_uniform(max - min + 1))

#define IS_RETINA ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0))
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE5 (!IS_IPAD && [UIScreen mainScreen].bounds.size.height > 480.0f)

#define GRID_MAX_X      6
#define GRID_MAX_Y      6
#define GRID_BLOCK_SIZE 52 // 104 -hd, 208 - ipadhd

#define Z_UIBASE        4
#define Z_EXIT          3
#define Z_BLOCKS        2
#define Z_ARROW         1
#define HORIZONTAL      1
#define VERTICAL        0

// Player
#define BLANK           0
#define PLAYER          1
#define PLAYER_2        2
#define WINNER          3

#define TYPE_1x1        3

// Vertical
#define TYPE_1x2_START      0x40
#define TYPE_1x2            0x41

#define TYPE_1x3_START      0x50
#define TYPE_1x3            0x51

#define TYPE_1x4_START      0x60
#define TYPE_1x4            0x61

// Horizontal
#define TYPE_2x1_START      0x70
#define TYPE_2x1            0x71

#define TYPE_3x1_START      0x80
#define TYPE_3x1            0x81

#define TYPE_4x1_START      0x90
#define TYPE_4x1            0x91

// Square
#define TYPE_2x2_START      0xA0
#define TYPE_2x2            0xA1

// Horizontal
/*
#define TYPE_2x1        7
#define TYPE_2x2        8
#define TYPE_3x1        9
#define TYPE_4x1        10
*/

#define LEFT            1
#define RIGHT           2
#define UP              3
#define DOWN            4

// Milk status / moves in and out
#define MILK_RESET          0 // starts the right of the screen
#define MILK_CENTER_DONE    1
#define MILK_RIGHT_DONE     2

#define MAX_STARS_STAGE     50
#define MAX_DEPTH   200
#define SCALE       128

#define EYES_TOP            1
#define EYES_TOP_LEFT       2
#define EYES_TOP_RIGHT      3
#define EYES_LEFT           4
#define EYES_RIGHT          5
#define EYES_BOTTOM         6
#define EYES_BOTTOM_LEFT    7
#define EYES_BOTTOM_RIGHT   8

#define BLOCK_MOVE_SPEED    0.12

#define LAST_STAGE          120

@interface Stage : CCScene <UnityAdsDelegate>
{
    NSMutableArray *blockSprites;   // Block sprite data
    NSMutableArray *pausedSprites;  // Container which will get faded out on pause
    NSMutableArray *pauseScreenSprites;
    NSMutableArray *gridAndTiles;   // Used for in and out animations
    
    NSMutableArray *headerSprites;
    
  
    
    int gridWidth;
    int gridHeight;
    
    unsigned char map[72];
    
    unsigned char tiles1D[GRID_MAX_X * GRID_MAX_Y];       // Holds the tiles data 1D
    unsigned char blockGrid1D[GRID_MAX_X * GRID_MAX_Y];   // Holds the blocks data 1D
    unsigned char tiles[GRID_MAX_X][GRID_MAX_Y];         //  tiles 2D array
    unsigned char blocks[GRID_MAX_X][GRID_MAX_Y];      //  blocks 2D array
    
    int savedBlockID;
    int savedBlockType;
    
    int topPadding;
    int leftPadding;
    int moveInProgress;
  //  int moves;
    int bestCount;
    
   // int exitX;
   // int exitY;

    int playerWin;
    int playersConnected;
    int moveCount;
    
    int stageValue;
    
    CCLabelTTF *movesVal;
  //  CCLabelTTF *movesWinVal;
    

    
    int pausedPressed;
    
    
    // star stuff
    int starMoveCount;
    float aa;
    
    float starsX[MAX_STARS_STAGE];
    float starsY[MAX_STARS_STAGE];
    float starsZ[MAX_STARS_STAGE];
    
    float durationCount;
    float starOpacity;
    
    unsigned short target;
    unsigned short starReach;
    
   // unsigned int player1or2;
    
    NSMutableArray *starArray;
    
    
    /*
    UISwipeGestureRecognizer *swipeLeftRecognizer;
    UISwipeGestureRecognizer *swipeRightRecognizer;
    UISwipeGestureRecognizer *swipeUpRecognizer;
    UISwipeGestureRecognizer *swipeDownRecognizer;
    */
    
    // Add pad recognizers
    
    UIPanGestureRecognizer *panLeftRecognizer;
    UIPanGestureRecognizer *panRightRecognizer;
    UIPanGestureRecognizer *panUpRecognizer;
    UIPanGestureRecognizer *panDownRecognizer;
    
    
    // variables used for the eye code
  //  int player1BlockID; // This should not change so stor the block ID for fast lookup of the player
  //  int savedPlayer2BlockID;
    
    int exitX;
    int exitY;
    
    int exitXPos;
    
    OALSimpleAudio *audio;
    
    // Settings stuff
    int sound;
    int music;
    int fbConnect;
    int notifications;
    int rated;
    
    int stage2tutPhase;
    int stage3tutPhase;
    
    int phaseSwitched;
    
    int UIBaseShown; // if shown disable bg stuff
    
    // Store stuff
    NSArray *_products;
    BOOL _productsRequestFinished;
    int iapRequestOK;
    
    NSString *unlimitedPrice;
    NSString *unlimitedTitle;
    
    int upgradeModeActive;
    int fbLikeUsed;
    
    int starCount;
    
    CCMotionStreak *streakCurrent;
    int videoWatched;
    int videoAvailable;
    
    int videoRunning; // use to disable all buttons on the scene
    
    UIImage *screenCapture;
    
    int iPadScale;
}




//---------------------------------------------------------------------------------------------------------------------
+ (Stage *)scene;

/*
@property (retain)UISwipeGestureRecognizer *swipeLeftRecognizer;
@property (retain)UISwipeGestureRecognizer *swipeRightRecognizer;
@property (retain)UISwipeGestureRecognizer *swipeUpRecognizer;
@property (retain)UISwipeGestureRecognizer *swipeDownRecognizer;
*/

@property (retain)UIPanGestureRecognizer *panRecognizer;



@end
