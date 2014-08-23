/*
 
 [The "BSD licence"]
 Copyright (c) 2003-2006 Arizona Software
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
														   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
														   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "AudioTipsPanel.h"
#import "AudioApp.h"
#import "AudioDialogPrefs.h"

@implementation AudioTipsPanel

+ (AudioTipsPanel*)shared
{
    static AudioTipsPanel *panel_ = NULL;
    if(panel_ == NULL)
    {
        panel_ = [[AudioTipsPanel alloc] init];
        [AudioApp addStaticObject:panel_];
    }
    return panel_;
}

+ (void)showPanel
{
    if([[AudioDialogPrefs shared] displayTipDialog])
    {
        [[AudioTipsPanel shared] displayNextTip];
        [NSApp runModalForWindow:[[AudioTipsPanel shared] window]];
    }
}

- (id)init
{
    self = [super initWithWindowNibName:@"AudioTips"];
    if(self)
    {
        [self window];
        [self initTips];
    }
    return self;
}

- (void)dealloc
{
    [mTipArray release];
    [mTipDisplayedArray release];
    [super dealloc];
}

- (void)initTips
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource:@"Tips" ofType:@"xml" inDirectory:@""];
    mTipArray = [[NSArray arrayWithContentsOfFile:path] retain];
    mTipDisplayedArray = [[NSMutableArray arrayWithCapacity:[mTipArray count]] retain];
    mLastTip = -1;
}

- (BOOL)alreadyDisplayedTip:(short)tip
{
    return [mTipDisplayedArray indexOfObject:[NSNumber numberWithShort:tip]] != NSNotFound;
}

- (short)randomTip
{
    double x = (double)rand()/RAND_MAX;
    return x*[mTipArray count];
}

- (void)displayNextTip
{
    if(mLastTip == -1)
        [mTipDisplayedArray addObjectsFromArray:[[AudioDialogPrefs shared] displayedTips]];
        
    short tip = [self randomTip];
        
    while([self alreadyDisplayedTip:tip] && [mTipDisplayedArray count]<[mTipArray count])
        tip = [self randomTip];

    if([self alreadyDisplayedTip:tip])
    {
        [mTipDisplayedArray removeAllObjects];
        switch(mLastTip) {
            case -1:
                tip = 0;
                break;
            case 0:
                tip = 1;
                break;
            default:
                tip = mLastTip-1;
                break;
        }
    }

    mLastTip = tip;

    [mTipDisplayedArray addObject:[NSNumber numberWithShort:tip]];
    [[AudioDialogPrefs shared] setDisplayedTips:mTipDisplayedArray];
    [mTipsTextField setStringValue:[mTipArray objectAtIndex:tip]];
}

- (IBAction)dontShowAgainAction:(id)sender
{
    [[AudioDialogPrefs shared] setDisplayTipDialog:[sender state] == NSOffState];
}

- (IBAction)nextTipsAction:(id)sender
{
    [self displayNextTip];
}

- (IBAction)closePanelAction:(id)sender
{
    [[self window] orderOut:self];
    [[NSApplication sharedApplication] stopModalWithCode:0];   
}

@end
