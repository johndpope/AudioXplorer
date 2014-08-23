//
//  ARCheckForUpdates.h
//  ArizonaUpdateManager
//
//  Created by Simon Bovet on Mon Sep 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

#define ARUpdateManagerDidFinishCheckingNotification @"ARUpdateManagerDidFinishCheckingNotification"
#define ARUpdateManagerDidFinishDownloadingNotification @"ARUpdateManagerDidFinishDownloadingNotification"

enum {
    ARUpdateManagerAtStartupIntervall = 0,
    ARUpdateManagerDailyIntervall,
    ARUpdateManagerWeeklyIntervall,
    ARUpdateManagerMonthlyIntervall
};

@class ARUpdateInfo, ARUpdate;

@interface ARUpdateManager : NSWindowController {
    ARUpdateInfo *mInfo;
    NSMutableDictionary *mStatus;
    NSTimer *mTimer;
    NSArray *mUpdates;
    
    IBOutlet NSView *mCheckView;
    IBOutlet NSTableView *mUpdateTableView;
    IBOutlet NSTextView *mDescriptionTextView;
    IBOutlet id mTotalSize;
    IBOutlet id mDownloadButton;
    
    IBOutlet NSWindow *mProgressWindow;
    IBOutlet id mProgressTitle;
    IBOutlet id mProgressCancelButton;
    IBOutlet id mProgressIndicator;
    IBOutlet id mProgressSize;
    
    NSURLHandle *mDownloadURLHandle;
    NSMutableArray *mUpdatesToDownload;
    NSMutableArray *mFilesToOpen;
    unsigned long mDownloadedSize;
    ARUpdate *mUpdate;
    
    BOOL mInProgress;
    BOOL mDisplay;
    
    IBOutlet id mAutoCheck;
    IBOutlet id mAutoCheckFrequency;
    IBOutlet id mNextCheckDate;
    IBOutlet id mLastCheckStatus;
    IBOutlet id mLastCheckDate;
    
    BOOL mFailed;
}

+(id)sharedManager;
+(id)manager;

-(void)setServerName:(NSString *)inServerName; // e.g. www.curvuspro.ch
-(void)setServerPath:(NSString *)inServerPath; // e.g. /updates/
-(void)setLocalPath:(NSString *)inLocalPath; // e.g. /Library/Application Support/Curvus Pro X/Updates/
	// or [[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist" inDirectory:@"Updates"] stringByDeletingLastPathComponent]
-(void)setName:(NSString *)inName; // e.g. osx
-(void)setUpdateBlacklist:(BOOL)inUpdateBlacklist;

-(void)insertPreferencesIntoView:(NSView *)inView; // e.g. -[NSBox contentView]
-(void)setAutoCheck:(BOOL)inAutoCheck;
-(void)setAutoCheckFrequency:(int)inFrequency;

-(void)terminate;

@end

@interface ARUpdateManager (Check)

-(IBAction)checkForUpdates:(id)inSender;
-(IBAction)checkWithNoDisplay:(id)inSender;
-(void)checkOnceWithNoDisplayUntil:(NSDate *)inDate;

@end

@interface ARUpdateManager (Preferences)

-(IBAction)update:(id)inSender;

@end

@interface ARUpdateManager (Install)

-(IBAction)download:(id)inSender;
-(IBAction)cancel:(id)inSender;

@end

@interface ARUpdateManager (Progress)

-(IBAction)cancelProgress:(id)inSender;

@end