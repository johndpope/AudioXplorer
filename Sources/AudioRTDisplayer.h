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

#import <Cocoa/Cocoa.h>
#import "AudioRecorder.h"
#import "AudioRTOp.h"
#import "AudioDataAmplitude.h"
#import "AudioDataFFT.h"
#import "AudioView2D.h"
#import "AudioView3D.h"

#define LAYOUT_SINGLE 0
#define LAYOUT_MULTIPLE 1

#define AMPLITUDE_VIEW 0
#define FFT_VIEW 1
#define SONO_VIEW 2

#define AMPLITUDE_FFT_VIEWS 3
#define AMPLITUDE_SONO_VIEWS 4
#define FFT_SONO_VIEWS 5
#define AMPLITUDE_FFT_SONO_VIEWS 6

@interface AudioRTDisplayer : NSObject {    
    AudioRecorder *mAudioRecorder;
    AudioRTOp *mAudioRTOp;
    
    NSWindow *mRTWindow;
    id mRTWindowDelegate;
    
    AudioView2D *mAmplitudeView;
    AudioView2D *mFFTView;
    AudioView3D *mSonoView;
        
    USHORT mLayoutViewID;
    SHORT mDisplayedChannel;
    
    id mDelegate;
    
    NSTimer *mDisplayTimer;
    
    BOOL mMonitoring;
    BOOL mPaused;
    
    FLOAT mBufferDuration;		// RT buffer duration
    FLOAT mMonitoringInterval;		// Display resolution
    FLOAT mMonitoringResolution;	// Computation resolution
        
    FLOAT mAmplitudeVisualMinX, mAmplitudeVisualMaxX;
    FLOAT mAmplitudeVisualMinY, mAmplitudeVisualMaxY;
    FLOAT mFFTVisualMinX, mFFTVisualMaxX;
    FLOAT mFFTVisualMinY, mFFTVisualMaxY;
    FLOAT mSonoVisualMinX, mSonoVisualMaxX;
    FLOAT mSonoVisualMinY, mSonoVisualMaxY;
    
    BOOL mAmplitudeAutoYAxis;
    BOOL mFFTAutoYAxis;
    BOOL mAmplitudeTimeFollow;
    
    SHORT mFFTXAxisScale;    
    SHORT mFFTYAxisScale;    
}

- (void)setDelegate:(id)delegate;
- (void)setRTWindow:(NSWindow*)window;
- (void)setRTWindowDelegate:(id)delegate;

- (void)initView:(AudioView*)view;
- (void)initViews;

- (AudioView*)amplitudeView;
- (AudioView*)fftView;
- (AudioView*)sonoView;

- (AudioDataSono*)sonoData;
- (AudioRecorder*)audioRecorder;

- (void)applyLayout;

- (void)setLayoutID:(USHORT)layout;
- (USHORT)layoutID;

- (void)setLayoutByKey:(USHORT)key;

- (void)setPlaythru:(BOOL)flag;

- (void)setBufferDuration:(FLOAT)duration;
- (FLOAT)bufferDuration;

- (void)setMonitoringInterval:(FLOAT)value;
- (FLOAT)monitoringInterval;

- (void)setMonitoringResolution:(FLOAT)value;
- (FLOAT)monitoringResolution;

- (void)setAmplitudeRange:(FLOAT)range;
- (FLOAT)amplitudeRange;

- (void)setDisplayedChannel:(SHORT)channel;
- (SHORT)displayedChannel;

- (void)setFFTSize:(ULONG)size;
- (ULONG)fftSize;

- (void)setFFTWindowFunctionID:(SHORT)windowID;
- (SHORT)fftWindowFunctionID;
- (void)setFFTWindowFunctionParameterValue:(FLOAT)value;
- (FLOAT)fftWindowFunctionParameterValue;

- (void)viewKeyDown:(NSEvent*)event;

- (void)applyData:(id)data toView:(AudioView*)view;
- (void)updateFFTDataToFFTView;
- (void)updateSonoDataToSonoView;
@end

@interface AudioRTDisplayer (Display)
- (void)refreshViews;
- (void)recordCompleted:(AudioDataAmplitude*)audioData;
- (void)recording:(AudioDataAmplitude*)audioData;
@end

@interface AudioRTDisplayer (Monitoring)

- (IBAction)toggleRTMonitoring:(id)sender;
- (IBAction)startRTMonitoring:(id)sender;
- (IBAction)stopRTMonitoring:(id)sender;

- (void)pauseMonitoring;
- (void)resumeMonitoring;

- (BOOL)startRTMonitoring_;
- (BOOL)stopRTMonitoring_;

- (BOOL)monitoring;

@end

@interface AudioRTDisplayer (Parameters)

- (void)initDefaultParameters;

- (void)applyRangeFromAmplitudeView;
- (void)applyRangeFromFFTView;
- (void)applyRangeFromSonoView;

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

- (void)setAmplitudeAutoYAxis:(BOOL)value;
- (void)setFFTAutoYAxis:(BOOL)value;

- (BOOL)amplitudeAutoYAxis;
- (BOOL)fftAutoYAxis;

- (void)setFFTXAxisScale:(SHORT)scale;
- (int)fftXAxisScale;
- (void)setFFTYAxisScale:(SHORT)scale;
- (int)fftYAxisScale;
- (void)adjustAmplitudeYAxis;

- (void)checkAmplitudeRange;
- (void)checkFFTRange;

- (void)applyAmplitudeRangeToView;
- (void)applyFFTRangeToView;

- (void)setAmplitudeVisualMinX:(FLOAT)value;
- (void)setAmplitudeVisualMaxX:(FLOAT)value;
- (void)setAmplitudeVisualMinY:(FLOAT)value;
- (void)setAmplitudeVisualMaxY:(FLOAT)value;

- (void)setFFTVisualMinX:(FLOAT)value;
- (void)setFFTVisualMaxX:(FLOAT)value;
- (void)setFFTVisualMinY:(FLOAT)value;
- (void)setFFTVisualMaxY:(FLOAT)value;

- (FLOAT)amplitudeVisualMinX;
- (FLOAT)amplitudeVisualMaxX;
- (FLOAT)amplitudeVisualMinY;
- (FLOAT)amplitudeVisualMaxY;

- (FLOAT)fftVisualMinX;
- (FLOAT)fftVisualMaxX;
- (FLOAT)fftVisualMinY;
- (FLOAT)fftVisualMaxY;

@end

@interface AudioRTDisplayer (Objects)
- (AudioRecorder*)audioRecorder;
@end

@interface AudioRTDisplayer (Timers)
- (BOOL)startTimers;
- (BOOL)stopTimers;
@end

@interface AudioRTDisplayer (Delegate)
- (void)audioViewScaleHasChanged:(AudioView*)view;
@end