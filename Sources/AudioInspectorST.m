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

#import "AudioInspectorST.h"
#import "AudioConstants.h"
#import "AudioNotifications.h"
#import "AudioView2D.h"
#import "AudioInspectorController.h"

#define WINDOW_SIZE_TAG 0
#define WINDOW_OFFSET_TAG 1
#define FFT_SIZE_TAG 2

#define FFT_CURSOR 0
#define FFT_SELECTION 1

@implementation AudioInspectorST

- (id)init
{
    if(self = [super init])
    {
        mAudioViewAppearanceController = [[AudioViewAppearanceController alloc] init];
        mDataSonoAppearanceController = [[AudioSonoAppearanceController alloc] init];
        
        [mDataSonoAppearanceController setDelegate:self];
        
        mCurrentWindow = NULL;
        mCurrentWrapper = NULL;
        mCurrentView = NULL;

        mInspectorView = NULL;
        
        mValidTarget = NO;
        mLastDisplayIndex = 0;
        
        mSharedOperator = [AudioOperator shared];  
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [mAnalyzeAmplitudeView release];
    [mAnalyzeFFTView release];
    [mAudioViewAppearanceController release];
    [mDataSonoAppearanceController release];
    
    [super dealloc];
}

- (void)windowDidLoad
{
    [mAnalyzeAmplitudeView retain];
    [mAnalyzeAmplitudeView removeFromSuperview];

    [mAnalyzeFFTView retain];
    [mAnalyzeFFTView removeFromSuperview];

    [mAudioViewAppearanceController setContainerBox:mAppearanceBox];
 
    [mDisplayChannelPopUp setAutoenablesItems:NO];	// Allow custom enable

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionHasChanged:) name:AudioViewSelectionHasChangedNotification object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scaleHasChanged:) name:AudioViewScaleHasChangedNotification object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cursorHasChanged:) name:AudioViewCursorHasChangedNotification object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerHeadHasChanged:) name:AudioViewPlayerHeadHasChangedNotification object:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioWrapperDidBecomeSelectNotif:) name:AudioWrapperDidBecomeSelectNotification object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioViewHasUpdated:) name:AudioViewHasUpdatedNotification object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioWrapperWillDeallocate:) name:AudioWrapperWillDeallocateNotification object:NULL];
}

- (void)setNoMainWindow
{
    mCurrentView = NULL;
    mCurrentWindow = NULL;
    mCurrentWrapper = NULL;
    mValidTarget = NO;
    [mAudioViewAppearanceController setView:NULL];
}

- (void)setMainWindow:(NSWindow*)mainWindow
{
    mValidTarget = NO;
    NSWindowController *controller = [mainWindow windowController];
    if([controller isKindOfClass:[AudioSTWindowController class]])
    {
        [self setupInspectorPopUp];
        
        mCurrentWindow = [mainWindow windowController];
                
        mCurrentWrapper = [mCurrentWindow currentAudioWrapper];
        mCurrentView = [mCurrentWindow currentAudioView];
        
        if(mCurrentView)
        {
            mValidTarget = YES;
            [self displayViewAtIndex:mLastDisplayIndex];
            [mAudioViewAppearanceController setView:mCurrentView];
            [self applyDataFromCurrentWrapper];
            [self selectWrapper:mCurrentWrapper];
        }
    } else
        [self setNoMainWindow];
}

- (void)resignMainWindow:(NSWindow*)mainWindow
{
    NSWindowController *controller = [mainWindow windowController];
    if([controller isKindOfClass:[AudioSTWindowController class]] && controller == mCurrentWindow)
    {
        [self applyDataToCurrentWrapper];
        [self setNoMainWindow];
    }
}

- (void)selectWrapper:(AudioDataWrapper*)wrapper
{
    [self applyDataToCurrentWrapper];
    
    mCurrentWrapper = wrapper;
    mCurrentView = NULL;
    if(mCurrentWrapper)
    {    
        mCurrentView = [mCurrentWrapper view];        
        [self applyDataFromCurrentWrapper];
    }

    [mAudioViewAppearanceController setView:mCurrentView];
}

- (void)setupInspectorPopUp
{
    [mInspectorPopUp removeAllItems];
    [mInspectorPopUp addItemWithTitle:NSLocalizedString(@"View", NULL)];
    [mInspectorPopUp addItemWithTitle:NSLocalizedString(@"Appearance", NULL)];
    [mInspectorPopUp addItemWithTitle:NSLocalizedString(@"Characteristics", NULL)];
    
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

- (void)displayViewAtIndex:(USHORT)index
{
    mLastDisplayIndex = index;
    mInspectorView = NULL;
    switch(index) {
        case 0:
            mInspectorView = mViewView;
            break;
        case 1:
            mInspectorView = mViewAppearance;
            break;
        case 2:
            mInspectorView = mViewCharacteristics;
            break;
    }

    if(mInspectorView)
        [AudioInspectorController setContentView:mInspectorView resize:YES];
}

- (NSView*)view
{
    return mInspectorView;
}

- (void)applyDataToCurrentWrapper
{
    if(mCurrentWrapper)
    {
        [self updateParametersToCurrentWrapper];
        [self updateInfoToCurrentWrapper];
        [self updateRangeToCurrentWrapper];
        [mCurrentWrapper applyToView];
        [mCurrentView refresh];
    }
}

- (void)applyDataFromCurrentWrapper
{
    if(mCurrentWrapper)
    {
        [self updateAnalyzeBox];
        [self updateParametersFromCurrentWrapper];
        [self updateInfoFromCurrentWrapper];
        [self updateRangeFromCurrentWrapper];
        [self updateAppearanceFromCurrentWrapper];
        [self updateCharacteristicsFromCurrentWrapper];
    }
}

- (void)computeOperation:(SHORT)op
{
    AudioDataWrapper *wrapper = [mSharedOperator computeOperation:op withWrapper:mCurrentWrapper];
    [mCurrentWindow addAudioDataWrapper:wrapper parentWrapper:mCurrentWrapper];
}

@end

@implementation AudioInspectorST (ViewTab)

- (void)updateDisplayChannelPopUpItem
{
    [mDisplayChannelPopUp setEnabled:[mCurrentWrapper kind] != KIND_SONO];
    [[mDisplayChannelPopUp itemAtIndex:0] setEnabled:[mCurrentWrapper leftChannelExists]];
    [[mDisplayChannelPopUp itemAtIndex:1] setEnabled:[mCurrentWrapper rightChannelExists]];
    [[mDisplayChannelPopUp itemAtIndex:2] setEnabled:[mCurrentWrapper stereoChannelExists]];
    [[mDisplayChannelPopUp itemAtIndex:3] setEnabled:[mCurrentWrapper stereoChannelExists] &&
                                                    [mCurrentWrapper kind] != KIND_FFT];
}

- (void)updateViewTabInterface
{
    [mPlayerHeadPositionTextField setEnabled:[mCurrentWrapper supportPlayback]];
    [mPlaySoundButton setEnabled:[mCurrentWrapper supportPlayback]];
    
    [mZoomIntoSelectionButton setEnabled:[mCurrentWrapper selectionExist]];
    
    [mDisplayChannelOptionButton setEnabled:[mDisplayChannelPopUp indexOfSelectedItem]==3 
                                    && [mCurrentWrapper kind] != KIND_SONO];
    [self updateDisplayChannelPopUpItem];
}

- (void)updateParametersFromCurrentWrapper
{    
    [self updateAmplitudeAnalyzeParametersFromCurrentWrapper];
    [self updateFFTAnalyzeParametersFromCurrentWrapper];
}

- (void)updateParametersToCurrentWrapper
{    
    [self updateAmplitudeAnalyzeParametersToCurrentWrapper];
    [self updateFFTAnalyzeParametersToCurrentWrapper];
}

- (void)updateRangeFromCurrentWrapper
{            
    // X-axis range
        
    [mXFromTextField setFloatValue:[mCurrentWrapper visualMinX]];
    [mXToTextField setFloatValue:[mCurrentWrapper visualMaxX]];

    // Y-axis range

    [mYFromTextField setFloatValue:[mCurrentWrapper visualMinY]];
    [mYToTextField setFloatValue:[mCurrentWrapper visualMaxY]];
    
    // X-axis selection range

    [mSelFromTextField setFloatValue:[mCurrentWrapper selMinX]];
    [mSelToTextField setFloatValue:[mCurrentWrapper selMaxX]];
    
    // Cursor position

    [mCursorXTextField setFloatValue:[mCurrentWrapper cursorX]];
    [mCursorYTextField setFloatValue:[mCurrentWrapper cursorY]];
    if([mCurrentView isKindOfClass:[AudioView2D class]])
        [mCursorZTextField setStringValue:@""];
    else
        [mCursorZTextField setFloatValue:[mCurrentWrapper cursorZ]];
    
    // Playerhead position
    
    [mPlayerHeadPositionTextField setFloatValue:[mCurrentWrapper playerHeadPosition]];
    
    // Display Channel
    
    [mDisplayChannelPopUp selectItemAtIndex:[mCurrentView displayedChannel]];
    [self updateViewTabInterface];
}

- (void)updateRangeToCurrentWrapper
{
    [mCurrentWrapper setViewVisualMinX:[mXFromTextField floatValue]
                        maxX:[mXToTextField floatValue]];
    [mCurrentWrapper setViewVisualMinY:[mYFromTextField floatValue]
                        maxY:[mYToTextField floatValue]];
    [mCurrentWrapper setViewSelMinX:[mSelFromTextField floatValue]
                        maxX:[mSelToTextField floatValue]];

    [mCurrentWrapper setViewCursorX:[mCursorXTextField floatValue]
                            cursorY:[mCursorYTextField floatValue]];
    
    [mCurrentWrapper setViewPlayerHeadPosition:[mPlayerHeadPositionTextField floatValue]];
    
    [mCurrentWrapper updateRangeToView];
}

- (void)updateInfoFromCurrentWrapper
{
    [mViewNameTextField setStringValue:[mCurrentWrapper viewName]];
    [mXAxisUnitTextField setStringValue:[mCurrentWrapper xAxisUnit]];
    [mYAxisUnitTextField setStringValue:[mCurrentWrapper yAxisUnit]];
    [mSelectionUnitTextField setStringValue:[mCurrentWrapper xAxisUnit]];
    [mCursorXUnitTextField setStringValue:[mCurrentWrapper xAxisUnit]];
    [mCursorYUnitTextField setStringValue:[mCurrentWrapper yAxisUnit]];
    [mCursorZUnitTextField setStringValue:[mCurrentWrapper zAxisUnit]];
}

- (void)updateInfoToCurrentWrapper
{
    [mCurrentWrapper setViewName:[mViewNameTextField stringValue] always:YES];
}

- (void)updateAnalyzeBox
{
    NSView *view = NULL;
    
    switch([mCurrentWrapper kind]) {
        case KIND_AMPLITUDE:
            view = mAnalyzeAmplitudeView;
            break;
        
        case KIND_FFT:
            view = mAnalyzeFFTView;
            break;
        
        case KIND_SONO:
            view = [mDataSonoAppearanceController view];
            [mDataSonoAppearanceController setSonoData:[mCurrentWrapper data]];
            break;
    }
    
    if(view)
    {
        [mAnalyzeBox setContentView:view];
    }
}

- (IBAction)updateCurrentView:(id)sender
{
    [self applyDataToCurrentWrapper];
    [self applyDataFromCurrentWrapper];
    [mCurrentWindow viewHasChanged];
}

- (IBAction)resetXAxis:(id)sender
{
    [mCurrentWrapper resetXAxis];
}

- (IBAction)resetYAxis:(id)sender
{
    [mCurrentWrapper resetYAxis];
}

- (IBAction)zoomIntoSelection:(id)sender
{
    [mCurrentWrapper setViewVisualMinX:[mSelFromTextField floatValue]
                        maxX:[mSelToTextField floatValue]];
    [mCurrentWrapper updateRangeToView];
    [self updateRangeFromCurrentWrapper];
    [mCurrentView refresh];
}

- (IBAction)playSound:(id)sender
{
    [mCurrentView playSound];
}

- (IBAction)displayChannelAction:(id)sender
{
    switch([sender indexOfSelectedItem]) {
        case 0:
            [mCurrentView setDisplayedChannel:LEFT_CHANNEL];
            break;
        case 1:
            [mCurrentView setDisplayedChannel:RIGHT_CHANNEL];
            break;
        case 2:
            [mCurrentView setDisplayedChannel:STEREO_CHANNEL];
            break;
        case 3:
            [mCurrentView setDisplayedChannel:LISSAJOUS_CHANNEL];
            break;
    }
    [mCurrentView refresh];
    [mCurrentWrapper updateRangeFromView];
    [self updateRangeFromCurrentWrapper];
}

- (IBAction)displayChannelOptionAction:(id)sender
{
    [mCurrentWindow openDisplayChannelOptionPanelForWrapper:mCurrentWrapper];
}

@end

@implementation AudioInspectorST (AmplitudeAnalyze)

- (void)updateAmplitudeAnalyzeParametersFromCurrentWrapper
{
}

- (void)updateAmplitudeAnalyzeParametersToCurrentWrapper
{
}

@end

@implementation AudioInspectorST (FFTAnalyze)

- (void)updateFFTAnalyzeParametersFromCurrentWrapper
{
    [mFFTYAxisScalePopUp selectItemAtIndex:[mCurrentWrapper yAxisScale]];
    
    [mFFTViewLinkedButton setState:[mCurrentWrapper linkState]];
    
    [mCurrentWindow fillWrapperPopUp:mFFTViewLinkedSonoPopUp withWrapperOfKind:KIND_SONO];
    [mCurrentWindow selectWrapperPopUp:mFFTViewLinkedSonoPopUp ofKind:KIND_SONO
                withWrapperID:[mCurrentWrapper linkedViewID]];
}

- (void)updateFFTAnalyzeParametersToCurrentWrapper
{
    // mFFTYAxisScalePopUp : le wrapper reçoit la valeur directement de l'action du pop-up
}

- (IBAction)changeYAxisScale:(id)sender
{
    SHORT scale = YAxisLinearScale;
    
    if([sender indexOfSelectedItem]==1)
        scale = YAxisLogScale;
        
    [self applyDataToCurrentWrapper];
    [mCurrentWrapper setYAxisScale:scale];
    [mCurrentWrapper refreshYAxis];
    if(scale == YAxisLogScale)
        [mCurrentWrapper setViewVisualMinY:MAX(-30, [mCurrentWrapper minYOfChannel:LEFT_CHANNEL])
                            maxY:MAX(0,[mCurrentWrapper maxYOfChannel:LEFT_CHANNEL])];
    else
        [mCurrentWrapper setViewVisualMinY:[mCurrentWrapper minYOfChannel:LEFT_CHANNEL]
                            maxY:[mCurrentWrapper maxYOfChannel:LEFT_CHANNEL]];
    [mCurrentWrapper applyToView];
    [mCurrentView refresh];
    [self applyDataFromCurrentWrapper];
}

- (IBAction)fftViewLinkedButton:(id)sender
{
    BOOL linked = [sender state] == NSOnState;
    [mCurrentWrapper setLinkState:linked];
    if(linked)
        [self fftViewLinkedPopUp:mFFTViewLinkedSonoPopUp];
}

- (IBAction)fftViewLinkedPopUp:(id)sender
{
    [mCurrentWrapper linkToWrapper:[mCurrentWindow wrapperOfPopUp:mFFTViewLinkedSonoPopUp ofKind:KIND_SONO]];
}

@end

@implementation AudioInspectorST (SonoAnalyze)

- (void)sonoDataAppearanceHasChanged
{
    // Pas besoin de mettre à jour le wrapper puisque les données sont déjà à jour
    // par le appearance controller. Le wrapper ne fait que passer les info aux données...
    
    [mCurrentWrapper renderImage];
    [mCurrentView setNeedsDisplay:YES];
}

@end

@implementation AudioInspectorST (AppearanceTab)

- (void)updateAppearanceFromCurrentWrapper
{        
}

- (IBAction)checkBoxAction:(id)sender
{
}

- (IBAction)colorWellAction:(id)sender
{
}

- (IBAction)sliderAction:(id)sender
{
    NSRect viewFrame;
    
    switch([sender tag]) {
        case 1: // Height
            viewFrame = [mCurrentWrapper viewFrame];
            viewFrame.size.height = [sender floatValue];
            [mCurrentWrapper setViewFrame:viewFrame];
            break;
    }
}

@end

@implementation AudioInspectorST (CharacteristicsTab)

- (void)updateCharacteristicsFromCurrentWrapper
{
    [mInfoNumberOfChannelsTextField setStringValue:[mCurrentWrapper infoNumberOfChannels]];
    [mInfoSampleRateTextField setStringValue:[mCurrentWrapper infoSampleRate]];
    [mInfoSampleSizeTextField setStringValue:[mCurrentWrapper infoSampleSize]];
    [mInfoSoundSizeTextField setStringValue:[mCurrentWrapper infoSoundSize]];

    [mInfoHorizontalResolutionTextField setStringValue:[mCurrentWrapper infoHorizontalResolution]];
    [mInfoVerticalResolutionTextField setStringValue:[mCurrentWrapper infoVerticalResolution]];
}

@end

@implementation AudioInspectorST (Notifications)

- (void)selectionHasChanged:(NSNotification*)notification
{    
    if([notification object] == mCurrentView)
        [self updateRangeFromCurrentWrapper];
}

- (void)cursorHasChanged:(NSNotification*)notification
{    
    if([notification object] == mCurrentView)
        [self updateRangeFromCurrentWrapper];
}

- (void)playerHeadHasChanged:(NSNotification*)notification
{    
    if([notification object] == mCurrentView)
        [self updateRangeFromCurrentWrapper];
}

- (void)scaleHasChanged:(NSNotification*)notification
{
    if([notification object] == mCurrentView)
    {
        [mCurrentWrapper updateRangeFromView];
        [self updateRangeFromCurrentWrapper];
    }
}

- (void)audioViewHasUpdated:(NSNotification*)notification
{
    if([notification object] == mCurrentView)
        [self applyDataFromCurrentWrapper];
}

- (void)audioWrapperDidBecomeSelectNotif:(NSNotification*)notification
{
    if([mCurrentWindow ownsWrapper:[notification object]])
        [self selectWrapper:[notification object]];
}

- (void)audioWrapperWillDeallocate:(NSNotification*)notification
{
    if(mCurrentWrapper == [notification object])
        [self selectWrapper:NULL];
}

@end