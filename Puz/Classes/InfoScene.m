//
//  Menu.m
//  Puz
//
//  Created by Ian Callaghan on 6/1/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Start.h"
#import "InfoScene.h"
#import "File.h"
#import "Stage.h"
#import "GameGlobals.h"
#import "MenuBlock.h"


static inline int FY(int y) {return (SCREEN_HEIGHT-y);}

@implementation InfoScene

+ (InfoScene *)scene
{
    return [[self alloc] init];
}


- (void)initVars
{
    self.userInteractionEnabled = YES;
    menuNodes = [[NSMutableArray alloc]init];
    
    currentPage = 1;
    
    starArray = [[NSMutableArray alloc]init];
    menuDots = [[NSMutableArray alloc]init];
    starMoveCount = 0;
    durationCount = 10;
    previousPage = -1;
    
    starOpacity = 0;
    starCount = 0;
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
    [self setupBG];
    [self setupHeader];
    [self initStars];
    
    [self doTextWriter];
    
    return self;
}

- (void)doTextWriter
{
    NSString *header = @"Puz";
    NSString *gap1 = @"\n";
    NSString *line1 = @"Developed by:";
    NSString *line2 = @"9loops";
    NSString *gap2 = @"\n";
    NSString *line3 = @"Design & Code";
    NSString *line4 = @"Ian Callaghan";
    NSString *gap3 = @"\n";
    NSString *line5 = @"Copyright 9loops 2015";
    NSString *line6 = @"http://9loops.com";

    
    
    // Create array to place all the strings
    
    NSArray *stringArray = [[NSArray alloc]initWithObjects:header,gap1,line1,line2,gap2,line3,line4,gap3,line5,line6, nil];
    
    float currentYPos = 0;
    int lineCount = 1;
    int fontSize;
    
    for(NSString *line in stringArray) {
        NSLog(@"line %@",line);
        
        if(lineCount == 1) {
            fontSize = 22;
        }
        else if(lineCount == 2 || lineCount == 5) {
            fontSize = 20;
        }
        else {
            fontSize = 16;
        }
        
        CCLabelTTF *lineTTF = [[CCLabelTTF alloc] initWithString:line fontName:@"JosefinSans-Bold" fontSize:fontSize];
        lineTTF.position = ccp(SCREEN_WIDTH / 2, FY(0 + lineTTF.contentSize.height * 4 + currentYPos));
        [self addChild:lineTTF z:1];
        currentYPos += lineTTF.contentSize.height;
        lineCount ++;
    }
    
    /*
    CCLabelBMFont *wellDone = [[CCLabelBMFont alloc]initWithString:@"Perfect!" fntFile:@"Josefin.fnt"];
    wellDone.position = ccp(SCREEN_WIDTH / 2, FY(0 - wellDone.contentSize.height));
    [self addChild:wellDone];
    
    for (CCNode *child in wellDone.children) {
        id moveAction = [CCActionMoveBy actionWithDuration:moveVals[count] position:ccp(0, -wellDone.contentSize.height * 2.8)];
        [child runAction:moveAction];
        count++;
    }
     */
    
}


- (void)preLoadSounds
{
    audio = [OALSimpleAudio sharedInstance];
    [audio preloadEffect:@"uiclick.caf"];
    [audio preloadEffect:@"uiclickback.caf"];
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

}

- (void)fixedUpdate:(CCTime)delta
{
    [self fadeInStars];
    [self moveStars];
    
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
            
            NSLog(@"name int %d",nameInt);
            if(menuBlock.type == 0) {
                levelLocked = 0;
                break;
            }
        }
    }
    
    if(levelLocked == 0) {
        NSString *levelStr = [NSString stringWithFormat:@"%d",levelNumber];
        CCSprite *menuBlock = (CCSprite*)[self getChildByName:levelStr recursively:YES];
        menuBlock.color = [CCColor colorWithCcColor3b:ccc3(0x77, 0x77, 0x77)];
    
        // Save the level number to global
        [GameGlobals globals].loadingLevel = levelNumber;
        [[GameGlobals globals] save];

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
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    int levelNo;
    
    int currentAdd = (currentPage - 1) * 20;
    
    NSLog(@"current Add %d",currentAdd);
    
    for(CCSprite *menuBlock in menuNodes) {
        if(CGRectContainsPoint(menuBlock.boundingBox, location)) {
            levelNo = [menuBlock.name intValue];
            
            levelNo += currentAdd;
            
            NSLog(@"levelNo %d current page %d",levelNo,currentPage);
            
            // 0 is locked, 1-120 is the level
            if(levelNo > 0 && levelNo < 121) {
                [self loadLevel:levelNo];
            }
            
            break;
        }
    }
}



@end
