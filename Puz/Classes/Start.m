//
//  Start.m
//  ChocoBlocks
//
//  Created by Ian Callaghan on 5/28/15.


#import "Start.h"
#import "Stage.h"
#import "Menu.h"
#import "File.h"
#import "MBProgressHUD.h"
#import "InfoScene.h"



static inline int FY(int y) {return (SCREEN_HEIGHT-y);}

@implementation Start

+ (Start *)scene
{
    return [[self alloc] init];
}


//---------------------------------------------------------------------------------------------------------------------

- (void)initVars
{
    self.userInteractionEnabled = YES;
    
    starArray = [[NSMutableArray alloc]init];
    starMoveCount = 0;
    durationCount = 10;
    
    starOpacity = 0;
    logoOpacity = 0;
    
    settingsMenuActive = 0;
    socialMenuActive = 0;
    
    settingsButtonInMotion = 0;
    socialButtonInMotion = 0;
}




//---------------------------------------------------------------------------------------------------------------------

- (id)init
{
    self = [super init];
    if(!self) {
        return NULL;
    }
    
    //[LoopsGK sharedManager];
    // Set GameCenter Manager Delegate
    [[GameCenterManager sharedManager] setDelegate:self];
    
    [self initVars];
    [self loadSettings];
    [self preLoadSounds];
    [self loadAtlases];
    [self setupBG];
    [self setupMenuButtons];
    
    [self initStars];

    [self bringInLogo];
    
    return self;
}


//---------------------------------------------------------------------------------------------------------------------

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

//---------------------------------------------------------------------------------------------------------------------

- (void)saveSettings
{
    File *file = [[File alloc]init];
    [file saveSettings:sound :music :fbConnect :notifications :fbLikeBonus];
}

//---------------------------------------------------------------------------------------------------------------------

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

//---------------------------------------------------------------------------------------------------------------------

- (void)loadAtlases
{
    // Load the texture atlas
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"StartAtlas.plist"];

}

//---------------------------------------------------------------------------------------------------------------------

- (void)setupBG
{
    CCSprite9Slice *background = [CCSprite9Slice spriteWithImageNamed:@"white_square.png"];
    background.anchorPoint = CGPointZero;
    background.contentSize = [CCDirector sharedDirector].viewSize;
    background.color = [CCColor colorWithCcColor3b:ccc3(0x25, 0x2B, 0x31)];
    [self addChild:background];
    
    // Copyright
    CCLabelTTF *loops = [[CCLabelTTF alloc]initWithString:@"©9LOOPS 2015" fontName:@"JosefinSans-Bold" fontSize:12];
    loops.position = ccp(SCREEN_WIDTH / 2, 0 + loops.contentSize.height);
    [self addChild:loops z:1];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)setupMenuButtons
{
    // Settings button
    CCButton *settingsButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"SettingsButton.png"]];
    settingsButton.position = ccp(0 + settingsButton.contentSize.width / 1.2, 0 + settingsButton.contentSize.height / 1.2);
    [settingsButton setTarget:self selector:@selector(settingsPressed)];
    settingsButton.cascadeColorEnabled = YES;
    settingsButton.name = @"settingsButton";
    [self addChild:settingsButton z:1];
    
    // Music button
    CCButton *musicButton = [[CCButton alloc]initWithTitle:@""
                                               spriteFrame:[CCSpriteFrame frameWithImageNamed:@"MusicOnButton.png"]
                                    highlightedSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MusicOffButton.png"]
                                       disabledSpriteFrame:nil];
    
    musicButton.togglesSelectedState = YES;
    musicButton.position = ccp(0 - musicButton.contentSize.width,settingsButton.position.y + musicButton.contentSize.height * 1.2);
    [musicButton setTarget:self selector:@selector(musicPressed)];
    musicButton.name = @"musicButton";
    [self addChild:musicButton z:1];
    
    // Set the toggled button state
    if(music == 1) {
        [musicButton setSelected:NO];
    }
    else if(music == 0) {
        [musicButton setSelected:YES];
    }
    
    
    // Sound button
    CCButton *soundButton = [[CCButton alloc]initWithTitle:@""
                                               spriteFrame:[CCSpriteFrame frameWithImageNamed:@"SoundOnButton.png"]
                                    highlightedSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"SoundOffButton.png"]
                                       disabledSpriteFrame:nil];
    
    soundButton.togglesSelectedState = YES;
    soundButton.position = ccp(0 - soundButton.contentSize.width,musicButton.position.y + soundButton.contentSize.height * 1.2);
    [soundButton setTarget:self selector:@selector(soundPressed)];
    soundButton.name = @"soundButton";
    [self addChild:soundButton z:1];
    
    // Set the toggled button state
    if(sound == 1) {
        [soundButton setSelected:NO];
    }
    else if(sound == 0) {
        [soundButton setSelected:YES];
    }
    
    // Restore button
    CCButton *restoreButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"RestoreButton.png"]];
    restoreButton.position = ccp(0 - restoreButton.contentSize.width,soundButton.position.y + restoreButton.contentSize.height * 1.2);
    [restoreButton setTarget:self selector:@selector(restorePressed)];
    restoreButton.name  = @"restoreButton";
    [self addChild:restoreButton z:1];
    
    //---- Second menu
    
    // Social button
    CCButton *socialButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"SocialButton.png"]];
    socialButton.position = ccp(SCREEN_WIDTH - socialButton.contentSize.width / 1.2, 0 + socialButton.contentSize.height / 1.2);
    [socialButton setTarget:self selector:@selector(socialPressed)];
    socialButton.name = @"socialButton";
    [self addChild:socialButton z:1];
    
    // Game center button
    CCButton *GCButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"GCButton.png"]];
    GCButton.position = ccp(SCREEN_WIDTH + GCButton.contentSize.width, socialButton.position.y + GCButton.contentSize.height * 1.2);
    [GCButton setTarget:self selector:@selector(GCPressed)];
    GCButton.name = @"GCButton";
    [self addChild:GCButton z:1];
    
    // Facebook button
    CCButton *FBButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"ShareFBButton.png"]];
    FBButton.position = ccp(SCREEN_WIDTH + FBButton.contentSize.width, GCButton.position.y + FBButton.contentSize.height * 1.2);
    [FBButton setTarget:self selector:@selector(FBPressed)];
    FBButton.name = @"FBButton";
    [self addChild:FBButton z:1];
    
    // Info button
    CCButton *infoButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"InfoButton.png"]];
    infoButton.position = ccp(SCREEN_WIDTH + infoButton.contentSize.width, FBButton.position.y + infoButton.contentSize.height * 1.2);
    [infoButton setTarget:self selector:@selector(infoPressed)];
    infoButton.name = @"infoButton";
    [self addChild:infoButton z:1];
    
    
}


- (float)randFloatBetween:(float)low and:(float)high
{
    float diff = high - low;
    return (((float) rand() / RAND_MAX) * diff) + low;
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
        
        
        NSString *starStr = [NSString stringWithFormat:@"Block%d.png",ran];
   
        CCSprite *star = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:starStr]];
        star.position = ccp(starX,starY);
       // star.color = [CCColor colorWithCcColor4b:ccc4(0x68, 0xc9, 0xda, 0xff)]; //68c9da
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

- (void)bringInLogo
{
    
    // Bring in the logo from the top of the screen
    CCSprite *u = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"U.png"]];
    u.position = ccp(SCREEN_WIDTH / 2 - u.contentSize.width / 1.3, FY(0 - u.contentSize.height));
    u.name = @"u";
    [self addChild:u z: 2];
    
    CCSprite *p = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"P.png"]];
    p.position = ccp(u.position.x - p.contentSize.width * 1.4, FY(0 - u.contentSize.height));
    p.name = @"p";
    [self addChild:p z: 2];
    
    CCSprite *z = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"Z.png"]];
    z.position = ccp(u.position.x + z.contentSize.width * 1.4, FY(0 - u.contentSize.height));
    z.name = @"z";
    [self addChild:z z: 2];
    
    CCSprite *sideBlock = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"SideBlock.png"]];
    sideBlock.position = ccp(SCREEN_WIDTH + sideBlock.contentSize.width, FY(0 + u.contentSize.height * 2.0));
    sideBlock.name = @"sideBlock";
    [self addChild:sideBlock z: 2];
    
    
    // Motion streaks, just for some coolness //8400CB
    CCMotionStreak *uStreak = [CCMotionStreak streakWithFade:0.3 minSeg:5 width:u.contentSize.width
                                                       color:[CCColor colorWithCcColor3b:ccc3(0x84, 0x00, 0xCB)] textureFilename:@"pixel.png"];
    uStreak.name = @"uStreak";
    [uStreak setPosition:u.position];
    [uStreak reset];
    [self addChild:uStreak z:1];
    

    CCMotionStreak *pStreak = [CCMotionStreak streakWithFade:0.3 minSeg:5 width:u.contentSize.width
                                                       color:[CCColor colorWithCcColor3b:ccc3(0x84, 0x00, 0xCB)] textureFilename:@"pixel.png"];
    pStreak.name = @"pStreak";
    [pStreak setPosition:p.position];
    [pStreak reset];
    [self addChild:pStreak z:1];
    
    CCMotionStreak *zStreak = [CCMotionStreak streakWithFade:0.3 minSeg:5 width:u.contentSize.width
                                                       color:[CCColor colorWithCcColor3b:ccc3(0x84, 0x00, 0xCB)] textureFilename:@"pixel.png"];
    zStreak.name = @"zStreak";
    [zStreak setPosition:z.position];
    [zStreak reset];
    [self addChild:zStreak z:1];
    
    CCMotionStreak *sideblockStreak = [CCMotionStreak streakWithFade:0.3 minSeg:5 width:u.contentSize.width
                                                       color:[CCColor colorWithCcColor3b:ccc3(0xDB, 0x09, 0x62)] textureFilename:@"pixel.png"];
    sideblockStreak.name = @"sideBlockStreak";
    [sideblockStreak setPosition:sideBlock.position];
    [sideblockStreak reset];
    [self addChild:sideblockStreak z:1];
    
    
    // P
    CCActionMoveTo *moveP = [CCActionMoveTo actionWithDuration:0.5
                                                      position:ccp(p.position.x, FY(0 + p.contentSize.height * 2.0))];
    CCActionEaseBackOut *movePEase = [CCActionEaseElasticOut actionWithAction:moveP period:0.95];
    
    [p runAction:[CCActionSequence actions:movePEase, nil]];
    
    // U
    CCActionMoveTo *moveU = [CCActionMoveTo actionWithDuration:0.8
                                                      position:ccp(u.position.x, FY(0 + u.contentSize.height * 2.0))];
    CCActionEaseBackOut *moveUEase = [CCActionEaseElasticOut actionWithAction:moveU period:0.95];
    
    [u runAction:[CCActionSequence actions:moveUEase, nil]];
    
    // Z
    CCActionMoveTo *moveZ = [CCActionMoveTo actionWithDuration:1.1
                                                      position:ccp(z.position.x, FY(0 + z.contentSize.height * 2.0))];
    CCActionEaseBackOut *moveZEase = [CCActionEaseElasticOut actionWithAction:moveZ period:0.95];
    
    [z runAction:[CCActionSequence actions:moveZEase, nil]];
    
    
    // Side block
    CCActionMoveTo *moveSideBlock = [CCActionMoveTo actionWithDuration:1.5
                                            position:ccp(z.position.x + sideBlock.contentSize.width * 1.1, FY(0 + p.contentSize.height * 2.0))];
    CCActionEaseBackOut *moveSBEase = [CCActionEaseElasticOut actionWithAction:moveSideBlock period:0.95];
    
    [sideBlock runAction:[CCActionSequence actions:moveSBEase, nil]];
    
    
    // Play
    CCButton *playButton = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"PlayButtonStart.png"]];
    playButton.position = ccp(SCREEN_WIDTH / 2, sideBlock.position.y - playButton.contentSize.height * 2.2);
    [playButton setTarget:self selector:@selector(playPressed)];
    [self addChild:playButton z:1];
    
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

- (void)fixedUpdate:(CCTime)delta
{
    
    [self fadeInStars];
    [self moveStars];
    
    CCSprite *p = (CCSprite*)[self getChildByName:@"p" recursively:YES];
    CCMotionStreak *pStreak = (CCMotionStreak*)[self getChildByName:@"pStreak" recursively:YES];
    [pStreak setPosition:p.position];
    
    CCSprite *u = (CCSprite*)[self getChildByName:@"u" recursively:YES];
    CCMotionStreak *uStreak = (CCMotionStreak*)[self getChildByName:@"uStreak" recursively:YES];
    [uStreak setPosition:u.position];
    
    CCSprite *z = (CCSprite*)[self getChildByName:@"z" recursively:YES];
    CCMotionStreak *zStreak = (CCMotionStreak*)[self getChildByName:@"zStreak" recursively:YES];
    [zStreak setPosition:z.position];
    
    CCSprite *sideBlock = (CCSprite*)[self getChildByName:@"sideBlock" recursively:YES];
    CCMotionStreak *sideBlockStreak = (CCMotionStreak*)[self getChildByName:@"sideBlockStreak" recursively:YES];
    [sideBlockStreak setPosition:sideBlock.position];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)playPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    CCScene *scene = [Menu scene];
    CCTransition *fadeTransition = [CCTransition transitionFadeWithColor:[CCColor colorWithCcColor3b:ccc3(0, 0, 0)] duration:0.4f];
    [[CCDirector sharedDirector] replaceScene:scene withTransition:fadeTransition];
}

//---------------------------------------------------------------------------------------------------------------------
- (void)settingsPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    if(settingsButtonInMotion == 0) {
        
        settingsButtonInMotion = 1;
        
        if(settingsMenuActive == 0) {
            settingsMenuActive = 1;
        
            // Tint to grey when active
      //      CCButton *settingsButton = (CCButton*)[self getChildByName:@"settingsButton" recursively:NO];
        
        
            // Animate the buttons
            CCButton *musicButton = (CCButton*)[self getChildByName:@"musicButton" recursively:NO];
        
            CCActionMoveTo *musicButtonMoveAction = [CCActionMoveTo actionWithDuration:0.4f
                                                                position:ccp(0 + musicButton.contentSize.width / 1.2,
                                                                             musicButton.position.y)];
            CCActionEaseElasticOut *musicEaseAction = [CCActionEaseElasticOut actionWithAction:musicButtonMoveAction period:0.55];
            [musicButton runAction:musicEaseAction];
        
        
            CCButton *soundButton = (CCButton*)[self getChildByName:@"soundButton" recursively:NO];
        
            CCActionMoveTo *soundButtonMoveAction = [CCActionMoveTo actionWithDuration:0.5f
                                                                          position:ccp(0 + soundButton.contentSize.width / 1.2,
                                                                                       soundButton.position.y)];
            CCActionEaseElasticOut *soundEaseAction = [CCActionEaseElasticOut actionWithAction:soundButtonMoveAction period:0.55];
            [soundButton runAction:soundEaseAction];
        
            CCButton *restoreButton = (CCButton*)[self getChildByName:@"restoreButton" recursively:NO];
        
            CCActionMoveTo *restoreButtonMoveAction = [CCActionMoveTo actionWithDuration:0.6f
                                                                          position:ccp(0 + restoreButton.contentSize.width / 1.2,
                                                                                       restoreButton.position.y)];
            CCActionEaseElasticOut *restoreEaseAction = [CCActionEaseElasticOut actionWithAction:restoreButtonMoveAction period:0.55];
            
            // Add a call to set the action in motion back to 0 after the restore button has finished
            CCActionCallBlock *callAction = [CCActionCallBlock actionWithBlock:^{
                settingsButtonInMotion = 0;
            }];
            
            [restoreButton runAction:[CCActionSequence actions:restoreEaseAction, callAction,nil]];
        }
        else if(settingsMenuActive == 1) {
            settingsMenuActive = 0;
        
            // Animate the buttons
            CCButton *musicButton = (CCButton*)[self getChildByName:@"musicButton" recursively:NO];
        
            CCActionMoveTo *musicButtonMoveAction = [CCActionMoveTo actionWithDuration:0.4f
                                                                          position:ccp(0 - musicButton.contentSize.width,
                                                                                       musicButton.position.y)];
            CCActionEaseElasticIn *musicEaseAction = [CCActionEaseElasticIn actionWithAction:musicButtonMoveAction period:0.55];
            [musicButton runAction:musicEaseAction];
        
        
            CCButton *soundButton = (CCButton*)[self getChildByName:@"soundButton" recursively:NO];
        
            CCActionMoveTo *soundButtonMoveAction = [CCActionMoveTo actionWithDuration:0.5f
                                                                          position:ccp(0 - soundButton.contentSize.width,
                                                                                       soundButton.position.y)];
            CCActionEaseElasticIn *soundEaseAction = [CCActionEaseElasticIn actionWithAction:soundButtonMoveAction period:0.55];
            [soundButton runAction:soundEaseAction];
        
        
            CCButton *restoreButton = (CCButton*)[self getChildByName:@"restoreButton" recursively:NO];
        
            CCActionMoveTo *restoreButtonMoveAction = [CCActionMoveTo actionWithDuration:0.6f
                                                                            position:ccp(0 - restoreButton.contentSize.width,
                                                                                         restoreButton.position.y)];
            CCActionEaseElasticIn *restoreEaseAction = [CCActionEaseElasticIn actionWithAction:restoreButtonMoveAction period:0.55];
            
            // Add a call to set the action in motion back to 0 after the restore button has finished
            CCActionCallBlock *callAction = [CCActionCallBlock actionWithBlock:^{
                settingsButtonInMotion = 0;
            }];
            
            [restoreButton runAction:[CCActionSequence actions:restoreEaseAction, callAction,nil]];
        }
    }

}

//---------------------------------------------------------------------------------------------------------------------
- (void)socialPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    if(socialButtonInMotion == 0) {
        socialButtonInMotion = 1;
        
        if(socialMenuActive == 0) {
            socialMenuActive = 1;
        
            // Animate the buttons
            CCSprite *GCButton = (CCSprite*)[self getChildByName:@"GCButton" recursively:NO];
        
            CCActionMoveTo *GCButtonMoveAction = [CCActionMoveTo actionWithDuration:0.4f
                                                                          position:ccp(SCREEN_WIDTH - GCButton.contentSize.width / 1.2,
                                                                                       GCButton.position.y)];
            CCActionEaseElasticOut *socialEaseAction = [CCActionEaseElasticOut actionWithAction:GCButtonMoveAction period:0.55];
            [GCButton runAction:socialEaseAction];
        
            CCSprite *FBButton = (CCSprite*)[self getChildByName:@"FBButton" recursively:NO];
        
            CCActionMoveTo *FBButtonMoveAction = [CCActionMoveTo actionWithDuration:0.5f
                                                                          position:ccp(SCREEN_WIDTH - FBButton.contentSize.width / 1.2,
                                                                                       FBButton.position.y)];
            CCActionEaseElasticOut *FBEaseAction = [CCActionEaseElasticOut actionWithAction:FBButtonMoveAction period:0.55];
            [FBButton runAction:FBEaseAction];
        
            CCSprite *infoButton = (CCSprite*)[self getChildByName:@"infoButton" recursively:NO];
        
            CCActionMoveTo *infoButtonMoveAction = [CCActionMoveTo actionWithDuration:0.6f
                                                                            position:ccp(SCREEN_WIDTH - infoButton.contentSize.width / 1.2,
                                                                                         infoButton.position.y)];
            CCActionEaseElasticOut *infoEaseAction = [CCActionEaseElasticOut actionWithAction:infoButtonMoveAction period:0.55];
            
            // Add a call to set the action in motion back to 0 after the restore button has finished
            CCActionCallBlock *callAction = [CCActionCallBlock actionWithBlock:^{
                socialButtonInMotion = 0;
            }];
            
            [infoButton runAction:[CCActionSequence actions:infoEaseAction, callAction,nil]];
        }
        else if(socialMenuActive == 1) {
            socialMenuActive = 0;
        
            // Animate the buttons
            CCSprite *GCButton = (CCSprite*)[self getChildByName:@"GCButton" recursively:NO];
        
            CCActionMoveTo *GCButtonMoveAction = [CCActionMoveTo actionWithDuration:0.4f
                                                                       position:ccp(SCREEN_WIDTH + GCButton.contentSize.width,
                                                                                    GCButton.position.y)];
            CCActionEaseElasticIn *socialEaseAction = [CCActionEaseElasticIn actionWithAction:GCButtonMoveAction period:0.55];
            [GCButton runAction:socialEaseAction];
        
            CCSprite *FBButton = (CCSprite*)[self getChildByName:@"FBButton" recursively:NO];
        
            CCActionMoveTo *FBButtonMoveAction = [CCActionMoveTo actionWithDuration:0.5f
                                                                       position:ccp(SCREEN_WIDTH + FBButton.contentSize.width,
                                                                                    FBButton.position.y)];
            CCActionEaseElasticIn *FBEaseAction = [CCActionEaseElasticIn actionWithAction:FBButtonMoveAction period:0.55];
            [FBButton runAction:FBEaseAction];
        
            CCSprite *infoButton = (CCSprite*)[self getChildByName:@"infoButton" recursively:NO];
        
            CCActionMoveTo *infoButtonMoveAction = [CCActionMoveTo actionWithDuration:0.6f
                                                                         position:ccp(SCREEN_WIDTH + infoButton.contentSize.width,
                                                                                      infoButton.position.y)];
            CCActionEaseElasticIn *infoEaseAction = [CCActionEaseElasticIn actionWithAction:infoButtonMoveAction period:0.55];
            
            // Add a call to set the action in motion back to 0 after the restore button has finished
            CCActionCallBlock *callAction = [CCActionCallBlock actionWithBlock:^{
                socialButtonInMotion = 0;
            }];
            
            [infoButton runAction:[CCActionSequence actions:infoEaseAction, callAction,nil]];
        }
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)cleanup
{

    starArray = nil;
    [audio unloadEffect:@"uiclick.caf"];
    [audio unloadEffect:@"uiclickback.caf"];
}

//---------------------------------------------------------------------------------------------------------------------

- (void)restorePressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    
    // Start the spinner
    [MBProgressHUD showHUDAddedTo:[[CCDirector sharedDirector] view] animated:YES];
    
    [[RMStore defaultStore] restoreTransactionsOnSuccess:^(NSArray *transactions) {
       
        [MBProgressHUD hideHUDForView:[[CCDirector sharedDirector] view] animated:YES];
        
        unsigned int transactionCount = (unsigned int)[transactions count];
        
     //   NSLog(@"%d",transactionCount);

        if(transactionCount) {
            File *file = [[File alloc]init];
            [file setUpgraded];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Purchases Restored", @"")
                                                                message:@"Your in-app purchases have been restored"
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                      otherButtonTitles:nil];
            [alertView show];

        }
        else if(transactionCount == 0) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Purchases Not Found", @"")
                                                                message:@"No previous in-app purchases found"
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        
        
    } failure:^(NSError *error) {
        
        [MBProgressHUD hideHUDForView:[[CCDirector sharedDirector] view] animated:YES];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Restore Transactions Failed", @"")
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
    
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



- (void)infoPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    CCScene *scene = [InfoScene scene];
    CCTransition *fadeTransition = [CCTransition transitionFadeWithColor:[CCColor colorWithCcColor3b:ccc3(0, 0, 0)] duration:0.4f];
    [[CCDirector sharedDirector] replaceScene:scene withTransition:fadeTransition];
    

    /*
    [[GameCenterManager sharedManager] resetAchievementsWithCompletion:^(NSError *error) {
        if (error) NSLog(@"Error Resetting Achievements: %@", error);
    }];
    */
    

}

//---------------------------------------------------------------------------------------------------------------------

- (void)FBPressed
{
    if(sound == 1) {
        [audio playEffect:@"uiclick.caf"];
    }
    
    // link to facebook page
    NSURL *facebookURL = [NSURL URLWithString:@"fb://profile/158605581138351"];
    
    if ([[UIApplication sharedApplication] canOpenURL:facebookURL]) {
        [[UIApplication sharedApplication] openURL:facebookURL];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://facebook.com/9loop"]];
    }
}

//---------------------------------------------------------------------------------------------------------------------

- (void)MessageBox:(NSString*)headerText :(NSString*)bodyString
{
    NSLog(@"message box called");
    /*
    CCSprite *messageBox = [[CCSprite alloc]initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:@"MessageBox.png"]];
    messageBox.position = ccp(SCREEN_WIDTH / 2, 0 - messageBox.contentSize.height);
    
    CCButton *messageBoxButt = [[CCButton alloc]initWithTitle:@"" spriteFrame:[CCSpriteFrame frameWithImageNamed:@"MessageBoxButt.png"]];
    messageBoxButt.position = ccp(SCREEN_WIDTH / 2, 0 + messageBoxButt.contentSize.height);
    [messageBox addChild:messageBox z:10];
    
    // Bring in
    id moveAction = [CCActionMoveTo actionWithDuration:0.4f position:ccp(SCREEN_WIDTH / 2,SCREEN_HEIGHT / 2)];
    
    id easeAction = [CCActionEaseBackOut actionWithAction:moveAction];
    [messageBox runAction: [CCActionSequence actions:easeAction, nil]];
    */
}

//---------------------------------------------------------------------------------------------------------------------

- (void)GCPressed
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
// Game Center delegates

- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController {
    [[CCDirector sharedDirector] presentViewController:gameCenterLoginController animated:YES completion:^{
        NSLog(@"Finished Presenting Authentication Controller");
    }];
}


- (void)dealloc
{
    [[GameCenterManager sharedManager] setDelegate:nil];
}

@end
