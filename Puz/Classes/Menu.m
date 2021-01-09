//
//  Menu.m
//  Puz
//
//  Created by Ian Callaghan on 6/1/15.


#import "Start.h"
#import "Menu.h"
#import "File.h"
#import "Stage.h"
#import "GameGlobals.h"
#import "MenuBlock.h"


static inline int FY(int y) {return (SCREEN_HEIGHT-y);}

@implementation Menu

+ (Menu *)scene
{
    return [[self alloc] init];
}

- (void)initVars
{
    self.userInteractionEnabled = YES;
    menuNodes = [[NSMutableArray alloc]init];
    
    currentPage = [GameGlobals globals].pageNumber;
    
    starArray = [[NSMutableArray alloc]init];
    menuDots = [[NSMutableArray alloc]init];
    starMoveCount = 0;
    durationCount = 10;
    previousPage = -1;
    
    starOpacity = 0;
    starCount = 0;
    
    scrolling = 0;
}


- (id)init
{
    self = [super init];
    if(!self) {
        return NULL;
    }

    [self initVars];
    [self loadAtlases];
    [self loadSettings];
    [self preLoadSounds];
    [self loadWorldData];
    [self setupBG];
    [self setupHeader];
    [self setupScrollView];
    [self initStars];

    return self;
}

- (void)preLoadSounds
{
    audio = [OALSimpleAudio sharedInstance];
    [audio preloadEffect:@"uiclick.caf"];
    [audio preloadEffect:@"uiclickback.caf"];
    
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
    fbLikeBonus = [[settingsDict objectForKey:@"FBLikeBonus"] intValue];
    
    /*
    NSLog(@"sound %d",sound);
    NSLog(@"music %d",music);
    NSLog(@"fbConnect %d",fbConnect);
    NSLog(@"notifications %d",notifications);
    NSLog(@"fb bonus %d",fbLikeBonus);
    */
}


- (void)loadAtlases
{
    // Load the texture atlas
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"GameAtlas.plist"];
}


- (void)loadWorldData
{

    File *file = [[File alloc]init];
    NSArray *worldData = [file loadWorld:1];
    
    int count = 0;
    int starAmount = 0;
    
    for(NSDictionary *entries in worldData) {
        NSNumber *star = [entries objectForKey:@"Star"];
        NSNumber *locked = [entries objectForKey:@"Locked"];
        NSNumber *best = [entries objectForKey:@"Best"];
        
        starAmount = [star intValue];
        starCount += starAmount;
        
        starData[count] = (unsigned char)[star intValue];
        lockedData[count] = (unsigned char)[locked intValue];
        bestData[count] = (unsigned short)[best intValue];
        count++;
    }
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
    CCButton *menuButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"HomeButton.png"]];
    menuButton.position = ccp(0 + menuButton.contentSize.width, FY(0 + menuButton.contentSize.height));
    [menuButton setTarget:self selector:@selector(homePressed)];
    [self addChild:menuButton z:1];
    
    
    // Stage
    CCLabelTTF *level = [CCLabelTTF labelWithString:@"Stages" fontName:@"JosefinSans-Bold" fontSize:22];
    level.position = ccp(SCREEN_WIDTH / 2,
                         FY(0 + level.contentSize.height * 1.1));
    [self addChild:level z:1];
    
    NSString *starsString = [NSString stringWithFormat:@"%d/%d",starCount,MAX_LEVELS];
    
    // Menu stars amount
    CCLabelTTF *starsAmountText = [CCLabelTTF labelWithString:starsString fontName:@"JosefinSans-Bold" fontSize:17];
    starsAmountText.position = ccp(SCREEN_WIDTH- starsAmountText.contentSize.width, level.position.y - 8);
    [self addChild:starsAmountText z:1];
    
    // Create the stars amount / counter
    CCSprite *menuStar = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MenuStar.png"]];
    menuStar.position = ccp(starsAmountText.position.x - starsAmountText.contentSize.width / 1.2,starsAmountText.position.y);
    [self addChild:menuStar z:1];
}


- (void)setupScrollView
{
    int i;
    int x;
    int y;
    int level = 1;
    float xSpacing = 0;
    float ySpacing = 0;
    float leftPadding;
    float topPadding;
    float mBWidth;
    float mBHeight;
    
    int page = 0;
    
    unsigned star;
    unsigned locked;
    unsigned short best;
    
    CCNode *menuScroll = [[CCNode alloc]init];
    [menuScroll setContentSize:CGSizeMake(SCREEN_WIDTH * PAGES,SCREEN_HEIGHT)]; // 120 level (20 * 6)
    
    CCSprite *menuButt = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBLocked.png"]];
    mBHeight = menuButt.contentSize.height;
    mBWidth = menuButt.contentSize.width;
    
   // leftPadding = mBWidth * 1.2;
    
    leftPadding = ((SCREEN_WIDTH / 2) - mBWidth * 2.1);
    topPadding = mBHeight * 2.2;
    
    menuButt = nil;
    
    // Page 1
    for(y=0;y<5;y++) {
        for(x=0;x<4;x++) {
            
            star = starData[level-1];
            locked = lockedData[level-1];
            best = bestData[level-1];

            MenuBlock *menuButton;
            
            if(locked == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBLocked.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBStar.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 0) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBEmpty.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }

            // Stage
            if(locked == 0) {
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            
                CCLabelTTF *levelTTF = [CCLabelTTF labelWithString:menuNumber fontName:@"JosefinSans-Bold" fontSize:22];
                levelTTF.position = ccp(0 + menuButton.contentSize.width / 2.0,0 + menuButton.contentSize.height / 1.6);
                [menuButton addChild:levelTTF];
                menuButton.type = 0;
            }
            else {
                menuButton.type = 1;
            }

            
            [menuScroll addChild:menuButton];
            [menuNodes addObject:menuButton];
            
            xSpacing += mBWidth * 1.4;
            level++;
            
        }
        
        xSpacing = 0;
        ySpacing += mBHeight * 1.4;
    }
    
    page++;
    xSpacing = 0;
    ySpacing = 0;
    
    // Page 2
    for(y=0;y<5;y++) {
        for(x=0;x<4;x++) {
            
            star = starData[level-1];
            locked = lockedData[level-1];
            best = bestData[level-1];
            
            MenuBlock *menuButton;
            
            if(locked == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBLocked.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBStar.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 0) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBEmpty.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            
            // Stage
            if(locked == 0) {
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
                
                CCLabelTTF *levelTTF = [CCLabelTTF labelWithString:menuNumber fontName:@"JosefinSans-Bold" fontSize:22];
                levelTTF.position = ccp(0 + menuButton.contentSize.width / 2.0,0 + menuButton.contentSize.height / 1.6);
                [menuButton addChild:levelTTF];
                menuButton.type = 0;

            }
            else {
                menuButton.type = 1;
            }

            [menuScroll addChild:menuButton];
            [menuNodes addObject:menuButton];
            
            xSpacing += mBWidth * 1.4;
            
          //  NSLog(@"level number %d",level);
            level++;
        }
        
        xSpacing = 0;
        ySpacing += mBHeight * 1.4;
    }
    
    page++;
    xSpacing = 0;
    ySpacing = 0;
    
    // Page 3
    for(y=0;y<5;y++) {
        for(x=0;x<4;x++) {
            
            star = starData[level-1];
            locked = lockedData[level-1];
            best = bestData[level-1];
            
            MenuBlock *menuButton;
            
            if(locked == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBLocked.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBStar.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 0) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBEmpty.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            
            // Stage
            if(locked == 0) {
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
                
                CCLabelTTF *levelTTF = [CCLabelTTF labelWithString:menuNumber fontName:@"JosefinSans-Bold" fontSize:22];
                levelTTF.position = ccp(0 + menuButton.contentSize.width / 2.0,0 + menuButton.contentSize.height / 1.6);
                [menuButton addChild:levelTTF];
                menuButton.type = 0;

            }
            else {
                menuButton.type = 1;
            }

            
            [menuScroll addChild:menuButton];
            [menuNodes addObject:menuButton];
            
            xSpacing += mBWidth * 1.4;
            level++;
        }
        
        xSpacing = 0;
        ySpacing += mBHeight * 1.4;
    }
    
    page++;
    xSpacing = 0;
    ySpacing = 0;
    
    // Page 4
    for(y=0;y<5;y++) {
        for(x=0;x<4;x++) {
            
            star = starData[level-1];
            locked = lockedData[level-1];
            best = bestData[level-1];
            
            MenuBlock *menuButton;
            
            if(locked == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBLocked.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
                
            }
            else if(locked == 0 && star == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBStar.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 0) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBEmpty.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            
            // Stage
            if(locked == 0) {
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
                
                CCLabelTTF *levelTTF = [CCLabelTTF labelWithString:menuNumber fontName:@"JosefinSans-Bold" fontSize:22];
                levelTTF.position = ccp(0 + menuButton.contentSize.width / 2.0,0 + menuButton.contentSize.height / 1.6);
                [menuButton addChild:levelTTF];
                menuButton.type = 0;

            }
            else {
                menuButton.type = 1;
            }
            
            [menuScroll addChild:menuButton];
            [menuNodes addObject:menuButton];
            
            xSpacing += mBWidth * 1.4;
            level++;
        }
        
        xSpacing = 0;
        ySpacing += mBHeight * 1.4;
    }
    
    page++;
    xSpacing = 0;
    ySpacing = 0;
    
    // Page 5
    for(y=0;y<5;y++) {
        for(x=0;x<4;x++) {
            
            star = starData[level-1];
            locked = lockedData[level-1];
            best = bestData[level-1];
            
            MenuBlock *menuButton;
            
            if(locked == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBLocked.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBStar.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 0) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBEmpty.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            
            // Stage
            if(locked == 0) {
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
                
                CCLabelTTF *levelTTF = [CCLabelTTF labelWithString:menuNumber fontName:@"JosefinSans-Bold" fontSize:22];
                levelTTF.position = ccp(0 + menuButton.contentSize.width / 2.0,0 + menuButton.contentSize.height / 1.6);
                [menuButton addChild:levelTTF];
                menuButton.type = 0;

            }
            else {
                menuButton.type = 1;
            }

            
            [menuScroll addChild:menuButton];
            [menuNodes addObject:menuButton];
            
            xSpacing += mBWidth * 1.4;
            level++;
        }
        
        xSpacing = 0;
        ySpacing += mBHeight * 1.4;
    }
    
    page++;
    xSpacing = 0;
    ySpacing = 0;
    
    // Page 6
    for(y=0;y<5;y++) {
        for(x=0;x<4;x++) {
            
            star = starData[level-1];
            locked = lockedData[level-1];
            best = bestData[level-1];
            
            MenuBlock *menuButton;
            
            if(locked == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBLocked.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 1) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBStar.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            else if(locked == 0 && star == 0) {
                menuButton = [[MenuBlock alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MBEmpty.png"]];
                menuButton.position = ccp((SCREEN_WIDTH * page) + leftPadding + xSpacing,FY(topPadding + ySpacing));
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
            }
            
            // Stage
            if(locked == 0) {
                NSString *menuNumber = [NSString stringWithFormat:@"%d",level];
                menuButton.name = menuNumber;
                
                CCLabelTTF *levelTTF = [CCLabelTTF labelWithString:menuNumber fontName:@"JosefinSans-Bold" fontSize:22];
                levelTTF.position = ccp(0 + menuButton.contentSize.width / 2.0,0 + menuButton.contentSize.height / 1.6);
                [menuButton addChild:levelTTF];
                menuButton.type = 0;

            }
            else {
                menuButton.type = 1;
            }

            
            [menuScroll addChild:menuButton];
            [menuNodes addObject:menuButton];
            
            xSpacing += mBWidth * 1.4;
            level++;
        }
        
        xSpacing = 0;
        ySpacing += mBHeight * 1.4;
    }
    
    page = 13;
    

    
    
    CCLabelTTF *comingSoonLabel = [CCLabelTTF labelWithString:@"Coming Soon"
                                                      fontName:@"JosefinSans-Bold"
                                                      fontSize:34];
    comingSoonLabel.position = ccp((SCREEN_WIDTH / 2) * page,
                                   FY(0 + comingSoonLabel.contentSize.height * 4));
    [menuScroll addChild:comingSoonLabel];
    
    
    xSpacing = 0;

    scrollView = [[CCScrollView alloc]initWithContentNode:menuScroll];
    [scrollView setHorizontalScrollEnabled:YES];
    [scrollView setVerticalScrollEnabled:NO];
    [scrollView setBounces:YES];
    [scrollView setPagingEnabled:YES];
    [self addChild:scrollView z:1];
    
    CCSprite *menuDotSample = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MenuDotWhite.png"]];
    
    int dotWidth = menuDotSample.contentSize.width * PAGES;
    int screenCenter = SCREEN_WIDTH / 2;
    int dotStartPos = screenCenter - (dotWidth / 2);

    // Menu Dots
    for(i=0;i<PAGES;i++) {
        CCSprite *menuDot = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MenuDotWhite.png"]];
        menuDot.position = ccp(dotStartPos + xSpacing,FY(topPadding + ySpacing));
        [self addChild:menuDot z:1];
        xSpacing += menuDot.contentSize.width * 1.5;
        
        if(i > 0) {
            menuDot.color = [CCColor colorWithCcColor4b:ccc4(0, 0, 0, 255)];
        }
        
        [menuDots addObject:menuDot];
    }
    
    // Set the position to the page we previously saved on
    scrollView.scrollPosition = ccp((currentPage - 1) * SCREEN_WIDTH,0);
    [self moveDots];
}


- (void)fixedUpdate:(CCTime)delta
{
    [self fadeInStars];
    [self moveDots];
    [self moveStars];
}


- (void)drawDots
{
    int count = 1;
    
    if(currentPage != previousPage) {
        for(CCSprite *dot in menuDots) {
            if(currentPage == count) {
                dot.color = [CCColor colorWithCcColor4b:ccc4(255, 255, 255, 255)];
                previousPage = currentPage;
            }
            else {
                dot.color = [CCColor colorWithCcColor4b:ccc4(0, 0, 0, 255)];
                previousPage = currentPage;
            }
            count++;
        }
    }
}


- (void)moveDots
{
    int menuPos = ABS(scrollView.scrollPosition.x);
    
    if(menuPos == 0) {
        currentPage = 1;
        scrolling = 0;
    }
    else if(menuPos == SCREEN_WIDTH) {
        currentPage = 2;
        scrolling = 0;
    }
    else if(menuPos == SCREEN_WIDTH * 2) {
        currentPage = 3;
        scrolling = 0;
    }
    else if(menuPos == SCREEN_WIDTH * 3) {
        currentPage = 4;
        scrolling = 0;
    }
    else if(menuPos == SCREEN_WIDTH * 4) {
        currentPage = 5;
        scrolling = 0;
    }
    else if(menuPos == SCREEN_WIDTH * 5) {
        currentPage = 6;
        scrolling = 0;
    }
    else if(menuPos == SCREEN_WIDTH * 6) {
        currentPage = 7;
        scrolling = 0;
    }
    else {
        scrolling = 1;
    }

    
    [self drawDots];
}


- (void)fadeInStars
{
    if(starOpacity < 1.0f) {
        for(CCSprite *star in starArray) {
            star.opacity = starOpacity;
        }
        starOpacity += 0.02f;
    }
}


- (void)homePressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclickback.caf"];
    }
    
    CCScene *scene = [Start scene];

    CCTransition *fadeTransition = [CCTransition transitionFadeWithColor:[CCColor colorWithCcColor3b:ccc3(0, 0, 0)] duration:0.4f];
    [[CCDirector sharedDirector] replaceScene:scene withTransition:fadeTransition];
}


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

        NSString *starStr = [NSString stringWithFormat:@"Block%d.png",ran];
        
        CCSprite *star = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:starStr]];
        star.position = ccp(starX,starY);
        //star.color = [CCColor colorWithCcColor4b:ccc4(0x68, 0xc9, 0xda, 0xff)]; //68c9da
        star.opacity = 0.0f;
        starOpacity = 0.0f;
        
        // Scale;
        scale = (1 - starZ / MAX_DEPTH) * 1;
        star.scale = scale;
        
        [starArray addObject:star];
        [self addChild:star];
    }
}

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


- (void)loadLevel:(int)levelNumber
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    int levelLocked = 1;
    
    for(MenuBlock *menuBlock in menuNodes) {
        int nameInt = [menuBlock.name intValue];
        if(levelNumber == nameInt) {
            
            //NSLog(@"name int %d",nameInt);
            if(menuBlock.type == 0) {
                levelLocked = 0;
                break;
            }
        }
    }
    
    // make sure put below code back
    if(levelLocked == 0) {
        NSString *levelStr = [NSString stringWithFormat:@"%d",levelNumber];
        CCSprite *menuBlock = (CCSprite*)[self getChildByName:levelStr recursively:YES];
        menuBlock.color = [CCColor colorWithCcColor3b:ccc3(0x77, 0x77, 0x77)];
    
        NSString *flurryLog = [NSString stringWithFormat:@"User loaded stage %d",levelNumber];
        [Flurry logEvent:flurryLog];
    
        // Save the level number to global
        [GameGlobals globals].loadingLevel = levelNumber;
        [[GameGlobals globals] save];
        
        [GameGlobals globals].pageNumber = currentPage;
        [[GameGlobals globals] savePageNumber];

        CCScene *scene = [Stage scene];
        CCTransition *fadeTransition = [CCTransition transitionFadeWithColor:[CCColor colorWithCcColor3b:ccc3(0, 0, 0)] duration:0.4f];
        [[CCDirector sharedDirector] replaceScene:scene withTransition:fadeTransition];
    }
}


- (void)cleanup
{
    starArray = nil;
    menuDots = nil;
    menuNodes = nil;
    
    [audio unloadEffect:@"uiclick.caf"];
    [audio unloadEffect:@"uiclickback.caf"];
}


-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    /*
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    int levelNo;
    
    int currentAdd = (currentPage - 1) * 20;
    
    //NSLog(@"current Add %d",currentAdd);
    
    for(CCSprite *menuBlock in menuNodes) {
        if(CGRectContainsPoint(menuBlock.boundingBox, location)) {
            levelNo = [menuBlock.name intValue];
            
            levelNo += currentAdd;
            
            //NSLog(@"levelNo %d current page %d",levelNo,currentPage);
            
            // 0 is locked, 1-120 is the level
            if(levelNo > 0 && levelNo < 121) {
                [self loadLevel:levelNo];
            }
            
            break;
        }
    }
    */
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    int levelNo;
    
    int currentAdd = (currentPage - 1) * 20;
    
    //NSLog(@"current Add %d",currentAdd);
    
    for(CCSprite *menuBlock in menuNodes) {
        if(CGRectContainsPoint(menuBlock.boundingBox, location)) {
            levelNo = [menuBlock.name intValue];
            
            levelNo += currentAdd;
            
        //    NSLog(@"levelNo %d current page %d",levelNo,currentPage);
            
            // 0 is locked, 1-120 is the level
            if(levelNo > 0 && levelNo < 121 && scrolling == 0) {
                [self loadLevel:levelNo];
            }
            
            break;
        }
    }

}



@end
