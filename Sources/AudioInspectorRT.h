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

#import <AppKit/AppKit.h>
#import "AudioRTDisplayer.h"
#import "AudioViewAppearanceController.h"
#import "AudioSonoAppearanceController.h"

@interface AudioInspectorRT : NSObject
{
    AudioRTDisplayer *mAudioRTDisplayer;

    AudioViewAppearanceController *mViewAmplitudeAppearanceController;
    AudioViewAppearanceController *mViewFFTAppearanceController;
    AudioViewAppearanceController *mViewSonoAppearanceController;
    
    AudioSonoAppearanceController *mDataSonoAppearanceController;

    NSArray *mAmplitudeWindowTitleArray;
    NSArray *mAmplitudeWindowDurationArray;

    BOOL mValidTarget;
    USHORT mLastDisplayIndex;
    
    // Inspector popup menu

    IBOutlet NSPopUpButton *mInspectorPopUp;

    NSView *mInspectorView;
    IBOutlet NSWindow *mInspectorWindow;
    IBOutlet NSView *mViewLayout;
    IBOutlet NSView *mViewAmplitude;
    IBOutlet NSView *mViewFFT;
    IBOutlet NSView *mViewSono;
    IBOutlet NSView *mViewChannelMixer;
    
    // General view
    
    IBOutlet NSPopUpButton *mBufferDurationPopUp;
    IBOutlet NSPopUpButton *mLayoutPopUp;
        
    // Amplitude view

    IBOutlet NSPopUpButton *mAmplitudeRangePopUp;
    IBOutlet NSButton *mAmplitudeDisplayModeCheckBox;

    IBOutlet NSButton *mTriggerCheckBox;
    IBOutlet NSMatrix *mTriggerSlopeMatrix;
    IBOutlet NSTextField *mTriggerOffsetValue;
    IBOutlet NSTextField *mTriggerOffsetUnit;
        
        // Other
    IBOutlet NSTextField *mAmplitudeVisualMinY;
    IBOutlet NSTextField *mAmplitudeVisualMaxY;
    IBOutlet NSTextField *mAmplitudeYAxisUnit;
    IBOutlet NSButton *mAmplitudeAutoYAxis;
    IBOutlet NSBox *mAmplitudeAppearanceBox;

    // FFT view
    
	IBOutlet NSTabView *mFFTXAxisScaleTabView;
	IBOutlet NSPopUpButton *mFFTXAxisScalePopUp;
	IBOutlet NSPopUpButton *mFFTYAxisScalePopUp;
    IBOutlet NSButton *mFFTAutoYAxis;
    IBOutlet NSTextField *mFFTVisualMinX;
    IBOutlet NSTextField *mFFTVisualMaxX;
    IBOutlet NSTextField *mFFTVisualMinXLog;
    IBOutlet NSTextField *mFFTVisualMaxXLog;
    IBOutlet NSTextField *mFFTVisualMinY;
    IBOutlet NSTextField *mFFTVisualMaxY;
    IBOutlet NSBox *mFFTAppearanceBox;
    
    // Sono view
    
    IBOutlet NSBox *mSonoDataAppearanceBox;
    IBOutlet NSBox *mSonoViewAppearanceBox;
	
	// Channel Mixer view
	
	IBOutlet NSTableView *mChannelMixerTableView;
	IBOutlet NSTextField *mInputDeviceTextField;
	IBOutlet NSTextField *mOutputDeviceTextField;
}

- (void)windowDidLoad;
- (void)setNoMainWindow;
- (void)setMainWindow:(NSWindow*)mainWindow;
- (void)resignMainWindow:(NSWindow*)mainWindow;

- (void)setupInspectorPopUp;
- (void)displayViewAtIndex:(int)index;
- (NSView*)view;

- (void)toggleRTMonitoring;
- (void)rtLayoutChanged;
- (void)changeRTLayout:(USHORT)key;

- (void)applyAmplitudeRangeFromAudioRTDisplayer;
- (void)applyFFTRangeFromAudioRTDisplayer;
- (void)setAudioRTDisplayer:(AudioRTDisplayer*)displayer;
@end

@interface AudioInspectorRT (GeneralView)

+ (void)fillLayoutIDPopUp:(NSPopUpButton*)popUp;
+ (void)fillBufferDurationPopUp:(NSPopUpButton*)popUp;

+ (USHORT)layoutIDOfPopUp:(NSPopUpButton*)popUp;
+ (USHORT)itemIndexOfLayoutID:(USHORT)layoutID;

+ (FLOAT)bufferDurationOfPopUp:(NSPopUpButton*)popUp;
+ (USHORT)itemIndexOfBufferDuration:(FLOAT)duration;

- (IBAction)bufferDurationAction:(id)sender;
- (IBAction)layoutPopUpAction:(id)sender;

@end

@interface AudioInspectorRT (AmplitudeView)
- (void)adjustAmplitudeViewGUI;
- (IBAction)triggerCheckBoxAction:(id)sender;
- (IBAction)triggerSlopeMatrixAction:(id)sender;
- (IBAction)triggerOffsetAction:(id)sender;
- (void)setupAmplitudeWindowPopUp;
- (SHORT)itemForAmplitudeRange:(FLOAT)range;
- (IBAction)amplitudeDisplayWindowModeAction:(id)sender;
- (IBAction)amplitudeRangeAction:(id)sender;
- (IBAction)amplitudeVisualTextField:(id)sender;
- (IBAction)amplitudeAdjustYAxis:(id)sender;
- (IBAction)amplitudeAutoYAxis:(id)sender;
@end

@interface AudioInspectorRT (FFTView)
- (IBAction)fftVisualTextField:(id)sender;
- (IBAction)fftXAxisScale:(id)sender;
- (IBAction)fftYAxisScale:(id)sender;
- (IBAction)fftAutoYAxis:(id)sender;
@end

@interface AudioInspectorRT (ChannelMixer)
- (void)pushChannelMixerView;
- (void)popChannelMixerView;
@end

