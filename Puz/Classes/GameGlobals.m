//
//  GameGlobals.m


#import "GameGlobals.h"

static __strong GameGlobals* _globals;

@implementation GameGlobals

+ (GameGlobals*) globals
{
    if (!_globals)
    {
        _globals = [[GameGlobals alloc] init];
    }
    
    return _globals;
}

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    [self load];
    [self loadPageNumber];
    
    return self;
}

- (void)load
{
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    _loadingLevel = [[d objectForKey:@"loadingLevel"] intValue];
}

- (void)save
{
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    [d setObject:[NSNumber numberWithInt:_loadingLevel] forKey:@"loadingLevel"];
}

- (void)loadPageNumber
{
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    _loadingLevel = [[d objectForKey:@"pageNumber"] intValue];
}

- (void)savePageNumber
{
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    [d setObject:[NSNumber numberWithInt:_pageNumber] forKey:@"pageNumber"];
}



@end
