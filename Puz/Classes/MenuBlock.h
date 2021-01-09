//
//  MenuBlock.h
//  Puz
//
//  Created by Ian Callaghan on 8/18/15.

//

#import "CCSprite.h"

@interface MenuBlock : CCSprite
{
    NSUInteger type;
}


@property (readwrite,nonatomic) NSUInteger type;

@end
