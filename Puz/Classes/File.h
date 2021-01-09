//
//  File.h
//  32finaltemplate
//
//  Created by Ian on 5/10/14.


#import <Foundation/Foundation.h>

// Fixed number of stages per world
#define NUMBER_STAGES   120

@interface File : NSObject
{
    
}

- (void)createWorld:(int)worldNumber;
- (NSArray*)loadWorld:(int)worldNumber;
- (void)copyJSONtoFS:(NSString*)filename;
- (NSArray*)loadJSONfromFS:(NSString*)filename;
- (NSArray*)loadJSONfromDir:(NSString*)filename;
- (void)saveSettings:(int)sound :(int)music :(int)fbConnect :(int)notifications :(int)fbLikeBonus;
- (void)unlockNextStage:(int)currentStage :(int)worldNumber;
- (void)gainStarBest:(int)currentStage :(int)worldNumber :(int)newScore;
- (unsigned int)getCurrentBest:(int)currentStage :(int)worldNumber;
- (int)checkUpgraded;
- (int)checkFBLiked;
- (void)setUpgraded;
- (void)setfbliked;

@end
