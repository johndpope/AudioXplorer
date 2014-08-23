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

#import "AudioInspectorRT.h"
#import "AudioInspectorController.h"
#import "AudioRTWindowController.h"
#import "AudioNotifications.h"

#define MIN_VIEW_INDEX 0
#define MAX_VIEW_INDEX 4

@implementation AudioInspectorRT

- (id)init
{
    if(self = [super init])
    {
        mViewAmplitudeAppearanceController = [[AudioViewAppearanceController alloc] init];
        mViewFFTAppearanceController = [[AudioViewAppearanceController alloc] init];
        mViewSonoAppearanceController = [[AudioViewAppearanceController alloc] init];
        mDataSonoAppearanceController = [[AudioSonoAppearanceController alloc] init];

        [mDataSonoAppearanceController setDelegate:self];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(devicesChangedNotification:) 
													 name:CADeviceManagerDevicesChangedNotification
												   object:NULL];
		
        mAmplitudeWindowTitleArray = NULL;
        mAmplitudeWindowDurationArray = NULL;

        mInspectorView = NULL;
        
        mValidTarget = NO;
        mLastDisplayIndex = 0;
    }
    return self;
}

- (void)dealloc
{
    [mViewAmplitudeAppearanceController release];
    [mViewFFTAppearanceController release];
    [mViewSonoAppearanceController release];
    [mDataSonoAppearanceController release];

    [mAmplitudeWindowTitleArray release];
    [mAmplitudeWindowDurationArray release];

    [super dealloc];
}

- (void)windowDidLoad
{
    [AudioInspectorRT fillLayoutIDPopUp:mLayoutPopUp];
    [AudioInspectorRT fillBufferDurationPopUp:mBufferDurationPopUp];	
}

- (void)setNoMainWindow
{	
	// WARNING: do the following method call before settings the mAudioRTDisplayer to NULL!
	[self popChannelMixerView];

    mAudioRTDisplayer = NULL;
    mValidTarget = NO;
    [mViewAmplitudeAppearanceController setView:NULL];
    [mViewFFTAppearanceController setView:NULL];
    [mViewSonoAppearanceController setView:NULL];
}

- (void)setMainWindow:(NSWindow*)mainWindow
{
    NSWindowController *controller = [mainWindow windowController];
    if([controller isKindOfClass:[AudioRTWindowController class]])
    {
        mValidTarget = YES;
        [self setupInspectorPopUp];
        [self displayViewAtIndex:mLastDisplayIndex];
        [self setAudioRTDisplayer:[(AudioRTWindowController*)controller audioRTDisplayer]];
		[self pushChannelMixerView];
    } else
        [self setNoMainWindow];
}

- (void)resignMainWindow:(NSWindow*)mainWindow
{
    NSWindowController *controller = [mainWindow windowController];
    if([controller isKindOfClass:[AudioRTWindowController class]])
    {
        [self setNoMainWindow];
    }
}

- (void)setupInspectorPopUp
{
    [mInspectorPopUp removeAllItems];
    [mInspectorPopUp addItemWithTitle:NSLocalizedString(@"General", NULL)];
    [mInspectorPopUp addItemWithTitle:NSLocalizedString(@"Oscilloscope", NULL)];
    [mInspectorPopUp addItemWithTitle:NSLocalizedString(@"Spectrum", NULL)];
    [mInspectorPopUp addItemWithTitle:NSLocalizedString(@"Sonogram", NULL)];
    [mInspectorPopUp addItemWithTitle:NSLocalizedString(@"ChannelsMixer", NULL)];
    
    USHORT index;
    for(index=0; index<[mInspectorPopUp numberOfItems]; index++)
    {
        NSMenuItem *item = [mInspectorPopUp itemAtIndex:index];
        [item setKeyEquivalent:[NSString stringWithFormat:@"%d", index+1]];
        [item setKeyEquivalentModifierMask:NSCommandKeyMask];
        [item setTarget:self];
        [item setAction:@selector(inspectorPopUpAction:)];
        [item setTag:index];
    }
    [mInspectorPopUp synchronizeTitleAndSelectedItem];
    [mInspectorPopUp selectItemAtIndex:mLastDisplayIndex];
}

- (void)inspectorPopUpAction:(id)sender
{
    if(mValidTarget)
        [self displayViewAtIndex:[sender tag]];
}

- (void)displayViewAtIndex:(int)index
{
	if(index<MIN_VIEW_INDEX || index>MAX_VIEW_INDEX)
		return;
	
    mLastDisplayIndex = index;
    mInspectorView = NULL;
    switch(index) {
        case 0:
            mInspectorView = mViewLayout;
            break;
        case 1:
            mInspectorView = mViewAmplitude;
            break;
        case 2:
            mInspectorView = mViewFFT;
            break;
        case 3:
            mInspectorView = mViewSono;
            break;
        case 4:
            mInspectorView = mViewChannelMixer;
            break;
    }

    if(mInspectorView)
        [AudioInspectorController setContentView:mInspectorView resize:YES];
}

- (NSView*)view
{
    return mInspectorView;
}

- (void)toggleRTMonitoring
{
    if(mValidTarget)
    {
        [mAudioRTDisplayer toggleRTMonitoring:self];
    }
}

- (void)rtLayoutChanged
{
    [mLayoutPopUp selectItemAtIndex:[AudioInspectorRT itemIndexOfLayoutID:[mAudioRTDisplayer layoutID]]];
}

- (void)changeRTLayout:(USHORT)key
{
    [mAudioRTDisplayer setLayoutByKey:key];
    [self rtLayoutChanged];
}

- (void)applyAmplitudeRangeFromAudioRTDisplayer
{
    [mAmplitudeVisualMinY setFloatValue:[mAudioRTDisplayer amplitudeVisualMinY]];
    [mAmplitudeVisualMaxY setFloatValue:[mAudioRTDisplayer amplitudeVisualMaxY]];
}

- (void)applyFFTRangeFromAudioRTDisplayer
{
	if([mAudioRTDisplayer fftXAxisScale] == XAxisLogScale) {
		[mFFTVisualMinXLog setFloatValue:log10([mAudioRTDisplayer fftVisualMinX])];
		[mFFTVisualMaxXLog setFloatValue:log10([mAudioRTDisplayer fftVisualMaxX])];
	} else {
		[mFFTVisualMinX setFloatValue:[mAudioRTDisplayer fftVisualMinX]];
		[mFFTVisualMaxX setFloatValue:[mAudioRTDisplayer fftVisualMaxX]];		
	}
    [mFFTVisualMinY setFloatValue:[mAudioRTDisplayer fftVisualMinY]];
    [mFFTVisualMaxY setFloatValue:[mAudioRTDisplayer fftVisualMaxY]];
}

- (void)setAudioRTDisplayer:(AudioRTDisplayer*)displayer
{
    mAudioRTDisplayer = displayer;
    
    [mAudioRTDisplayer setDelegate:self];
	
    [self applyAmplitudeRangeFromAudioRTDisplayer];
    [self applyFFTRangeFromAudioRTDisplayer];

    [self setupAmplitudeWindowPopUp];

    [mBufferDurationPopUp selectItemAtIndex:[AudioInspectorRT itemIndexOfBufferDuration:[mAudioRTDisplayer bufferDuration]]];
    [mLayoutPopUp selectItemAtIndex:[AudioInspectorRT itemIndexOfLayoutID:[mAudioRTDisplayer layoutID]]];
    
    [mAmplitudeDisplayModeCheckBox setState:[mAudioRTDisplayer amplitudeDisplayWindowMode]];
    
    [mTriggerCheckBox setState:[mAudioRTDisplayer triggerState]];
    [mTriggerSlopeMatrix selectCellWithTag:[mAudioRTDisplayer triggerSlope]];
    [mTriggerOffsetValue setFloatValue:[mAudioRTDisplayer triggerOffset]];
    [mTriggerOffsetUnit setStringValue:[mAudioRTDisplayer triggerOffsetUnit]];
    
    [mAmplitudeRangePopUp selectItemAtIndex:[self itemForAmplitudeRange:[mAudioRTDisplayer amplitudeRange]]];
    [mAmplitudeYAxisUnit setStringValue:[mAudioRTDisplayer amplitudeYAxisUnit]];
        	
	[mFFTXAxisScalePopUp selectItemAtIndex:[mAudioRTDisplayer fftXAxisScale]];
	[mFFTXAxisScaleTabView selectTabViewItemAtIndex:[mAudioRTDisplayer fftXAxisScale]];

	[mFFTYAxisScalePopUp selectItemAtIndex:[mAudioRTDisplayer fftYAxisScale]];
	
    [mAmplitudeAutoYAxis setState:[mAudioRTDisplayer amplitudeAutoYAxis]];
    [mFFTAutoYAxis setIntValue:[mAudioRTDisplayer fftAutoYAxis]];
    
    [mViewAmplitudeAppearanceController setContainerBox:mAmplitudeAppearanceBox];
    [mViewFFTAppearanceController setContainerBox:mFFTAppearanceBox];
    [mViewSonoAppearanceController setContainerBox:mSonoViewAppearanceBox];
    [mDataSonoAppearanceController setContainerBox:mSonoDataAppearanceBox];

    [mViewAmplitudeAppearanceController setView:[mAudioRTDisplayer amplitudeView]];
    [mViewFFTAppearanceController setView:[mAudioRTDisplayer fftView]];
    [mViewSonoAppearanceController setView:[mAudioRTDisplayer sonoView]];
    [mDataSonoAppearanceController setSonoData:[mAudioRTDisplayer sonoData]];
    
    [self adjustAmplitudeViewGUI];
}

@end

@implementation AudioInspectorRT (GeneralView)

+ (void)fillLayoutIDPopUp:(NSPopUpButton*)popUp
{
    [popUp removeAllItems];
    [popUp addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"All views", NULL),
                                                        NSLocalizedString(@"Oscilloscope", NULL),
                                                        NSLocalizedString(@"Spectrum", NULL),
                                                        NSLocalizedString(@"Sonogram", NULL),
                                                        NSLocalizedString(@"Oscilloscope+Spectrum", NULL),
                                                        NSLocalizedString(@"Oscilloscope+Sonogram", NULL),
                                                        NSLocalizedString(@"Spectrum+Sonogram", NULL),
                                                        NULL]];
    
    [[popUp menu] insertItem:[NSMenuItem separatorItem] atIndex:4];
    [[popUp menu] insertItem:[NSMenuItem separatorItem] atIndex:1];
}

+ (void)fillBufferDurationPopUp:(NSPopUpButton*)popUp
{
    [popUp removeAllItems];
    [popUp addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"2 s", NULL),
                                                        NSLocalizedString(@"5 s", NULL),
                                                        NSLocalizedString(@"10 s", NULL),
                                                        NSLocalizedString(@"20 s", NULL),
                                                        NSLocalizedString(@"30 s", NULL),
                                                        NSLocalizedString(@"1 mn", NULL),
                                                        NSLocalizedString(@"2 mn", NULL),
                                                        NULL]];
}

+ (USHORT)layoutIDOfPopUp:(NSPopUpButton*)popUp
{
    switch([popUp indexOfSelectedItem]) {
        case 0:		// All
            return 6;
        case 2:		// Single
            return 0;
        case 3:
            return 1;
        case 4:
            return 2;
        case 6:		// Multiple
            return 3;
        case 7:
            return 4;
        case 8:
            return 5;
    }
    return 6;
}

+ (USHORT)itemIndexOfLayoutID:(USHORT)layoutID
{
    switch(layoutID) {
        case 0:		// Single
            return 2;
        case 1:
            return 3;
        case 2:
            return 4;
        case 3:		// Multiple
            return 6;
        case 4:
            return 7;
        case 5:
            return 8;
        case 6:		// All
            return 0;
    }
    return 0;
}

+ (FLOAT)bufferDurationOfPopUp:(NSPopUpButton*)popUp
{
    switch([popUp indexOfSelectedItem]) {
        case 0:
            return 2;
        case 1:
            return 5;
        case 2:
            return 10;
        case 3:
            return 20;
        case 4:	
            return 30;
        case 5:
            return 60;
        case 6:
            return 120;
    }
    return 5;
}

+ (USHORT)itemIndexOfBufferDuration:(FLOAT)duration
{
    switch((int)duration) {
        case 2:
            return 0;
        case 5:
            return 1;
        case 10:
            return 2;
        case 20:
            return 3;
        case 30:
            return 4;
        case 60:
            return 5;
        case 120:
            return 6;
    }
    return 1;
}

- (IBAction)bufferDurationAction:(id)sender
{
    [mAudioRTDisplayer setBufferDuration:[AudioInspectorRT bufferDurationOfPopUp:sender]];
}

- (IBAction)layoutPopUpAction:(id)sender
{
    [mAudioRTDisplayer setLayoutID:[AudioInspectorRT layoutIDOfPopUp:sender]];
}

@end

@implementation AudioInspectorRT (AmplitudeView)

- (void)adjustAmplitudeViewGUI
{
    BOOL enabled = [mAmplitudeDisplayModeCheckBox state] == NSOnState;
    
    [mTriggerCheckBox setEnabled:enabled];
    [mTriggerSlopeMatrix setEnabled:enabled];
    [mTriggerOffsetValue setEnabled:enabled];
    [mTriggerOffsetUnit setEnabled:enabled];
}

- (IBAction)triggerCheckBoxAction:(id)sender
{
    [mAudioRTDisplayer setTriggerState:[sender state] == NSOnState];
}

- (IBAction)triggerSlopeMatrixAction:(id)sender
{
    [mAudioRTDisplayer setTriggerSlope:[[sender selectedCell] tag]];
}

- (IBAction)triggerOffsetAction:(id)sender
{
    [mAudioRTDisplayer setTriggerOffset:[sender floatValue]];
}

- (void)setupAmplitudeWindowPopUp
{
    [mAmplitudeWindowTitleArray release];
    [mAmplitudeWindowDurationArray release];
    
    mAmplitudeWindowTitleArray = [NSArray arrayWithObjects:@"0.5 ms",
                                                    @"1 ms",
                                                    @"5 ms",
                                                    @"10 ms",
                                                    @"20 ms",
                                                    @"30 ms",
                                                    @"50 ms",
                                                    @"100 ms",
                                                    @"200 ms",
                                                    @"500 ms",
                                                    @"1 s",
                                                    @"2 s",
                                                    @"5 s",
                                                    NULL];
                                                    
    mAmplitudeWindowDurationArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0005],
                                                    [NSNumber numberWithFloat:0.001],
                                                    [NSNumber numberWithFloat:0.005],
                                                    [NSNumber numberWithFloat:0.01],
                                                    [NSNumber numberWithFloat:0.02],
                                                    [NSNumber numberWithFloat:0.03],
                                                    [NSNumber numberWithFloat:0.05],
                                                    [NSNumber numberWithFloat:0.1],
                                                    [NSNumber numberWithFloat:0.2],
                                                    [NSNumber numberWithFloat:0.5],
                                                    [NSNumber numberWithFloat:1],
                                                    [NSNumber numberWithFloat:2],
                                                    [NSNumber numberWithFloat:5],
                                                    NULL];                                

    [mAmplitudeWindowTitleArray retain];
    [mAmplitudeWindowDurationArray retain];
    
    [mAmplitudeRangePopUp removeAllItems];
    [mAmplitudeRangePopUp addItemsWithTitles:mAmplitudeWindowTitleArray];
}

- (FLOAT)amplitudeRangeForItem:(SHORT)item
{
    return [[mAmplitudeWindowDurationArray objectAtIndex:item] floatValue];
}

- (SHORT)itemForAmplitudeRange:(FLOAT)range
{
    return [mAmplitudeWindowDurationArray indexOfObject:[NSNumber numberWithFloat:range]];
}

- (IBAction)amplitudeDisplayWindowModeAction:(id)sender
{
    [mAudioRTDisplayer setAmplitudeDisplayWindowMode:[sender state] == NSOnState];
    [self adjustAmplitudeViewGUI];
}

- (IBAction)amplitudeRangeAction:(id)sender
{
    [mAudioRTDisplayer setAmplitudeRange:[self amplitudeRangeForItem:[sender indexOfSelectedItem]]];
}

- (IBAction)amplitudeVisualTextField:(id)sender
{
    [mAudioRTDisplayer setAmplitudeVisualMinY:[mAmplitudeVisualMinY floatValue]];
    [mAudioRTDisplayer setAmplitudeVisualMaxY:[mAmplitudeVisualMaxY floatValue]];
    [mAudioRTDisplayer checkAmplitudeRange];
    [mAudioRTDisplayer applyAmplitudeRangeToView];
    [self applyAmplitudeRangeFromAudioRTDisplayer];
}

- (IBAction)amplitudeAdjustYAxis:(id)sender
{
    [mAudioRTDisplayer adjustAmplitudeYAxis];
    [self applyAmplitudeRangeFromAudioRTDisplayer];
}

- (IBAction)amplitudeAutoYAxis:(id)sender
{
    [mAudioRTDisplayer setAmplitudeAutoYAxis:[sender state] == NSOnState];
}

@end

@implementation AudioInspectorRT (FFTView)

- (IBAction)fftVisualTextField:(id)sender
{
	if([mAudioRTDisplayer fftXAxisScale] == XAxisLogScale) {
		[mAudioRTDisplayer setFFTVisualMinX:pow10([mFFTVisualMinXLog floatValue])];
		[mAudioRTDisplayer setFFTVisualMaxX:pow10([mFFTVisualMaxXLog floatValue])];		
	} else {
		[mAudioRTDisplayer setFFTVisualMinX:[mFFTVisualMinX floatValue]];
		[mAudioRTDisplayer setFFTVisualMaxX:[mFFTVisualMaxX floatValue]];		
	}
    [mAudioRTDisplayer setFFTVisualMinY:[mFFTVisualMinY floatValue]];
    [mAudioRTDisplayer setFFTVisualMaxY:[mFFTVisualMaxY floatValue]];
    [mAudioRTDisplayer checkFFTRange];
    [mAudioRTDisplayer applyFFTRangeToView];
    [self applyFFTRangeFromAudioRTDisplayer];
}

- (IBAction)fftXAxisScale:(id)sender
{
    SHORT scale = XAxisLinearScale;
    
    if([sender indexOfSelectedItem]==1)
        scale = XAxisLogScale;
	
	if(scale != [mAudioRTDisplayer fftXAxisScale]) {
		if(scale == XAxisLogScale) {
			[mFFTVisualMinXLog setFloatValue:[mFFTVisualMinX floatValue]>0?round(log10([mFFTVisualMinX floatValue])):3];
			[mFFTVisualMaxXLog setFloatValue:[mFFTVisualMaxX floatValue]>0?round(log10([mFFTVisualMaxX floatValue])):3];
		} else {
			[mFFTVisualMinX setFloatValue:pow10([mFFTVisualMinXLog floatValue])];
			[mFFTVisualMaxX setFloatValue:pow10([mFFTVisualMaxXLog floatValue])];
		}
		
		[mFFTXAxisScaleTabView selectTabViewItemAtIndex:[mFFTXAxisScalePopUp indexOfSelectedItem]];
		
		[mAudioRTDisplayer setFFTXAxisScale:scale];
		[self applyFFTRangeFromAudioRTDisplayer];		
	}
}

- (IBAction)fftYAxisScale:(id)sender
{
    SHORT scale = YAxisLinearScale;
    
    if([sender indexOfSelectedItem]==1)
        scale = YAxisLogScale;

    [mAudioRTDisplayer setFFTYAxisScale:scale];
    [self applyFFTRangeFromAudioRTDisplayer];
}

- (IBAction)fftAutoYAxis:(id)sender
{
    [mAudioRTDisplayer setFFTAutoYAxis:[sender intValue]];
}

@end

@implementation AudioInspectorRT (ChannelMixer)

- (void)pushChannelMixerView
{
	[mInputDeviceTextField setStringValue:[[AudioDeviceManager shared] currentInputDeviceTitle]];
	[mOutputDeviceTextField setStringValue:[[AudioDeviceManager shared] currentOutputDeviceTitle]];
	
	[[[[mAudioRTDisplayer audioRecorder] playthruDevice] channelMixer] addTableView:mChannelMixerTableView];
	[[[[mAudioRTDisplayer audioRecorder] playthruDevice] channelMixer] reloadAllTableView];
}

- (void)popChannelMixerView
{
	[[[[mAudioRTDisplayer audioRecorder] playthruDevice] channelMixer] removeTableView:mChannelMixerTableView];
}

@end

@implementation AudioInspectorRT (Notification)

- (void)devicesChangedNotification:(NSNotification*)notif
{
	NSString *title = [[AudioDeviceManager shared] currentInputDeviceTitle];
	[mInputDeviceTextField setStringValue:title?title:@""];
	title = [[AudioDeviceManager shared] currentOutputDeviceTitle];
	[mOutputDeviceTextField setStringValue:title?title:@""];
}

@end

@implementation AudioInspectorRT (Delegate)

- (void)sonoDataAppearanceHasChanged
{
    [[mAudioRTDisplayer sonoData] createImage];
    [[mAudioRTDisplayer sonoView] setNeedsDisplay:YES];
}

- (void)audioViewTriggerCursorHasChanged:(AudioView*)view
{
    [mTriggerOffsetValue setFloatValue:[mAudioRTDisplayer triggerOffset]];
}

- (void)scaleHasChanged:(AudioView*)view
{
    if(view == [mAudioRTDisplayer amplitudeView])
        [self applyAmplitudeRangeFromAudioRTDisplayer];
    if(view == [mAudioRTDisplayer fftView])
        [self applyFFTRangeFromAudioRTDisplayer];
}

- (BOOL)performInspectorKeyEquivalent:(NSEvent*)event
{
	NSString *chars = [event charactersIgnoringModifiers];
	if([chars intValue]-1<MIN_VIEW_INDEX || [chars intValue]-1>MAX_VIEW_INDEX)
		return NO;
	
	if(![mInspectorWindow isVisible]) {
		[mInspectorWindow makeKeyAndOrderFront:self];
	}
	[self displayViewAtIndex:[chars intValue]-1];
	
	return YES;
}

@end