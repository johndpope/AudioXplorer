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

#import "AudioRTInfo.h"

@implementation AudioRTInfo

- (id)init
{
    if(self = [super init])
    {
        mAudioRecorder = [[AudioRecorder alloc] init];
        [mAudioRecorder setCompletionSelector:@selector(recordCompleted:) fromObject:self];
        [mAudioRecorder setRecordingSelector:@selector(recording:) fromObject:self];
        
        mAmplitudeData = NULL;
        mMonitoring = NO;
        
		mMeanPoint = 0;
        mUserGain = 1;
    }
    return self;
}

- (void)dealloc
{
    [mAudioRecorder release];
    [mAmplitudeData release];
    [super dealloc];
}

- (void)recordCompleted:(AudioDataAmplitude*)audioData
{
}

- (float)leftLevel
{
	FLOAT mean = 0;
	int i;
	for(i=0; i<MAX_MEAN_POINT; i++) {
		mean += mLeftLevel[i];
	}
	return mean/MAX_MEAN_POINT;
}

- (float)rightLevel
{
	FLOAT mean = 0;
	int i;
	for(i=0; i<MAX_MEAN_POINT; i++) {
		mean += mRightLevel[i];
	}
	return mean/MAX_MEAN_POINT;
}

- (void)recording:(AudioDataAmplitude*)audioData
{
    FLOAT leftLevel = [audioData instantLevelOfChannel:LEFT_CHANNEL];
    FLOAT rightLevel = [audioData instantLevelOfChannel:RIGHT_CHANNEL];
	
	mMeanPoint++;
	if(mMeanPoint>=MAX_MEAN_POINT)
		mMeanPoint = 0;
		
	mLeftLevel[mMeanPoint] = leftLevel;
	mRightLevel[mMeanPoint] = rightLevel;
			
	leftLevel = [self leftLevel];
	rightLevel = [self rightLevel];
	
    [mLeftLevelProgressBar setDoubleValue:leftLevel];
    [mRightLevelProgressBar setDoubleValue:rightLevel];

    if(leftLevel>1)
    {
        leftLevel = 1;
        [mLeftLevelTextField setTextColor:[NSColor redColor]];
    } else
        [mLeftLevelTextField setTextColor:[NSColor blackColor]];

    if(rightLevel>1)
    {
        rightLevel = 1;
        [mRightLevelTextField setTextColor:[NSColor redColor]];
    } else
        [mRightLevelTextField setTextColor:[NSColor blackColor]];
    
    [mLeftLevelTextField setStringValue:[NSString stringWithFormat:@"%d%%", (USHORT)(leftLevel*100)]];
    [mRightLevelTextField setStringValue:[NSString stringWithFormat:@"%d%%", (USHORT)(rightLevel*100)]];
}

- (IBAction)applyUserGain:(id)sender
{
    mUserGain = [mUserGainTextField floatValue];
    [mAmplitudeData setGain:mUserGain];
}

- (IBAction)startMonitoring:(id)sender
{
    if(mMonitoring)
        return;
        
    [mAmplitudeData release];
    mAmplitudeData = [[AudioDataAmplitude alloc] init];
    [mAmplitudeData setGain:mUserGain];
    [mAmplitudeData setLoopBuffer:YES timeFollow:YES];
    [mAmplitudeData setDuration:0.2 rate:SOUND_DEFAULT_RATE channel:STEREO_CHANNEL];
        
    [mAudioRecorder setRecordingSelectorInterval:0.1];
    if([mAudioRecorder recordData:mAmplitudeData channel:STEREO_CHANNEL])
        mMonitoring = YES;
    else
        NSLog(@"Unable to START the RT Monitoring");
}

- (IBAction)stopMonitoring:(id)sender
{
    if(mMonitoring == NO) return;
    
    if([mAudioRecorder stopData:mAmplitudeData])
        mMonitoring = NO;
    else
        NSLog(@"Unable to STOP the RT Monitoring");
}

- (IBAction)playthru:(id)sender
{
	[mAudioRecorder setPlaythru:[sender state] == NSOnState];
}

@end
