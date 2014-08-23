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

#import "AudioDialogRecord.h"
#import "AudioDialogPrefs.h"
#import "AudioDataAmplitude.h"
#import "AudioOperator.h"
#import "AudioOpFFT.h"
#import "AudioApp.h"

@implementation AudioDialogRecord

- (id)init
{
    self = [super initWithWindowNibName:@"AudioRecord"];
    if(self)
    {
        mParentWindow = NULL;
        mAudioData = NULL;
        mIsRecording = NO;
        mIsPlaying = NO;

        // Recording
        
        mMaxRecordDuration = [[AudioDialogPrefs shared] maxRecordDuration];
        mRecordChannel = STEREO_CHANNEL;
        
        mAudioRecorder = [[AudioRecorder alloc] init];
        [mAudioRecorder setCompletionSelector:@selector(recordCompleted:) fromObject:self];
        [mAudioRecorder setRecordingSelector:@selector(recording:) fromObject:self];
        [mAudioRecorder setPlaythru:NO];

        // Playing
        
        mAudioPlayer = [[AudioPlayer alloc] init];
        [mAudioPlayer setCompletionSelector:@selector(playCompleted:) fromObject:self];
        [mAudioPlayer setPlayingSelector:@selector(playing:) fromObject:self];

        // Init window
        
        [self window];
    }
    return self;
}

- (void)dealloc
{
    [mAudioPlayer release];
    [mAudioRecorder release];
    
    [mAudioData release];
    
    [super dealloc];
}

- (void)sheetEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    AudioDataWrapper *wrapper = NULL;
    
    if(returnCode==INSERT_DATA || returnCode==ADD_DATA)
    {
        wrapper = [AudioDataWrapper initWithAudioData:mAudioData];
        [wrapper setViewName:[mViewNameTextField stringValue] always:YES];
        [wrapper setViewNameImmutable:YES];

        [mParentWindow addAudioDataWrapper:wrapper parentWrapper:NULL];
    }
    
    [mAudioData release];
    mAudioData = NULL;
    
    [mParentWindow audioDialogRecordHasFinished:wrapper];
}

- (void)performOpenOperationWithDefaultName:(NSString*)defaultName
{
    mMaxRecordDuration = [[AudioDialogPrefs shared] maxRecordDuration];

   /* if([[ARRegManager sharedRegManager] isRegistered] == NO && mMaxRecordDuration > 10)
    {
        NSRunAlertPanel(NSLocalizedString(@"Maximum record duration is limited to 10s", NULL), NSLocalizedString(@"Register AudioXplorer to remove this limitation.", NULL), NSLocalizedString(@"OK", NULL), NULL, NULL, NULL);  
        mMaxRecordDuration = 10;
    }*/

    [mProgressBar setDoubleValue:0];
    [mProgressTextField setFloatValue:mMaxRecordDuration];
    [mViewNameTextField setStringValue:defaultName];
    [mAddSoundButton setEnabled:mAudioData!=NULL];
    [mAudioRTInfo startMonitoring:self];
}

- (void)performCloseOperation
{
	[mAudioRTInfo stopMonitoring:self];
    
    [mAudioPlayer stop];
}

- (void)openAsPanel:(id)sender defaultName:(NSString*)defaultName
{
    mParentWindow = sender;
    mIsASheet = NO;
    [self performOpenOperationWithDefaultName:defaultName];
    [self sheetEnd:[self window] returnCode:[[NSApplication sharedApplication] runModalForWindow:[self window]] contextInfo:NULL];
}

- (void)openAsSheet:(id)sender defaultName:(NSString*)defaultName
{
    mParentWindow = sender;
    mIsASheet = YES;
    [self performOpenOperationWithDefaultName:defaultName];
    [NSApp beginSheet:[self window] modalForWindow:[sender window]
        modalDelegate:self didEndSelector:@selector(sheetEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)closeAndCancel:(id)sender
{
    [self performCloseOperation];
    
    [[self window] orderOut:self];
    if(mIsASheet)
        [NSApp endSheet:[self window] returnCode:CANCEL];
    else
        [[NSApplication sharedApplication] stopModalWithCode:CANCEL];
}

- (IBAction)closeAndInsert:(id)sender
{
    [self performCloseOperation];
    
    [[self window] orderOut:self];
    if(mIsASheet)
        [NSApp endSheet:[self window] returnCode:INSERT_DATA];
    else
        [[NSApplication sharedApplication] stopModalWithCode:ADD_DATA];
}

- (IBAction)recordChannelAction:(id)sender
{	
    switch([sender indexOfSelectedItem]) {
        case 0:
            mRecordChannel = LEFT_CHANNEL;
            break;
        case 1:
            mRecordChannel = RIGHT_CHANNEL;
            break;
        case 2:
            mRecordChannel = STEREO_CHANNEL;
            break;
    }
}

- (IBAction)recordAudioFromInput:(id)sender
{
    [self setRecordStatus:!mIsRecording];
}

- (IBAction)playAudioFromInternalBuffer:(id)sender
{
    [self setPlayStatus:!mIsPlaying];
}

- (void)playCompleted:(AudioDataAmplitude*)audioData
{
    mIsPlaying = NO;
    [mPlayButton setTitle:NSLocalizedString(@"Play", NULL)];
}

- (void)playing:(AudioDataAmplitude*)audioData
{
}

- (void)setPlayStatus:(BOOL)play
{    
    if(play)
    {
        mIsPlaying = YES;

        [mPlayButton setTitle:NSLocalizedString(@"Stop", NULL)];

        [mAudioPlayer playData:mAudioData];        
    } else
        [mAudioPlayer stopData:mAudioData];
}

- (void)recordCompleted:(AudioDataAmplitude*)audioData
{
    mIsRecording = NO;
    [mRecordButton setTitle:NSLocalizedString(@"Record", NULL)];
    [mRecordButton setKeyEquivalent:@""];

    [mProgressBar stopAnimation:self];
    [mAddSoundButton setEnabled:mAudioData!=NULL];
    [mChannelPopUp setEnabled:YES];
    
    [mAudioData optimizeSize];
}

- (void)recording:(AudioDataAmplitude*)audioData
{
    FLOAT curTime = [mAudioData currentPositionOfChannel:mRecordChannel==STEREO_CHANNEL?LEFT_CHANNEL:mRecordChannel];
    [mProgressBar setDoubleValue:curTime];
    [mProgressTextField setFloatValue:mMaxRecordDuration-curTime];
}

- (void)setRecordStatus:(BOOL)play
{    
    if(play)
    {
        mMaxRecordDuration = [[AudioDialogPrefs shared] maxRecordDuration];
        
        mIsRecording = YES;
        [mRecordButton setTitle:NSLocalizedString(@"Stop", NULL)];
        [mRecordButton setKeyEquivalent:@"\r"];
        
        [mChannelPopUp setEnabled:NO];
        
        [mProgressBar setMinValue:0];
        [mProgressBar setMaxValue:mMaxRecordDuration];
        [mProgressBar startAnimation:self];
        
        [mAudioData release];
        mAudioData = [[AudioDataAmplitude alloc] init];
        [mAudioData setDuration:mMaxRecordDuration rate:SOUND_DEFAULT_RATE channel:mRecordChannel];
        [mAudioData setGain:[mGainTextField floatValue]];
        
        [mAudioRecorder recordData:mAudioData channel:mRecordChannel];
    } else
    {
        [mAudioRecorder stopData:mAudioData];
    }
}

@end
