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

#import "AudioRecorder.h"
#import "AudioDialogPrefs.h"

@implementation AudioRecorder

static NSMutableArray *_audioRecorderArray = NULL;

+ (void)addAudioRecorderObject:(AudioRecorder*)obj
{
    if(!_audioRecorderArray)
        _audioRecorderArray = [[NSMutableArray alloc] initWithCapacity:1];
    
    [_audioRecorderArray addObject:obj];
}

+ (void)removeAudioRecorderObject:(AudioRecorder*)obj
{
    [_audioRecorderArray removeObject:obj];
    
    if([_audioRecorderArray count]==0)
    {
        [_audioRecorderArray release];
        _audioRecorderArray = NULL;
    }
}

static OSStatus inputIOProc (AudioDeviceID  inDevice,
                            const AudioTimeStamp*  inNow,
                            const AudioBufferList*   inInputData, 
                            const AudioTimeStamp*  inInputTime,
                            AudioBufferList*  outOutputData,
                            const AudioTimeStamp* inOutputTime, 
                            void* userData)
{    
   if(!inInputData)
	   return noErr;
		
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@try {
		unsigned short recorder;
		for(recorder = 0; recorder<[_audioRecorderArray count]; recorder++)
		{
			AudioRecorder *audioRecorder = [_audioRecorderArray objectAtIndex:recorder];
			
			CAPlaythruDevice *playthruDevice = audioRecorder->mPlaythruDevice;
			[playthruDevice writeDataFromAudioBufferList:inInputData];
			
			AudioDataAmplitude *audioData = audioRecorder->mCurrentAudioData;
			if(![audioData addStereoRawDataPtr:[playthruDevice convertedBuffer]
										ofSize:[playthruDevice convertedBufferSize]
									 inChannel:audioRecorder->mRecordChannel])
			{
				[audioData setStatusFlag:NONE];			
			}			
			
			[audioRecorder recording];
		}		
	}
	@finally {
		[pool release];
	}
	
    return noErr;
}

static OSStatus outputIOProc (AudioDeviceID  inDevice,
							 const AudioTimeStamp*  inNow,
							 const AudioBufferList*   inInputData, 
							 const AudioTimeStamp*  inInputTime,
							 AudioBufferList*  outOutputData,
							 const AudioTimeStamp* inOutputTime, 
							 void* userData)
{    
#warning send playthru only to front real-time window
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@try {
		unsigned short recorder;
		for(recorder = 0; recorder<[_audioRecorderArray count]; recorder++)
		{
			AudioRecorder *audioRecorder = [_audioRecorderArray objectAtIndex:recorder];		
			[audioRecorder->mPlaythruDevice readDataToAudioBufferList:outOutputData];
		}
	}
	@finally {
		[pool release];
	}
		
	return noErr;
}

- (id)init
{
    if(self=[super init])
    {
        mIOProcTimer = NULL;
        mTimerInterval = 0.1;
        mRecordChannel = STEREO_CHANNEL;
        mCurrentAudioData = NULL;
        mCompletionObject = NULL;
        mCompletionSelector = NULL;
        mRecordingObject = NULL;
        mRecordingSelector = NULL;
		
        mInputDeviceID = -1;
		mOutputDeviceID = -1;
        mInputTicket = NULL;
		mOutputTicket = NULL;
        
		mPlaythruDevice = [[CAPlaythruDevice alloc] init];
		[[mPlaythruDevice channelMixer] adopt:[[AudioDialogPrefs shared] defaultsChannelMixer]];

		mLock = [[NSLock alloc] init];
        mRecordingCount = 0;
    }
    return self;
}

- (void)dealloc
{
    [mPlaythruDevice release];
    [mLock release];
    [super dealloc];
}

- (void)ioProcWatchTimer:(NSTimer*)timer
{
    [mRecordingObject performSelector:mRecordingSelector withObject:mCurrentAudioData];
    if([mCurrentAudioData statusFlag] == NONE)
        [self stopData:mCurrentAudioData];
}

- (void)startIOProcTimer
{
    mIOProcTimer = [NSTimer scheduledTimerWithTimeInterval:mTimerInterval 
                        target:self 
                        selector:@selector(ioProcWatchTimer:) 
                        userInfo:self 
                        repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:mIOProcTimer forMode:NSEventTrackingRunLoopMode];
}

- (void)setCompletionSelector:(SEL)completionSelector fromObject:(id)completionObject
{
    mCompletionSelector = completionSelector;
    mCompletionObject = completionObject;
}

- (void)setRecordingSelector:(SEL)recordingSelector fromObject:(id)recordingObject
{
    mRecordingSelector = recordingSelector;
    mRecordingObject = recordingObject;
}

- (void)setRecordingSelectorInterval:(FLOAT)interval
{
    mTimerInterval = interval;
    if([mIOProcTimer isValid])
    {
        [mIOProcTimer invalidate];
        [self startIOProcTimer];
    }
}

- (BOOL)startIOProc
{
    [AudioRecorder addAudioRecorderObject:self];
    
    if([_audioRecorderArray count]==1) {
		[[AudioDeviceManager shared] addAndStartIOProc:mInputTicket];
		[[AudioDeviceManager shared] addAndStartIOProc:mOutputTicket];
		return YES;
	}
    
    return YES;
}

- (BOOL)stopIOProc
{
    if([_audioRecorderArray count]==0)
        return YES;
        
    [AudioRecorder removeAudioRecorderObject:self];

    if([_audioRecorderArray count]==0)
    {
        [[AudioDeviceManager shared] stopAndRemoveIOProc:mInputTicket];
        [[AudioDeviceManager shared] stopAndRemoveIOProc:mOutputTicket];
		return YES;
    } else
        return YES;
}

- (BOOL)_recordData
{    
    if([self startIOProc])   
    {
        [mCurrentAudioData setStatusFlag:RECORDING];
        
        [self startIOProcTimer];
        
        return YES;
    } else
        return NO;
}

- (void)setPlaythru:(BOOL)flag
{
	[mPlaythruDevice setEnabled:flag];
}

- (BOOL)playthru
{
    return [mPlaythruDevice enabled];
}

- (CAPlaythruDevice*)playthruDevice
{
	return mPlaythruDevice;
}

- (BOOL)recordData:(AudioDataAmplitude*)audioData channel:(SHORT)channel
{
    mRecordChannel = channel;
    mCurrentAudioData = audioData;
	
    mInputDeviceID = [[AudioDeviceManager shared] currentInputDeviceID];
    mOutputDeviceID = [[AudioDeviceManager shared] currentOutputDeviceID];
    	
    mInputTicket = [[AudioDeviceManager shared] registerClient:self
                                            deviceID:mInputDeviceID
                                            ioProc:inputIOProc
                                            userData:self
                                            notifySelector:@selector(clientNotification:)];

	mOutputTicket = [[AudioDeviceManager shared] registerClient:self
													  deviceID:mOutputDeviceID
														ioProc:outputIOProc
													  userData:self
												notifySelector:@selector(clientNotification:)];
	
	[mPlaythruDevice startDevice];
	
    return [self _recordData];
}

- (BOOL)stopData:(AudioDataAmplitude*)audioData
{    
    [audioData setStatusFlag:NONE];
    
	[mPlaythruDevice stopDevice];
	
    if([self stopIOProc])
    {
        [mIOProcTimer invalidate];
        mIOProcTimer = NULL;
        
		[[AudioDeviceManager shared] removeClient:mInputTicket];
        [[AudioDeviceManager shared] removeClient:mOutputTicket];
        mInputTicket = NULL;
		mOutputTicket = NULL;
		
        [mCompletionObject performSelector:mCompletionSelector withObject:audioData];
        return YES;
    } else
        return NO;
}

- (void)clientNotification:(CAClientObject*)client
{
    // Device has changed (can be dead)
    if([client isRunning] == NO)
        [mCurrentAudioData setStatusFlag:NONE];
}

- (BOOL)isRecording
{
    if(mCurrentAudioData)
        return [mCurrentAudioData statusFlag] == RECORDING;
    else
        return NO;
}

- (UInt32)inputDeviceID
{
    return mInputDeviceID;
}

@end

@implementation AudioRecorder (Thread)

// Called by the audio thread when a new bunch of audio data has been collected
- (void)recording
{
    [mLock lock];

    mRecordingCount++;
    if(mRecordingCount>1e9)
        mRecordingCount = 0;
        
    [mLock unlock];
}

// Thread-safe reading method
- (ULONG)recordingCount
{
    ULONG value = 0;
    
    [mLock lock];

    value = mRecordingCount;
    
    [mLock unlock];
    
    return value;
}

@end
