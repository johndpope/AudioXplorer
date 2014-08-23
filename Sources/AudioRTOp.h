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

#import <Foundation/Foundation.h>
#import "AudioDataAmplitude.h"
#import "AudioDataFFT.h"
#import "AudioDataSono.h"

@interface AudioRTOp : NSObject {
    // Real-time data
    AudioDataAmplitude 	*mAmplitudeData;
    AudioDataFFT 	*mFFTData;
    AudioDataSono 	*mSonoData;

    // Real-time parameters
    FLOAT mBufferDuration;
    FLOAT mResolutionInterval;
    FLOAT mLastAmplitudePosition;
    BOOL mTimeCalibrated;
    NSTimeInterval mLastTimeInterval;
    NSDate *mDate;
        
    // Spectrogram information
    ULONG mFFTSize;
    SHORT mFFTWindowFunctionID;
    FLOAT mFFTWindowFunctionParameter;
    NSArray *mFFTWindowParametersArray;

    FLOAT mFFTTimeOffset;
    
    // What to compute ?
    BOOL mComputeFFT;
    BOOL mComputeSono;
    
    // Dirty flag
    
    BOOL mParametersDirty;
}

- (void)setBufferDuration:(FLOAT)duration;
- (void)setResolutionInterval:(FLOAT)seconds;

- (void)setComputeFFT:(BOOL)flag;
- (void)setComputeSono:(BOOL)flag;

- (void)setAmplitudeDisplayWindowMode:(BOOL)flag;
- (BOOL)amplitudeDisplayWindowMode;
- (void)setTriggerState:(BOOL)flag;
- (BOOL)triggerState;
- (void)setTriggerSlope:(USHORT)slope;
- (USHORT)triggerSlope;
- (void)setTriggerOffset:(FLOAT)offset;
- (FLOAT)triggerOffset;

- (NSString*)triggerOffsetUnit;
- (NSString*)amplitudeYAxisUnit;

- (void)setFFTSize:(ULONG)size;
- (void)setFFTWindowFunctionID:(SHORT)func;
- (void)setFFTWindowFunctionParameter:(FLOAT)param;

- (ULONG)fftSize;
- (SHORT)fftWindowFunctionID;
- (FLOAT)fftWindowFunctionParameter;

- (void)initAmplitudeData;
- (void)initFFTData;
- (void)initSonoData;

- (AudioDataAmplitude*)amplitudeData;
- (AudioDataFFT*)fftData;
- (AudioDataSono*)sonoData;

- (void)displayFFTOfSonoAtX:(FLOAT)x;

@end

@interface AudioRTOp (Computation)
- (void)updateAmplitude:(BOOL)reset;
- (void)updateFFT:(BOOL)reset;
- (void)updateSono:(BOOL)reset;
- (void)updateParameters:(BOOL)reset;
- (void)computeImage;
- (void)compute;
- (BOOL)start:(BOOL)resuming;
- (BOOL)stop;
@end
