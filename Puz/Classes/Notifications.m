//
//  Notifications.m
//  Puz
//
//  Created by Ian Callaghan on 8/18/15.
//

#import "AppDelegate.h"
#import "Notifications.h"

@implementation Notifications

// Notication for the game will be scheduled 24 hours after the user has closed the app
// if the user returns to the app then any scheduled notications will be cleared


- (id)init
{
    self = [super init];
    if(!self) {
        return NULL;
    }
    
    [self scheduleNotication];
    
    return self;
}

- (void)scheduleNotication
{
    // cancel any outstanding just to be safe
    [self cancelNotifications];
    UILocalNotification *localNotification = [[UILocalNotification alloc]init];
    localNotification.alertBody = @"It's time to beat another stage!\nCome back and play!";
    localNotification.timeZone = [NSTimeZone defaultTimeZone];

    // Two days later and every week after that if the user is not playing
    NSDate *spawnDateTwoDaysLater = [NSDate dateWithTimeInterval:((60 * 60) * 48) sinceDate:[NSDate date]];
    localNotification.fireDate = spawnDateTwoDaysLater;
    localNotification.repeatInterval = NSCalendarUnitWeekOfYear;

    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
   // [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification]; // spawns now just to test message
}


- (void)cancelNotifications
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

@end
