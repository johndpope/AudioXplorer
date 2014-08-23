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
#import "AudioDataAmplitude.h"
#import "AudioPlayer.h"
#import "AudioProtocols.h"

@interface AudioDialogGenerator : NSWindowController {
    IBOutlet NSPopUpButton *mWaveTypePopUp;
    IBOutlet NSTextField *mAmplitudeTextField;
    IBOutlet NSTextField *mFrequencyTextField;
    IBOutlet NSTextField *mDurationTextField;
    IBOutlet NSTextField *mViewNameTextField;
    IBOutlet NSPopUpButton *mRatePopUp;
    IBOutlet NSPopUpButton *mChannelPopUp;
    IBOutlet NSButton *mPlaySoundButton;
    BOOL mIsASheet;
    id<AudioSTWindowControllerProtocol> mParentWindow;
    AudioDataAmplitude *mAmplitudeData;
    AudioPlayer *mPlayer;
}
- (void)openAsSheet:(id)sender defaultName:(NSString*)defaultName;
- (IBAction)popUpAction:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)generate:(id)sender;
@end
