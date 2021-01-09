//
//  AppDelegate.m
//  Puz
//
//  Created by Ian Callaghan on 6/25/15.

#import "AppDelegate.h"
#import "Flurry.h"
#import "File.h"
#import "Start.h"
#import "Notifications.h"
#import "GameGlobals.h"

@implementation AppDelegate

@synthesize currentPlayerID, gameCenterAuthenticationComplete;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [self setupCocos2dWithOptions:@{
                                    //       CCSetupShowDebugStats: @(YES),
                                    //     CCSetupTabletScale2X: @(YES),
                                    CCSetupScreenOrientation: CCScreenOrientationPortrait,
                                    }];
    
    
    
    // ipad 2, content scale is 1.0
    // ipad air, content scale is 2.0
    
    
    //  NSLog(@"content scale %f", [UIScreen mainScreen].scale);
    // iPhone 6 Plus support, seems to work well
    /*
     if([UIScreen mainScreen].scale > 2.1) {
     NSLog(@"iphone 6 plus selected");
     CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
     [sharedFileUtils setiPhoneContentScaleFactor:3];
     }
     */
    
    
    if(IS_IPAD) {
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
            
            // iPad 2 is none retina so force -HD graphics, will need some tweeking
            if([[UIScreen mainScreen] scale] == 1.0) {
                //    NSLog(@"none retina ipad");
                CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
                [sharedFileUtils setiPadSuffix:@"-hd"];
            }
        }
        
    }
    
    
    
    
    
    [[GameCenterManager sharedManager] setupManagerAndSetShouldCryptWithKey:@"KEYREMOVED"];
    
    // Unity Ads setup
    //   [[UnityAds sharedInstance] setTestMode:YES];
    //   [[UnityAds sharedInstance] setDebugMode:YES];
    
    
    [[UnityAds sharedInstance] startWithGameId:@"KEYREMOVED"];
    
    
    // Init with key, for saving cached results encrypted
    
    
    [Flurry startSession:@"KEYREMOVED"];
    
    
    // required for iOS 8.x or higher
    [self registerNotifications];
    
    Notifications *notifications = [[Notifications alloc]init];
    [notifications cancelNotifications];
    
    // Set page to 1
    [GameGlobals globals].pageNumber = 1;
    [[GameGlobals globals] savePageNumber];
    
    return YES;
}

- (void)registerNotifications
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    
    //   NSLog(@"using iOS 8 or higher");
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    
#else
    
    //  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
    //   (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
#endif
}

- (CCScene *)startScene
{
    File *file = [[File alloc]init];
    [file createWorld:1];
    
    [file copyJSONtoFS:@"Settings.json"];
    [file copyJSONtoFS:@"0.dat"];
    return [Start node];
}

- (void)configureStore
{
    
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    
}


- (void)applicationDidEnterBackground:(UIApplication*)application
{
    [[CCDirector sharedDirector] stopAnimation];
    [[CCDirector sharedDirector] pause];
    
    //  NSLog(@"schedule notifications");
    
    Notifications *notifications = [[Notifications alloc]init];
    [notifications scheduleNotication];
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[CCDirector sharedDirector] stopAnimation];
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] startAnimation];
    
    //    NSLog(@"schedule notifications cancelled");
    
    Notifications *notifications = [[Notifications alloc]init];
    [notifications cancelNotifications];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    [[CCDirector sharedDirector] stopAnimation];
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] startAnimation];
    
    //   NSLog(@"schedule notifications cancelled");
    
    Notifications *notifications = [[Notifications alloc]init];
    [notifications cancelNotifications];
}


@end























