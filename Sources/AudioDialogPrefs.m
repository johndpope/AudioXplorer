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

#import "AudioDialogPrefs.h"
#import "AudioDialogPrefs+Toolbar.h"

#import "AudioConstants.h"
#import "AudioNotifications.h"
#import "AudioUtilities.h"
#import "AudioInspectorController.h"
#import "AudioApp.h"
#import <ARCheckForUpdates/ARCheckForUpdates.h>

#define AudioDefaultsUseToolTipsKey @"AXUseToolTips"
#define AudioDefaultsUseVisualAnimationKey @"AXVisualAnimation"
#define AudioDefaultsInspectorAlphaKey @"AXInspectorAlpha"
#define AudioDefaultsCursorHorizontalKey @"AXCursorHorizontal"
#define AudioDefaultsCursorVerticalKey @"AXCursorVertical"
#define AudioDefaultsViewHorizontalScrollerKey @"AXViewHorizontalScroller"
#define AudioDefaultsViewVerticalScrollerKey @"AXViewVerticalScroller"
#define AudioDefaultsAddViewAtEndKey @"AXAddViewAtEnd"
#define AudioDefaultsMaxRecordDurationKey @"AXMaxRecordDuration"
#define AudioDefaultsFullScaleVoltageKey @"AXFullScaleVoltage"
#define AudioDefaultsOpenActionKey @"AXOpenAction"
#define AudioDefaultsFirstStartupDialogKey @"AXFirstStartupDialog"
#define AudioDefaultsDisplayTipDialogKey @"AXDisplayTipDialogKey"
#define AudioDefaultsYAxisFreeKey @"AXYAxisFree"

#define AudioDefaultsRTLayoutIDKey @"AudioDefaultsRTLayoutIDKey"
#define AudioDefaultsRTBufferDurationKey @"AudioDefaultsRTBufferDurationKey"
#define AudioDefaultsRTComputeSonoKey @"AudioDefaultsRTComputeSonoKey"
#define AudioDefaultsRTSonoColorModeKey @"AudioDefaultsRTSonoColorModeKey"
#define AudioDefaultsRTFFTMinXKey @"AudioDefaultsRTFFTMinXKey"
#define AudioDefaultsRTFFTMaxXKey @"AudioDefaultsRTFFTMaxXKey"
#define AudioDefaultsRTSonoMinYKey @"AudioDefaultsRTSonoMinYKey"
#define AudioDefaultsRTSonoMaxYKey @"AudioDefaultsRTSonoMaxYKey"
#define AudioDefaultsLastTipKey @"AudioDefaultsLastTipKey"
#define AudioDefaultsViewAppearanceKey @"AudioDefaultsViewAppearanceKey"

#define AudioDefaultsEffectsAsSubmenuKey @"AudioDefaultsEffectsAsSubmenuKey"
#define AudioDefaultsPreloadAudioUnitsKey @"AudioDefaultsPreloadAudioUnitsUpKey"

#define AudioDefaultsDeviceInputDeviceKey @"AudioDefaultsDeviceInputDeviceKey"
#define AudioDefaultsDeviceInputDataSourceKey @"AudioDefaultsDeviceInputDataSourceKey"
#define AudioDefaultsDeviceOutputDeviceKey @"AudioDefaultsDeviceOutputDeviceKey"
#define AudioDefaultsDeviceOutputDataSourceKey @"AudioDefaultsDeviceOutputDataSourceKey"

#define AudioDefaultsRegisterNameKey @"AudioDefaultsRegisterNameKey"
#define AudioDefaultsRegisterCodeKey @"AudioDefaultsRegisterCodeKey"

@implementation AudioDialogPrefs

+ (AudioDialogPrefs*)shared
{
    static AudioDialogPrefs *_shared = NULL;
    
    if(!_shared)
    {
        _shared = [[AudioDialogPrefs alloc] init];
        [AudioApp addStaticObject:_shared];
    }
    
    return _shared;
}

+ (void)initDefaultValues
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];

    // Registration
    
    [defaultValues setObject:@"" forKey:AudioDefaultsRegisterNameKey];
    [defaultValues setObject:@"" forKey:AudioDefaultsRegisterCodeKey];
    
    // General
    
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AudioDefaultsAddViewAtEndKey];
    
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AudioDefaultsUseToolTipsKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AudioDefaultsUseVisualAnimationKey];
    [defaultValues setObject:[NSNumber numberWithFloat:1.0] forKey:AudioDefaultsInspectorAlphaKey];

    [defaultValues setObject:[NSNumber numberWithInt:OPEN_STATIC_WINDOW] forKey:AudioDefaultsOpenActionKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AudioDefaultsFirstStartupDialogKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AudioDefaultsDisplayTipDialogKey];

    [defaultValues setObject:[NSMutableArray array] forKey:AudioDefaultsLastTipKey];

    // View
    
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AudioDefaultsCursorHorizontalKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AudioDefaultsCursorVerticalKey];

    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AudioDefaultsViewHorizontalScrollerKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AudioDefaultsViewVerticalScrollerKey];

    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AudioDefaultsYAxisFreeKey];

    // RT

    [defaultValues setObject:[NSNumber numberWithInt:AMPLITUDE_FFT_SONO_VIEWS] forKey:AudioDefaultsRTLayoutIDKey];
    [defaultValues setObject:[NSNumber numberWithFloat:5] forKey:AudioDefaultsRTBufferDurationKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AudioDefaultsRTComputeSonoKey];
    [defaultValues setObject:[NSNumber numberWithInt:IMAGE_COLOR_HOT] forKey:AudioDefaultsRTSonoColorModeKey];
    [defaultValues setObject:[NSNumber numberWithFloat:0] forKey:AudioDefaultsRTFFTMinXKey];
    [defaultValues setObject:[NSNumber numberWithFloat:1e4] forKey:AudioDefaultsRTFFTMaxXKey];
    [defaultValues setObject:[NSNumber numberWithFloat:0] forKey:AudioDefaultsRTSonoMinYKey];
    [defaultValues setObject:[NSNumber numberWithFloat:1e4] forKey:AudioDefaultsRTSonoMaxYKey];
    
    // Effects

    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:AudioDefaultsEffectsAsSubmenuKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:AudioDefaultsPreloadAudioUnitsKey];

    // Devices
    
    [defaultValues setObject:[NSNumber numberWithFloat:10] forKey:AudioDefaultsMaxRecordDurationKey];
    [defaultValues setObject:[NSNumber numberWithFloat:2.5] forKey:AudioDefaultsFullScaleVoltageKey];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];    
}

- (id)init
{
    if(self = [self initWithWindowNibName:@"AudioPrefs"])
    {		
        mUserDefaults = [NSUserDefaults standardUserDefaults];
        mAudioDeviceManager = [AudioDeviceManager shared];
		mDefaultsMixer = [[CAChannelMixer alloc] init];

        mDefaultViewAppearanceController = [AudioViewAppearanceController shared];
        
        mInputDeviceTitlesArray = NULL;
        mOutputDeviceTitlesArray = NULL;
        mInputDataSourceNameArray = NULL;
        mOutputDataSourceNameArray = NULL;
		
		[self window];
        [self refresh];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	[mDefaultsMixer release];
	
    [mInputDeviceTitlesArray release];
    [mOutputDeviceTitlesArray release];
    [mInputDataSourceNameArray release];
    [mOutputDataSourceNameArray release];
    
    [mDefaultViewAppearanceController release];
    
    [super dealloc];
}

- (void)refresh
{
	@try {
		[self refreshGeneralTab];
		[self refreshViewTab];
		[self refreshRTTab];
		[self refreshEffectsTab];
		[self refreshDevicesTab];		
	} @catch(id exception) {
		NSLog(@"Exception while refreshing the preferences: %@", exception);
	}
}

- (void)awakeFromNib
{
    [[ARUpdateManager sharedManager] insertPreferencesIntoView:[mVersionCheckerBox contentView]];

	[self setupToolbar];
    [self createViewTabGUI];
    [self createRTTabGUI];

    [self refresh];

    [self initDevicesTab];

	[self applyDeviceDefaults];
}

- (void)load
{
}

- (void)save
{    
    [mUserDefaults setObject:[mDefaultViewAppearanceController defaultAppearanceData]
                    forKey:AudioDefaultsViewAppearanceKey];
}

@end

@implementation AudioDialogPrefs (General)

- (void)refreshGeneralTab
{
    [mUseToolTipsButton setState:[[mUserDefaults objectForKey:AudioDefaultsUseToolTipsKey] boolValue]];
    [mUseVisualAnimationButton setState:[[mUserDefaults objectForKey:AudioDefaultsUseVisualAnimationKey] boolValue]];
    [mInspectorAlphaSlider setDoubleValue:[[mUserDefaults objectForKey:AudioDefaultsInspectorAlphaKey] floatValue]];

    [mOpenActionPopUp selectItemAtIndex:[[mUserDefaults objectForKey:AudioDefaultsOpenActionKey] intValue]];

    [mDisplayTipDialogButton setState:[[mUserDefaults objectForKey:AudioDefaultsDisplayTipDialogKey] boolValue]];
}

- (IBAction)computedViewPositionAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithBool:[[sender selectedCell] tag]] 
                                    forKey:AudioDefaultsAddViewAtEndKey];
}

- (BOOL)addViewAtEnd
{
    return [[mUserDefaults objectForKey:AudioDefaultsAddViewAtEndKey] boolValue];
}

- (IBAction)useToolTipsAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithBool:[sender intValue]] forKey:AudioDefaultsUseToolTipsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioPrefsUseToolTipsChangedNotification object:self];
}

- (BOOL)useToolTips
{
    return [[mUserDefaults objectForKey:AudioDefaultsUseToolTipsKey] boolValue];
}

- (IBAction)useVisualAnimationAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithBool:[sender intValue]] forKey:AudioDefaultsUseVisualAnimationKey];
}

- (BOOL)useVisualAnimation
{
    return [[mUserDefaults objectForKey:AudioDefaultsUseVisualAnimationKey] boolValue];
}

- (IBAction)inspectorTransparencyAction:(id)sender
{
    [[[AudioInspectorController shared] window] setAlphaValue:[sender floatValue]];

    [mUserDefaults setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:AudioDefaultsInspectorAlphaKey];
}

- (FLOAT)inspectorTransparency
{
    return [[mUserDefaults objectForKey:AudioDefaultsInspectorAlphaKey] floatValue];
}

- (IBAction)openActionAction:(id)sender
{
    [self setOpenAction:[sender indexOfSelectedItem]];
}

- (void)setOpenAction:(SHORT)action
{
    [mUserDefaults setObject:[NSNumber numberWithInt:action] forKey:AudioDefaultsOpenActionKey];
}

- (SHORT)openAction
{
    return [[mUserDefaults objectForKey:AudioDefaultsOpenActionKey] intValue];
}

- (void)setShouldDisplayOpenActionDialog:(BOOL)flag
{
    [mUserDefaults setObject:[NSNumber numberWithBool:flag] forKey:AudioDefaultsFirstStartupDialogKey];
}

- (BOOL)shouldDisplayOpenActionDialog
{
    return [[mUserDefaults objectForKey:AudioDefaultsFirstStartupDialogKey] boolValue];
}

- (IBAction)displayTipDialogAction:(id)sender
{
    [self setDisplayTipDialog:[sender state] == NSOnState];
}

- (void)setDisplayTipDialog:(BOOL)flag
{
    [mUserDefaults setObject:[NSNumber numberWithBool:flag] forKey:AudioDefaultsDisplayTipDialogKey];
    [self refreshGeneralTab];
}

- (BOOL)displayTipDialog
{
    return [[mUserDefaults objectForKey:AudioDefaultsDisplayTipDialogKey] boolValue];
}

- (void)setDisplayedTips:(NSMutableArray*)tips
{
    [mUserDefaults setObject:tips forKey:AudioDefaultsLastTipKey];
}

- (NSMutableArray*)displayedTips
{
    return [mUserDefaults objectForKey:AudioDefaultsLastTipKey];
}

@end

@implementation AudioDialogPrefs (View)

- (void)createViewTabGUI
{
    [mDefaultViewAppearanceController setDefaultAppearanceFromData:[mUserDefaults objectForKey:AudioDefaultsViewAppearanceKey]];
    [mDefaultViewAppearanceController setContainerBox:mDefaultViewAppearanceBox];
    [mDefaultViewAppearanceController setView:NULL];
}

- (void)refreshViewTab
{
    [mCursorHorizontalButton setState:[[mUserDefaults objectForKey:AudioDefaultsCursorHorizontalKey] boolValue]];
    [mCursorVerticalButton setState:[[mUserDefaults objectForKey:AudioDefaultsCursorVerticalKey] boolValue]];

    [mUseHorizontalScrollerButton setState:[[mUserDefaults objectForKey:AudioDefaultsViewHorizontalScrollerKey] boolValue]];
    [mUseVerticalScrollerButton setState:[[mUserDefaults objectForKey:AudioDefaultsViewVerticalScrollerKey] boolValue]];

    [mYAxisFreeButton setState:[[mUserDefaults objectForKey:AudioDefaultsYAxisFreeKey] boolValue]];    
}

- (IBAction)cursorDirectionAction:(id)sender
{    
    if([sender tag]==0)
        [mUserDefaults setObject:[NSNumber numberWithBool:[sender intValue]] 
                                        forKey:AudioDefaultsCursorHorizontalKey];
    else if([sender tag]==1)
        [mUserDefaults setObject:[NSNumber numberWithBool:[sender intValue]] 
                                        forKey:AudioDefaultsCursorVerticalKey];
                                        
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioPrefsCursorDirectionChangedNotification object:self];
}

- (BOOL)horizontalCursor
{
    return [[mUserDefaults objectForKey:AudioDefaultsCursorHorizontalKey] boolValue];
}

- (BOOL)verticalCursor
{
    return [[mUserDefaults objectForKey:AudioDefaultsCursorVerticalKey] boolValue];
}

- (IBAction)scrollerNavigationAction:(id)sender
{    
    if([sender tag]==0)
        [mUserDefaults setObject:[NSNumber numberWithBool:[sender intValue]] 
                                        forKey:AudioDefaultsViewHorizontalScrollerKey];
    else if([sender tag]==1)
        [mUserDefaults setObject:[NSNumber numberWithBool:[sender intValue]] 
                                        forKey:AudioDefaultsViewVerticalScrollerKey];
                                        
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioPrefsViewScrollerChangedNotification object:self];
}

- (BOOL)horizontalScroller
{
    return [[mUserDefaults objectForKey:AudioDefaultsViewHorizontalScrollerKey] boolValue];
}

- (BOOL)verticalScroller
{
    return [[mUserDefaults objectForKey:AudioDefaultsViewVerticalScrollerKey] boolValue];
}

- (IBAction)yAxisFreeAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithBool:[sender intValue]] forKey:AudioDefaultsYAxisFreeKey];
}

- (void)setYAxisFree:(BOOL)flag
{
    [mUserDefaults setObject:[NSNumber numberWithBool:flag] forKey:AudioDefaultsYAxisFreeKey];
}

- (BOOL)yAxisFree
{
    return [[mUserDefaults objectForKey:AudioDefaultsYAxisFreeKey] boolValue];
}

@end

@implementation AudioDialogPrefs (RT)

- (void)createRTTabGUI
{
    [AudioInspectorRT fillLayoutIDPopUp:mRTLayoutPopUp];
    [AudioInspectorRT fillBufferDurationPopUp:mRTBufferDurationPopUp];
    [AudioSonoAppearanceController fillSonoColorModePopUp:mRTSonoColorModePopUp];
}

- (void)refreshRTTab
{
    int index = [AudioInspectorRT itemIndexOfLayoutID:[[mUserDefaults objectForKey:AudioDefaultsRTLayoutIDKey] intValue]];
    [mRTLayoutPopUp selectItemAtIndex:index];
    
    index = [AudioInspectorRT itemIndexOfBufferDuration:[[mUserDefaults objectForKey:AudioDefaultsRTBufferDurationKey] intValue]];
    [mRTBufferDurationPopUp selectItemAtIndex:index];

	[mRTComputeSonoButton setState:[mUserDefaults boolForKey:AudioDefaultsRTComputeSonoKey]];
	
    index = [AudioSonoAppearanceController itemIndexOfColorMode:[[mUserDefaults objectForKey:AudioDefaultsRTSonoColorModeKey] intValue]];
    [mRTSonoColorModePopUp selectItemAtIndex:index];
    
    [mRTFFTMinXTextField setFloatValue:[[mUserDefaults objectForKey:AudioDefaultsRTFFTMinXKey] floatValue]];
    [mRTFFTMaxXTextField setFloatValue:[[mUserDefaults objectForKey:AudioDefaultsRTFFTMaxXKey] floatValue]];

    [mRTSonoMinYTextField setFloatValue:[[mUserDefaults objectForKey:AudioDefaultsRTSonoMinYKey] floatValue]];
    [mRTSonoMaxYTextField setFloatValue:[[mUserDefaults objectForKey:AudioDefaultsRTSonoMaxYKey] floatValue]];
}

- (IBAction)rtLayoutAction:(id)sender
{
    int value = [AudioInspectorRT layoutIDOfPopUp:sender];
    [mUserDefaults setObject:[NSNumber numberWithInt:value] 
                                forKey:AudioDefaultsRTLayoutIDKey];
}

- (IBAction)rtBufferDurationAction:(id)sender
{
    FLOAT value = [AudioInspectorRT bufferDurationOfPopUp:sender];
    [mUserDefaults setObject:[NSNumber numberWithFloat:value] 
                                forKey:AudioDefaultsRTBufferDurationKey];
}

- (IBAction)computeSonoAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithBool:[sender state] == NSOnState] 
					  forKey:AudioDefaultsRTComputeSonoKey];	
}

- (IBAction)rtFFTMinXAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithFloat:[sender floatValue]] 
                                forKey:AudioDefaultsRTFFTMinXKey];
}

- (IBAction)rtFFTMaxXAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithFloat:[sender floatValue]] 
                                forKey:AudioDefaultsRTFFTMaxXKey];
}

- (IBAction)rtSonoMinYAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithFloat:[sender floatValue]] 
                                forKey:AudioDefaultsRTSonoMinYKey];
}

- (IBAction)rtSonoMaxYAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithFloat:[sender floatValue]] 
                                forKey:AudioDefaultsRTSonoMaxYKey];
}

- (IBAction)rtSonoColorModeAction:(id)sender
{
    int value = [AudioSonoAppearanceController colorModeOfPopUp:sender];
    [mUserDefaults setObject:[NSNumber numberWithInt:value] 
                                forKey:AudioDefaultsRTSonoColorModeKey];
}

- (USHORT)rtLayout
{
    return [[mUserDefaults objectForKey:AudioDefaultsRTLayoutIDKey] intValue];
}

- (FLOAT)rtBufferDuration
{
    return [[mUserDefaults objectForKey:AudioDefaultsRTBufferDurationKey] floatValue];
}

- (FLOAT)rtFFTMinX
{
    return [[mUserDefaults objectForKey:AudioDefaultsRTFFTMinXKey] floatValue];
}

- (FLOAT)rtFFTMaxX
{
    return [[mUserDefaults objectForKey:AudioDefaultsRTFFTMaxXKey] floatValue];
}

- (FLOAT)rtSonoMinY
{
    return [[mUserDefaults objectForKey:AudioDefaultsRTSonoMinYKey] floatValue];
}

- (FLOAT)rtSonoMaxY
{
    return [[mUserDefaults objectForKey:AudioDefaultsRTSonoMaxYKey] floatValue];
}

- (USHORT)rtSonoColorMode
{
    return [[mUserDefaults objectForKey:AudioDefaultsRTSonoColorModeKey] intValue];
}

- (BOOL)computeSonogramOnlyIfVisible
{
    return [mUserDefaults boolForKey:AudioDefaultsRTComputeSonoKey];
}

@end

@implementation AudioDialogPrefs (Effects)

- (void)refreshEffectsTab
{
    [mEffectsAsSubmenuButton setState:[[mUserDefaults objectForKey:AudioDefaultsEffectsAsSubmenuKey] boolValue]];
    [mPreloadAudioUnitsUpButton setState:[[mUserDefaults objectForKey:AudioDefaultsPreloadAudioUnitsKey] boolValue]];
}

- (IBAction)effectsAsSubmenuAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithBool:[sender state] == NSOnState] 
                                forKey:AudioDefaultsEffectsAsSubmenuKey];
}

- (BOOL)effectsAsSubmenu
{
    return [[mUserDefaults objectForKey:AudioDefaultsEffectsAsSubmenuKey] boolValue];
}

- (IBAction)preloadAudioUnitsAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithBool:[sender state] == NSOnState] 
                                forKey:AudioDefaultsPreloadAudioUnitsKey];
}

- (BOOL)preloadAudioUnits
{
    return [[mUserDefaults objectForKey:AudioDefaultsPreloadAudioUnitsKey] boolValue];
}

@end

@implementation AudioDialogPrefs (Devices)

- (CAChannelMixer*)defaultsChannelMixer
{
	return mDefaultsMixer;
}

- (void)updateMixer
{
	[mDefaultsMixer setNumberOfInputChannels:[mAudioDeviceManager numberOfInputChannels]];
	[mDefaultsMixer setNumberOfOutputChannels:[mAudioDeviceManager numberOfOutputChannels]];
	[mDefaultsMixer refresh];
}

- (void)applyDeviceDefaultsStage:(int)stage index:(int)index
{
    switch(stage) {
        case 0: // Input Device
            [mAudioDeviceManager setCurrentInputDeviceAtIndex:index];
            [self updateDataSourcePopup];
            break;
        case 1: // Input Data Source
            [mAudioDeviceManager setCurrentInputDataSourceAtIndex:index];
            break;

        case 2: // Output Device
            [mAudioDeviceManager setCurrentOutputDeviceAtIndex:index];
            [self updateDataSourcePopup];
            break;
        case 3: // Output Data Source
            [mAudioDeviceManager setCurrentOutputDataSourceAtIndex:index];
            break;
    }
}

- (void)applyDeviceDefaultForPopUp:(NSPopUpButton*)popup key:(NSString*)key stage:(int)stage
{
	NSString *title = [mUserDefaults objectForKey:key];
	if(title)
		[popup selectItemWithTitle:title];

	if((title == NULL  || [popup indexOfSelectedItem] == -1) && [popup numberOfItems] > 0) {
		[popup selectItemAtIndex:0];
		[mUserDefaults setObject:[popup titleOfSelectedItem] forKey:key];
	}

	[self applyDeviceDefaultsStage:stage index:[popup indexOfSelectedItem]];
}

- (void)applyDeviceDefaults
{
	[self applyDeviceDefaultForPopUp:mInputDeviceListPopUp key:AudioDefaultsDeviceInputDeviceKey stage:0];
	[self applyDeviceDefaultForPopUp:mInputDataSourceListPopUp key:AudioDefaultsDeviceInputDataSourceKey stage:1];
	[self applyDeviceDefaultForPopUp:mOutputDeviceListPopUp key:AudioDefaultsDeviceOutputDeviceKey stage:2];
	[self applyDeviceDefaultForPopUp:mOutputDataSourceListPopUp key:AudioDefaultsDeviceOutputDataSourceKey stage:3];
}

- (void)registerDeviceDefaults
{
	[mUserDefaults setObject:[mInputDeviceListPopUp titleOfSelectedItem] forKey:AudioDefaultsDeviceInputDeviceKey];
	[mUserDefaults setObject:[mInputDataSourceListPopUp titleOfSelectedItem] forKey:AudioDefaultsDeviceInputDataSourceKey];
	[mUserDefaults setObject:[mOutputDeviceListPopUp titleOfSelectedItem] forKey:AudioDefaultsDeviceOutputDeviceKey];
	[mUserDefaults setObject:[mOutputDataSourceListPopUp titleOfSelectedItem] forKey:AudioDefaultsDeviceOutputDataSourceKey];	
}

- (void)refreshDevicesTab
{
    [mMaximumRecordDurationTextField setFloatValue:[[mUserDefaults objectForKey:AudioDefaultsMaxRecordDurationKey] floatValue]];
    [mFullScaleVoltageTextField setFloatValue:[[mUserDefaults objectForKey:AudioDefaultsFullScaleVoltageKey] floatValue]];
}

- (void)updateDeviceManagerArray
{
    [mInputDeviceTitlesArray release];
    [mOutputDeviceTitlesArray release];
    [mInputDataSourceNameArray release];
    [mOutputDataSourceNameArray release];
    
    mInputDeviceTitlesArray = [[mAudioDeviceManager inputDeviceTitlesArray] retain];
    mOutputDeviceTitlesArray = [[mAudioDeviceManager outputDeviceTitlesArray] retain];
    
    mInputDataSourceNameArray = [[mAudioDeviceManager inputDataSourceTitlesArray] retain];
    mOutputDataSourceNameArray = [[mAudioDeviceManager outputDataSourceTitlesArray] retain];
}

- (void)updateDevicesPopup
{    
    [self updateDeviceManagerArray];
    
    [mInputDeviceListPopUp removeAllItems];
    [mInputDeviceListPopUp setEnabled:mInputDeviceTitlesArray!=NULL];
    if(mInputDeviceTitlesArray)
    {
        [mInputDeviceListPopUp addItemsWithTitles:mInputDeviceTitlesArray];
		[mInputDeviceListPopUp selectItemWithTitle:[mAudioDeviceManager currentInputDeviceTitle]];
    }
    
    [mOutputDeviceListPopUp removeAllItems];
    [mOutputDeviceListPopUp setEnabled:mOutputDeviceTitlesArray!=NULL];
    if(mOutputDeviceTitlesArray)
    {
        [mOutputDeviceListPopUp addItemsWithTitles:mOutputDeviceTitlesArray];    
		[mOutputDeviceListPopUp selectItemWithTitle:[mAudioDeviceManager currentOutputDeviceTitle]];
    }
}

- (void)updateDataSourcePopup
{    
    [self updateDeviceManagerArray];

    // INPUT
    
    BOOL hasInputDataSource = mInputDataSourceNameArray && [mInputDataSourceNameArray count]>0;
    
    [mInputDataSourceListPopUp removeAllItems];
    [mInputDataSourceListPopUp setEnabled:hasInputDataSource];
    if(hasInputDataSource)
    {
        [mInputDataSourceListPopUp addItemsWithTitles:mInputDataSourceNameArray];
        [mInputDataSourceListPopUp selectItemWithTitle:[mAudioDeviceManager currentInputDataSourceTitle]];
    } else if(mInputDeviceTitlesArray && [mAudioDeviceManager currentInputDeviceTitle])
        [mInputDataSourceListPopUp addItemWithTitle:[mAudioDeviceManager currentInputDeviceTitle]];
    
    // OUTPUT

    BOOL hasOutputDataSource = mOutputDataSourceNameArray && [mOutputDataSourceNameArray count]>0;
    
    [mOutputDataSourceListPopUp removeAllItems];
    [mOutputDataSourceListPopUp setEnabled:hasOutputDataSource];
    if(hasOutputDataSource)
    {
        [mOutputDataSourceListPopUp addItemsWithTitles:mOutputDataSourceNameArray];
        [mOutputDataSourceListPopUp selectItemWithTitle:[mAudioDeviceManager currentOutputDataSourceTitle]];
    } else if(mOutputDeviceTitlesArray && [mAudioDeviceManager currentOutputDeviceTitle])
        [mOutputDataSourceListPopUp addItemWithTitle:[mAudioDeviceManager currentOutputDeviceTitle]];
}

- (void)devicesChangedNotification:(NSNotification*)notif
{
    [self updateDevicesTab];
	[self updateMixer];
}

- (void)initDevicesTab
{
    mInputDeviceTitlesArray = NULL;
    mOutputDeviceTitlesArray = NULL;
    mInputDataSourceNameArray = NULL;
    mOutputDataSourceNameArray = NULL;

	[mDefaultsMixer addTableView:mMixerTableView];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(devicesChangedNotification:) 
                                            name:CADeviceManagerDevicesChangedNotification
                                            object:NULL];
    [self updateDevicesTab];
	[self updateMixer];
}

- (void)updateQualityInfo
{
    [mInputRequestedQuality setStringValue:[mAudioDeviceManager inputRequestedQuality]];
    [mInputObtainedQuality setStringValue:[mAudioDeviceManager inputObtainedQuality]];
    
    [mOutputRequestedQuality setStringValue:[mAudioDeviceManager outputRequestedQuality]];
    [mOutputObtainedQuality setStringValue:[mAudioDeviceManager outputObtainedQuality]];
}

- (void)updateDevicesTab
{
    [self updateDevicesPopup];
    [self updateDataSourcePopup];
    [self updateQualityInfo];
    
    if([mAudioDeviceManager inputDeviceAvailable])
        [mInputDeviceBox setContentView:mInputDeviceView];
    else
        [mInputDeviceBox setContentView:mNoInputDeviceView];
}

- (IBAction)maxRecordDurationAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithFloat:[sender floatValue]] 
                                    forKey:AudioDefaultsMaxRecordDurationKey];
}

- (FLOAT)maxRecordDuration
{
    return [[mUserDefaults objectForKey:AudioDefaultsMaxRecordDurationKey] floatValue];
}

- (IBAction)fullScaleVoltageAction:(id)sender
{
    [mUserDefaults setObject:[NSNumber numberWithFloat:[sender floatValue]] 
                                    forKey:AudioDefaultsFullScaleVoltageKey];
}

- (FLOAT)fullScaleVoltage
{
    return [[mUserDefaults objectForKey:AudioDefaultsFullScaleVoltageKey] floatValue];
}

- (IBAction)popUpAction:(id)sender
{
    SHORT item = [sender indexOfSelectedItem];
    switch([sender tag]) {
        case 0: // Input Device
            [mAudioDeviceManager setCurrentInputDeviceAtIndex:item];
            [self updateDataSourcePopup];
            break;
        case 1: // Input Data Source
            [mAudioDeviceManager setCurrentInputDataSourceAtIndex:item];
            break;

        case 2: // Output Device
            [mAudioDeviceManager setCurrentOutputDeviceAtIndex:item];
            [self updateDataSourcePopup];
            break;
        case 3: // Output Data Source
            [mAudioDeviceManager setCurrentOutputDataSourceAtIndex:item];
            break;
    }
	[self registerDeviceDefaults];
}

@end
