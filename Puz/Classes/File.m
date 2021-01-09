//
//  File.m
//  32finaltemplate
//
//  Created by Ian on 5/10/14.


#include <stdio.h>
#import "AppDelegate.h"
#import "File.h"
#import "GameGlobals.h"


@implementation File

// Helper functions

- (unsigned short)readBE16:(const unsigned char *)p
{
    return (p[0] << 8) | p[1];
}

- (void)writeBE16:(unsigned char *)p :(unsigned short)x
{
    p[0] = x >> 8;
    p[1] = x;
}

- (void)worldArrayToBinSave:(NSMutableArray*)worldData :(int)worldNumber
{
    unsigned char worldArray[4 * NUMBER_STAGES];
    
    unsigned char star;
    unsigned char locked;
    unsigned short best;
    
    int j = 0;
    
    for(NSDictionary *dict in worldData) {
        
        star = [[dict objectForKey:@"Star"]intValue];
        locked = [[dict objectForKey:@"Locked"]intValue];
        best = [[dict objectForKey:@"Best"]intValue];
        
        worldArray[j + 0] = star;
        worldArray[j + 1] = locked;
        [self writeBE16:worldArray+j+2 :best];
        
        j += 4;
    }
    
    
  //  NSLog(@"writing %d",worldNumber);
    // Save
    NSData *worldDat = [NSData dataWithBytes:worldArray length:sizeof(worldArray)];
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path objectAtIndex:0];
    
    NSString *worldString = [NSString stringWithFormat:@"dat%d.bin",worldNumber];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:worldString];
    
    [worldDat writeToFile:appFile atomically:YES];
}

- (void)createWorld:(int)worldNumber
{
    int i;
    int j = 0;
    
    unsigned char star = 0;
    unsigned char locked = 1;
    unsigned short best = 999;
    
    unsigned char worldArray[4 * NUMBER_STAGES];
    
    for(i=0;i<NUMBER_STAGES;i++) {
        
        if(i == 0) {
            locked = 0;
        }
        else if(i > 0) {
            locked = 1;
        }
        
        worldArray[j + 0] = star;
        worldArray[j + 1] = locked;
        [self writeBE16:worldArray+j+2 :best];
        
        j += 4;
    }
    
    NSData *worldData = [NSData dataWithBytes:worldArray length:sizeof(worldArray)];
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path objectAtIndex:0];
    
    NSString *worldString = [NSString stringWithFormat:@"dat%d.bin",worldNumber];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:worldString];

    // Check to see if the JSON exists, if not create the file and save to the file system
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager fileExistsAtPath:appFile];
    
    if(!success) {
        [worldData writeToFile:appFile atomically:YES];
    }
}

- (void)unlockNextStage:(int)currentStage :(int)worldNumber
{
  //  NSLog(@"current stage %d worldNumber %d",currentStage,worldNumber);
    
    int nextStage = currentStage + 1;
    
    unsigned char star;
    unsigned char locked;
    unsigned short best;
    
    // current array
    NSMutableArray *worldArray = [[NSMutableArray alloc]initWithArray:[self loadWorld:worldNumber]];
    
    // Get the unlocked entry
    NSDictionary *currentEntry = [worldArray objectAtIndex:nextStage-1];
    
    star = [[currentEntry objectForKey:@"Star"]intValue];
    locked  = [[currentEntry objectForKey:@"Locked"]intValue];
    best = [[currentEntry objectForKey:@"Best"]intValue];
    
    // create a new entry with existing info but change the locked to 0
    
    NSDictionary *newEntry = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:star], @"Star",
                           [NSNumber numberWithInt:0], @"Locked",
                           [NSNumber numberWithInt:best], @"Best",
                           nil];
    
    [worldArray replaceObjectAtIndex:nextStage-1 withObject:newEntry];
    
  //  NSLog(@"wa %@",worldArray);
    
    [self worldArrayToBinSave:worldArray :worldNumber];

}

//---------------------------------------------------------------------------------------------------------------------
// Return the last 2 bytes which are

// 0 - upgrade byte - 0 is not upgraded, 1 is upgraded
// 1 - fb liked byte - 0 not click button, 1 has been clicked / liked

- (int)checkUpgraded
{
    int upgraded;
    int dataLen;
    
    unsigned char upgradeByte;
    unsigned char bytes[39];
    
    // Load the random blob
    NSString *worldName = [NSString stringWithFormat:@"0.dat"];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *path = [documentsDir stringByAppendingPathComponent:worldName];
    
    NSData *worldData = [NSData dataWithContentsOfFile:path];
    
    dataLen = (int)[worldData length];
    memcpy(bytes, [worldData bytes], dataLen);

    upgradeByte = bytes[dataLen-2];

   // NSLog(@"upgrade byte %x",upgradeByte);
    
    if(upgradeByte == 0) {
        upgraded = 0;
    }
    else if(upgradeByte == 1) {
        upgraded = 1;
    }
  
    return upgraded;
}

- (int)checkFBLiked
{
    int fbLiked;
    int dataLen;
    
    unsigned char fbLikeByte;
    
    unsigned char bytes[39];
    
    // Load the random blob
    NSString *worldName = [NSString stringWithFormat:@"0.dat"];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *path = [documentsDir stringByAppendingPathComponent:worldName];
    
    NSData *worldData = [NSData dataWithContentsOfFile:path];
    
    dataLen = (int)[worldData length];
    memcpy(bytes, [worldData bytes], dataLen);

    fbLikeByte = bytes[dataLen-1];
    
 //   NSLog(@"fblike byte %x",fbLikeByte);
    
    if(fbLikeByte == 0) {
        fbLiked = 0;
    }
    else if(fbLikeByte == 1) {
        fbLiked = 1;
    }
    
    return fbLiked;
}


- (void)setUpgraded
{
    int dataLen;
    unsigned char bytes[39];
    
    // read in
    NSString *worldName = [NSString stringWithFormat:@"0.dat"];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *path = [documentsDir stringByAppendingPathComponent:worldName];
    
    NSData *worldData = [NSData dataWithContentsOfFile:path];
    
    dataLen = (int)[worldData length];
    memcpy(bytes, [worldData bytes], dataLen);
    
    // set
    bytes[dataLen-2] = 1;
    
    // write
    NSData *worldDat = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    NSArray *path1 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path1 objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"0.dat"];
    [worldDat writeToFile:appFile atomically:YES];

}

- (void)setfbliked
{
    int dataLen;
    unsigned char bytes[39];
    
    // read in
    NSString *worldName = [NSString stringWithFormat:@"0.dat"];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *path = [documentsDir stringByAppendingPathComponent:worldName];
    
    NSData *worldData = [NSData dataWithContentsOfFile:path];
    
    dataLen = (int)[worldData length];
    memcpy(bytes, [worldData bytes], dataLen);
    
    // set
    bytes[dataLen-1] = 1;
    
    // write
    NSData *worldDat = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    NSArray *path1 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path1 objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"0.dat"];
    [worldDat writeToFile:appFile atomically:YES];
}

- (void)gainStarBest:(int)currentStage :(int)worldNumber :(int)newScore
{
 //   NSLog(@"current stage %d worldNumber %d",currentStage,worldNumber);
    
    unsigned char star;
    unsigned char locked;
    unsigned short best;
    
    // current array
    NSMutableArray *worldArray = [[NSMutableArray alloc]initWithArray:[self loadWorld:worldNumber]];
    
    // Get the unlocked entry
    NSDictionary *currentEntry = [worldArray objectAtIndex:currentStage-1];
    
    star = [[currentEntry objectForKey:@"Star"]intValue];
    locked  = [[currentEntry objectForKey:@"Locked"]intValue];
    best = [[currentEntry objectForKey:@"Best"]intValue];
    
    if(newScore < best) {
        best = newScore;
    }
    
    // create a new entry with existing info but change the locked to 0
    
    NSDictionary *newEntry = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:1], @"Star",
                              [NSNumber numberWithInt:locked], @"Locked",
                              [NSNumber numberWithInt:best], @"Best",
                              nil];
    
    [worldArray replaceObjectAtIndex:currentStage-1 withObject:newEntry];
    
    //  NSLog(@"wa %@",worldArray);
    
    [self worldArrayToBinSave:worldArray :worldNumber];

}

- (unsigned int)getCurrentBest:(int)currentStage :(int)worldNumber
{
    int best;
    
    NSMutableArray *worldArray = [[NSMutableArray alloc]initWithArray:[self loadWorld:worldNumber]];
    
    // Get the unlocked entry
    NSDictionary *currentEntry = [worldArray objectAtIndex:currentStage-1];
    
    best = [[currentEntry objectForKey:@"Best"]intValue];

    return best;
}

- (NSArray*)loadWorld:(int)worldNumber
{
    int i;
    int j = 0;
    int dataLen;
    unsigned char map[4 * NUMBER_STAGES];
    unsigned char star;
    unsigned char locked;
    unsigned short best;
    
    NSMutableArray *entries = [[NSMutableArray alloc]init];
    
    NSString *worldName = [NSString stringWithFormat:@"dat%d.bin",worldNumber];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *path = [documentsDir stringByAppendingPathComponent:worldName];

    NSData *worldData = [NSData dataWithContentsOfFile:path];
    
    dataLen = (int)[worldData length];
    
    //NSLog(@"dataLen %d bytes",dataLen);
    
    // Data to 1D array
    memcpy(map, [worldData bytes], dataLen);
    
    // Parse the map
    for(i=0;i<NUMBER_STAGES;i++) {
     
        star = map[0 + j];
        locked = map[1 + j];
        best = [self readBE16:map + 2 + j];
        
        //NSLog(@"star %d, locked %d, best %d",star, locked, best);
        
        NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithInt:star], @"Star",
                 [NSNumber numberWithInt:locked], @"Locked",
                 [NSNumber numberWithInt:best], @"Best",
                 nil];
        
        [entries addObject:entry];
        
        j += 4;
    }
    
    
    
   // NSLog(@"entries %@",entries);
    
    return entries;
}

- (void)copyJSONtoFS:(NSString*)filename
{
    BOOL *success;

    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *path = [documentsDir stringByAppendingPathComponent:filename];
    
  //  NSLog(@"path: %@",path);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    success = [fileManager fileExistsAtPath:path];
    
    // If the database already exists then return without doing anything
    if(success) {
       // NSLog(@"file %@ already exists on the fs",filename);
        return;
    }
    
    // If not then proceed to copy the database from the application to the users filesystem
    NSString *databasePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    [fileManager copyItemAtPath:databasePathFromApp toPath:path error:nil];
}


- (NSArray*)loadJSONfromFS:(NSString*)filename
{
    NSError *error;
    
    // NSString *fileName = @"settings.json";
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *path = [documentsDir stringByAppendingPathComponent:filename];
    
    
    // JSON Encoding
    NSString *jsonS = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    NSString *jsonString = jsonS;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:jsonData
                          
                          options:kNilOptions
                          error:&error];
    
    NSArray* entries = [json objectForKey:@"entry"];
    
    return entries;
}


- (NSArray*)loadJSONfromDir:(NSString*)filename
{
    // NSString *fileName = @"master.json";
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:filename ofType:nil];
    
    NSString *jsonS = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    NSString *jsonString = jsonS;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:jsonData
                          
                          options:kNilOptions
                          error:&error];
    
    // Parse the entry
    NSArray* entries = [json objectForKey:@"entry"];
    
    return entries;
}

- (void)saveSettings:(int)sound :(int)music :(int)fbConnect :(int)notifications :(int)fbLikeBonus
{
    NSDictionary *statdict;
    NSMutableArray *dictArray = [[NSMutableArray alloc]init];
    
    // Build the object
    statdict = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:sound], @"Sound",
                [NSNumber numberWithInt:music], @"Music",
                [NSNumber numberWithInt:fbConnect], @"FBConnect",
                [NSNumber numberWithInt:notifications], @"Notifications",
                [NSNumber numberWithInt:fbLikeBonus], @"Rated",
                nil];
    
    [dictArray addObject:statdict];
    
    NSError *err;
    
    NSDictionary *requestDictionary = @{@"entry": dictArray};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestDictionary options:NSJSONWritingPrettyPrinted error:&err];
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"Settings.json"];
    [jsonStr writeToFile:appFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
}



@end
