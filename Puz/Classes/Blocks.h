//  Puz
//  (c) Ian Callaghan
//  Created by Ian Callaghan on 4/16/15.

#import "CCNode_Private.h"
#import "CCSprite.h"

@interface Blocks : CCSprite
{
    
    int ID;
    int x;  // x,y is left / top
    int y;
    int HorV;
    int type;
    int width;
    int height;
    int tag;
    int isHighlighted;
    
}

@property (nonatomic,readwrite) int tag;
@property (nonatomic,readwrite) int ID;
@property (nonatomic,readwrite) int x;
@property (nonatomic,readwrite) int y;
@property (nonatomic,readwrite) int HorV;
@property (nonatomic,readwrite) int type;
@property (nonatomic,readwrite) int width;
@property (nonatomic,readwrite) int height;
@property (nonatomic,readwrite) int isHighlighted;



- (id)initWithType:(int)xPos :(int)yPos :(int)type;

@end
