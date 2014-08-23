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

#import "AudioSynth.h"
#import "CADeviceManager.h"

typedef struct {
    @defs(AudioSynth);
} AudioSynthStruct;

OSStatus _synthUserProc(double *phase, const double amplitude, const double incr, const unsigned numberOfSample, float *output)
{
    unsigned sample;
    for(sample=0; sample<numberOfSample; sample++)
    {
        float wave = sin(*phase)*amplitude;
        *phase += incr;
        *output++ = wave;	// LEFT
        *output++ = wave;	// RIGHT
    }
    return noErr;
}

OSStatus _synthIOProc (AudioDeviceID  inDevice,
                        const AudioTimeStamp*  inNow,
                        const AudioBufferList*   inInputData, 
                        const AudioTimeStamp*  inInputTime,
                        AudioBufferList*  outOutputData,
                        const AudioTimeStamp* inOutputTime, 
                        void* userData)
{
    AudioSynthStruct *as = userData;

    if(outOutputData == NULL) return kAudioHardwareNoError;
    if(outOutputData->mBuffers[0].mData == NULL) return kAudioHardwareNoError;

    unsigned numberOfSample = outOutputData->mBuffers[0].mDataByteSize/as->mStreamDescription.mBytesPerFrame;
        
    float *out = outOutputData->mBuffers[0].mData;
    double phase = as->mPhase;
    double freq = as->mFreq_;
	double amplitude = as->mAmplitude; 
    
    if(as->mCallBackProc)
    {
        (as->mCallBackProc)(&phase, amplitude, freq, numberOfSample, out);
    } else
    {
        unsigned sample;
        for(sample=0; sample<numberOfSample; sample++) {
        
            float wave = sin(phase)*amplitude;
            phase += freq;
            
            *out++ = wave;	// left channel
            *out++ = wave;	// right channel
        }
    }
        
    as->mPhase = phase;

    return kAudioHardwareNoError;
}

@implementation AudioSynth

+ (AudioSynth*)shared
{
    static AudioSynth *_synth = NULL;
    if(_synth == NULL)
        _synth = [[AudioSynth alloc] init];
    return _synth;
}

- (id)init
{
    if(self = [super init])
    {
        mOutputDeviceID = kAudioDeviceUnknown;
        mCallBackProc = NULL;
        mFreq = 0;
    }
    return self;
}

- (void)dealloc
{
	[self stop];
	[super dealloc];
}

- (void)setFrequency:(double)freq
{
    mFreq = freq;
    [self prepare];
}

- (void)setAmplitude:(double)amplitude
{
	mAmplitude = amplitude;
}

- (void)setFrequencyProc:(AudioSynthProc)proc
{
    mCallBackProc = proc;
}

- (void)prepare
{
    mStreamDescription = [[AudioDeviceManager shared] currentOutputStreamDescription];
    mFreq_ = mFreq * 2 * 3.14159265359 / mStreamDescription.mSampleRate;
}

- (BOOL)play
{
    mOutputDeviceID = [[AudioDeviceManager shared] currentOutputDeviceID];
    mPhase = 0;

    [self prepare];
    
    mClientTicket = [[AudioDeviceManager shared] registerClient:self
                                        deviceID:mOutputDeviceID
                                        ioProc:_synthIOProc
                                        userData:self
                                        notifySelector:@selector(clientNotification:)];

    if([[AudioDeviceManager shared] addAndStartIOProc:mClientTicket])
    {
        return YES;
    } else
        return NO;
}

- (BOOL)stop
{        
    if([[AudioDeviceManager shared] stopAndRemoveIOProc:mClientTicket])
    {
        [[AudioDeviceManager shared] removeClient:mClientTicket];
        mClientTicket = NULL;
        return YES;
    } else
        return NO;
}

- (BOOL)toggle
{
    if([self playing])
        return [self stop];
    else
        return [self play];
}

- (BOOL)playing
{
    return [[AudioDeviceManager shared] isRunningClient:mClientTicket];
}

- (void)clientNotification:(CAClientObject*)client
{
    // Device has changed (can be dead)
    if([client isRunning] == NO)
        NSLog(@"Device is not running anymore");
}

@end
