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

#import "AudioDialogGenerator.h"
#import "AudioDataWrapper.h"
#import "AudioApp.h"

#define TYPE_SINUS 0
#define TYPE_COSINUS 1
#define TYPE_RECTANGULAR 2
#define TYPE_TRIANGULAR 3
#define TYPE_SAWTOOTH 4

@implementation AudioDialogGenerator

- (id)init
{
    if(self = [super initWithWindowNibName:@"AudioGenerator"])
    {
        mParentWindow = NULL;
        mAmplitudeData = NULL;
        mPlayer = [[AudioPlayer alloc] init];
        [mPlayer setCompletionSelector:@selector(playCompleted:) fromObject:self];
        [self window];
    }
    return self;
}

- (void)dealloc
{
    [mPlayer release];
    [mAmplitudeData release];
    [super dealloc];
}

- (AudioDataAmplitude*)generateAmplitude
{
    AudioDataAmplitude *theAudioData = [[AudioDataAmplitude alloc] init];
    ULONG index;
    ULONG rate = SOUND_DEFAULT_RATE;
    
    SHORT type = [mWaveTypePopUp indexOfSelectedItem];
    FLOAT amplitude = [mAmplitudeTextField floatValue];
    FLOAT frequency = [mFrequencyTextField floatValue];
    FLOAT duration = [mDurationTextField floatValue];
    SHORT channel = [mChannelPopUp indexOfSelectedItem];
    
    FLOAT tau = (FLOAT)rate/frequency;
    ULONG idx = 0;
        
    [theAudioData setDuration:duration rate:rate channel:channel];
        
    for(index=0; index<[theAudioData maxIndex]; index++)
    {
        idx++;
        FLOAT t = ((FLOAT)index/rate);
        FLOAT value = 0;
        switch(type) {
            case TYPE_SINUS:
                value = amplitude*sin(t*frequency*2*pi);
                break;
            case TYPE_COSINUS:
                value = amplitude*cos(t*frequency*2*pi);
                break;
            case TYPE_RECTANGULAR:
                if(idx<tau*0.5)
                    value = amplitude;
                else if(idx>=tau*0.5 && idx<tau)
                    value = -amplitude;
                else
                {
                    idx = 0;
                    value = -amplitude;
                }
                break;
            case TYPE_TRIANGULAR:
                if(idx<tau*0.25)
                    value = amplitude*(FLOAT)idx/(tau*0.25);
                else if(idx>=tau*0.25 && idx<tau*0.5)
                    value = amplitude*(1-(FLOAT)(idx-tau*0.25)/(tau*0.25));
                else if(idx>=tau*0.5 && idx<tau*0.75)
                    value = -amplitude*(FLOAT)(idx-tau*0.5)/(tau*0.25);
                else if(idx>=tau*0.75 && idx<tau)
                    value = -amplitude*(1-(FLOAT)(idx-tau*0.75)/(tau*0.25));
                else
                {
                    idx = 0;
                    value = 0;
                }
                break;
            case TYPE_SAWTOOTH:
                if(idx<tau*0.5)
                    value = amplitude*(FLOAT)idx/(tau*0.5);
                else if(idx>=tau*0.5 && idx<tau)
                    value = -amplitude+amplitude*(FLOAT)(idx-tau*0.5)/(tau*0.5);
                else
                {
                    idx = 0;
                    value = 0;
                }
                break;
        }
        if(channel == LEFT_CHANNEL || channel == STEREO_CHANNEL)
            [theAudioData addDataValue:value inChannel:LEFT_CHANNEL];
        if(channel == RIGHT_CHANNEL || channel == STEREO_CHANNEL)
        [theAudioData addDataValue:value inChannel:RIGHT_CHANNEL];
    }

    return [theAudioData autorelease];
}

- (AudioDataWrapper*)generateWrapper
{
    AudioDataWrapper *wrapper = [AudioDataWrapper initWithAudioData:[self generateAmplitude]];
    [wrapper setViewName:[mViewNameTextField stringValue] always:YES];
    [wrapper setViewNameImmutable:YES];
    return wrapper;
}

- (void)sheetEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    AudioDataWrapper *wrapper = NULL;
    if(returnCode==INSERT_DATA || returnCode==ADD_DATA)
    {
        wrapper = [self generateWrapper];
        [mParentWindow addAudioDataWrapper:wrapper parentWrapper:NULL];
    }
    
    [mParentWindow audioDialogGenerateHasFinished:wrapper];
}

- (void)openAsSheet:(id)sender defaultName:(NSString*)defaultName
{
    mParentWindow = sender;
    mIsASheet = YES;
    [mViewNameTextField setStringValue:defaultName];
    [NSApp beginSheet:[self window] modalForWindow:[sender window]
        modalDelegate:self didEndSelector:@selector(sheetEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)playCompleted:(AudioDataAmplitude*)data
{
    [mPlaySoundButton setTitle:NSLocalizedString(@"Play", NULL)];
}

- (IBAction)popUpAction:(id)sender
{
}

- (IBAction)play:(id)sender
{
    if([mPlayer isPlaying])
    {
        [mPlaySoundButton setTitle:NSLocalizedString(@"Play", NULL)];
        [mPlayer stop];
    } else
    {
        [mPlaySoundButton setTitle:NSLocalizedString(@"Stop", NULL)];
        [mAmplitudeData release];
        mAmplitudeData = [[self generateAmplitude] retain];
        [mPlayer playData:mAmplitudeData];
    }
}

- (IBAction)cancel:(id)sender
{
    [mPlayer stop];
    [[self window] orderOut:self];
    if(mIsASheet)
        [NSApp endSheet:[self window] returnCode:CANCEL];
    else
        [[NSApplication sharedApplication] stopModalWithCode:CANCEL];
}

- (IBAction)generate:(id)sender
{
    [mPlayer stop];
    [[self window] orderOut:self];
    if(mIsASheet)
        [NSApp endSheet:[self window] returnCode:INSERT_DATA];
    else
        [[NSApplication sharedApplication] stopModalWithCode:ADD_DATA];
}

@end
