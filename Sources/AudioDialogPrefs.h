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
#import "AudioTypes.h"
#import "CADeviceManager.h"
#import "CAChannelMixer.h"
#import "AudioViewAppearanceController.h"

@interface AudioDialogPrefs : NSWindowController {

    NSUserDefaults *mUserDefaults;
    
    // Core Audio Devices
    
    NSArray	*mInputDeviceTitlesArray;
    NSArray	*mOutputDeviceTitlesArray;
    NSArray	*mInputDataSourceNameArray;
    NSArray	*mOutputDataSourceNameArray;
    
    AudioDeviceManager *mAudioDeviceManager;
    
    // Default View Appearance
    
    AudioViewAppearanceController *mDefaultViewAppearanceController;
    
    // General View
        
	IBOutlet NSView *mGeneralView;

    IBOutlet NSMatrix *mComputedViewPositionMatrix;
        
    IBOutlet NSPopUpButton *mOpenActionPopUp;
    
    IBOutlet NSButton *mUseToolTipsButton;
    IBOutlet NSButton *mUseVisualAnimationButton;
    IBOutlet NSSlider *mInspectorAlphaSlider;
    
    IBOutlet NSButton *mDisplayTipDialogButton;
    
    // Views View
    
	IBOutlet NSView *mViewsView;

    IBOutlet NSButton *mCursorHorizontalButton;
    IBOutlet NSButton *mCursorVerticalButton;

    IBOutlet NSButton *mUseHorizontalScrollerButton;
    IBOutlet NSButton *mUseVerticalScrollerButton;
    
    IBOutlet NSButton *mYAxisFreeButton;
    
    IBOutlet NSBox *mDefaultViewAppearanceBox;
    
    // RT View
    
	IBOutlet NSView *mRTView;

    IBOutlet NSPopUpButton *mRTLayoutPopUp;
    IBOutlet NSPopUpButton *mRTBufferDurationPopUp;
	IBOutlet NSButton *mRTComputeSonoButton;
    IBOutlet NSTextField *mRTFFTMinXTextField;
    IBOutlet NSTextField *mRTFFTMaxXTextField;
    IBOutlet NSTextField *mRTSonoMinYTextField;
    IBOutlet NSTextField *mRTSonoMaxYTextField;
    IBOutlet NSPopUpButton *mRTSonoColorModePopUp;
    
    // Effects View
    
	IBOutlet NSView *mEffectsView;
    IBOutlet NSButton *mEffectsAsSubmenuButton;
    IBOutlet NSButton *mPreloadAudioUnitsUpButton;
    
    // Device View

	IBOutlet NSView *mDevicesView;
	
		// Input
    IBOutlet NSTextField *mMaximumRecordDurationTextField;    
    IBOutlet NSTextField *mFullScaleVoltageTextField;

    IBOutlet NSBox *mInputDeviceBox;
    IBOutlet NSView *mInputDeviceView;
    IBOutlet NSView *mNoInputDeviceView;
    
    IBOutlet NSPopUpButton *mInputDeviceListPopUp;
    IBOutlet NSPopUpButton *mInputDataSourceListPopUp;
    
    IBOutlet NSTextField *mInputRequestedQuality;
    IBOutlet NSTextField *mInputObtainedQuality;
    
		// Output
        
    IBOutlet NSPopUpButton *mOutputDeviceListPopUp;
    IBOutlet NSPopUpButton *mOutputDataSourceListPopUp;

    IBOutlet NSTextField *mOutputRequestedQuality;
    IBOutlet NSTextField *mOutputObtainedQuality;

		// Channels Mixer
	
	IBOutlet NSTableView	*mMixerTableView;
	CAChannelMixer			*mDefaultsMixer;
	
    // Update View
    
	IBOutlet NSView *mUpdateView;
    IBOutlet NSBox *mVersionCheckerBox;
}

+ (AudioDialogPrefs*)shared;
+ (void)initDefaultValues;

- (void)refresh;
- (void)load;
- (void)save;

@end

@interface AudioDialogPrefs (General)

- (void)refreshGeneralTab;

- (IBAction)computedViewPositionAction:(id)sender;
- (BOOL)addViewAtEnd;

- (IBAction)useToolTipsAction:(id)sender;
- (BOOL)useToolTips;

- (IBAction)useVisualAnimationAction:(id)sender;
- (BOOL)useVisualAnimation;

- (IBAction)inspectorTransparencyAction:(id)sender;
- (FLOAT)inspectorTransparency;

- (IBAction)openActionAction:(id)sender;
- (void)setOpenAction:(SHORT)action;
- (SHORT)openAction;

- (void)setShouldDisplayOpenActionDialog:(BOOL)flag;
- (BOOL)shouldDisplayOpenActionDialog;

- (IBAction)displayTipDialogAction:(id)sender;
- (void)setDisplayTipDialog:(BOOL)flag;
- (BOOL)displayTipDialog;

- (void)setDisplayedTips:(NSMutableArray*)tips;
- (NSMutableArray*)displayedTips;

@end

@interface AudioDialogPrefs (View)

- (void)createViewTabGUI;
- (void)refreshViewTab;

- (IBAction)cursorDirectionAction:(id)sender;
- (BOOL)horizontalCursor;
- (BOOL)verticalCursor;

- (IBAction)scrollerNavigationAction:(id)sender;
- (BOOL)horizontalScroller;
- (BOOL)verticalScroller;

- (IBAction)yAxisFreeAction:(id)sender;
- (void)setYAxisFree:(BOOL)flag;
- (BOOL)yAxisFree;

@end

@interface AudioDialogPrefs (RT)

- (void)createRTTabGUI;
- (void)refreshRTTab;

- (IBAction)rtLayoutAction:(id)sender;
- (IBAction)rtBufferDurationAction:(id)sender;
- (IBAction)computeSonoAction:(id)sender;

- (IBAction)rtFFTMinXAction:(id)sender;
- (IBAction)rtFFTMaxXAction:(id)sender;
- (IBAction)rtSonoMinYAction:(id)sender;
- (IBAction)rtSonoMaxYAction:(id)sender;
- (IBAction)rtSonoColorModeAction:(id)sender;

- (USHORT)rtLayout;
- (FLOAT)rtBufferDuration;
- (FLOAT)rtFFTMinX;
- (FLOAT)rtFFTMaxX;
- (FLOAT)rtSonoMinY;
- (FLOAT)rtSonoMaxY;
- (USHORT)rtSonoColorMode;

- (BOOL)computeSonogramOnlyIfVisible;

@end

@interface AudioDialogPrefs (Effects)
- (void)refreshEffectsTab;
- (IBAction)effectsAsSubmenuAction:(id)sender;
- (BOOL)effectsAsSubmenu;
- (IBAction)preloadAudioUnitsAction:(id)sender;
- (BOOL)preloadAudioUnits;
@end

@interface AudioDialogPrefs (Devices)

- (CAChannelMixer*)defaultsChannelMixer;

- (void)applyDeviceDefaults;
- (void)refreshDevicesTab;

- (void)initDevicesTab;
- (void)updateDevicesTab;
- (void)updateDataSourcePopup;

- (IBAction)maxRecordDurationAction:(id)sender;
- (FLOAT)maxRecordDuration;

- (IBAction)fullScaleVoltageAction:(id)sender;
- (FLOAT)fullScaleVoltage;

- (IBAction)popUpAction:(id)sender;

@end
