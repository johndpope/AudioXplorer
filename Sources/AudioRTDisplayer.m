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

#import "AudioRTDisplayer.h"
#import "AudioOpFFT.h"
#import "AudioNotifications.h"
#import "CAConstants.h"
#import "CADeviceObject.h"
#import "AudioDialogPrefs.h"

@implementation AudioRTDisplayer

- (id)init
{
    if(self = [super init])
    {            
        mAudioRTOp = [[AudioRTOp alloc] init];
        mAudioRecorder = [[AudioRecorder alloc] init];
        [mAudioRecorder setCompletionSelector:@selector(recordCompleted:) fromObject:self];
        [mAudioRecorder setRecordingSelector:@selector(recording:) fromObject:self];
        [mAudioRecorder setPlaythru:NO];
        
        mDelegate = NULL;
        
        mDisplayTimer = NULL;
        
        mMonitoring = NO;
        mPaused = NO;
        
        mBufferDuration = [[AudioDialogPrefs shared] rtBufferDuration];
        
        mMonitoringInterval = 0.1;
        mMonitoringResolution = 0.1;
                
        mLayoutViewID = [[AudioDialogPrefs shared] rtLayout];
        mDisplayedChannel = LEFT_CHANNEL;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(devicesChangedNotification:) 
                                                name:CADeviceManagerDevicesChangedNotification
                                                object:NULL];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(deviceIsAliveNotification:) 
                                                name:CADeviceObjectIsAliveChangedNotification
                                                object:NULL];

        [self initViews];
        [self initDefaultParameters];                
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
		
    [mDisplayTimer release];
    
    [mAudioRecorder release];
    [mAudioRTOp release];

	[mAmplitudeView removeFromSuperview];
    [mAmplitudeView release];
	
    [mFFTView removeFromSuperview];
    [mFFTView release];
	
    [mSonoView removeFromSuperview];
    [mSonoView release];
    
    [super dealloc];
}

- (void)setDelegate:(id)delegate
{
    mDelegate = delegate;
}

- (void)setRTWindow:(NSWindow*)window
{
    mRTWindow = window;
}

- (void)setRTWindowDelegate:(id)delegate
{
    mRTWindowDelegate = delegate;
}

- (void)initView:(AudioView*)view
{
    [view setAllowsSelection:NO];
    [view setAllowsCursor:YES];
    [view setAllowsPlayerhead:NO];
    
    [view setAllowsViewSelect:NO];
    [view setAllowsPlayback:NO];
    
    [view setDelegate:self];    
}

- (void)initViews
{
    mAmplitudeView = [[AudioView2D alloc] initWithFrame:NSMakeRect(0,0,200,100)];
    mFFTView = [[AudioView2D alloc] initWithFrame:NSMakeRect(0,100,200,100)];
    mSonoView = [[AudioView3D alloc] initWithFrame:NSMakeRect(0,200,200,100)];
    
    [self initView:mAmplitudeView];
    [self initView:mFFTView];
    [self initView:mSonoView];
}

- (AudioView*)amplitudeView
{
    return mAmplitudeView;
}

- (AudioView*)fftView
{
    return mFFTView;
}

- (AudioView*)sonoView
{
    return mSonoView;
}

- (AudioDataSono*)sonoData
{
    return [mAudioRTOp sonoData];
}

- (AudioRecorder*)audioRecorder
{
	return mAudioRecorder;
}

- (void)setSonogramVisible:(BOOL)visible
{
	if(visible)
		[mAudioRTOp setComputeSono:YES];
	else
		[mAudioRTOp setComputeSono:![[AudioDialogPrefs shared] computeSonogramOnlyIfVisible]];
}

- (void)applySingleLayout
{
    NSView *view = NULL;
    switch(mLayoutViewID) {
        case AMPLITUDE_VIEW:
            view = mAmplitudeView;
			[self setSonogramVisible:NO];
            break;
        case FFT_VIEW:
            view = mFFTView;
			[self setSonogramVisible:NO];
            break;
        case SONO_VIEW:
            view = mSonoView;
			[self setSonogramVisible:YES];
            break;
    }
    
    if(view)
        [mRTWindow setContentView:view];
}

- (void)applyMultipleLayout
{
    NSSplitView *sva = [[NSSplitView alloc] initWithFrame:[[mRTWindow contentView] frame]];
    NSSplitView *svb = [[NSSplitView alloc] initWithFrame:[[mRTWindow contentView] frame]];

    [sva setDelegate:mRTWindowDelegate];
    [svb setDelegate:mRTWindowDelegate];
    
    NSRect frame = [sva frame];
    NSRect a = frame;
    NSRect b = frame;
    NSRect c = frame;

    if(mLayoutViewID == AMPLITUDE_FFT_SONO_VIEWS)
    {
        a.size.height *= 0.5;
        a.origin.y += a.size.height;
        
        [svb setFrame:a];
        [svb setVertical:YES];
        
        b = a;
        
        a.size.width *= 0.5;
        b.size.width *= 0.5;
        b.origin.x += b.size.width;
        
        c.size.height *= 0.5;
    } else
    {
        a.size.height *= 0.5;
        a.origin.y += a.size.height;
        
        b.size.height *= 0.5;
    }
    
    NSView *va = NULL;
    NSView *vb = NULL;
    NSView *vc = NULL;
    
    switch(mLayoutViewID) {
        case AMPLITUDE_FFT_VIEWS:
            va = mAmplitudeView;
            vb = mFFTView;
			[self setSonogramVisible:NO];
            break;
            
        case AMPLITUDE_SONO_VIEWS:
            va = mAmplitudeView;
            vb = mSonoView;
			[self setSonogramVisible:YES];
            break;
                    
        case FFT_SONO_VIEWS:
            va = mFFTView;
            vb = mSonoView;
			[self setSonogramVisible:YES];
            break;
        
        case AMPLITUDE_FFT_SONO_VIEWS:
            va = mAmplitudeView;
            vb = mFFTView;
            vc = mSonoView;
			[self setSonogramVisible:YES];
            break;
    }

    [va setFrame:a];
    [vb setFrame:b];
    [vc setFrame:c];
    
    [mRTWindow setContentView:sva];

    if(mLayoutViewID == AMPLITUDE_FFT_SONO_VIEWS)
    {
        [svb addSubview:va];
        [svb addSubview:vb];
        [svb adjustSubviews];
        [sva addSubview:svb];
        [sva addSubview:vc];
        [sva adjustSubviews];
    } else
    {
        [sva addSubview:va];
        [sva addSubview:vb];
        [sva adjustSubviews];
    }
}

- (void)applyLayout
{
    if(mLayoutViewID>SONO_VIEW)
        [self applyMultipleLayout];
    else
        [self applySingleLayout];
}

- (void)setLayoutID:(USHORT)layout
{
    mLayoutViewID = layout;
    [self applyLayout];
}

- (USHORT)layoutID
{
    return mLayoutViewID;
}

- (void)setLayoutByKey:(USHORT)key
{
    switch(key)
    {
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
            [self setLayoutID:key-'1'];
            [self applyLayout];
            break;
    }
}

- (void)setPlaythru:(BOOL)flag
{
    [mAudioRecorder setPlaythru:flag];
}

- (void)setBufferDuration:(FLOAT)duration
{
    mBufferDuration = duration;
    if(mMonitoring && mPaused == NO)
    {
        [self stopRTMonitoring:self];
        [mAudioRTOp setBufferDuration:mBufferDuration];
        [self startRTMonitoring:self];
    } else
        [mAudioRTOp setBufferDuration:mBufferDuration];
    
    mSonoVisualMinX = -duration;
    mSonoVisualMaxX = 0;
    [mSonoView setVisualRangeForXAxisFrom:mSonoVisualMinX to:mSonoVisualMaxX];
}

- (FLOAT)bufferDuration
{
    return mBufferDuration;
}

- (void)setMonitoringInterval:(FLOAT)value
{
    mMonitoringInterval = value;
    if(mMonitoring && mPaused == NO)
    {
        [self stopTimers];
        [self startTimers];
    }
}

- (FLOAT)monitoringInterval
{
    return mMonitoringInterval;
}

- (void)setMonitoringResolution:(FLOAT)value
{
    mMonitoringResolution = value;
    if(mMonitoring && mPaused == NO)
    {
        [self pauseMonitoring];
        [mAudioRTOp setResolutionInterval:mMonitoringResolution];
        [mAudioRecorder setRecordingSelectorInterval:mMonitoringResolution];
        [self resumeMonitoring];
    } else {
        [mAudioRTOp setResolutionInterval:mMonitoringResolution];
		[mAudioRecorder setRecordingSelectorInterval:mMonitoringResolution];
	}
}

- (FLOAT)monitoringResolution
{
    return mMonitoringResolution;
}

- (void)setAmplitudeRange:(FLOAT)range
{
    [[mAudioRTOp amplitudeData] setDisplayWindowDuration:range];
}

- (FLOAT)amplitudeRange
{
    return [[mAudioRTOp amplitudeData] displayWindowDuration];
}

- (void)setDisplayedChannel:(SHORT)channel
{
    mDisplayedChannel = channel;
    [mAmplitudeView setDisplayedChannel:channel];
    [mFFTView setDisplayedChannel:channel];
    [mSonoView setDisplayedChannel:channel];
}

- (SHORT)displayedChannel
{
    return mDisplayedChannel;
}

- (void)setFFTSize:(ULONG)size
{
    [mAudioRTOp setFFTSize:size];
}

- (ULONG)fftSize
{
    return [mAudioRTOp fftSize];
}

- (void)setFFTWindowFunctionID:(SHORT)windowID
{
    [mAudioRTOp setFFTWindowFunctionID:windowID];
}

- (SHORT)fftWindowFunctionID
{
    return [mAudioRTOp fftWindowFunctionID];
}

- (void)setFFTWindowFunctionParameterValue:(FLOAT)value
{
    [mAudioRTOp setFFTWindowFunctionParameter:value];
}

- (FLOAT)fftWindowFunctionParameterValue
{
    return [mAudioRTOp fftWindowFunctionParameter];
}

- (void)viewKeyDown:(NSEvent*)event
{
    NSString *c = [event charactersIgnoringModifiers];
    //unsigned int flags = [event modifierFlags];
    unsigned char c_ = [c characterAtIndex:0];

	switch(c_) {
		case 32:
			[self toggleRTMonitoring:self];
			break;
		case '+':
		case '-':
			[mAmplitudeView keyDown:event];
			[mAmplitudeView setNeedsDisplay:YES];
			[mFFTView keyDown:event];
			[mFFTView setNeedsDisplay:YES];
			[mSonoView keyDown:event];
			[mSonoView setNeedsDisplay:YES];
			break;
	}
}

- (void)drawCustomRect:(NSRect)rect
{
}

- (void)applyData:(id)data toView:(AudioView*)view
{
    if(data && view)
    {
        [view setDataSource:data];
        [view setViewName:[data name]];
        
        [view setXAxisUnit:[data xAxisUnit]];        
        [view setXAxisName:[data xAxisName]];
    
        [view setYAxisUnit:[data yAxisUnit]];        
        [view setYAxisName:[data yAxisName]];
    }
}

- (void)updateFFTDataToFFTView
{
    [self applyData:[mAudioRTOp fftData] toView:mFFTView];
}

- (void)updateSonoDataToSonoView
{
    [self applyData:[mAudioRTOp sonoData] toView:mSonoView];
}

@end

@implementation AudioRTDisplayer (Display)

- (void)realTimeAmplitudeDisplay
{
    AudioDataAmplitude *data = [mAudioRTOp amplitudeData];
        
    FLOAT minX = [data minXOfChannel:mDisplayedChannel];
    FLOAT maxX = [data maxXOfChannel:mDisplayedChannel];
    FLOAT minY = [data minYOfChannel:mDisplayedChannel];
    FLOAT maxY = [data maxYOfChannel:mDisplayedChannel];
        
    [mAmplitudeView setRangeForXAxisFrom:minX to:maxX];

    if([mAudioRTOp amplitudeDisplayWindowMode] == NO)
        if(fabs(maxX-minX) >= [data displayWindowDuration])
            minX = MIN(0,maxX-[data displayWindowDuration]);
    
    [mAmplitudeView setVisualRangeForXAxisFrom:minX to:maxX];       
    if(mAmplitudeAutoYAxis)
    {
        [mAmplitudeView setRangeForYAxisFrom:minY to:maxY];       
        [mAmplitudeView setVisualRangeForYAxisFrom:minY to:maxY]; 
        [self audioViewScaleHasChanged:mAmplitudeView];      
    } else
        [mAmplitudeView setRangeForYAxisFrom:minY to:maxY];
}

- (void)realTimeFFTDisplay
{ 
    AudioDataFFT *data = [mAudioRTOp fftData];
    
    [mFFTView setDataSource:data];
    
    [mFFTView setRangeForXAxisFrom:[data minXOfChannel:mDisplayedChannel]
                                to:[data maxXOfChannel:mDisplayedChannel]];
    [mFFTView setVisualRangeForXAxisFrom:mFFTVisualMinX to:mFFTVisualMaxX];
    
    if(mFFTVisualMaxY==0 && mFFTVisualMinY==0)
    {
        mFFTVisualMaxY = [data maxYOfChannel:LEFT_CHANNEL];
        [mFFTView setRangeForYAxisFrom:[data minYOfChannel:mDisplayedChannel]
                                    to:[data maxYOfChannel:mDisplayedChannel]];
        [mFFTView setVisualRangeForYAxisFrom:[data minYOfChannel:mDisplayedChannel]
                                    to:[data maxYOfChannel:mDisplayedChannel]];
        [self audioViewScaleHasChanged:mFFTView];
    }
    
    if(mFFTAutoYAxis)
    {
        [mFFTView setRangeForYAxisFrom:[data minYOfChannel:mDisplayedChannel]
                                    to:[data maxYOfChannel:mDisplayedChannel]];
        [mFFTView setVisualRangeForYAxisFrom:[data minYOfChannel:mDisplayedChannel]
                                    to:[data maxYOfChannel:mDisplayedChannel]];
        [self audioViewScaleHasChanged:mFFTView];
    }
}

- (void)realTimeSonoDisplay
{
    [mSonoView setDataSource:[mAudioRTOp sonoData]];
    [mSonoView setVisualRangeForXAxisFrom:mSonoVisualMinX to:mSonoVisualMaxX];
    [mSonoView setVisualRangeForYAxisFrom:mSonoVisualMinY to:mSonoVisualMaxY];
}

- (void)refreshViews
{
	if(mLayoutViewID == AMPLITUDE_VIEW || mLayoutViewID == AMPLITUDE_FFT_VIEWS || mLayoutViewID == AMPLITUDE_SONO_VIEWS
		|| mLayoutViewID == AMPLITUDE_FFT_SONO_VIEWS)
	{
		[mAmplitudeView refreshSelf];
		[mAmplitudeView setNeedsDisplay:YES];
    }
	
	if(mLayoutViewID == FFT_VIEW || mLayoutViewID == AMPLITUDE_FFT_VIEWS || mLayoutViewID == FFT_SONO_VIEWS
		|| mLayoutViewID == AMPLITUDE_FFT_SONO_VIEWS)
	{
		[mFFTView refreshSelf];
		[mFFTView setNeedsDisplay:YES];
    }
	
	if(mLayoutViewID == SONO_VIEW || mLayoutViewID == AMPLITUDE_SONO_VIEWS
		|| mLayoutViewID == FFT_SONO_VIEWS || mLayoutViewID == AMPLITUDE_FFT_SONO_VIEWS)
	{
		[mAudioRTOp computeImage];
		[mSonoView refreshSelf];
		[mSonoView setNeedsDisplay:YES];
	}
}

- (void)realTimeDisplay
{
    [self realTimeAmplitudeDisplay];
    [self realTimeFFTDisplay];
    [self realTimeSonoDisplay];

    [self refreshViews];
}

- (void)displayTimer:(NSTimer*)timer
{
    [mAudioRTOp computeImage];
    [self realTimeDisplay];
}

- (void)recordCompleted:(AudioDataAmplitude*)audioData
{
}

- (void)recording:(AudioDataAmplitude*)audioData
{
    [mAudioRTOp compute];
}

@end

@implementation AudioRTDisplayer (Monitoring)

- (IBAction)toggleRTMonitoring:(id)sender
{
    if([mAudioRecorder isRecording])
        [self pauseMonitoring];
    else
        [self resumeMonitoring];
}

- (IBAction)startRTMonitoring:(id)sender
{    
    if(mMonitoring)
        if(mPaused)
            [self resumeMonitoring];
        else
            return;
        
    if(mAmplitudeView)
    {
        [self applyData:[mAudioRTOp amplitudeData] toView:mAmplitudeView];
        [mAmplitudeView setDisplayedChannel:mDisplayedChannel];
        [mAmplitudeView setRangeForYAxisFrom:mAmplitudeVisualMinY to:mAmplitudeVisualMaxY];       
        [mAmplitudeView setVisualRangeForYAxisFrom:mAmplitudeVisualMinY to:mAmplitudeVisualMaxY]; 
    }
    
    if(mFFTView)
    {
        [self updateFFTDataToFFTView];
        [mFFTView setDisplayedChannel:mDisplayedChannel];
        [mFFTView setRangeForYAxisFrom:mFFTVisualMinY to:mFFTVisualMaxY];
        [mFFTView setVisualRangeForYAxisFrom:mFFTVisualMinY to:mFFTVisualMaxY];
    }

    if(mSonoView)
    {
        [self updateSonoDataToSonoView];
        [mSonoView setDisplayedChannel:mDisplayedChannel];
        [mSonoView setRangeForYAxisFrom:mSonoVisualMinY to:mSonoVisualMaxY];
        [mSonoView setVisualRangeForYAxisFrom:mSonoVisualMinY to:mSonoVisualMaxY];
        [mSonoView setRangeForZAxisFrom:0 to:0.05]; //[[mAudioRTOp sonoData] maxZOfChannel:LEFT_CHANNEL]];
        [mSonoView setVisualRangeForZAxisFrom:0 to:0.05]; //[[mAudioRTOp sonoData] maxZOfChannel:LEFT_CHANNEL]];
    }
    
    [self applyLayout];

    [mAudioRTOp setBufferDuration:mBufferDuration];
    [mAudioRTOp setResolutionInterval:mMonitoringResolution];
    [mAudioRecorder setRecordingSelectorInterval:mMonitoringResolution];
        
    if([self startRTMonitoring_])
    {
        mMonitoring = YES;
        mPaused = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:AudioRTMonitoringStatusChangedNotification object:self];
    } else
        NSLog(@"Unable to START the RT Monitoring");
}

- (IBAction)stopRTMonitoring:(id)sender
{
    if(mMonitoring == NO) return;
    
    if([self stopRTMonitoring_])
    {
        mMonitoring = NO;
        mPaused = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:AudioRTMonitoringStatusChangedNotification object:self];
    } else
        NSLog(@"Unable to STOP the RT Monitoring");
}

- (void)pauseMonitoring
{
    if([self stopRTMonitoring_])
    {
        mPaused = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:AudioRTMonitoringStatusChangedNotification object:self];
    } else
        NSLog(@"Unable to PAUSE the RT Monitoring");
}

- (void)resumeMonitoring
{	
    if([self startRTMonitoring_])
    {
        mPaused = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:AudioRTMonitoringStatusChangedNotification object:self];
    } else
        NSLog(@"Unable to RESUME the RT Monitoring");
}

- (BOOL)startRTMonitoring_
{
    BOOL success = NO;
    
    if([mAudioRTOp start:mPaused])
    {
        if([self startTimers])
        {
            if([mAudioRecorder recordData:[mAudioRTOp amplitudeData] channel:STEREO_CHANNEL])
                success = YES;
            else
            {
                [self stopTimers];
                [mAudioRTOp stop];
            }
        } else
            [mAudioRTOp stop];
    }
    return success;
}

- (BOOL)stopRTMonitoring_
{
    BOOL success = NO;
    
    if([mAudioRTOp stop]
        && [self stopTimers]
        && [mAudioRecorder stopData:[mAudioRTOp amplitudeData]])
        success = YES;

    [self refreshViews];

    return success;
}

- (BOOL)monitoring
{
    return [mAudioRecorder isRecording];
}

@end

@implementation AudioRTDisplayer (Parameters)

- (void)initDefaultParameters
{
    mAmplitudeAutoYAxis = NO;
    mFFTAutoYAxis = NO;

    mFFTYAxisScale = YAxisLinearScale;

    mAmplitudeVisualMinX = 0;
    mAmplitudeVisualMaxX = mBufferDuration-1;
    mAmplitudeVisualMinY = -[[AudioDialogPrefs shared] fullScaleVoltage]*0.5;
    mAmplitudeVisualMaxY = [[AudioDialogPrefs shared] fullScaleVoltage]*0.5;
    
    mFFTVisualMinX = [[AudioDialogPrefs shared] rtFFTMinX];
    mFFTVisualMaxX = [[AudioDialogPrefs shared] rtFFTMaxX];
    mFFTVisualMinY = 0;
    mFFTVisualMaxY = 0;

    mSonoVisualMinX = -mBufferDuration;
    mSonoVisualMaxX = 0;
    mSonoVisualMinY = [[AudioDialogPrefs shared] rtSonoMinY];
    mSonoVisualMaxY = [[AudioDialogPrefs shared] rtSonoMaxY];
}

- (void)applyRangeFromAmplitudeView
{
    mAmplitudeVisualMinX = [mAmplitudeView xAxisVisualRangeFrom];
    mAmplitudeVisualMaxX = [mAmplitudeView xAxisVisualRangeTo];
    mAmplitudeVisualMinY = [mAmplitudeView yAxisVisualRangeFrom];
    mAmplitudeVisualMaxY = [mAmplitudeView yAxisVisualRangeTo];
}

- (void)applyRangeFromFFTView
{
    mFFTVisualMinX = [mFFTView xAxisVisualRangeFrom];
    mFFTVisualMaxX = [mFFTView xAxisVisualRangeTo];
    mFFTVisualMinY = [mFFTView yAxisVisualRangeFrom];
    mFFTVisualMaxY = [mFFTView yAxisVisualRangeTo];    
}

- (void)applyRangeFromSonoView
{
    mSonoVisualMinX = [mSonoView xAxisVisualRangeFrom];
    mSonoVisualMaxX = [mSonoView xAxisVisualRangeTo];
    mSonoVisualMinY = [mSonoView yAxisVisualRangeFrom];
    mSonoVisualMaxY = [mSonoView yAxisVisualRangeTo];
}

- (void)setAmplitudeDisplayWindowMode:(BOOL)flag
{
    [mAudioRTOp setAmplitudeDisplayWindowMode:flag];
}

- (BOOL)amplitudeDisplayWindowMode
{
    return [mAudioRTOp amplitudeDisplayWindowMode];
}

- (void)setTriggerState:(BOOL)flag
{
    [mAudioRTOp setTriggerState:flag];
}

- (BOOL)triggerState
{
    return [mAudioRTOp triggerState];
}

- (void)setTriggerSlope:(USHORT)slope
{
    [mAudioRTOp setTriggerSlope:slope];
}

- (USHORT)triggerSlope
{
    return [mAudioRTOp triggerSlope];
}

- (void)setTriggerOffset:(FLOAT)offset
{
    [mAudioRTOp setTriggerOffset:offset];
}

- (FLOAT)triggerOffset
{
    return [mAudioRTOp triggerOffset];
}

- (NSString*)triggerOffsetUnit
{
    return [mAudioRTOp triggerOffsetUnit];
}

- (NSString*)amplitudeYAxisUnit
{
    return [mAudioRTOp amplitudeYAxisUnit];
}

- (void)setAmplitudeAutoYAxis:(BOOL)value
{
    mAmplitudeAutoYAxis = value;
}
- (void)setFFTAutoYAxis:(BOOL)value
{
    mFFTAutoYAxis = value;
}

- (BOOL)amplitudeAutoYAxis
{
    return mAmplitudeAutoYAxis;
}
- (BOOL)fftAutoYAxis
{
    return mFFTAutoYAxis;
}

- (void)setFFTXAxisScale:(SHORT)scale
{
    if(mFFTXAxisScale == scale) return;
    
    mFFTXAxisScale = scale;
    AudioDataFFT *data = [mAudioRTOp fftData];
    if(data)
    {
        [data setXAxisScale:mFFTXAxisScale];
        
        [self updateFFTDataToFFTView];
    }
}

- (int)fftXAxisScale
{
	return mFFTXAxisScale;
}

- (void)setFFTYAxisScale:(SHORT)scale
{
    if(mFFTYAxisScale == scale) return;
    
    mFFTYAxisScale = scale;
    AudioDataFFT *data = [mAudioRTOp fftData];
    if(data)
    {
        [data setYAxisScale:mFFTYAxisScale];
        
        [self updateFFTDataToFFTView];
        if(mFFTView)
        {
            [mFFTView setVisualRangeForYAxisFrom:MAX(-40, [data minYOfChannel:mDisplayedChannel])
                                to:[data maxYOfChannel:mDisplayedChannel]];
            [mFFTView refresh];
            [self applyRangeFromFFTView];
        }
    }
}

- (int)fftYAxisScale
{
	return mFFTYAxisScale;
}

- (void)adjustAmplitudeYAxis
{
    FLOAT minY = [[mAudioRTOp amplitudeData] minYOfChannel:mDisplayedChannel];
    FLOAT maxY = [[mAudioRTOp amplitudeData] maxYOfChannel:mDisplayedChannel];
    [mAmplitudeView setVisualRangeForYAxisFrom:minY to:maxY];   
    [mAmplitudeView refresh]; 
    [self applyRangeFromAmplitudeView];   
}

#define MIN_AXIS(value, axis) (value<axis) ? axis:value
#define MAX_AXIS(value, axis) (value>axis) ? axis:value

- (void)checkAmplitudeRange
{
    mAmplitudeVisualMinX = MIN_AXIS(mAmplitudeVisualMinX, [[mAudioRTOp amplitudeData] minXOfChannel:mDisplayedChannel]);
    mAmplitudeVisualMaxX = MAX_AXIS(mAmplitudeVisualMaxX, [[mAudioRTOp amplitudeData] maxXOfChannel:mDisplayedChannel]);
}

- (void)checkFFTRange
{
    mFFTVisualMinX = MIN_AXIS(mFFTVisualMinX, [[mAudioRTOp fftData] minXOfChannel:mDisplayedChannel]);
    mFFTVisualMaxX = MAX_AXIS(mFFTVisualMaxX, [[mAudioRTOp fftData] maxXOfChannel:mDisplayedChannel]);
}

- (void)checkSonoRange
{
    mSonoVisualMinX = MIN_AXIS(mSonoVisualMinX, [[mAudioRTOp sonoData] minXOfChannel:mDisplayedChannel]);
    mSonoVisualMaxX = MAX_AXIS(mSonoVisualMaxX, [[mAudioRTOp sonoData] maxXOfChannel:mDisplayedChannel]);
}

- (void)applyAmplitudeRangeToView
{
    [mAmplitudeView setVisualRangeForYAxisFrom:mAmplitudeVisualMinY to:mAmplitudeVisualMaxY];       
}

- (void)applyFFTRangeToView
{
    [mFFTView setVisualRangeForYAxisFrom:mFFTVisualMinY to:mFFTVisualMaxY];       
}

- (void)setAmplitudeVisualMinX:(FLOAT)value
{
    mAmplitudeVisualMinX = value;
}
- (void)setAmplitudeVisualMaxX:(FLOAT)value
{
    mAmplitudeVisualMaxX = value;
}
- (void)setAmplitudeVisualMinY:(FLOAT)value
{
    mAmplitudeVisualMinY = value;
}
- (void)setAmplitudeVisualMaxY:(FLOAT)value
{
    mAmplitudeVisualMaxY = value;
}

- (void)setFFTVisualMinX:(FLOAT)value
{
    mFFTVisualMinX = value;
}
- (void)setFFTVisualMaxX:(FLOAT)value
{
    mFFTVisualMaxX = value;
}
- (void)setFFTVisualMinY:(FLOAT)value
{
    mFFTVisualMinY = value;
}
- (void)setFFTVisualMaxY:(FLOAT)value
{
    mFFTVisualMaxY = value;
}

- (FLOAT)amplitudeVisualMinX
{
    return mAmplitudeVisualMinX;
}
- (FLOAT)amplitudeVisualMaxX
{
    return mAmplitudeVisualMaxX;
}
- (FLOAT)amplitudeVisualMinY
{
    return mAmplitudeVisualMinY;
}
- (FLOAT)amplitudeVisualMaxY
{
    return mAmplitudeVisualMaxY;
}

- (FLOAT)fftVisualMinX
{
    return mFFTVisualMinX;
}
- (FLOAT)fftVisualMaxX
{
    return mFFTVisualMaxX;
}
- (FLOAT)fftVisualMinY
{
    return mFFTVisualMinY;
}
- (FLOAT)fftVisualMaxY
{
    return mFFTVisualMaxY;
}

@end

@implementation AudioRTDisplayer (Delegate)

- (void)audioViewTriggerCursorHasChanged:(AudioView*)view
{
    if([mDelegate respondsToSelector:@selector(audioViewTriggerCursorHasChanged:)])
        [mDelegate performSelector:@selector(audioViewTriggerCursorHasChanged:) withObject:view];
}

- (void)audioViewScaleHasChanged:(AudioView*)view
{
    if(view == mAmplitudeView)
        [self applyRangeFromAmplitudeView];
    else if(view == mFFTView)
        [self applyRangeFromFFTView];
    else if(view == mSonoView)
        [self applyRangeFromSonoView];
    
    if([mDelegate respondsToSelector:@selector(scaleHasChanged:)])
        [mDelegate performSelector:@selector(scaleHasChanged:) withObject:view];
}

- (void)audioViewCursorHasChanged:(AudioView*)view
{
    if(view == mSonoView && [self monitoring] == NO)
    {
        [mAudioRTOp displayFFTOfSonoAtX:[view xCursorPosition]];
        [mFFTView applyDataSourceToView];
        [mFFTView refresh];
    }
}

- (void)devicesChangedNotification:(NSNotification*)notif
{
    if(mMonitoring && mPaused == NO)
    {
        [self pauseMonitoring];
        [self resumeMonitoring];
    }
}

- (void)deviceIsAliveNotification:(NSNotification*)notif
{
    AudioDeviceObject *theAudioDeviceObject = [notif object];
    if([mAudioRecorder inputDeviceID] == [theAudioDeviceObject deviceID])
    {
        if([theAudioDeviceObject isInputAlive] == NO && [self monitoring])
            [self stopRTMonitoring:self];
    }
}

- (BOOL)performInspectorKeyEquivalent:(NSEvent*)event
{
	return [mDelegate performInspectorKeyEquivalent:event];
}

@end

@implementation AudioRTDisplayer (Objects)

- (AudioRecorder*)audioRecorder
{
    return mAudioRecorder;
}

@end

@implementation AudioRTDisplayer (Timers)

- (BOOL)startTimers
{
    [mDisplayTimer release];
    mDisplayTimer = [[NSTimer scheduledTimerWithTimeInterval:mMonitoringInterval target:self selector:@selector(displayTimer:) userInfo:NULL repeats:YES] retain];

	[[NSRunLoop currentRunLoop] addTimer:mDisplayTimer forMode:NSEventTrackingRunLoopMode];

    return YES;
}

- (BOOL)stopTimers
{
    [mDisplayTimer invalidate];
    return YES;
}

@end
