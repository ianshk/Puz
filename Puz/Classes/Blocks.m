//  Puz
//  (c) Ian Callaghan
//  Created by Ian Callaghan on 4/16/15.


#import "Blocks.h"


@implementation Blocks

@synthesize ID;
@synthesize x;
@synthesize y;
@synthesize HorV;
@synthesize type;
@synthesize width;
@synthesize height;
@synthesize tag;
@synthesize isHighlighted;




- (id)initWithType:(int)xPos :(int)yPos :(int)enemyType
{
    /*
    NSString *enemyTypeStr = [NSString stringWithFormat:@"Sprites/Enemy%d.png", enemyType];
    self = [super initWithSpriteFrame:[CCSpriteFrame frameWithImageNamed:enemyTypeStr]];
    self.anchorPoint = ccp(0,0);
    self.x = xPos;
    self.y = yPos;
    self.type = enemyType;
    */
    
    return self;
}

@end
