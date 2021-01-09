//
//  AppDelegate.h
//  Puz
//
//  Created by Ian Callaghan on 6/25/15.

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

// Unity Ads
#import <UnityAds/UnityAds.h>

#import "cocos2d.h"
#import "RMStore.h"
#import "GameCenterManager.h"
#define IS_RETINA ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0))
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


@interface AppDelegate : CCAppDelegate
{
    
}

@property (retain,readwrite) NSString * currentPlayerID;

// isGameCenterAuthenticationComplete is set after authentication, and authenticateWithCompletionHandler's completionHandler block has been run. It is unset when the application is backgrounded.
@property (readwrite, getter=isGameCenterAuthenticationComplete) BOOL gameCenterAuthenticationComplete;

@end
