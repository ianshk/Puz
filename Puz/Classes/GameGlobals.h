//
//  GameGlobals.h
//

#import <Foundation/Foundation.h>

@interface GameGlobals : NSObject

@property (nonatomic,assign) int loadingLevel;
@property (nonatomic,assign) int pageNumber;

+ (GameGlobals*) globals;

- (void)save;
- (void)savePageNumber;

@end
