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

#import "AudioRTOp.h"
#import "AudioOpFFT.h"
#import "AudioDialogPrefs.h"

@implementation AudioRTOp

- (id)init
{
    if(self = [super init])
    {
        mAmplitudeData = NULL;
        mFFTData = NULL;
        mSonoData = NULL;

        mBufferDuration = 5;
        mResolutionInterval = 0;
        mLastTimeInterval = 0;
        mDate = NULL;

        mFFTSize = DEFAULT_FFT_SIZE;
        mFFTWindowFunctionID = 0;
        mFFTWindowFunctionParameter = 0;
        mFFTWindowParametersArray = NULL;
        
        mComputeFFT = YES;
        mComputeSono = YES;      
        
        mParametersDirty = YES;

        [self initAmplitudeData];
        [self initFFTData];
        [self initSonoData];

        [self updateParameters:YES];
    }
    return self;
}

- (void)dealloc
{
    [mAmplitudeData release];
    [mFFTData release];
    [mSonoData release];
    [mDate release];
    [mFFTWindowParametersArray release];
    [super dealloc];
}

- (void)setBufferDuration:(FLOAT)duration
{
    mBufferDuration = duration;
    mParametersDirty = YES;
}

- (void)setResolutionInterval:(FLOAT)seconds
{
    mResolutionInterval = seconds;
    mParametersDirty = YES;
}

- (void)setComputeFFT:(BOOL)flag
{
    mComputeFFT = flag;
}

- (void)setComputeSono:(BOOL)flag
{
    mComputeSono = flag;
}

- (void)setAmplitudeDisplayWindowMode:(BOOL)flag
{
    [mAmplitudeData setDisplayWindowMode:flag];
}

- (BOOL)amplitudeDisplayWindowMode
{
    return [mAmplitudeData displayWindowMode];
}

- (void)setTriggerState:(BOOL)flag
{
    [mAmplitudeData setTriggerState:flag];
}

- (BOOL)triggerState
{
    return [mAmplitudeData triggerState];
}

- (void)setTriggerSlope:(USHORT)slope
{
    [mAmplitudeData setTriggerSlope:slope];
}

- (USHORT)triggerSlope
{
    return [mAmplitudeData triggerSlope];
}

- (void)setTriggerOffset:(FLOAT)offset
{
    [mAmplitudeData setTriggerOffset:offset];
}

- (FLOAT)triggerOffset
{
    return [mAmplitudeData triggerOffset];
}

- (NSString*)triggerOffsetUnit
{
    return [mAmplitudeData yAxisUnit];
}

- (NSString*)amplitudeYAxisUnit
{
    return [mAmplitudeData yAxisUnit];
}

- (void)setFFTSize:(ULONG)size
{
    mFFTSize = size;
    [self updateFFT:NO];
    [self updateSono:YES];
}

- (void)setFFTWindowFunctionID:(SHORT)func
{
    mFFTWindowFunctionID = func;
    [self updateFFT:NO];
}

- (void)setFFTWindowFunctionParameter:(FLOAT)param
{
    mFFTWindowFunctionParameter = param;
    [self updateFFT:NO];
}

- (ULONG)fftSize
{
    return mFFTSize;
}

- (SHORT)fftWindowFunctionID
{
    return mFFTWindowFunctionID;
}

- (FLOAT)fftWindowFunctionParameter
{
    return mFFTWindowFunctionParameter;
}

- (void)initAmplitudeData
{
    [mAmplitudeData release];
    mAmplitudeData = [[AudioDataAmplitude alloc] init];
}

- (void)initFFTData
{
    [mFFTData release];
    mFFTData = [[AudioDataFFT alloc] init];
}

- (void)initSonoData
{
    [mSonoData release];
    mSonoData = [[AudioDataSono alloc] init];
    [mSonoData setColorMode:[[AudioDialogPrefs shared] rtSonoColorMode]];
}

- (AudioDataAmplitude*)amplitudeData
{
    return mAmplitudeData;
}

- (AudioDataFFT*)fftData
{
    return mFFTData;
}

- (AudioDataSono*)sonoData
{
    return mSonoData;
}

- (void)displayFFTOfSonoAtX:(FLOAT)x
{
    [mFFTData copyFFTDataFromSonoData:mSonoData atX:x channel:LEFT_CHANNEL];    
}

@end

@implementation AudioRTOp (Computation)

- (void)updateAmplitude:(BOOL)reset
{
    if(reset)
    {
        [mAmplitudeData setDisplayWindowMode:YES];
        [mAmplitudeData setTriggerState:YES];
    }

    [mAmplitudeData setReverseXAxis:[mAmplitudeData displayWindowMode] == NO];
    [mAmplitudeData setLoopBuffer:YES timeFollow:NO];
    if(reset)
        [mAmplitudeData setDuration:mBufferDuration rate:SOUND_DEFAULT_RATE channel:STEREO_CHANNEL];
}

- (void)updateFFT:(BOOL)reset
{
    if(mAmplitudeData)
        mFFTTimeOffset = (FLOAT)mFFTSize/[mAmplitudeData dataRate];
    else
        mFFTTimeOffset = 0;
    
    [mFFTWindowParametersArray release];
    mFFTWindowParametersArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:mFFTWindowFunctionID],
                                        [NSNumber numberWithFloat:mFFTWindowFunctionParameter],
                                        NULL];
    [mFFTWindowParametersArray retain];
}

- (void)updateSono:(BOOL)reset
{	
    [mSonoData setFFTWindowWidth:mFFTSize];
    [mSonoData setFFTWindowOffset:mResolutionInterval*[mAmplitudeData dataRate]];
    if(reset)
    {
        [mSonoData setReverseXAxis:YES];
        [mSonoData setDuration:mBufferDuration];
        [mSonoData setDataRate:SOUND_DEFAULT_RATE];
        [mSonoData prepareParameters];
        [mSonoData prepareBuffer];
    }
}

- (void)updateParameters:(BOOL)reset
{
    if(mParametersDirty)
    {
        mParametersDirty = NO;
        reset = YES;
    }
    [self updateAmplitude:reset];
    [self updateFFT:reset];
    [self updateSono:reset];    
}

- (void)computeAmplitude
{
    if(mTimeCalibrated == NO)
    {
        mLastAmplitudePosition = [mAmplitudeData currentAbsolutePositionOfChannel:LEFT_CHANNEL];
        mTimeCalibrated = YES;
    }
}

- (void)computeFFT
{
    FLOAT currentAbsoluteAmplitudePosition = [mAmplitudeData currentAbsolutePositionOfChannel:LEFT_CHANNEL];
    
    while((currentAbsoluteAmplitudePosition-mLastAmplitudePosition)>=mResolutionInterval)
    {
        mLastAmplitudePosition += mResolutionInterval;
        
        FLOAT t = [mAmplitudeData currentPositionOfChannel:LEFT_CHANNEL]
                        - (currentAbsoluteAmplitudePosition-mLastAmplitudePosition)
                        - mFFTTimeOffset;
        
        if([mAmplitudeData positionInRange:t channel:LEFT_CHANNEL])
        {     
            mFFTData = [AudioOpFFT computeData:mAmplitudeData from:t to:t
                                    size:mFFTSize audioDataFFT:mFFTData
                                    windowParametersArray:mFFTWindowParametersArray];
            [mSonoData addFFT:[mFFTData dataForChannel:LEFT_CHANNEL]];
        }
    }
}

- (void)computeImage
{
	if(mComputeSono)
	   [mSonoData computeImage];
}

- (void)compute
{
    [self computeAmplitude];
    
    if(mComputeFFT)
        [self computeFFT];
}

- (BOOL)start:(BOOL)resuming
{
    [mDate release];
    mDate = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
    mTimeCalibrated = NO;

    [self updateParameters:resuming?NO:YES];

    return YES;
}

- (BOOL)stop
{
    return YES;
}

@end
