#import "Stage.h"
#import "Blocks.h"
#import "Stage.h"
#import "Start.h"
#import "Menu.h"
#import "GameGlobals.h"
#import "File.h"
#import "MBProgressHUD.h"
#import "Reachability.h"




static inline int FY(int y) {return (SCREEN_HEIGHT-y);}

@implementation Stage


+ (Stage *)scene
{
    return [[self alloc] init];
}

@synthesize panRecognizer;



- (void)initVars
{
    self.userInteractionEnabled = YES;
    
    //  blockArray = [[NSMutableArray alloc]init];
    blockSprites = [[NSMutableArray alloc]init];
    pausedSprites = [[NSMutableArray alloc]init];
    pauseScreenSprites = [[NSMutableArray alloc]init];
    gridAndTiles = [[NSMutableArray alloc]init];
    headerSprites = [[NSMutableArray alloc]init];


    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
    [[[CCDirector sharedDirector] view] addGestureRecognizer:panRecognizer];
    
 //   [self clearGameGrid];
    
    moveInProgress = 1;
    playerWin = 0;
    moveCount = 0;
    stageValue = 1;
    pausedPressed = 0;
    
    starArray = [[NSMutableArray alloc]init];
    starMoveCount = 0;
    durationCount = 10;
    starOpacity = 0;
    
    playersConnected = 0;
    
    stage2tutPhase = 0;
    stage3tutPhase = 0;
    phaseSwitched = 0;
    
    UIBaseShown = 0;
    
    iapRequestOK = 0;
    
    upgradeModeActive = 0;
    fbLikeUsed = 0;
    
    videoWatched = 0;
    videoAvailable = 1;
    videoRunning = 0;
    
    unlimitedPrice = [[NSString alloc]init];
    
    _products = [[NSArray alloc]init];
    
    savedBlockID = -1;
    
   }



- (id)init
{
    self = [super init];
    if(!self) {
        return NULL;
    }
    
    // Load data
    [self initVars];
    [self loadMap];
    [self loadSettings];
    [self countStars];
    [self preLoadSounds];
    [self getGridDimensions];
    
    // Setup scene
    [self loadAtlases];

    [self setupBG];
    [self setupHeader];
    [self drawTiles];
    [self drawBlocks];
 //   [self createStreaks];
    
    [self bringInGridAndTiles];
    
    [self initStars];
    
   // [self tutorialHand];
    
    // IAP
    if([self isConnected]) {
        [self requestProducts];
        
    }
    else {
        iapRequestOK = 0;
    }
    


    
    [[UnityAds sharedInstance] setViewController:[CCDirector sharedDirector]];
    
    [[UnityAds sharedInstance] setDelegate:self];
    
    // Set the zone before checking readiness or attempting to show.
    [[UnityAds sharedInstance] setZone:@"defaultZone"];
    
    // Use the canShow method to check for zone readiness,
    //  then use the canShowAds method to check for ad readiness.
    if ([[UnityAds sharedInstance] canShow])
    {
        // If both are ready, show the ad.
      //  [[UnityAds sharedInstance] show];
    //    NSLog(@"video available");
        videoAvailable = 1;
    }
    else {
    //    NSLog(@"no video available");
        videoAvailable = 0;
    }

    
    return self;
}


- (void)preLoadSounds
{
    audio = [OALSimpleAudio sharedInstance];
    [audio preloadEffect:@"uiclick.caf"];
    [audio preloadEffect:@"uiclickback.caf"];
    [audio preloadEffect:@"teleport.caf"];
    [audio preloadEffect:@"swift.caf"];
    [audio preloadEffect:@"gamewin.caf"];
    
    if(audio.bgPlaying == FALSE && music == 1) {
        [audio preloadBg:@"gameloop.mp3"];
        [audio playBgWithLoop:YES];
    }
}


- (void)loadSettings
{
    File *file = [[File alloc]init];
    NSArray *settings = [file loadJSONfromFS:@"Settings.json"];
    
    NSDictionary *settingsDict = [settings objectAtIndex:0];
    
    sound = [[settingsDict objectForKey:@"Sound"] intValue];
    music = [[settingsDict objectForKey:@"Music"] intValue];
    fbConnect = [[settingsDict objectForKey:@"FBConnect"] intValue];
    notifications = [[settingsDict objectForKey:@"Notifications"] intValue];
    rated = [[settingsDict objectForKey:@"Rated"] intValue];
    
    // current best

    bestCount = [file getCurrentBest:stageValue :1];
    
    // Check if upgraded / iAP
    upgradeModeActive = [file checkUpgraded];
    fbLikeUsed = [file checkFBLiked];
    
    /*
    NSLog(@"sound %d",sound);
    NSLog(@"music %d",music);
    NSLog(@"fbConnect %d",fbConnect);
    NSLog(@"notifications %d",notifications);
    NSLog(@"rated %d",rated);
    
    NSLog(@"best count %d",bestCount);
    NSLog(@"upgrade active %d",upgradeModeActive);
    NSLog(@"fb like used %d",fbLikeUsed);
    */
}


- (void)saveSettings
{
    File *file = [[File alloc]init];
    [file saveSettings:sound :music :fbConnect :notifications :rated];
}


- (void)setupBG
{
    CCSprite9Slice *background = [CCSprite9Slice spriteWithImageNamed:@"white_square.png"];
    background.anchorPoint = CGPointZero;
    background.contentSize = [CCDirector sharedDirector].viewSize;
    background.color = [CCColor colorWithCcColor3b:ccc3(0x25, 0x2B, 0x31)];
    [self addChild:background];
}


- (void)setupHeader
{
    // Draw menu and pause buttons
    CCButton *menuButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"MenuButton.png"]];
    menuButton.position = ccp(0 + menuButton.contentSize.width, FY(0 + menuButton.contentSize.height));
    [menuButton setTarget:self selector:@selector(menuPressed)];
    [self addChild:menuButton z:Z_BLOCKS];
    
    CCButton *pauseButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"PauseButton.png"]];
    pauseButton.position = ccp(SCREEN_WIDTH - pauseButton.contentSize.width, FY(0 + pauseButton.contentSize.height));
    [pauseButton setTarget:self selector:@selector(pausePressed)];
    [self addChild:pauseButton z:Z_BLOCKS];
    
    topPadding = 0 + menuButton.contentSize.height * 3;
    

    
    // Moves - fixing for new resolutions, center moves first
    CCLabelTTF* movesTTF = [CCLabelTTF labelWithString:@"Moves" fontName:@"JosefinSans-Bold" fontSize:19];
    movesTTF.position = ccp(SCREEN_WIDTH / 2,
                         menuButton.position.y + menuButton.contentSize.height / 4);
    [self addChild:movesTTF z:1];
    
    // Moves Value
    NSString *movesString = [NSString stringWithFormat:@"%d",moveCount];
    movesVal = [CCLabelTTF labelWithString:movesString fontName:@"JosefinSans-Bold" fontSize:20];
    movesVal.position = ccp(movesTTF.position.x,movesTTF.position.y - movesVal.contentSize.height);
    [self addChild:movesVal z:1];
    
    
    // Stage
    CCLabelTTF *stageTTF = [CCLabelTTF labelWithString:@"Stage" fontName:@"JosefinSans-Bold" fontSize:19];
    stageTTF.position = ccp(movesTTF.position.x - stageTTF.contentSize.width * 1.6,
                         movesTTF.position.y);
    [self addChild:stageTTF z:1];
    
    // Stage Value
    NSString *stageString = [NSString stringWithFormat:@"%d",stageValue];
    CCLabelTTF *levelVal = [CCLabelTTF labelWithString:stageString fontName:@"JosefinSans-Bold" fontSize:20];
    levelVal.position = ccp(stageTTF.position.x,stageTTF.position.y - levelVal.contentSize.height);
    [self addChild:levelVal z:1];
    
    // Target
    CCLabelTTF* targetTTF = [CCLabelTTF labelWithString:@"Max" fontName:@"JosefinSans-Bold" fontSize:19];
    targetTTF.position = ccp(movesTTF.position.x + targetTTF.contentSize.width * 1.9,
                         movesTTF.position.y);
    targetTTF.name = @"targetTTF";
    [self addChild:targetTTF z:1];
    
    // Target value
    NSString *targetString = [NSString stringWithFormat:@"%d",target];
    CCLabelTTF *targetVal = [CCLabelTTF labelWithString:targetString fontName:@"JosefinSans-Bold" fontSize:20];
    targetVal.position = ccp(targetTTF.position.x,targetTTF.position.y - targetVal.contentSize.height);
    targetVal.name = @"targetVal";
    [self addChild:targetVal z:1];
    
    if(upgradeModeActive == 1) {
        int newTarget = target + 50;
        
        target += 50;
        NSString *newTargerStr = [NSString stringWithFormat:@"%d",newTarget];
        [targetVal setString:newTargerStr];
    }
    
    NSString *starsString = [NSString stringWithFormat:@"%d",starReach];
    
    // Create the stars amount / counter
    CCSprite *menuStar = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MenuStar.png"]];
    menuStar.position = ccp(pauseButton.position.x - menuStar.contentSize.width * 1.2,
                            pauseButton.position.y - menuStar.contentSize.height * 2.2);
    [self addChild:menuStar z:1];
    
    
    // Menu stars amount
    CCLabelTTF *starsAmountText = [CCLabelTTF labelWithString:starsString fontName:@"JosefinSans-Bold" fontSize:17];
    starsAmountText.position = ccp(menuStar.position.x + menuStar.contentSize.width / 2 + starsAmountText.contentSize.width / 2.0 + 4,
                                   menuStar.position.y);
    [self addChild:starsAmountText z:1];
    

    [headerSprites addObject:menuButton];
    [headerSprites addObject:pauseButton];
    [headerSprites addObject:stageTTF];
    [headerSprites addObject:levelVal];
    [headerSprites addObject:movesTTF];
    [headerSprites addObject:movesVal];
    [headerSprites addObject:targetTTF];
    [headerSprites addObject:targetVal];
    [headerSprites addObject:starsAmountText];
    [headerSprites addObject:menuStar];
    
    [pausedSprites addObject:menuButton];
    [pausedSprites addObject:pauseButton];
    [pausedSprites addObject:stageTTF];
    [pausedSprites addObject:levelVal];
    [pausedSprites addObject:movesTTF];
    [pausedSprites addObject:movesVal];
    [pausedSprites addObject:targetTTF];
    [pausedSprites addObject:targetVal];
    [pausedSprites addObject:starsAmountText];
    [pausedSprites addObject:menuStar];
    
}



- (unsigned short)readBE16:(const unsigned char *)p
{
    return (p[0] << 8) | p[1];
}


- (void)loadMap
{
    unsigned char gridValue;
    int dataLen;
    int x;
    int y;
    int count = 0;
    int levelNumber;
    
    GameGlobals* globals = [GameGlobals globals];
    levelNumber = globals.loadingLevel;
    stageValue = globals.loadingLevel;
    
    NSString *mapfn = [NSString stringWithFormat:@"%d.dat",levelNumber];
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:mapfn ofType:nil];
    NSData *mapData = [NSData dataWithContentsOfFile:path];
    dataLen = (int)[mapData length];
    
  //  NSLog(@"dataLen %d bytes",dataLen);
    
    // Data to 1D array
    memcpy(map, [mapData bytes], dataLen);
    
    // Tiles to 2D grid
    for(y=0;y<GRID_MAX_Y;y++) {
        for(x=0;x<GRID_MAX_X;x++) {
            gridValue = map[count];
            tiles[x][y] = gridValue;
            count++;
        }
    }
    
    // Blocks to 2D grid
    for(y=0;y<GRID_MAX_Y;y++) {
        for(x=0;x<GRID_MAX_X;x++) {
            gridValue = map[count];
            blocks[x][y] = gridValue;
            count++;
        }
    }
    
    target = [self readBE16:&map[72]];
    starReach = [self readBE16:&map[74]];
    
    
    //NSLog(@"path %@",path);
    //NSLog(@"mapdata %@",mapData);
    //NSLog(@"dataLen %d",dataLen);
    
  //  [self dumpTiles];
  //  [self dumpBlocks];
}


- (void)getGridDimensions
{
    gridWidth = [self calculateMapWidth];
    gridHeight = [self calculateMapHeight];
    

   // NSLog(@"grid Width %d",gridWidth);
   // NSLog(@"grid height %d",gridHeight);
}


- (void)saveBlockNumber:(int)blockID :(int)blockType
{
    savedBlockID = blockID;
    savedBlockType = blockType;
}


- (int)calculateMapWidth
{
    int x;
    int y;
    int width = 0;
    
    for(y=0;y<GRID_MAX_Y;y++) {
        for(x=0;x<GRID_MAX_X;x++) {
            if(tiles[x][y] > 0) {
                if(width < x) {
                    width = x;
                }
            }
        }
    }
    
    width++;
    
    return width;
}


- (int)calculateMapHeight
{
    int x;
    int y;
    int height = 0;
    
    for(y=0;y<GRID_MAX_Y;y++) {
        for(x=0;x<GRID_MAX_X;x++) {
            if(tiles[x][y] > 0) {
                if(height < y) {
                    height = y;
                }
            }
        }
    }
    
    height++;
    
    return height;
}

- (void)loadAtlases
{
    // Load the texture atlas
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"GameAtlas.plist"];
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"ShapesAtlas.plist"];
}


- (void)drawTiles
{
    int x;
    int y;
    int xPos;
    int yPos;
    
    unsigned char gridValue;
    int maxWidth;
    int tileWidth = 52;
    int tileHeight = 52;
    int topPad;
    int leftPad;
    
    
    
    // Just to get the block size
    CCSprite *tileSample = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"1.png"]];
    topPad = 0 + tileSample.contentSize.height * 2;
    tileWidth = tileSample.contentSize.width - 3;
    tileHeight = tileSample.contentSize.height - 3;
    
    maxWidth = gridWidth * tileWidth;
    leftPad = (SCREEN_WIDTH - maxWidth) / 2;
 
    
    for(y=0;y<gridHeight;y++) {
        for(x=0;x<gridWidth;x++) {
            gridValue = tiles[x][y];
            if(gridValue > 0) {
                NSString *tileStr = [NSString stringWithFormat:@"%d.png",gridValue];
                xPos = x * tileWidth;
                yPos = y * tileHeight;
                Blocks *gridSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:tileStr]];
                gridSprite.position = ccp(leftPad + (xPos + gridSprite.contentSize.width / 2) + SCREEN_WIDTH,
                                          FY(topPad + yPos + gridSprite.contentSize.height / 2));
                gridSprite.color = [CCColor colorWithCcColor4b:ccc4(0xef, 0xf4, 0xff, 0xff)]; //eff4ff //415A65 4C265E //#34495e
                
                [self addChild:gridSprite z:1];
                
                [pausedSprites addObject:gridSprite];
                [gridAndTiles addObject:gridSprite];
            }
        }
    }
}


- (void)drawBlocks
{
    int x;
    int y;
    unsigned char blockValue;
    int blockID = 0;
    int topPad;
    int leftPad;
    int tileWidth;
    int tileHeight;
    int maxWidth;
    
    CCSprite *tileSample = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"1.png"]];


    tileWidth = tileSample.contentSize.width - 3;
    tileHeight = tileSample.contentSize.height - 3;
    
    maxWidth = gridWidth * tileWidth;
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        topPad = (0 + tileSample.contentSize.height * 2) + 6;
        leftPad = ((SCREEN_WIDTH - maxWidth) / 2) + 6;
    }
    else {
        topPad = (0 + tileSample.contentSize.height * 2) + 3;
        leftPad = ((SCREEN_WIDTH - maxWidth) / 2) + 3;
    }
    
    for(y=0;y<gridHeight;y++) {
        for(x=0;x<gridWidth;x++) {
            blockValue = blocks[x][y];
            
            if(blockValue == PLAYER) {
                
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                Blocks *blockSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"1x1Player.png"]];
                blockSprite.position = ccp(leftPad + (x1 + (blockSprite.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + blockSprite.contentSize.height / 2));
                blockSprite.ID = blockID;
                blockSprite.x = x;
                blockSprite.y = y;
                blockSprite.tag = blockID;
                blockSprite.type = PLAYER;
                blockSprite.name = [NSString stringWithFormat:@"%d",blockID];
                blockSprite.isHighlighted = 0;
                [self addChild:blockSprite z:Z_BLOCKS];
                
                
                [blockSprites addObject:blockSprite];
                [pausedSprites addObject:blockSprite];
                [gridAndTiles addObject:blockSprite];
            }
            
            else if(blockValue == TYPE_1x1) {
                
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                Blocks *blockSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"1x1.png"]];
                blockSprite.position = ccp(leftPad + (x1 + (blockSprite.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + blockSprite.contentSize.height / 2));
                blockSprite.ID = blockID;
                blockSprite.x = x;
                blockSprite.y = y;
                blockSprite.type = TYPE_1x1;
                blockSprite.name = [NSString stringWithFormat:@"%d",blockID];
                blockSprite.isHighlighted = 0;
                
                [self addChild:blockSprite z:Z_BLOCKS];
                
                [blockSprites addObject:blockSprite];
                [pausedSprites addObject:blockSprite];
                [gridAndTiles addObject:blockSprite];
            }
            
            else if(blockValue == PLAYER_2) {
                
                exitX = x;
                exitY = y;
                blocks[x][y] = 0; // clear
                
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                // Top
                if(exitY == 0) {
                    
                    // Bar
                    Blocks *exitBar = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"ExitBar.png"]];
                    exitBar.position = ccp(leftPad + (x1 + (exitBar.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 - exitBar.contentSize.height / 2));

                    exitBar.name = @"exitBar";
                    [self addChild:exitBar z:Z_EXIT];
                    
                    [pausedSprites addObject:exitBar];
                    [gridAndTiles addObject:exitBar];
                    
                    
                    CCParticleSystem *teleport = [CCParticleSystem particleWithFile:@"Teleport.plist"];
                    teleport.position = ccp(exitBar.position.x,exitBar.position.y + exitBar.contentSize.height * 1.4);
                    teleport.name = @"teleport";
                    [self addChild:teleport z:Z_EXIT];
                    
                    [pausedSprites addObject:teleport];
   
                }
                // Bottom
                else if(exitY == gridHeight-1) {
                    // Bar
                    Blocks *exitBar = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"ExitBar.png"]];
                    exitBar.position = ccp(leftPad + (x1 + (exitBar.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + exitBar.contentSize.height * 7.5));
                    
                    exitBar.name = @"exitBar";
                    [self addChild:exitBar z:Z_EXIT];
                    
                    [pausedSprites addObject:exitBar];
                    [gridAndTiles addObject:exitBar];
                    
                    CCParticleSystem *teleport = [CCParticleSystem particleWithFile:@"Teleport.plist"];
                    teleport.position = ccp(exitBar.position.x,exitBar.position.y - exitBar.contentSize.height * 1.4);
                    teleport.angle = 270;
                    teleport.name = @"teleport";
                    [self addChild:teleport z:Z_EXIT];
                    
                    [pausedSprites addObject:teleport];
                }
                // Right
                else if(exitX == gridWidth-1) {
                    //Bar
                    Blocks *exitBar = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"ExitBar.png"]];
                    exitBar.position = ccp(leftPad + (x1 + exitBar.contentSize.width * 1.07) + SCREEN_WIDTH,
                                           FY(topPad + y1 + exitBar.contentSize.height * 3.5));
                    
                    exitBar.name = @"exitBar";
                    exitBar.rotation = 90.0f;
                    [self addChild:exitBar z:Z_EXIT];
                    
                    [pausedSprites addObject:exitBar];
                    [gridAndTiles addObject:exitBar];
                    
                    CCParticleSystem *teleport = [CCParticleSystem particleWithFile:@"TeleportX.plist"];
                    teleport.position = ccp(exitBar.position.x + exitBar.contentSize.width / 3.7,exitBar.position.y - exitBar.contentSize.height);
                    teleport.angle = 360;
                    teleport.name = @"teleport";
                    [self addChild:teleport z:Z_EXIT];
                    
                    [pausedSprites addObject:teleport];

                }
                // Left
                else if(exitX == 0) {
                    //Bar
                    Blocks *exitBar = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"ExitBar.png"]];
                    exitBar.position = ccp(leftPad + (x1 - exitBar.contentSize.width / 14) + SCREEN_WIDTH,
                                           FY(topPad + y1 + exitBar.contentSize.height * 3.5));
                    
                    exitBar.name = @"exitBar";
                    exitBar.rotation = 90.0f;
                    [self addChild:exitBar z:Z_EXIT];
                    
                    [pausedSprites addObject:exitBar];
                    [gridAndTiles addObject:exitBar];
                    
                    CCParticleSystem *teleport = [CCParticleSystem particleWithFile:@"TeleportX.plist"];
                    teleport.position = ccp(exitBar.position.x - exitBar.contentSize.width / 3.7,exitBar.position.y - exitBar.contentSize.height);
                    teleport.angle = 180;
                    teleport.name = @"teleport";
                    [self addChild:teleport z:Z_EXIT];
                    
                    [pausedSprites addObject:teleport];
                    
                }

            }
            else if(blockValue == TYPE_1x2_START) {
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                Blocks *blockSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"1x2.png"]];
                blockSprite.position = ccp(leftPad + (x1 + (blockSprite.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + blockSprite.contentSize.height / 2));
                blockSprite.ID = blockID;
                blockSprite.x = x;
                blockSprite.y = y;
                blockSprite.name = [NSString stringWithFormat:@"%d",blockID];
                blockSprite.type = TYPE_1x2_START;
                blockSprite.isHighlighted = 0;
                
                [self addChild:blockSprite z:Z_BLOCKS];
                
                [blockSprites addObject:blockSprite];
                [pausedSprites addObject:blockSprite];
                [gridAndTiles addObject:blockSprite];
            }
            else if(blockValue == TYPE_1x3_START) {
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                Blocks *blockSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"1x3.png"]];
                blockSprite.position = ccp(leftPad + (x1 + (blockSprite.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + blockSprite.contentSize.height / 2));
                blockSprite.ID = blockID;
                blockSprite.x = x;
                blockSprite.y = y;
                blockSprite.name = [NSString stringWithFormat:@"%d",blockID];
                blockSprite.type = TYPE_1x3_START;
                blockSprite.isHighlighted = 0;
                
                [self addChild:blockSprite z:Z_BLOCKS];
                
                [blockSprites addObject:blockSprite];
                [pausedSprites addObject:blockSprite];
                [gridAndTiles addObject:blockSprite];
            }
            else if(blockValue == TYPE_1x4_START) {
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                Blocks *blockSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"1x4.png"]];
                blockSprite.position = ccp(leftPad + (x1 + (blockSprite.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + blockSprite.contentSize.height / 2));
                blockSprite.ID = blockID;
                blockSprite.x = x;
                blockSprite.y = y;
                blockSprite.name = [NSString stringWithFormat:@"%d",blockID];
                blockSprite.type = TYPE_1x4_START;
                blockSprite.isHighlighted = 0;
                
                [self addChild:blockSprite z:Z_BLOCKS];
                
                [blockSprites addObject:blockSprite];
                [pausedSprites addObject:blockSprite];
                [gridAndTiles addObject:blockSprite];
            }
            else if(blockValue == TYPE_2x1_START) {
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                Blocks *blockSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"2x1.png"]];
                blockSprite.position = ccp(leftPad + (x1 + (blockSprite.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + blockSprite.contentSize.height / 2));
                blockSprite.ID = blockID;
                blockSprite.x = x;
                blockSprite.y = y;
                blockSprite.name = [NSString stringWithFormat:@"%d",blockID];
                blockSprite.type = TYPE_2x1_START;
            //    blockSprite.flipX = YES;
                blockSprite.isHighlighted = 0;
                
                [self addChild:blockSprite z:Z_BLOCKS];
                
                [blockSprites addObject:blockSprite];
                [pausedSprites addObject:blockSprite];
                [gridAndTiles addObject:blockSprite];
            }
            else if(blockValue == TYPE_3x1_START) {
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                Blocks *blockSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"3x1.png"]];
                blockSprite.position = ccp(leftPad + (x1 + (blockSprite.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + blockSprite.contentSize.height / 2));
                blockSprite.ID = blockID;
                blockSprite.x = x;
                blockSprite.y = y;
                blockSprite.name = [NSString stringWithFormat:@"%d",blockID];
                blockSprite.type = TYPE_3x1_START;
           //     blockSprite.flipX = YES;
                blockSprite.isHighlighted = 0;
                
                [self addChild:blockSprite z:Z_BLOCKS];
                
                [blockSprites addObject:blockSprite];
                [pausedSprites addObject:blockSprite];
                [gridAndTiles addObject:blockSprite];
            }
            else if(blockValue == TYPE_4x1_START) {
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                Blocks *blockSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"4x1.png"]];
                blockSprite.position = ccp(leftPad + (x1 + (blockSprite.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + blockSprite.contentSize.height / 2));
                blockSprite.ID = blockID;
                blockSprite.x = x;
                blockSprite.y = y;
                blockSprite.name = [NSString stringWithFormat:@"%d",blockID];
                blockSprite.type = TYPE_4x1_START;
            //    blockSprite.flipX = YES;
                blockSprite.isHighlighted = 0;
                
                [self addChild:blockSprite z:Z_BLOCKS];
                
                [blockSprites addObject:blockSprite];
                [pausedSprites addObject:blockSprite];
                [gridAndTiles addObject:blockSprite];
            }
            
            else if(blockValue == TYPE_2x2_START) {
                float x1 = ((x * tileWidth));
                float y1 = (y * tileHeight);
                
                Blocks *blockSprite = [[Blocks alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"2x2.png"]];
                blockSprite.position = ccp(leftPad + (x1 + (blockSprite.contentSize.width / 2)) + SCREEN_WIDTH,
                                           FY(topPad + y1 + blockSprite.contentSize.height / 2));
                blockSprite.ID = blockID;
                blockSprite.x = x;
                blockSprite.y = y;
                blockSprite.name = [NSString stringWithFormat:@"%d",blockID];
                blockSprite.type = TYPE_2x2_START;
                blockSprite.isHighlighted = 0;
                
                [self addChild:blockSprite z:Z_BLOCKS];
                
                [blockSprites addObject:blockSprite];
                [pausedSprites addObject:blockSprite];
                [gridAndTiles addObject:blockSprite];
            }
             


            blockID++;
        }
    }
    
  //  [self dumpBlocks];
}


//---------------------------------------------------------------------------------------------------------------------

- (void)captureScreen
{
    screenCapture = [self screenGrab:self];
}


//---------------------------------------------------------------------------------------------------------------------
// set move in progress to 0 and show exit bar
- (void)gameStart
{
   // NSLog(@"Game start");
    moveInProgress = 0;
  //  [self performSelector:@selector(captureScreen) withObject:self afterDelay:0.3f];
    
    if(stageValue == 1 || stageValue == 2 || stageValue == 3) {
        [self tutorialHand];
    }
    
    // On stage 20 ask for review
    if(stageValue == 20 && rated == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Huge Thanks!" message:@"Thanks for playing our game! \n Would you mind rating us? \n We would be so grateful" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
        alert.tag = 1;
        [alert show];
        
        // save so popup doesn't show again
        rated = 1;
        [self saveSettings];
    }

    
}

//---------------------------------------------------------------------------------------------------------------------

- (void)bringInGridAndTiles
{
   // NSLog(@"bring in tiles %d",moveInProgress);
    for(CCSprite *block in gridAndTiles) {
        id moveAction = [CCActionMoveBy actionWithDuration:0.3 position:ccp(-SCREEN_WIDTH,0)];
        [block runAction:[CCActionSequence actions:moveAction, nil]];
    }
    
    CCParticleSystem *teleport = (CCParticleSystem*)[self getChildByName:@"teleport" recursively:YES];
    id moveAction = [CCActionMoveBy actionWithDuration:0.3 position:ccp(-SCREEN_WIDTH,0)];
    [teleport runAction:[CCActionSequence actions:moveAction, nil]];
    
    [self performSelector:@selector(gameStart) withObject:nil afterDelay:0.8f];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)bringOutGridAndTiles
{
    for(Blocks *block in gridAndTiles) {
        if(block.type != PLAYER) {
  
            id moveAction = [CCActionFadeTo actionWithDuration:0.3f opacity:0.0f];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                [block removeFromParentAndCleanup:YES];
            }];
        
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
        }
    }
    
    CCParticleSystem *teleport = (CCParticleSystem*)[self getChildByName:@"teleport" recursively:YES];
    id moveAction = [CCActionFadeTo actionWithDuration:0.3f opacity:0.0f];
    id callAction = [CCActionCallBlock actionWithBlock:^{
        [teleport removeFromParentAndCleanup:YES];
    }];
    
    [teleport runAction:[CCActionSequence actions:moveAction, callAction, nil]];
    
    [self performSelector:@selector(bringInButtons) withObject:nil afterDelay:0.1f];
}


//---------------------------------------------------------------------------------------------------------------------
- (void)bringInButtons
{
    // replay
    CCButton *replayButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"RetryButtonWin.png"]];
    replayButton.position = ccp(0-replayButton.contentSize.width, FY(0 + replayButton.contentSize.height * 4));
    [replayButton setTarget:self selector:@selector(replayPressed)];
    [self addChild:replayButton z:1];
    
    id replayMoveAction = [CCActionMoveBy actionWithDuration:0.6 position:ccp(replayButton.contentSize.width * 2.5,0)];
    id easeReply = [CCActionEaseElasticOut actionWithAction:replayMoveAction period:5.0];
    [replayButton runAction:easeReply];
    
    // next
    CCButton *nextButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"NextButtonWin.png"]];
    nextButton.position = ccp(SCREEN_WIDTH + nextButton.contentSize.width, replayButton.position.y);
    [nextButton setTarget:self selector:@selector(nextPressed)];
    [self addChild:nextButton z:1];
    
    id nextMoveAction = [CCActionMoveBy actionWithDuration:0.6 position:ccp(-nextButton.contentSize.width * 2.5,0)];
    id easeNext = [CCActionEaseElasticOut actionWithAction:nextMoveAction period:5.0];
    [nextButton runAction:easeNext];
    
    // ---- smaller buttons
    
    
    // Home button
    
    
    CCButton *homeButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"MenuButtonPaused.png"]];
    homeButton.position = ccp(SCREEN_WIDTH / 2 - homeButton.contentSize.width * 1.6,0 - homeButton.contentSize.height);
    [homeButton setTarget:self selector:@selector(homePressed)];
    [self addChild:homeButton z:1];
    
    id homeMoveAction = [CCActionMoveTo actionWithDuration:0.6 position:ccp(homeButton.position.x,
                                                                            nextButton.position.y - homeButton.contentSize.width * 2)];
    id easeHome = [CCActionEaseElasticOut actionWithAction:homeMoveAction period:5.0];
    [homeButton runAction:easeHome];
    
    // Game Center button
    CCButton *gcButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"GCButton.png"]];
    gcButton.position = ccp(SCREEN_WIDTH / 2,0 - gcButton.contentSize.height);
    [gcButton setTarget:self selector:@selector(gcPressed)];
    [self addChild:gcButton z:1];
    
    id gcMoveAction = [CCActionMoveTo actionWithDuration:0.5 position:ccp(gcButton.position.x,
                                                                          nextButton.position.y - homeButton.contentSize.width * 2)];
    id easeGC = [CCActionEaseElasticOut actionWithAction:gcMoveAction period:5.0];
    [gcButton runAction:easeGC];
    
    // Share button
    CCButton *fbButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"ShareButton.png"]];
    fbButton.position = ccp(SCREEN_WIDTH / 2 + fbButton.contentSize.width * 1.6,0 - fbButton.contentSize.height);
    [fbButton setTarget:self selector:@selector(sharePressed)];
    [self addChild:fbButton z:1];
    
    id fbMoveAction = [CCActionMoveTo actionWithDuration:0.6 position:ccp(fbButton.position.x,
                                                                          nextButton.position.y - homeButton.contentSize.width * 2)];
    id easefb = [CCActionEaseElasticOut actionWithAction:fbMoveAction period:5.0];
    [fbButton runAction:easefb];
    
    
    // Rate button
    CCButton *rateButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"RateButton.png"]];
    rateButton.position = ccp(SCREEN_WIDTH / 2,0 - fbButton.contentSize.height);
    [rateButton setTarget:self selector:@selector(ratePressed)];
    [self addChild:rateButton z:1];
    
    id rateMoveAction = [CCActionMoveTo actionWithDuration:0.6 position:ccp(rateButton.position.x,
                                                                          nextButton.position.y - homeButton.contentSize.width * 3.8)];
    id easerate = [CCActionEaseElasticOut actionWithAction:rateMoveAction period:5.0];
    [rateButton runAction:easerate];
    

    
}


//---------------------------------------------------------------------------------------------------------------------

- (void)moveBlockLeft:(int)blockID :(int)blockType
{
    int blockX;
    int blockY;
    int newBlockID = 0;
  //  unsigned char nextLeftValue;
  //  unsigned char currentValue;
    
    unsigned char movingIntoValue = 1;
    unsigned char movingIntoValue2 = 1;
    unsigned char movingIntoValue3 = 1;
    unsigned char movingIntoValue4 = 1;
    
    unsigned char nextBlockValue = 0;
    unsigned char nextBlockValue2 = 0;
    unsigned char nextBlockValue3 = 0;
    unsigned char currentBlockValue = 0;
    
 
 //   NSLog(@"move block left - type %x",blockType);
    
    // Clamp
    // block ID back to 2D
    blockX = blockID % gridWidth;
    blockY = blockID / gridWidth;
    
    // Check if we are at the left bounds, clamp if so
    if(blockX <= 0) {
        return;
    }
    
    int blockMoveAmount;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        blockMoveAmount = 9;
    }
    else {
        blockMoveAmount = 3;
    }

    
    // Check if the block to the left is 0;
    // 1 x 1 blocks
    if(blockType == TYPE_1x1 || blockType == PLAYER) {
        movingIntoValue = blocks[blockX-1][blockY];
        currentBlockValue = blocks[blockX][blockY];
        
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(-block.contentSize.width - blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];

            blocks[blockX-1][blockY] = currentBlockValue;
            blocks[blockX][blockY] = movingIntoValue;

            newBlockID = blockID - 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x - 1;
            
            [self increseMoveCount];
            
        }
    }
    else if(blockType == TYPE_1x2_START) {
        movingIntoValue = blocks[blockX-1][blockY];
        movingIntoValue2 = blocks[blockX-1][blockY+1];
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(-block.contentSize.width - blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
 
            blocks[blockX-1][blockY] = currentBlockValue;
            blocks[blockX-1][blockY+1] = nextBlockValue;
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+1] = movingIntoValue2;

            newBlockID = blockID - 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x - 1;
            
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_1x3_START) {
        movingIntoValue = blocks[blockX-1][blockY];
        movingIntoValue2 = blocks[blockX-1][blockY+1];
        movingIntoValue3 = blocks[blockX-1][blockY+2];
        
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        nextBlockValue2 = blocks[blockX][blockY+2];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && movingIntoValue3 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(-block.contentSize.width - blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX-1][blockY] = currentBlockValue;
            blocks[blockX-1][blockY+1] = nextBlockValue;
            blocks[blockX-1][blockY+2] = nextBlockValue2;
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+1] = movingIntoValue2;
            blocks[blockX][blockY+2] = movingIntoValue3;
            
            newBlockID = blockID - 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x - 1;
            
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_1x4_START) {
        movingIntoValue = blocks[blockX-1][blockY];
        movingIntoValue2 = blocks[blockX-1][blockY+1];
        movingIntoValue3 = blocks[blockX-1][blockY+2];
        movingIntoValue4 = blocks[blockX-1][blockY+3];
        
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        nextBlockValue2 = blocks[blockX][blockY+2];
        nextBlockValue3 = blocks[blockX][blockY+3];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && movingIntoValue3 == 0 && movingIntoValue4 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(-block.contentSize.width - blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX-1][blockY] = currentBlockValue;
            blocks[blockX-1][blockY+1] = nextBlockValue;
            blocks[blockX-1][blockY+2] = nextBlockValue2;
            blocks[blockX-1][blockY+3] = nextBlockValue3;
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+1] = movingIntoValue2;
            blocks[blockX][blockY+2] = movingIntoValue3;
            blocks[blockX][blockY+3] = movingIntoValue4;
            
            newBlockID = blockID - 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x - 1;
            
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_2x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        movingIntoValue = blocks[blockX-1][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(-block.contentSize.height - blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+1][blockY] = movingIntoValue;
            blocks[blockX][blockY] = nextBlockValue;
            blocks[blockX-1][blockY] = currentBlockValue;
            
            newBlockID = blockID - 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x - 1;
            
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_3x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        movingIntoValue = blocks[blockX-1][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        nextBlockValue2 = blocks[blockX+2][blockY];
        
        /*
        NSLog(@"current %d",currentBlockValue);
        NSLog(@"moving into %d",movingIntoValue);
        NSLog(@"next bv %d",nextBlockValue);
        NSLog(@"next bv %d",nextBlockValue2);
        */
        
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(-block.contentSize.height - blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+2][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = nextBlockValue2;
            blocks[blockX][blockY] = nextBlockValue;
            blocks[blockX-1][blockY] = currentBlockValue;
            
            newBlockID = blockID - 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x - 1;
            
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_4x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        movingIntoValue = blocks[blockX-1][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        nextBlockValue2 = blocks[blockX+2][blockY];
        nextBlockValue3 = blocks[blockX+3][blockY];
        
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(-block.contentSize.height - blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+3][blockY] = movingIntoValue;
            blocks[blockX+2][blockY] = nextBlockValue3;
            blocks[blockX+1][blockY] = nextBlockValue2;
            blocks[blockX][blockY] = nextBlockValue;
            blocks[blockX-1][blockY] = currentBlockValue;
            
            newBlockID = blockID - 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x - 1;
            
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_2x2_START) {
        movingIntoValue = blocks[blockX-1][blockY];
        movingIntoValue2 = blocks[blockX-1][blockY+1];
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        nextBlockValue2 = blocks[blockX+1][blockY];
        nextBlockValue3 = blocks[blockX+1][blockY+1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(-block.contentSize.width / 2 - 1,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX-1][blockY] = currentBlockValue;
            blocks[blockX-1][blockY+1] = nextBlockValue;
            blocks[blockX][blockY] = nextBlockValue2;
            blocks[blockX][blockY+1] = nextBlockValue3;
            blocks[blockX+1][blockY] = movingIntoValue;
            blocks[blockX+1][blockY+1] = movingIntoValue2;
            
            newBlockID = blockID - 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x - 1;
            
            [self increseMoveCount];
        }
    }




 //   [self dumpBlocks];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)moveBlockRight:(int)blockID :(int)blockType
{
    int blockX;
    int blockY;
    int newBlockID = 0;

    unsigned char movingIntoValue = 1;
    unsigned char movingIntoValue2 = 1;
    unsigned char movingIntoValue3 = 1;
    unsigned char movingIntoValue4 = 1;
    
    unsigned char nextBlockValue = 0;
    unsigned char nextBlockValue2 = 0;
    unsigned char nextBlockValue3 = 0;
    unsigned char currentBlockValue = 0;
    
    int clampX = 0;
    
    int blockMoveAmount;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        blockMoveAmount = 9;
    }
    else {
        blockMoveAmount = 3;
    }
    
  //  NSLog(@"move block right - type %x",blockType);
    
    // Clamp
    // block ID back to 2D
    blockX = blockID % gridWidth;
    blockY = blockID / gridWidth;

    // Check if we are at the left bounds, clamp if so
    if(blockX >= gridWidth-1) {
        return;
    }
    
    // Check if the block to the right is 0;
    // 1 x 1 blocks
    if(blockType == TYPE_1x1 || blockType == PLAYER) {
        movingIntoValue = blocks[blockX+1][blockY];
        currentBlockValue = blocks[blockX][blockY];
        
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(+block.contentSize.width + blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+1][blockY] = currentBlockValue;
            blocks[blockX][blockY] = movingIntoValue;
            
            newBlockID = blockID + 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }

    }
    // 1 x 2 blocks
    else if(blockType == TYPE_1x2_START) {
        movingIntoValue = blocks[blockX+1][blockY];
        movingIntoValue2 = blocks[blockX+1][blockY+1];
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0) {
            moveInProgress = 1;
            
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(+block.contentSize.width + blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];

            blocks[blockX+1][blockY] = currentBlockValue;
            blocks[blockX+1][blockY+1] = nextBlockValue;
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+1] = movingIntoValue2;
            
            newBlockID = blockID + 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    // 1 x 2 blocks
    else if(blockType == TYPE_1x3_START) {
        movingIntoValue = blocks[blockX+1][blockY];
        movingIntoValue2 = blocks[blockX+1][blockY+1];
        movingIntoValue3 = blocks[blockX+1][blockY+2];
        
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        nextBlockValue2 = blocks[blockX][blockY+2];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && movingIntoValue3 == 0) {
            moveInProgress = 1;
            
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(+block.contentSize.width + blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+1][blockY] = currentBlockValue;
            blocks[blockX+1][blockY+1] = nextBlockValue;
            blocks[blockX+1][blockY+2] = nextBlockValue2;
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+1] = movingIntoValue2;
            blocks[blockX][blockY+2] = movingIntoValue3;
            
            newBlockID = blockID + 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_1x4_START) {
        movingIntoValue = blocks[blockX+1][blockY];
        movingIntoValue2 = blocks[blockX+1][blockY+1];
        movingIntoValue3 = blocks[blockX+1][blockY+2];
        movingIntoValue4 = blocks[blockX+1][blockY+3];
        
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        nextBlockValue2 = blocks[blockX][blockY+2];
        nextBlockValue3 = blocks[blockX][blockY+3];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && movingIntoValue3 == 0 && movingIntoValue4 == 0) {
            moveInProgress = 1;
            
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(+block.contentSize.width + blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+1][blockY] = currentBlockValue;
            blocks[blockX+1][blockY+1] = nextBlockValue;
            blocks[blockX+1][blockY+2] = nextBlockValue2;
            blocks[blockX+1][blockY+3] = nextBlockValue3;
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+1] = movingIntoValue2;
            blocks[blockX][blockY+2] = movingIntoValue3;
            blocks[blockX][blockY+3] = movingIntoValue4;
            
            newBlockID = blockID + 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    
    else if(blockType == TYPE_2x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        movingIntoValue = blocks[blockX+2][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        
        clampX = blockX+2;
        
    //    NSLog(@"clampx %d",clampX);
        
        if(movingIntoValue == 0 && clampX < gridWidth) {
            moveInProgress = 1;
            
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(+block.contentSize.height + blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+2][blockY] = nextBlockValue;
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = currentBlockValue;
            
            newBlockID = blockID + 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_3x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        movingIntoValue = blocks[blockX+3][blockY];
        nextBlockValue = blocks[blockX+2][blockY];
        nextBlockValue2 = blocks[blockX+1][blockY];
        
        clampX = blockX+3;
        
        if(movingIntoValue == 0 && clampX < gridWidth) {
            moveInProgress = 1;
            
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(+block.contentSize.height + blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+3][blockY] = nextBlockValue2;
            blocks[blockX+2][blockY] = nextBlockValue;
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = currentBlockValue;
            
            newBlockID = blockID + 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_4x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        movingIntoValue = blocks[blockX+4][blockY];
        nextBlockValue = blocks[blockX+3][blockY];
        nextBlockValue2 = blocks[blockX+2][blockY];
        nextBlockValue3 = blocks[blockX+1][blockY];
        
        clampX = blockX+4;
        
        if(movingIntoValue == 0 && clampX < gridWidth) {
            moveInProgress = 1;
            
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(+block.contentSize.height + blockMoveAmount,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+4][blockY] = nextBlockValue3;
            blocks[blockX+3][blockY] = nextBlockValue2;
            blocks[blockX+2][blockY] = nextBlockValue;
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = currentBlockValue;
            
            newBlockID = blockID + 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_2x2_START) {
        movingIntoValue = blocks[blockX+2][blockY];
        movingIntoValue2 = blocks[blockX+2][blockY+1];
        currentBlockValue = blocks[blockX+1][blockY];
        nextBlockValue = blocks[blockX+1][blockY+1];
        nextBlockValue2 = blocks[blockX][blockY];
        nextBlockValue3 = blocks[blockX][blockY+1];
        
        clampX = blockX+2;
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && clampX < gridWidth) {
            moveInProgress = 1;
            
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(+block.contentSize.width / 2 + 1,0)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX+2][blockY] = currentBlockValue;
            blocks[blockX+2][blockY+1] = nextBlockValue;
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+1] = movingIntoValue2;
            
            blocks[blockX+1][blockY] = nextBlockValue2;
            blocks[blockX+1][blockY+1] = nextBlockValue3;
            
            newBlockID = blockID + 1;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.x = block.x + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    
   // [self dumpBlocks];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)moveBlockUp:(int)blockID :(int)blockType
{
    
    int blockX;
    int blockY;
    int newBlockID = 0;
    
    unsigned char movingIntoValue = 1;
    unsigned char movingIntoValue2 = 1;
    unsigned char movingIntoValue3 = 1;
    unsigned char movingIntoValue4 = 1;
    
    unsigned char nextBlockValue = 0;
    unsigned char nextBlockValue2 = 0;
    unsigned char nextBlockValue3 = 0;
    unsigned char currentBlockValue = 0;
    
   // NSLog(@"move block up - type %x",blockType);
 
    // Clamp
    // block ID back to 2D
    blockX = blockID % gridWidth;
    blockY = blockID / gridWidth;
    
    // Check if we are at the left bounds, clamp if so
    if(blockY <= 0) {
        return;
    }
    
    int blockMoveAmount;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        blockMoveAmount = 9;
    }
    else {
        blockMoveAmount = 3;
    }
    
    // 1 x 1 blocks
    if(blockType == TYPE_1x1 || blockType == PLAYER) {
        // Check if the block above is 0;
        movingIntoValue = blocks[blockX][blockY-1];
        currentBlockValue = blocks[blockX][blockY];
        
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,+block.contentSize.width + blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY-1] = currentBlockValue;
            blocks[blockX][blockY] = movingIntoValue;
            
            newBlockID = blockID - gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y - 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }

    }
    // 1 x 2 blocks
    else if(blockType == TYPE_1x2_START) {
        currentBlockValue = blocks[blockX][blockY];
        movingIntoValue = blocks[blockX][blockY-1];
        nextBlockValue = blocks[blockX][blockY+1];
        
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,+block.contentSize.width + blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY-1] = currentBlockValue;
            blocks[blockX][blockY] = nextBlockValue;
            blocks[blockX][blockY+1] = movingIntoValue;
            
            newBlockID = blockID - gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y - 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    // 1 x 3 blocks
    else if(blockType == TYPE_1x3_START) {
        currentBlockValue = blocks[blockX][blockY];
        movingIntoValue = blocks[blockX][blockY-1];
        nextBlockValue = blocks[blockX][blockY+1];
        nextBlockValue2 = blocks[blockX][blockY+2];
        
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,+block.contentSize.width + blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY-1] = currentBlockValue;
            blocks[blockX][blockY] = nextBlockValue;
            blocks[blockX][blockY+2] = movingIntoValue;
            blocks[blockX][blockY+1] = nextBlockValue2;
            
            newBlockID = blockID - gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y - 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_1x4_START) {
        movingIntoValue = blocks[blockX][blockY-1];
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        nextBlockValue2 = blocks[blockX][blockY+2];
        nextBlockValue3 = blocks[blockX][blockY+3];
        
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,+block.contentSize.width + blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY-1] = currentBlockValue;
            blocks[blockX][blockY] = nextBlockValue;
            blocks[blockX][blockY+3] = movingIntoValue;
            blocks[blockX][blockY+2] = nextBlockValue3;
            blocks[blockX][blockY+1] = nextBlockValue2;
            
            newBlockID = blockID - gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y - 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_2x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        
        movingIntoValue = blocks[blockX][blockY-1];
        movingIntoValue2 = blocks[blockX+1][blockY-1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,+block.contentSize.height + blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = movingIntoValue2;
            
            blocks[blockX][blockY-1] = currentBlockValue;
            blocks[blockX+1][blockY-1] = nextBlockValue;
            
            newBlockID = blockID - gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y - 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_3x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        nextBlockValue2 = blocks[blockX+2][blockY];
        
        movingIntoValue = blocks[blockX][blockY-1];
        movingIntoValue2 = blocks[blockX+1][blockY-1];
        movingIntoValue3 = blocks[blockX+2][blockY-1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && movingIntoValue3 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,+block.contentSize.height + blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = movingIntoValue2;
            blocks[blockX+2][blockY] = movingIntoValue3;
            
            blocks[blockX][blockY-1] = currentBlockValue;
            blocks[blockX+1][blockY-1] = nextBlockValue;
            blocks[blockX+2][blockY-1] = nextBlockValue2;
            
            newBlockID = blockID - gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y - 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_4x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        nextBlockValue2 = blocks[blockX+2][blockY];
        nextBlockValue3 = blocks[blockX+3][blockY];
        
        movingIntoValue = blocks[blockX][blockY-1];
        movingIntoValue2 = blocks[blockX+1][blockY-1];
        movingIntoValue3 = blocks[blockX+2][blockY-1];
        movingIntoValue4 = blocks[blockX+3][blockY-1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && movingIntoValue3 == 0 && movingIntoValue4 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,+block.contentSize.height + blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = movingIntoValue2;
            blocks[blockX+2][blockY] = movingIntoValue3;
            blocks[blockX+3][blockY] = movingIntoValue4;
            
            blocks[blockX][blockY-1] = currentBlockValue;
            blocks[blockX+1][blockY-1] = nextBlockValue;
            blocks[blockX+2][blockY-1] = nextBlockValue2;
            blocks[blockX+3][blockY-1] = nextBlockValue3;
            
            newBlockID = blockID - gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y - 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_2x2_START) {
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        
        nextBlockValue2 = blocks[blockX][blockY+1];
        nextBlockValue3 = blocks[blockX+1][blockY+1];
        
        movingIntoValue = blocks[blockX][blockY-1];
        movingIntoValue2 = blocks[blockX+1][blockY-1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,+block.contentSize.height / 2 + 1)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY+1] = movingIntoValue;
            blocks[blockX+1][blockY+1] = movingIntoValue2;
            
            blocks[blockX][blockY] = nextBlockValue2;
            blocks[blockX+1][blockY] = nextBlockValue3;
            
            blocks[blockX][blockY-1] = currentBlockValue;
            blocks[blockX+1][blockY-1] = nextBlockValue;
            
            newBlockID = blockID - gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y - 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }


    
   // [self dumpBlocks];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)moveBlockDown:(int)blockID :(int)blockType
{
    int blockX;
    int blockY;
    int newBlockID = 0;
    int clampY = 0;
    
    unsigned char movingIntoValue = 1;
    unsigned char movingIntoValue2 = 1;
    unsigned char movingIntoValue3 = 1;
    unsigned char movingIntoValue4 = 1;
    
    unsigned char nextBlockValue = 0;
    unsigned char nextBlockValue2 = 0;
    unsigned char nextBlockValue3 = 0;
    unsigned char currentBlockValue = 0;
    
 
    // Clamp
    // block ID back to 2D
    blockX = blockID % gridWidth;
    blockY = blockID / gridWidth;
    

    // Check if we are at the left bounds, clamp if so
    if(blockY >= gridHeight-1) {
        return;
    }
    
    int blockMoveAmount;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        blockMoveAmount = 9;
    }
    else {
        blockMoveAmount = 3;
    }
    
    // Check if the block to the down is 0;
    if(blockType == TYPE_1x1 || blockType == PLAYER) {
        
        movingIntoValue = blocks[blockX][blockY+1];
        currentBlockValue = blocks[blockX][blockY];
        
      
        if(movingIntoValue == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,-block.contentSize.width - blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            // swap the values in the grid
            blocks[blockX][blockY+1] = currentBlockValue;
            blocks[blockX][blockY] = movingIntoValue;
                
            newBlockID = blockID + gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }

    }
    else if(blockType == TYPE_1x2_START) {
        
        currentBlockValue = blocks[blockX][blockY];
        movingIntoValue = blocks[blockX][blockY+2];
        nextBlockValue = blocks[blockX][blockY+1];
        
        clampY = blockY+2;

        // Need to clamp or it will go off-screen
        if(movingIntoValue == 0 && clampY < gridHeight) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,-block.contentSize.width - blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY+1] = nextBlockValue;
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+2] = currentBlockValue;
            
            newBlockID = blockID + gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_1x3_START) {
        
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        nextBlockValue2 = blocks[blockX][blockY+2];
        movingIntoValue = blocks[blockX][blockY+3];
        
        clampY = blockY+3;

        if(movingIntoValue == 0 && clampY < gridHeight) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,-block.contentSize.width - blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            // move down / shift
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+1] = currentBlockValue;
            blocks[blockX][blockY+2] = nextBlockValue;
            blocks[blockX][blockY+3] = nextBlockValue2;
            
            newBlockID = blockID + gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_1x4_START) {
        
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX][blockY+1];
        nextBlockValue2 = blocks[blockX][blockY+2];
        nextBlockValue3 = blocks[blockX][blockY+3];
        movingIntoValue = blocks[blockX][blockY+4];
        
        clampY = blockY+4;

        if(movingIntoValue == 0 && clampY < gridHeight) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,-block.contentSize.width - blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            // move down / shift
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX][blockY+1] = currentBlockValue;
            blocks[blockX][blockY+2] = nextBlockValue;
            blocks[blockX][blockY+3] = nextBlockValue2;
            blocks[blockX][blockY+4] = nextBlockValue3;
            
            newBlockID = blockID + gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    
    else if(blockType == TYPE_2x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        
        movingIntoValue = blocks[blockX][blockY+1];
        movingIntoValue2 = blocks[blockX+1][blockY+1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,-block.contentSize.height - blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = movingIntoValue2;
            
            blocks[blockX][blockY+1] = currentBlockValue;
            blocks[blockX+1][blockY+1] = nextBlockValue;
            
            newBlockID = blockID + gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_3x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        nextBlockValue2 = blocks[blockX+2][blockY];
        
        movingIntoValue = blocks[blockX][blockY+1];
        movingIntoValue2 = blocks[blockX+1][blockY+1];
        movingIntoValue3 = blocks[blockX+2][blockY+1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && movingIntoValue3 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,-block.contentSize.height - blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = movingIntoValue2;
            blocks[blockX+2][blockY] = movingIntoValue3;
            
            blocks[blockX][blockY+1] = currentBlockValue;
            blocks[blockX+1][blockY+1] = nextBlockValue;
            blocks[blockX+2][blockY+1] = nextBlockValue2;
            
            newBlockID = blockID + gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_4x1_START) {
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        nextBlockValue2 = blocks[blockX+2][blockY];
        nextBlockValue3 = blocks[blockX+3][blockY];
        
        movingIntoValue = blocks[blockX][blockY+1];
        movingIntoValue2 = blocks[blockX+1][blockY+1];
        movingIntoValue3 = blocks[blockX+2][blockY+1];
        movingIntoValue4 = blocks[blockX+3][blockY+1];
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && movingIntoValue3 == 0 && movingIntoValue4 == 0) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,-block.contentSize.height - blockMoveAmount)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = movingIntoValue2;
            blocks[blockX+2][blockY] = movingIntoValue3;
            blocks[blockX+3][blockY] = movingIntoValue4;
            
            blocks[blockX][blockY+1] = currentBlockValue;
            blocks[blockX+1][blockY+1] = nextBlockValue;
            blocks[blockX+2][blockY+1] = nextBlockValue2;
            blocks[blockX+3][blockY+1] = nextBlockValue3;
            
            newBlockID = blockID + gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }
    else if(blockType == TYPE_2x2_START) {
        currentBlockValue = blocks[blockX][blockY];
        nextBlockValue = blocks[blockX+1][blockY];
        
        nextBlockValue2 = blocks[blockX][blockY+1];
        nextBlockValue3 = blocks[blockX+1][blockY+1];
        
        movingIntoValue = blocks[blockX][blockY+2];
        movingIntoValue2 = blocks[blockX+1][blockY+2];
        
        clampY = blockY+2;
        
        if(movingIntoValue == 0 && movingIntoValue2 == 0 && clampY < gridHeight) {
            moveInProgress = 1;
            NSString *blockStr = [NSString stringWithFormat:@"%d",blockID];
            Blocks *block = (Blocks*)[self getChildByName:blockStr recursively:NO];
            
            
            id moveAction = [CCActionMoveBy actionWithDuration:BLOCK_MOVE_SPEED position:ccp(0,-block.contentSize.height / 2 - 1)];
            id callAction = [CCActionCallBlock actionWithBlock:^{
                moveInProgress = 0;
            }];
            
            [block runAction:[CCActionSequence actions:moveAction, callAction, nil]];
            
            blocks[blockX][blockY] = movingIntoValue;
            blocks[blockX+1][blockY] = movingIntoValue2;
            
            blocks[blockX][blockY+2] = nextBlockValue2;
            blocks[blockX+1][blockY+2] = nextBlockValue3;
            
            blocks[blockX][blockY+1] = currentBlockValue;
            blocks[blockX+1][blockY+1] = nextBlockValue;
            
            newBlockID = blockID + gridWidth;
            
            block.ID = newBlockID;
            block.name = [NSString stringWithFormat:@"%d",newBlockID];
            block.y = block.y + 1;
            
            // Increase the move counter on a valid move
            [self increseMoveCount];
        }
    }



  //  [self dumpBlocks];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)moveBlock:(int)blockID :(int)direction :(int)blockType
{
    //[self createStreakBlock];
    
    if(direction == LEFT) {
        [self moveBlockLeft:blockID:blockType];
    }
    else if(direction == RIGHT) {
        [self moveBlockRight:blockID:blockType];
    }
    else if(direction == UP) {
        [self moveBlockUp:blockID:blockType];
    }
    else if(direction == DOWN) {
        [self moveBlockDown:blockID:blockType];
    }
}


//---------------------------------------------------------------------------------------------------------------------

- (void)detectStage2MoveSwitch
{
    if(stageValue == 2 && phaseSwitched == 0) {
        if(blocks[2][2] == 3) {
            stage2tutPhase = 1;
            phaseSwitched = 1;
            [self tutorialHand];
        }
    }
    
    else if(stageValue == 2 && phaseSwitched == 1) {
        if(blocks[0][1] == 3) {
            stage2tutPhase = 2;
            phaseSwitched = 2;
            [self tutorialHand];
        }
    }
}


//---------------------------------------------------------------------------------------------------------------------


- (void)detectStage3MoveSwitch
{
    if(stageValue == 3 && phaseSwitched == 0) {
        if(blocks[0][2] == 0x70) {
            stage3tutPhase = 1;
            phaseSwitched = 1;
            [self tutorialHand];
        }
    }
    
    else if(stageValue == 3 && phaseSwitched == 1) {
        if(blocks[4][1] == 0x71) {
            stage3tutPhase = 2;
            phaseSwitched = 2;
            [self tutorialHand];
        }
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)tutorialHand
{
    int topPad;
    int leftPad;
    int tileWidth;
    int tileHeight;
    int maxWidth;
    
    CCSprite *tileSample = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"1.png"]];
    
    
    tileWidth = tileSample.contentSize.width - 3;
    tileHeight = tileSample.contentSize.height - 3;
    
    maxWidth = gridWidth * tileWidth;
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        topPad = (0 + tileSample.contentSize.height * 2) + 6;
        leftPad = ((SCREEN_WIDTH - maxWidth) / 2) + 6;
    }
    else {
        topPad = (0 + tileSample.contentSize.height * 2) + 3;
        leftPad = ((SCREEN_WIDTH - maxWidth) / 2) + 3;
    }

   
    if(stageValue == 1) {
        // Start
        float x1 = ((0 * tileWidth));
        float y1 = (4 * tileHeight);
        

        // End
        CCSprite *finger = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"Hand.png"]];
        finger.position = ccp(leftPad + (x1 - finger.contentSize.width / 2.4),
                              FY(topPad + y1));
        finger.name = @"Hand";
        finger.flipX = true;
        finger.opacity = 0;
        [self addChild:finger z:Z_BLOCKS];
        
        [pausedSprites addObject:finger];
        
        // Actions
        id swipeUpAction = [CCActionMoveBy actionWithDuration:1.0f position:ccp(0,finger.contentSize.height * 3.5)];
        id fadeOutFinger = [CCActionFadeTo actionWithDuration:0.3 opacity:0.0f];
        id movebackFinger = [CCActionMoveBy actionWithDuration:0 position:ccp(0,-finger.contentSize.height * 3.5)];
        id fadeInFinger = [CCActionFadeTo actionWithDuration:0.1 opacity:1.0f];
        
        CCActionSequence *fingerMove = [CCActionSequence actions:fadeInFinger, swipeUpAction, fadeOutFinger, movebackFinger, nil];
        CCActionRepeatForever *repeatAction = [CCActionRepeatForever actionWithAction:fingerMove];
        [finger runAction:repeatAction];
    }
    
    else if(stageValue == 2) {
        
        if(stage2tutPhase == 0) {
            // Start
            float x1 = ((2 * tileWidth));
            float y1 = (3 * tileHeight);
            
            // End
            CCSprite *finger = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"Hand.png"]];
            finger.position = ccp(leftPad + (x1 - finger.contentSize.width / 1.1),
                                  FY(topPad + y1));
            finger.name = @"Hand";
            finger.flipX = true;
            finger.opacity = 0;
            [self addChild:finger z:Z_BLOCKS];
            
            [pausedSprites addObject:finger];
            
            // Actions
            id swipeUpAction = [CCActionMoveBy actionWithDuration:0.6f position:ccp(+finger.contentSize.height,0)];
            id fadeOutFinger = [CCActionFadeTo actionWithDuration:0.3 opacity:0.0f];
            id movebackFinger = [CCActionMoveBy actionWithDuration:0 position:ccp(-finger.contentSize.height,0)];
            id fadeInFinger = [CCActionFadeTo actionWithDuration:0.1 opacity:1.0f];
            
            CCActionSequence *fingerMove = [CCActionSequence actions:fadeInFinger, swipeUpAction, fadeOutFinger, movebackFinger, nil];
            CCActionRepeatForever *repeatAction = [CCActionRepeatForever actionWithAction:fingerMove];
            [finger runAction:repeatAction];
        }
        
        else if(stage2tutPhase == 1) {
            
            CCSprite *hand = (CCSprite*)[self getChildByName:@"Hand" recursively:YES];
            [hand removeFromParentAndCleanup:YES];
            
            
            // Start
            float x1 = ((2 * tileWidth));
            float y1 = (2 * tileHeight);
            
            // End
            CCSprite *finger = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"Hand.png"]];
            finger.position = ccp(leftPad + (x1 - finger.contentSize.width / 1.1),
                                  FY(topPad + y1));
            finger.name = @"Hand";
            finger.flipX = true;
            finger.opacity = 0;
            [self addChild:finger z:Z_BLOCKS];
            
            [pausedSprites addObject:finger];
            
            // Actions
            id swipeUpAction = [CCActionMoveBy actionWithDuration:0.6f position:ccp(-finger.contentSize.height,0)];
            id fadeOutFinger = [CCActionFadeTo actionWithDuration:0.3 opacity:0.0f];
            id movebackFinger = [CCActionMoveBy actionWithDuration:0 position:ccp(+finger.contentSize.height,0)];
            id fadeInFinger = [CCActionFadeTo actionWithDuration:0.1 opacity:1.0f];
            
            CCActionSequence *fingerMove = [CCActionSequence actions:fadeInFinger, swipeUpAction, fadeOutFinger, movebackFinger, nil];
            CCActionRepeatForever *repeatAction = [CCActionRepeatForever actionWithAction:fingerMove];
            [finger runAction:repeatAction];
        }
        
        else if(stage2tutPhase == 2) {
            
            CCSprite *hand = (CCSprite*)[self getChildByName:@"Hand" recursively:YES];
            [hand removeFromParentAndCleanup:YES];
            
            // Start
            float x1 = ((1 * tileWidth));
            float y1 = (4 * tileHeight);
            
            // End
            CCSprite *finger = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"Hand.png"]];
            finger.position = ccp(leftPad + (x1 - finger.contentSize.width / 2.4),
                                  FY(topPad + y1));
            finger.name = @"Hand";
            finger.flipX = true;
            finger.opacity = 0;
            [self addChild:finger z:Z_BLOCKS];
            
            [pausedSprites addObject:finger];
            
            // Actions
            id swipeUpAction = [CCActionMoveBy actionWithDuration:1.0f position:ccp(0,finger.contentSize.height * 3.5)];
            id fadeOutFinger = [CCActionFadeTo actionWithDuration:0.3 opacity:0.0f];
            id movebackFinger = [CCActionMoveBy actionWithDuration:0 position:ccp(0,-finger.contentSize.height * 3.5)];
            id fadeInFinger = [CCActionFadeTo actionWithDuration:0.1 opacity:1.0f];
            
            CCActionSequence *fingerMove = [CCActionSequence actions:fadeInFinger, swipeUpAction, fadeOutFinger, movebackFinger, nil];
            CCActionRepeatForever *repeatAction = [CCActionRepeatForever actionWithAction:fingerMove];
            [finger runAction:repeatAction];
        }
    }

    
    else if(stageValue == 3) {
        
        if(stage3tutPhase == 0) {
            // Start
            float x1 = ((3 * tileWidth));
            float y1 = (3 * tileHeight);
            
            // End
            CCSprite *finger = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"Hand.png"]];
            finger.position = ccp(leftPad + (x1 - finger.contentSize.width / 1.1),
                                  FY(topPad + y1));
            finger.name = @"Hand";
            finger.flipX = true;
            finger.opacity = 0;
            [self addChild:finger z:Z_BLOCKS];
            
            [pausedSprites addObject:finger];
            
            // Actions
            id swipeUpAction = [CCActionMoveBy actionWithDuration:0.8f position:ccp(-finger.contentSize.height * 2,0)];
            id fadeOutFinger = [CCActionFadeTo actionWithDuration:0.3 opacity:0.0f];
            id movebackFinger = [CCActionMoveBy actionWithDuration:0 position:ccp(+finger.contentSize.height * 2,0)];
            id fadeInFinger = [CCActionFadeTo actionWithDuration:0.1 opacity:1.0f];
            
            CCActionSequence *fingerMove = [CCActionSequence actions:fadeInFinger, swipeUpAction, fadeOutFinger, movebackFinger, nil];
            CCActionRepeatForever *repeatAction = [CCActionRepeatForever actionWithAction:fingerMove];
            [finger runAction:repeatAction];
        }

        else if(stage3tutPhase == 1) {
            
            CCSprite *hand = (CCSprite*)[self getChildByName:@"Hand" recursively:YES];
            [hand removeFromParentAndCleanup:YES];
            
            
            // Start
            float x1 = ((3 * tileWidth));
            float y1 = (2 * tileHeight);
            
            // End
            CCSprite *finger = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"Hand.png"]];
            finger.position = ccp(leftPad + (x1 - finger.contentSize.width / 1.1),
                                  FY(topPad + y1));
            finger.name = @"Hand";
            finger.flipX = true;
            finger.opacity = 0;
            [self addChild:finger z:Z_BLOCKS];
            
            [pausedSprites addObject:finger];
            
            // Actions
            id swipeUpAction = [CCActionMoveBy actionWithDuration:0.8f position:ccp(+finger.contentSize.height * 2,0)];
            id fadeOutFinger = [CCActionFadeTo actionWithDuration:0.3 opacity:0.0f];
            id movebackFinger = [CCActionMoveBy actionWithDuration:0 position:ccp(-finger.contentSize.height * 2,0)];
            id fadeInFinger = [CCActionFadeTo actionWithDuration:0.1 opacity:1.0f];
            
            CCActionSequence *fingerMove = [CCActionSequence actions:fadeInFinger, swipeUpAction, fadeOutFinger, movebackFinger, nil];
            CCActionRepeatForever *repeatAction = [CCActionRepeatForever actionWithAction:fingerMove];
            [finger runAction:repeatAction];
        }

        else if(stage3tutPhase == 2) {
            
            CCSprite *hand = (CCSprite*)[self getChildByName:@"Hand" recursively:YES];
            [hand removeFromParentAndCleanup:YES];
            
            // Start
            float x1 = ((2 * tileWidth));
            float y1 = (4 * tileHeight);
        
            // End
            CCSprite *finger = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"Hand.png"]];
            finger.position = ccp(leftPad + (x1 - finger.contentSize.width / 2.4),
                              FY(topPad + y1));
            finger.name = @"Hand";
            finger.flipX = true;
            finger.opacity = 0;
            [self addChild:finger z:Z_BLOCKS];
        
            [pausedSprites addObject:finger];
        
            // Actions
            id swipeUpAction = [CCActionMoveBy actionWithDuration:1.0f position:ccp(0,finger.contentSize.height * 3.5)];
            id fadeOutFinger = [CCActionFadeTo actionWithDuration:0.3 opacity:0.0f];
            id movebackFinger = [CCActionMoveBy actionWithDuration:0 position:ccp(0,-finger.contentSize.height * 3.5)];
            id fadeInFinger = [CCActionFadeTo actionWithDuration:0.1 opacity:1.0f];
        
            CCActionSequence *fingerMove = [CCActionSequence actions:fadeInFinger, swipeUpAction, fadeOutFinger, movebackFinger, nil];
            CCActionRepeatForever *repeatAction = [CCActionRepeatForever actionWithAction:fingerMove];
            [finger runAction:repeatAction];
        }
    }

    
}

//---------------------------------------------------------------------------------------------------------------------
- (void)resetMoveCount
{
  //  [GameScene currentGameScene].moveCounter.string = @"0";
}

//---------------------------------------------------------------------------------------------------------------------
- (void)increseMoveCount
{
    if(moveCount == 999) {
        moveCount = 999;
        movesVal.string = [NSString stringWithFormat:@"%d+",moveCount];
    }
    else {
        moveCount++;
        movesVal.string = [NSString stringWithFormat:@"%d",moveCount];
    }
    
    if(sound == 1) {
        [audio playEffect:@"swift.caf"];
    }
    
}


//---------------------------------------------------------------------------------------------------------------------
- (void)resetScore
{
  //  _moveCounter.string = @"0";
}


//---------------------------------------------------------------------------------------------------------------------
// cycles through the array and quickly fades out all the stuff we want gone on the pause menu
- (void)pauseMenuShown
{
    for(CCSprite *sprites in pausedSprites) {
        sprites.visible = false;
    }
    
    // Pause
    CCLabelTTF *pauseLabel = [[CCLabelTTF alloc]initWithString:@"Options" fontName:@"JosefinSans-Bold" fontSize:38];
    pauseLabel.position = ccp(SCREEN_WIDTH / 2, FY(0 +pauseLabel.contentSize.height * 4));
    pauseLabel.name = @"pausedLabel";
    pauseLabel.opacity = 0;
    [self addChild:pauseLabel z:3];
    [pauseScreenSprites addObject:pauseLabel];
    
    
    // Replay
    CCButton *menuButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"ReplayButtonPaused.png"]];
    menuButton.position = ccp(0 + menuButton.contentSize.width / 1.2, FY(0 + menuButton.contentSize.height / 1.2));
    [menuButton setTarget:self selector:@selector(replayPressed)];
    menuButton.cascadeOpacityEnabled = YES;
    menuButton.opacity = 0;
    [self addChild:menuButton z:3];
    [pauseScreenSprites addObject:menuButton];
    
    // Play Button
    CCButton *playButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"PlayButtonPaused.png"]];
    playButton.position = ccp(SCREEN_WIDTH - playButton.contentSize.width / 1.2, FY(0 + playButton.contentSize.height / 1.2));
    [playButton setTarget:self selector:@selector(playPressed)];
    playButton.cascadeOpacityEnabled = YES;
    playButton.opacity = 0;
    [self addChild:playButton z:3];
    
    [pauseScreenSprites addObject:playButton];
    
    
    // Menu button
    CCButton *homeButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"MenuButtonPaused.png"]];
    homeButton.position = ccp(SCREEN_WIDTH / 2 - homeButton.contentSize.width * 1.4,
                              pauseLabel.position.y - homeButton.contentSize.height * 2);
    [homeButton setTarget:self selector:@selector(menuPressed)];
    homeButton.cascadeOpacityEnabled = YES;
    homeButton.opacity = 0;
    [self addChild:homeButton z:Z_BLOCKS];
    [pauseScreenSprites addObject:homeButton];
    
    
    // Music Button
    CCButton *musicButton = [[CCButton alloc]initWithTitle:@""
                                               spriteFrame:[CCSpriteFrame frameWithImageNamed:@"MusicOnButton.png"]
                                               highlightedSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MusicOffButton.png"]
                                               disabledSpriteFrame:nil];
    
    musicButton.togglesSelectedState = YES;
    musicButton.position = ccp(SCREEN_WIDTH / 2,homeButton.position.y);
    musicButton.cascadeOpacityEnabled = YES;
    musicButton.opacity = 0;
    [musicButton setTarget:self selector:@selector(musicPressed)];
    [self addChild:musicButton z:Z_BLOCKS];
    [pauseScreenSprites  addObject:musicButton];
    
    // Set the toggled button state
    if(music == 1) {
        [musicButton setSelected:NO];
    }
    else if(music == 0) {
        [musicButton setSelected:YES];
    }

    // Music Button
    CCButton *soundButton = [[CCButton alloc]initWithTitle:@""
                                               spriteFrame:[CCSpriteFrame frameWithImageNamed:@"SoundOnButton.png"]
                                    highlightedSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"SoundOffButton.png"]
                                       disabledSpriteFrame:nil];
    
    soundButton.togglesSelectedState = YES;
    soundButton.position = ccp(SCREEN_WIDTH / 2 + soundButton.contentSize.width * 1.4,
                                homeButton.position.y);
    [soundButton setTarget:self selector:@selector(soundPressed)];
    soundButton.cascadeOpacityEnabled = YES;
    soundButton.opacity = 0;
    [self addChild:soundButton z:Z_BLOCKS];
    [pauseScreenSprites addObject:soundButton];
    
    // Set the toggled button state
    if(sound == 1) {
        [soundButton setSelected:NO];
    }
    else if(sound == 0) {
        [soundButton setSelected:YES];
    }
    
    
    id fadePauseLabelAction = [CCActionFadeIn actionWithDuration:0.5f];
    [pauseLabel runAction:fadePauseLabelAction];
    
    id fadeMenuButtonAction = [CCActionFadeIn actionWithDuration:0.3f];
    [menuButton runAction:fadeMenuButtonAction];
    
    id fadePlayButtonAction = [CCActionFadeIn actionWithDuration:0.3f];
    [playButton runAction:fadePlayButtonAction];
    
    id fadeHomeButtonAction = [CCActionFadeIn actionWithDuration:0.3f];
    [homeButton runAction:fadeHomeButtonAction];
    
    id fadeMusicButtonAction = [CCActionFadeIn actionWithDuration:0.3f];
    [musicButton runAction:fadeMusicButtonAction];
    
    id fadeSoundButtonAction = [CCActionFadeIn actionWithDuration:0.3f];
    [soundButton runAction:fadeSoundButtonAction];
}


//---------------------------------------------------------------------------------------------------------------------
- (void)pauseFadeUp
{
    for(CCSprite *sprites in pausedSprites) {
        sprites.visible = true;
    }
    
    // remove the paused items
    for(CCSprite *sprites in pauseScreenSprites) {
        [sprites removeFromParentAndCleanup:YES];
    }
}

//---------------------------------------------------------------------------------------------------------------------
- (void)menuPressed
{
    if(UIBaseShown == 1) {
        return;
    }
    
    if(sound == 1) {
        [audio playEffect:@"uiclickback.caf"];
    }
    
    CCScene *scene = [Menu scene];
    CCTransition *fadeTransition = [CCTransition transitionFadeWithColor:[CCColor colorWithCcColor3b:ccc3(0, 0, 0)] duration:0.4f];
    [[CCDirector sharedDirector] replaceScene:scene withTransition:fadeTransition];
}


//---------------------------------------------------------------------------------------------------------------------
- (void)pausePressed
{
    if(UIBaseShown == 1) {
        return;
    }
    
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    
    if(pausedPressed == 0) {
        pausedPressed = 1;
        [self pauseMenuShown];
    }
}


//---------------------------------------------------------------------------------------------------------------------

- (void)playPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclickback.caf"];
    }
    
    if(pausedPressed == 1) {
        // Bring back the game sprites
        [self pauseFadeUp];
        pausedPressed = 0;
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)replayPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclickback.caf"];
    }
    
    CCScene *currentScene = [CCDirector sharedDirector].runningScene;
    CCScene *newScene = [[[currentScene class] alloc] init];

    CCTransition *fadeTransition = [CCTransition transitionFadeWithColor:[CCColor colorWithCcColor3b:ccc3(0, 0, 0)] duration:0.4f];
    [[CCDirector sharedDirector] replaceScene:newScene withTransition:fadeTransition];
}


//---------------------------------------------------------------------------------------------------------------------

- (void)soundPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
        
        // disable and save
        sound = 0;
        [self saveSettings];
    }
    else if(sound == 0) {
        
        // enable and save
        sound = 1;
        [self saveSettings];
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)musicPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    if(music == 1) {
        music = 0;
        [audio stopBg];
        [self saveSettings];
    }
    else if(music == 0) {
        music = 1;
        [audio playBgWithLoop:YES];
        [self saveSettings];
    }
}


//---------------------------------------------------------------------------------------------------------------------
//-(void) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
//{
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{

    CGPoint location = [touch locationInNode:self];
    
    // Detect the touch of the current block
    if(moveInProgress == 0 && playerWin == 0 && pausedPressed == 0 && UIBaseShown == 0) {
        for(Blocks *block in blockSprites) {
            if(CGRectContainsPoint(block.boundingBox, location)) {

                // If paid don't do this check
          //      if(upgradeModeActive == 0) {
                    if(moveCount == target) {
                        UIBaseShown = 1;
                        [self showNoMoreMovesPopUp];
                        break;
                    }
            //    }
                
                block.color = [CCColor colorWithWhite:0.8 alpha:1];
                block.isHighlighted = 1;
                [self saveBlockNumber:block.ID :block.type];
                break;
            }
        }
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    savedBlockID = -1;
    [self unHighlight];
    
}

//---------------------------------------------------------------------------------------------------------------------

- (void)unHighlight
{
    for(Blocks *block in blockSprites) {
        if(block.isHighlighted == 1) {
            
            //  NSLog(@"block ID %d",block.ID);
            block.color = [CCColor colorWithWhite:1.0 alpha:1];
            block.isHighlighted = 0;
        }
    }
}

//---------------------------------------------------------------------------------------------------------------------

-(void)panHandler:(UIPanGestureRecognizer *)recognizer
{
    CGPoint panAmount = [recognizer translationInView:[[CCDirector sharedDirector] view]];

    if(savedBlockID > -1 && moveInProgress == 0 && playerWin == 0) {
        [self unHighlight];
        
        if(panAmount.y >= 5) {
            [self moveBlock:savedBlockID:DOWN :savedBlockType];
            savedBlockID = -1;
        }
        else if(panAmount.y <= -5) {
            [self moveBlock:savedBlockID:UP :savedBlockType];
            savedBlockID = -1;
        }
        else if(panAmount.x >= 5) {
            [self moveBlock:savedBlockID:RIGHT :savedBlockType];
            savedBlockID = -1;
        }
        else if(panAmount.x <= -5) {
            [self moveBlock:savedBlockID:LEFT :savedBlockType];
            savedBlockID = -1;
        }
        
        
    }
}



//---------------------------------------------------------------------------------------------------------------------

- (void)clearGameGrid
{
    memset(tiles, 0,  GRID_MAX_X * GRID_MAX_Y * sizeof(unsigned short));
    memset(blocks, 0,  GRID_MAX_X * GRID_MAX_Y * sizeof(unsigned char));
}

//---------------------------------------------------------------------------------------------------------------------
- (void)win
{

    int type = 0;
    
    // Get the player and make him exit
    for(Blocks *block in blockSprites) {
        type = block.type;
        if(type == PLAYER) {
            [self exitPlayer:block];
            break;
        }
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)exitScene
{
    [self bringOutGridAndTiles];
    [self writeMovesAndBest];
  //  [self bringOutUFO];
    [self performSelector:@selector(textWriter) withObject:nil afterDelay:0.2f];
   // [self textWriter];
   // [self doStars];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)exitPlayer:(CCSprite*)player
{
    File *file = [[File alloc]init];
    
    [self captureScreen];

    // submit score if online
    if([self isConnected]) {
        starCount++;
        [[GameCenterManager sharedManager] saveAndReportScore:starCount leaderboard:@"com.9loops.puz.leaderboard"
                                                    sortOrder:GameCenterSortOrderHighToLow];
        
        [self processAchievements];
    }
    
    [self hideHeaderWin];

    
    id delayAction = [CCActionDelay actionWithDuration:0.2f];
    id scaleAction = [CCActionScaleTo actionWithDuration:0.3f scaleX:0.5 scaleY:1.0f];
    id fadeAction = [CCActionFadeTo actionWithDuration:0.3f opacity:0.0f];
    id spawnAction = [CCActionSpawn actions:scaleAction, fadeAction, nil];
    
    CCSprite *exitBar = (CCSprite*)[self getChildByName:@"exitBar" recursively:YES];
    id delayBarAction = [CCActionDelay actionWithDuration:0.4f];
    id scaleBarAction = [CCActionScaleTo actionWithDuration:0.2f scaleX:0.0 scaleY:1.0f];

    id teleportSampleCallAction = [CCActionCallBlock actionWithBlock:^{
        if(sound == 1) {
            [audio playEffect:@"teleport.caf"];
        }
    }];
    
    id callAction = [CCActionCallBlock actionWithBlock:^{
        [player removeFromParentAndCleanup:YES];
        
        CCSprite *hand = (CCSprite*)[self getChildByName:@"Hand" recursively:YES];
        [hand removeFromParentAndCleanup:YES];
        
        // clamp on the last level as can't unlock level 121
        if(stageValue < LAST_STAGE) {
            [file unlockNextStage:stageValue :1];
        }
        
        [file gainStarBest:stageValue :1 :moveCount];
        
        [self exitScene];
    }];
    
    [player runAction:[CCActionSequence actions: delayAction, spawnAction, callAction, nil]];
    [exitBar runAction:[CCActionSequence actions: delayBarAction, teleportSampleCallAction, scaleBarAction, nil]];
}


//---------------------------------------------------------------------------------------------------------------------

- (void)hideHeaderWin
{
    for(CCSprite *headerItem in headerSprites) {
        CCActionMoveTo *moveAction = [CCActionMoveTo actionWithDuration:0.3f
                                     position:ccp(headerItem.position.x, FY(0-headerItem.contentSize.height))];
        [headerItem runAction:moveAction];
    }
}

//---------------------------------------------------------------------------------------------------------------------
- (void)writeMovesAndBest
{
    // Moves
    CCLabelTTF *movesTTF = [CCLabelTTF labelWithString:@"Moves" fontName:@"JosefinSans-Bold" fontSize:25];
    movesTTF.position = ccp(SCREEN_WIDTH / 2 - movesTTF.contentSize.width / 3, FY(0 + movesTTF.contentSize.height * 5));
    movesTTF.opacity = 0;
    
    [self addChild:movesTTF];
    
    // Moves Value
    NSString *movesString = [NSString stringWithFormat:@"%d",moveCount];
    CCLabelTTF *movesWinVal = [CCLabelTTF labelWithString:movesString fontName:@"JosefinSans-Bold" fontSize:25];
    movesWinVal.position = ccp(movesTTF.position.x + movesTTF.contentSize.width,movesTTF.position.y);
    movesWinVal.opacity = 0;
    [self addChild:movesWinVal];
    
    // Best
    CCLabelTTF *bestTTF = [CCLabelTTF labelWithString:@"Best" fontName:@"JosefinSans-Bold" fontSize:25];
    bestTTF.position = ccp(movesTTF.position.x - bestTTF.contentSize.width / 3.2,
                           movesTTF.position.y - bestTTF.contentSize.height * 1.2);
    bestTTF.opacity = 0;
    [self addChild:bestTTF];
    
    // best Value
    if(moveCount < bestCount) {
        bestCount = moveCount;
    }
    
    NSString *bestString = [NSString stringWithFormat:@"%d",bestCount];
    CCLabelTTF *bestVal = [CCLabelTTF labelWithString:bestString fontName:@"JosefinSans-Bold" fontSize:25];
    bestVal.position = ccp(movesWinVal.position.x,bestTTF.position.y);
    bestVal.opacity = 0;
    [self addChild:bestVal];
    
    id fadeAction = [CCActionFadeIn actionWithDuration:0.6f];
    id fadeAction1 = [CCActionFadeIn actionWithDuration:0.6f];
    id fadeAction2 = [CCActionFadeIn actionWithDuration:0.6f];
    id fadeAction3 = [CCActionFadeIn actionWithDuration:0.6f];
    
    [movesTTF runAction:fadeAction];
    [movesWinVal runAction:fadeAction1];
    [bestTTF runAction:fadeAction2];
    [bestVal runAction:fadeAction3];
}


//---------------------------------------------------------------------------------------------------------------------

- (void)detectExit
{
    /*
    if(playerWin == 0) {
        if(playersConnected == 1) {
            NSLog(@"win!");
            [self win];
            playerWin = 1;
        }
    }
    */
    
    if(playerWin == 0) {
        if(blocks[exitX][exitY] == PLAYER) {
    //        NSLog(@"win!");
            [self win];
            playerWin = 1;
        }
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)fixedUpdate:(CCTime)delta
{
    [self fadeInStars];
    [self detectExit];
    [self moveStars];

    [self detectStage2MoveSwitch];
    [self detectStage3MoveSwitch];
}



//---------------------------------------------------------------------------------------------------------------------

- (void)initStars
{
    int i;
    float starX;
    float starY;
    float starZ;
    
    float scale;
    int ran = 0;
    
    for(i=0;i<MAX_STARS;i++) {
        starX = arc4random_uniform(SCREEN_WIDTH);
        starY = arc4random_uniform(SCREEN_HEIGHT);
        starZ = i * (MAX_DEPTH / MAX_STARS);
        
        starsX[i] = starX;
        starsY[i] = starY;
        starsZ[i] = starZ;
        
        ran = RAND_FROM_TO(1, 4);
      //  NSLog(@"ran %d",ran);
        
        NSString *starStr = [NSString stringWithFormat:@"Block%d.png",ran];
        
        CCSprite *star = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:starStr]];
        star.position = ccp(starX,starY);
      //  star.color = [CCColor colorWithCcColor4b:ccc4(0x68, 0xc9, 0xda, 0xff)]; //68c9da
        star.opacity = 0.0f;
        starOpacity = 0.0f;
        
        // Scale;
        scale = (1 - starZ / MAX_DEPTH) * 1;
        star.scale = scale;
        
        [starArray addObject:star];
        [self addChild:star];
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)fadeInStars
{
    if(starOpacity < 1.0f) {
        for(CCSprite *star in starArray) {
            star.opacity = starOpacity;
        }
        starOpacity += 0.02f;
    }
}

//---------------------------------------------------------------------------------------------------------------------
- (void)moveStars
{
    int i = 0;
    float starX = 0;
    float starY = 0;
    float starZ = 0;
    
    float xSpeed = 0.0;
    float ySpeed = 0.0;
    float zSpeed = 0.80;
    float scale;
    
    aa += 0.01 ;
    
    // cycle through all the stars and move them
    for(CCSprite *star in starArray) {
        
        starsX[i] += xSpeed;
        starsY[i] += ySpeed;
        starsZ[i] -= zSpeed;
        
        starZ = starsZ[i];
        starX = starsX[i];
        starY = starsY[i];
        
        if((starX > SCREEN_WIDTH) || (starX < 0)) {
            starX -= SCREEN_WIDTH * (floor(starX / SCREEN_WIDTH));
        }
        
        if((starY > SCREEN_HEIGHT) || (starY < 0)) {
            starY -= SCREEN_HEIGHT * (floor(starY / SCREEN_HEIGHT));
        }
        
        if((starZ > MAX_DEPTH) || (starZ < 0)) {
            starZ -= MAX_DEPTH * (floor(starZ / MAX_DEPTH));
        }
        
        float k = SCALE / starZ;
        float x = ((starX - SCREEN_WIDTH / 2) * k + cos(aa / 2) * SCREEN_WIDTH / 4 + SCREEN_WIDTH / 2);
        float y = ((starY - SCREEN_HEIGHT / 2) * k + sin(aa) * SCREEN_HEIGHT / 4 + SCREEN_HEIGHT / 2);
        
        
        scale = (1 - starZ / MAX_DEPTH) * 1.2;
        
        star.position = ccp(x,y);
        star.scale = scale;
        
        i++;
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)textWriter
{
    int count = 0;
    
    if(sound == 1) {
        [audio playEffect:@"gamewin.caf"];
    }

    if(moveCount <= starReach) {
        float moveVals[8] = {0.6,0.5,0.4,0.3,0.2,0.3,0.4,0.5};
    
        CCLabelBMFont *wellDone = [[CCLabelBMFont alloc]initWithString:@"Perfect!" fntFile:@"Josefin.fnt"];
        wellDone.position = ccp(SCREEN_WIDTH / 2, FY(0 - wellDone.contentSize.height));
        [self addChild:wellDone];
        
        for (CCNode *child in wellDone.children) {
            id moveAction = [CCActionMoveBy actionWithDuration:moveVals[count] position:ccp(0, -wellDone.contentSize.height * 2.8)];
            [child runAction:moveAction];
            count++;
        }
    }
    else {
        float moveVals[6] = {0.4,0.3,0.2,0.3,0.4,0.5};
        
        CCLabelBMFont *wellDone = [[CCLabelBMFont alloc]initWithString:@"Great!" fntFile:@"Josefin.fnt"];
        wellDone.position = ccp(SCREEN_WIDTH / 2, FY(0 - wellDone.contentSize.height));
        [self addChild:wellDone];
        
        for (CCNode *child in wellDone.children) {
            id moveAction = [CCActionMoveBy actionWithDuration:moveVals[count] position:ccp(0, -wellDone.contentSize.height * 2.8)];
            [child runAction:moveAction];
            count++;
        }
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)doStars
{
    CCSprite *star1 = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"Star.png"]];
    star1.position = ccp(SCREEN_WIDTH / 2, FY(0 + star1.contentSize.height * 3.2));
    star1.scale = 0;
    [self addChild:star1];
        
    id scale1 = [CCActionScaleTo actionWithDuration:1.9 scale:1.0f];
    id ease1 = [CCActionEaseElasticOut actionWithAction:scale1];
    [star1 runAction:ease1];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)countStars
{
    
    File *file = [[File alloc]init];
    NSArray *worldData = [file loadWorld:1];
    
    int count = 0;
    int starAmount = 0;
    starCount = 0;
    
    for(NSDictionary *entries in worldData) {
        NSNumber *star = [entries objectForKey:@"Star"];
        starAmount = [star intValue];
        starCount += starAmount;
        count++;
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)processAchievements
{

    if(stageValue == 3) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.9loops.puz.tutorialComplete"
                                                    percentComplete:100 shouldDisplayNotification:YES];
    }
    
    // Star count based
    if(starCount == 5) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.9loops.puz.5Stars"
                                                    percentComplete:100 shouldDisplayNotification:YES];
    }
    
    else if(starCount == 10) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.9loops.puz.10Stars"
                                                    percentComplete:100 shouldDisplayNotification:YES];
    }
    
    else if(starCount == 20) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.9loops.puz.20Stars"
                                                    percentComplete:100 shouldDisplayNotification:YES];
    }
    
    else if(starCount == 40) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.9loops.puz.40Stars"
                                                    percentComplete:100 shouldDisplayNotification:YES];
    }
    
    else if(starCount == 80) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.9loops.puz.80Stars"
                                                    percentComplete:100 shouldDisplayNotification:YES];
    }
    
    else if(starCount == 100) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.9loops.puz.100Stars"
                                                    percentComplete:100 shouldDisplayNotification:YES];
    }
    
    else if(starCount == 120) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.9loops.puz.120Stars"
                                                    percentComplete:100 shouldDisplayNotification:YES];
    }
}


//---------------------------------------------------------------------------------------------------------------------

- (void)cleanup
{
    [[[CCDirector sharedDirector] view] removeGestureRecognizer:panRecognizer];
    
    blockSprites = nil;
    pausedSprites = nil;
    pauseScreenSprites = nil;
    gridAndTiles = nil;
    headerSprites = nil;

    [audio unloadEffect:@"uiclick.caf"];
    [audio unloadEffect:@"uiclickback.caf"];
}


//---------------------------------------------------------------------------------------------------------------------

- (void)nextPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    // Set the next loading level
    if(stageValue < LAST_STAGE) {
        [GameGlobals globals].loadingLevel = stageValue + 1;
        [[GameGlobals globals] save];
    
        CCScene *scene = [Stage scene];
        [[CCDirector sharedDirector] replaceScene:scene];
    }
    // clamp or will crash on the last stage, go to menu scene
    else if(stageValue == LAST_STAGE) {
        CCScene *scene = [Menu scene];
        [[CCDirector sharedDirector] replaceScene:scene];
        
    }
}


//---------------------------------------------------------------------------------------------------------------------

- (void)homePressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclickback.caf"];
    }
    
    CCScene *scene = [Menu scene];
    [[CCDirector sharedDirector] replaceScene:scene];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)gcPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    if(![self isConnected]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Connection", @"")
                                                            message:@"No internet connection found"
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    
    [[GameCenterManager sharedManager] presentLeaderboardsOnViewController:[CCDirector sharedDirector]];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)sharePressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    NSLog(@"share pressed");
    // FB sharing easy way using activity share
    NSString *textToShare = [NSString stringWithFormat:@"I just beat stage %d with %d moves in #Puz - https://itunes.apple.com/app/id1028807516",stageValue,moveCount];
    UIImage *imageToShare = screenCapture;
    NSArray *itemsToShare = @[textToShare, imageToShare];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                         UIActivityTypeCopyToPasteboard,
                                         UIActivityTypeAssignToContact,
                                         UIActivityTypeSaveToCameraRoll,
                                         UIActivityTypeAirDrop];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CCDirector sharedDirector] presentViewController:activityVC animated:YES completion:nil];
    });

}

//---------------------------------------------------------------------------------------------------------------------

- (void)watchVideo
{
    if(videoRunning == 1) {
        return;
    }
    
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    [[UnityAds sharedInstance] show];

    [self closePopUp];
}

//---------------------------------------------------------------------------------------------------------------------


- (void)givePlayer50Moves
{
    int newTarget = target + 50;
    
    target += 50;
    
    NSString *newTargerStr = [NSString stringWithFormat:@"%d",newTarget];
    
    CCLabelTTF *targetVal = (CCLabelTTF*)[self getChildByName:@"targetVal" recursively:YES];
    [targetVal setString:newTargerStr];
    
    videoWatched = 1;
}

//---------------------------------------------------------------------------------------------------------------------

- (void)setUpgraded
{
    upgradeModeActive = 1;
    
    int newTarget = target + 50;
    
    target += 50;
    
    NSString *newTargerStr = [NSString stringWithFormat:@"%d",newTarget];
    
    CCLabelTTF *targetVal = (CCLabelTTF*)[self getChildByName:@"targetVal" recursively:YES];
    [targetVal setString:newTargerStr];
    
    [self closePopUp];
}


- (void)unlimitedMoves
{
    if(videoRunning == 1) {
        return;
    }
    
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    if(iapRequestOK == 1) {
        
        // There is only 1 iAP
        NSString *productID = [_products objectAtIndex:0];
        
        // Start the spinner
            [MBProgressHUD showHUDAddedTo:[[CCDirector sharedDirector] view] animated:YES];
        
        // Do the purchase
        [[RMStore defaultStore] addPayment:productID success:^(SKPaymentTransaction *transaction) {
            
            [MBProgressHUD hideHUDForView:[[CCDirector sharedDirector] view] animated:YES];
            File *file = [[File alloc]init];
            [file setUpgraded];
            [self setUpgraded];
            [self closePopUp];
            
        } failure:^(SKPaymentTransaction *transaction, NSError *error) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Payment Transaction Failed", @"")
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                      otherButtonTitles:nil];
            [alertView show];
            
            [MBProgressHUD hideHUDForView:[[CCDirector sharedDirector] view] animated:YES];
            [self closePopUp];
        }];
        
        
        
    }
    else if(iapRequestOK == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"IAP Products Request Failed", @"")
                                                            message:@"Please check your connection and restart stage"
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles:nil];
        [alertView show];
        [self closePopUp];
    }

}

//---------------------------------------------------------------------------------------------------------------------

/*
- (void)likeOnFB
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
}
*/

//---------------------------------------------------------------------------------------------------------------------

- (void)playAgain
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    if(videoRunning == 1) {
        return;
    }
    
    [self closePopUp];
    CCScene *currentScene = [CCDirector sharedDirector].runningScene;
    CCScene *newScene = [[[currentScene class] alloc] init];
    
    CCTransition *fadeTransition = [CCTransition transitionFadeWithColor:[CCColor colorWithCcColor3b:ccc3(0, 0, 0)] duration:0.4f];
    [[CCDirector sharedDirector] replaceScene:newScene withTransition:fadeTransition];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)closePopUp
{
   // NSLog(@"close pop up");
    // remove the black base
    CCSprite *base = (CCSprite*)[self getChildByName:@"base" recursively:YES];
    [base removeFromParentAndCleanup:YES];
    
    // bring out the pop
    CCSprite *UIBase = (CCSprite*)[self getChildByName:@"UIBase" recursively:YES];
    
    id moveAction = [CCActionMoveTo actionWithDuration:0.3f position:ccp(SCREEN_WIDTH / 2, 0 - UIBase.contentSize.height)];
    id callAction = [CCActionCallBlock actionWithBlock:^{
        [UIBase removeFromParentAndCleanup:YES];
        UIBaseShown = 0;
    }];
    
    id easeAction = [CCActionEaseBackOut actionWithAction:moveAction];
    [UIBase runAction: [CCActionSequence actions:easeAction, callAction, nil]];
    
}

//---------------------------------------------------------------------------------------------------------------------

- (void)showNoMoreMovesPopUp
{
    // black base
    CCSprite *base = [CCSprite spriteWithImageNamed:@"pixel.png"];
    [base setTextureRect:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    base.position = ccp(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);
    base.colorRGBA = [CCColor colorWithCcColor4b:ccc4(0, 0, 0, 190)]; // Green Sea
    base.name = @"base";
    [self addChild:base z:Z_UIBASE];
    
    CCSprite *UIBase = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"UIBase.png"]];
    UIBase.position = ccp(SCREEN_WIDTH / 2, 0 - UIBase.contentSize.height);
    UIBase.name = @"UIBase";
    [self addChild:UIBase z:Z_UIBASE+1];
    
    
    // Add buttons
    CCButton *watchVideo;
    if(videoAvailable == 0 || videoWatched == 1) {
        watchVideo = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"DisabledButt.png"]];
        watchVideo.position = ccp(UIBase.contentSize.width / 2, UIBase.contentSize.height - watchVideo.contentSize.height * 2.4);
        watchVideo.name = @"watchVideo";
        [UIBase addChild:watchVideo];
    }
    else {
        watchVideo = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"UnlimitedButt.png"]];
        watchVideo.position = ccp(UIBase.contentSize.width / 2, UIBase.contentSize.height - watchVideo.contentSize.height * 2.4);
        [watchVideo setTarget:self selector:@selector(watchVideo)];
        watchVideo.name = @"watchVideo";
        [UIBase addChild:watchVideo];
    }

    if(videoAvailable == 0 || videoWatched == 1) {
        CCLabelTTF *watchVideoTTF = [[CCLabelTTF alloc] initWithString:@"No Free Offers" fontName:@"JosefinSans-Bold" fontSize:16];
        watchVideoTTF.position = ccp(watchVideo.contentSize.width / 2, watchVideo.contentSize.height / 1.35);
        watchVideoTTF.color = [CCColor colorWithCcColor3b:ccc3(0xFF, 0xFF, 0xFF)]; // FFE200
        [watchVideo addChild:watchVideoTTF];
    }
    else {
        CCLabelTTF *watchVideoTTF = [[CCLabelTTF alloc] initWithString:@"Watch Short Video" fontName:@"JosefinSans-Bold" fontSize:16];
        watchVideoTTF.position = ccp(watchVideo.contentSize.width / 2, watchVideo.contentSize.height / 1.35);
        watchVideoTTF.color = [CCColor colorWithCcColor3b:ccc3(0xFF, 0xFF, 0xFF)]; // FFE200
        [watchVideo addChild:watchVideoTTF];
    }

    if(videoAvailable == 0 || videoWatched == 1) {
        CCLabelTTF *watchVideoTTF1 = [[CCLabelTTF alloc] initWithString:@"Check Back Later" fontName:@"JosefinSans-Bold" fontSize:15];
        watchVideoTTF1.position = ccp(watchVideo.contentSize.width / 2, watchVideo.contentSize.height / 3.2);
        watchVideoTTF1.color = [CCColor colorWithCcColor3b:ccc3(0xFF, 0xFF, 0xFF)]; // FFE200
        [watchVideo addChild:watchVideoTTF1];
    }
    else {
        CCLabelTTF *watchVideoTTF1 = [[CCLabelTTF alloc] initWithString:@"50 Extra Moves" fontName:@"JosefinSans-Bold" fontSize:15];
        watchVideoTTF1.position = ccp(watchVideo.contentSize.width / 2, watchVideo.contentSize.height / 3.2);
        watchVideoTTF1.color = [CCColor colorWithCcColor3b:ccc3(0xFF, 0xE2, 0x00)]; // FFE200
        [watchVideo addChild:watchVideoTTF1];
    }
    
    CCButton *buyButt;
    
    if(upgradeModeActive == 0 && iapRequestOK == 1) {
        buyButt = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"UnlimitedButt.png"]];
        buyButt.position = ccp(UIBase.contentSize.width / 2, watchVideo.position.y - buyButt.contentSize.height * 1.6);
        [buyButt setTarget:self selector:@selector(unlimitedMoves)];
    
        CCLabelTTF *buyTTF = [[CCLabelTTF alloc] initWithString:@"Premium: Upgrade Moves!" fontName:@"JosefinSans-Bold" fontSize:16];
        buyTTF.position = ccp(buyButt.contentSize.width / 2, buyButt.contentSize.height / 1.35);
        buyTTF.color = [CCColor colorWithCcColor3b:ccc3(0xFF, 0xFF, 0xFF)];
        [buyButt addChild:buyTTF];
        
        // add the price
        CCLabelTTF *priceTTF = [[CCLabelTTF alloc] initWithString:unlimitedPrice fontName:@"JosefinSans-Bold" fontSize:15];
        priceTTF.position = ccp(buyButt.contentSize.width / 2, buyButt.contentSize.height / 3.2);
        priceTTF.color = [CCColor colorWithCcColor3b:ccc3(0xFF, 0xE2, 0x00)];
        [buyButt addChild:priceTTF];
        [UIBase addChild:buyButt];
    }
    else if(upgradeModeActive == 1 || iapRequestOK == 0) {
        
        // If already paid, grey out the button and remove selector
        buyButt = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"DisabledButt.png"]];
        buyButt.position = ccp(UIBase.contentSize.width / 2, watchVideo.position.y - buyButt.contentSize.height * 1.6);
        
        CCLabelTTF *buyTTF = [[CCLabelTTF alloc] initWithString:@"Premium: Upgrade Moves!" fontName:@"JosefinSans-Bold" fontSize:16];
        buyTTF.position = ccp(buyButt.contentSize.width / 2, buyButt.contentSize.height / 1.35);
        buyTTF.color = [CCColor colorWithCcColor3b:ccc3(0xFF, 0xFF, 0xFF)];
        [buyButt addChild:buyTTF];
        
        // add the price
        CCLabelTTF *priceTTF = [[CCLabelTTF alloc] initWithString:@"N/A" fontName:@"JosefinSans-Bold" fontSize:15];
        priceTTF.position = ccp(buyButt.contentSize.width / 2, buyButt.contentSize.height / 3.2);
        priceTTF.color = [CCColor colorWithCcColor3b:ccc3(0xFF, 0xE2, 0x00)];
        [buyButt addChild:priceTTF];
        [UIBase addChild:buyButt];

    }
    
    

    
    CCButton *playAgainButt = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"PlayAgain.png"]];
    playAgainButt.position = ccp(UIBase.contentSize.width / 2, buyButt.position.y - playAgainButt.contentSize.height * 1.6);
    [playAgainButt setTarget:self selector:@selector(playAgain)];
    [UIBase addChild:playAgainButt];
    
    CCLabelTTF *replayTTF = [[CCLabelTTF alloc] initWithString:@"Replay Stage" fontName:@"JosefinSans-Bold" fontSize:16];
    replayTTF.position = ccp(buyButt.contentSize.width / 2, playAgainButt.contentSize.height / 1.8);
    replayTTF.color = [CCColor colorWithCcColor3b:ccc3(0xFF, 0xFF, 0xFF)];
    [playAgainButt addChild:replayTTF];

    // Bring in
    id moveAction = [CCActionMoveTo actionWithDuration:0.4f position:ccp(SCREEN_WIDTH / 2,
                                                                     FY(0 + UIBase.contentSize.height / 1.3))];
    
    id easeAction = [CCActionEaseBackOut actionWithAction:moveAction];
    [UIBase runAction: [CCActionSequence actions:easeAction, nil]];
}


//---------------------------------------------------------------------------------------------------------------------
// Store Methods

- (void)requestProducts
{
    _products = @[@"com.9loops.puz.upgraded"];
    
    [[RMStore defaultStore] requestProducts:[NSSet setWithArray:_products] success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
        _productsRequestFinished = YES;
        iapRequestOK = 1;
        
        
        // Get the localized string and price for displaying on the button
        for (SKProduct *product in products) {
            if([product.productIdentifier isEqualToString:@"com.9loops.puz.upgraded"]) {
                
                unlimitedTitle = product.localizedTitle;
                
                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                [numberFormatter setLocale:product.priceLocale];
                
                NSLocale *storeLocale = product.priceLocale;
                NSString *storeCountry = (NSString*)CFLocaleGetValue((CFLocaleRef)storeLocale, kCFLocaleCountryCode);
                NSString *storePrice = [numberFormatter stringFromNumber:product.price];
                unlimitedPrice = [NSString stringWithFormat:@"%@ %@",storePrice,storeCountry];
            }
        }
        
    } failure:^(NSError *error) {
        
        iapRequestOK = 0;
        
    }];
}

//---------------------------------------------------------------------------------------------------------------------

// Rater code
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Reveal
    if(alertView.tag == 1) {
        if(buttonIndex == 1) {
            [self rater];
        }
    }
}

// Todo change app ID
- (void)rater
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1028807516&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"]];
}

- (void)ratePressed
{
    NSLog(@"rate pressed");
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1028807516&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"]];
}



//---------------------------------------------------------------------------------------------------------------------
// Reachability - check internet connection

- (BOOL)isConnected
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    
    if(networkStatus == NotReachable) {
        return NO;
    }
    
    return YES;
}



//---------------------------------------------------------------------------------------------------------------------
// Unity Delegates

- (void)unityAdsVideoCompleted:(NSString *)rewardItemKey skipped:(BOOL)skipped
{
    // dashboard is set so the user can't skip
    [self givePlayer50Moves];
}

- (void)unityAdsDidHide
{
    [[CCDirector sharedDirector] stopAnimation];
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] startAnimation];
    
    if(music == 1) {
        [audio playBgWithLoop:YES];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thanks for watching" message:@"Enjoy the extra moves!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
    [alert show];
}

- (void)unityAdsWillShow
{
    [[CCDirector sharedDirector] stopAnimation];
    [[CCDirector sharedDirector] pause];
    [audio stopEverything];
}

//---------------------------------------------------------------------------------------------------------------------

- (UIImage*)screenGrab:(CCNode*)startNode
{
    CCRenderTexture* rtx = [CCRenderTexture renderTextureWithWidth:SCREEN_WIDTH height:SCREEN_HEIGHT];
    
    [rtx begin];
    [startNode visit];
    [rtx end];
    
    return [rtx getUIImage];
}



- (void)dealloc
{
  //  [[VungleSDK sharedSDK] setDelegate:nil];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)dumpTiles
{
    int x;
    int y;
    int gridVal;
    
    NSLog(@"--- tiles ---");
    
    for(y=0;y<GRID_MAX_Y;y++) {
        for(x=0;x<GRID_MAX_X;x++) {
            gridVal = tiles[x][y];
            printf("%02d",gridVal);
        }
        printf("\n");
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)dumpBlocks
{
    int x;
    int y;
    int gridVal;
    
    NSLog(@"--- blocks ---");
    
    for(y=0;y<GRID_MAX_Y;y++) {
        for(x=0;x<GRID_MAX_X;x++) {
            gridVal = blocks[x][y];
            printf("%02X",gridVal);
        }
        printf("\n");
    }
}


@end

