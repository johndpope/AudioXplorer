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

#import <AppKit/AppKit.h>
#import "AudioViewAppearanceController.h"
#import "AudioDialogFFTParameters.h"
#import "AudioFullScreenWindow.h"

@class AudioView2D;
@class AudioView3D;
@class AudioRTDisplayer;

@interface AudioRTWindowController : NSWindowController
{
    AudioRTDisplayer *mAudioRTDisplayer;
    AudioDialogFFTParameters *mFFTParametersPanel;
            
    NSArray *mIntervalTitleArray;
    NSArray *mIntervalNumberArray;

    NSArray *mResolutionTitleArray;
    NSArray *mResolutionNumberArray;

	// Toolbar
	
    IBOutlet NSButton *mEnableButton;
    IBOutlet NSPopUpButton *mIntervalPopUp;
    IBOutlet NSPopUpButton *mResolutionPopUp;
    IBOutlet NSPopUpButton *mChannelPopUp;

    IBOutlet NSView *mEnableToolbarView;
    IBOutlet NSView *mPlaythruToolbarView;
    IBOutlet NSView *mIntervalToolbarView;
    IBOutlet NSView *mResolutionToolbarView;
    IBOutlet NSView *mChannelToolbarView;
    
    // Full screen
    
    AudioFullScreenWindow *mFullScreenWindow;
    NSView *mFullScreenContentViewForWindow;
    BOOL mWindowDisplayedInFullScreen;

    IBOutlet NSPanel *mFullScreenPanelForWindow;
    IBOutlet NSBox *mFullScreenBoxForWindow;
}

- (AudioRTDisplayer*)audioRTDisplayer;

- (IBAction)enableAction:(id)sender;
- (IBAction)playthruAction:(id)sender;
- (IBAction)intervalAction:(id)sender;
- (IBAction)resolutionAction:(id)sender;
- (IBAction)channelAction:(id)sender;

@end

@interface AudioRTWindowController (WindowMenu)
- (IBAction)closeFullScreenForWindow:(id)sender;
@end

@interface AudioRTWindowController (Toolbar)
- (void)setupToolbar;
@end