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

#import "AudioPlayer.h"
#import "AudioDialogPrefs.h"

#define NO_POSITION -1

@implementation AudioPlayer

OSStatus playIOProc (AudioDeviceID  inDevice,
                        const AudioTimeStamp*  inNow,
                        const AudioBufferList*   inInputData, 
                        const AudioTimeStamp*  inInputTime,
                        AudioBufferList*  outOutputData,
                        const AudioTimeStamp* inOutputTime, 
                        void* userData)
{
    AudioPlayer *audioPlayer = userData;
    AudioDataAmplitude *audioData = audioPlayer->mCurrentAudioData;

   if(outOutputData)
    {
        if(audioPlayer->mCurrentPosition>=audioPlayer->mEndPosition
            && audioPlayer->mEndPosition!=NO_POSITION)
        {
            [audioData setStatusFlag:NONE];
        } else
        {
            ULONG size = outOutputData->mBuffers[0].mDataByteSize;
            
            if(audioPlayer->mSoundBuffer != NULL && audioPlayer->mSoundBufferSize != size)
            {
                free(audioPlayer->mSoundBuffer);
                audioPlayer->mSoundBuffer = NULL;
            }
            
            if(audioPlayer->mSoundBuffer == NULL)
            {
                audioPlayer->mSoundBuffer = malloc(size);
                audioPlayer->mSoundBufferSize = size;
            }

            BOOL ok = [audioData readStereoRawDataInBuffer:audioPlayer->mSoundBuffer
                                    from:&audioPlayer->mCurrentPosition size:size];
            if(ok)
                memcpy(outOutputData->mBuffers[0].mData, audioPlayer->mSoundBuffer, size);
            else
                [audioData setStatusFlag:NONE];
        }
    }
        
    return noErr;
}

- (id)init
{
    if(self=[super init])
    {
        mIOProcTimer = NULL;
        mCurrentAudioData = NULL;
        mCompletionObject = NULL;
        mCompletionSelector = NULL;
        mPlayingObject = NULL;
        mPlayingSelector = NULL;
        mSoundBuffer = NULL;
        mSoundBufferSize = 0;
        mCurrentPosition = NO_POSITION;
        mEndPosition = NO_POSITION;
        mOutputDeviceID = -1;
        mClientTicket = NULL;
    }
    return self;
}

- (void)dealloc
{
	[[AudioDeviceManager shared] removeClient:mClientTicket];
	
    if(mCurrentAudioData)
    {
        if([mCurrentAudioData statusFlag] == PLAYING)
            [self stopData:mCurrentAudioData];
    }
    [mCurrentAudioData release];
    [super dealloc];
}

- (void)ioProcWatchTimer:(NSTimer*)timer
{
    [mPlayingObject performSelector:mPlayingSelector withObject:mCurrentAudioData];
    if([mCurrentAudioData statusFlag] == NONE)
        [self stopData:mCurrentAudioData];
}

- (void)setCompletionSelector:(SEL)completionSelector fromObject:(id)completionObject
{
    mCompletionSelector = completionSelector;
    mCompletionObject = completionObject;
}

- (void)setPlayingSelector:(SEL)playingSelector fromObject:(id)playingObject
{
    mPlayingSelector = playingSelector;
    mPlayingObject = playingObject;
}

- (void)clientNotification:(CAClientObject*)client
{
    // Device has changed (can be dead)
    if([client isRunning] == NO)
        [mCurrentAudioData setStatusFlag:NONE];
}

- (BOOL)_playData
{
    mOutputDeviceID = [[AudioDeviceManager shared] currentOutputDeviceID];
    
    mClientTicket = [[AudioDeviceManager shared] registerClient:self
                                            deviceID:mOutputDeviceID
                                            ioProc:playIOProc
                                            userData:self
                                            notifySelector:@selector(clientNotification:)];

    if([[AudioDeviceManager shared] addAndStartIOProc:mClientTicket])
    {
        if(mSoundBuffer)
        {
            free(mSoundBuffer);
            mSoundBuffer = NULL;
            mSoundBufferSize = 0;
        }
        
        [mCurrentAudioData setStatusFlag:PLAYING];
        
        mIOProcTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 
                            target:self 
                            selector:@selector(ioProcWatchTimer:) 
                            userInfo:self 
                            repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:mIOProcTimer forMode:NSEventTrackingRunLoopMode];
        return YES;
    } else
        return NO;
}

- (BOOL)playData:(AudioDataAmplitude*)audioData from:(FLOAT)from
{
    [mCurrentAudioData autorelease];
    mCurrentAudioData = [audioData retain];
    mCurrentPosition = from;
    mEndPosition = NO_POSITION;
    return [self _playData];
}

- (BOOL)playData:(AudioDataAmplitude*)audioData from:(FLOAT)from to:(FLOAT)to
{
    [mCurrentAudioData autorelease];
    mCurrentAudioData = [audioData retain];
    mCurrentPosition = from;
    mEndPosition = to;
    mOutputDeviceID = [[AudioDeviceManager shared] currentOutputDeviceID];
    return [self _playData];
}

- (BOOL)playData:(AudioDataAmplitude*)audioData
{    
    [mCurrentAudioData autorelease];
    mCurrentAudioData = [audioData retain];
    mCurrentPosition = [audioData minXOfChannel:LEFT_CHANNEL];
    mEndPosition = NO_POSITION;
    return [self _playData];
}

- (BOOL)stopData:(AudioDataAmplitude*)audioData
{        
    [audioData setStatusFlag:NONE];
    
    if([[AudioDeviceManager shared] stopAndRemoveIOProc:mClientTicket])
    {
        if(mIOProcTimer)
        {
            [mIOProcTimer invalidate];
            mIOProcTimer = NULL;
        }
        [mCompletionObject performSelector:mCompletionSelector withObject:audioData];
        [mCurrentAudioData release];
        mCurrentAudioData = NULL;
        return YES;
    } else
        return NO;
}

- (BOOL)stop
{
    return [self stopData:mCurrentAudioData];
}

- (BOOL)isPlaying
{
    if(mCurrentAudioData)
        return [mCurrentAudioData statusFlag] == PLAYING;
    else
        return NO;
}

- (FLOAT)currentPosition
{
    return mCurrentPosition;
}

@end
