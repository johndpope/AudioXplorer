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
#import "AudioSTWindowController.h"
#import "AudioViewAppearanceController.h"
#import "AudioSonoAppearanceController.h"
#import "AudioView.h"
#import "AudioOperator.h"

@interface AudioInspectorST : NSObject
{
    AudioSTWindowController *mCurrentWindow;
    AudioDataWrapper *mCurrentWrapper;
    AudioView *mCurrentView; 
    AudioOperator *mSharedOperator;

    BOOL mValidTarget;	// Indique si l'inspecteur peut afficher les infos
    USHORT mLastDisplayIndex;
    
    IBOutlet NSWindow *mInspectorWindow;
    NSView *mInspectorView;

    // Inspector popup menu

    IBOutlet NSPopUpButton *mInspectorPopUp;

    // View 'View'

    IBOutlet NSView *mViewView;
    IBOutlet NSTextField *mViewNameTextField;
            
    IBOutlet NSTextField *mXFromTextField;
    IBOutlet NSTextField *mXToTextField;
    IBOutlet NSTextField *mYFromTextField;
    IBOutlet NSTextField *mYToTextField;
    
    IBOutlet NSTextField *mSelFromTextField;
    IBOutlet NSTextField *mSelToTextField;

    IBOutlet NSTextField *mCursorXTextField;
    IBOutlet NSTextField *mCursorYTextField;
    IBOutlet NSTextField *mCursorZTextField;

    IBOutlet NSTextField *mPlayerHeadPositionTextField;
    IBOutlet NSButton *mPlaySoundButton;
    
    IBOutlet NSTextField *mXAxisUnitTextField;
    IBOutlet NSTextField *mYAxisUnitTextField;
    IBOutlet NSTextField *mSelectionUnitTextField;
    IBOutlet NSTextField *mCursorXUnitTextField;
    IBOutlet NSTextField *mCursorYUnitTextField;
    IBOutlet NSTextField *mCursorZUnitTextField;
    IBOutlet NSTextField *mPlayerHeadPositionUnitTextField;
    
    IBOutlet NSButton *mZoomIntoSelectionButton;
    
    IBOutlet NSPopUpButton *mDisplayChannelPopUp;
    IBOutlet NSButton *mDisplayChannelOptionButton;
    
    IBOutlet NSBox *mAnalyzeBox;
    
    // View 'Appearance'

    AudioViewAppearanceController *mAudioViewAppearanceController;
    IBOutlet NSView *mViewAppearance;
    IBOutlet NSBox *mAppearanceBox;
    
    // View 'Characteristics'

    IBOutlet NSView *mViewCharacteristics;
    
    IBOutlet NSTextField *mInfoNumberOfChannelsTextField;
    IBOutlet NSTextField *mInfoSampleRateTextField;
    IBOutlet NSTextField *mInfoSampleSizeTextField;
    IBOutlet NSTextField *mInfoSoundSizeTextField;
    IBOutlet NSTextField *mInfoHorizontalResolutionTextField;
    IBOutlet NSTextField *mInfoVerticalResolutionTextField;
    
    // Analyze & parameters views

    IBOutlet NSView *mAnalyzeAmplitudeView;
    IBOutlet NSView *mAnalyzeFFTView;

    AudioSonoAppearanceController *mDataSonoAppearanceController;
        
    // FFT parameters controls

    IBOutlet NSPopUpButton *mFFTYAxisScalePopUp;    
    IBOutlet NSButton *mFFTViewLinkedButton;
    IBOutlet NSPopUpButton *mFFTViewLinkedSonoPopUp;
}

- (void)windowDidLoad;

- (void)setNoMainWindow;
- (void)setMainWindow:(NSWindow*)mainWindow;
- (void)resignMainWindow:(NSWindow*)mainWindow;

- (void)setupInspectorPopUp;

- (void)displayViewAtIndex:(USHORT)index;
- (NSView*)view;

- (void)applyDataToCurrentWrapper;
- (void)applyDataFromCurrentWrapper;
- (void)selectWrapper:(AudioDataWrapper*)wrapper;

- (void)computeOperation:(SHORT)op;

@end

@interface AudioInspectorST (ViewTab)
- (void)updateParametersFromCurrentWrapper;
- (void)updateParametersToCurrentWrapper;

- (void)updateRangeFromCurrentWrapper;
- (void)updateRangeToCurrentWrapper;

- (void)updateInfoFromCurrentWrapper;
- (void)updateInfoToCurrentWrapper;

- (void)updateAnalyzeBox;
- (IBAction)updateCurrentView:(id)sender;

- (IBAction)resetXAxis:(id)sender;
- (IBAction)resetYAxis:(id)sender;
- (IBAction)zoomIntoSelection:(id)sender;
- (IBAction)playSound:(id)sender;

- (IBAction)displayChannelAction:(id)sender;
- (IBAction)displayChannelOptionAction:(id)sender;

@end

@interface AudioInspectorST (AmplitudeAnalyze)
- (void)updateAmplitudeAnalyzeParametersFromCurrentWrapper;
- (void)updateAmplitudeAnalyzeParametersToCurrentWrapper;
@end

@interface AudioInspectorST (FFTAnalyze)
- (void)updateFFTAnalyzeParametersFromCurrentWrapper;
- (void)updateFFTAnalyzeParametersToCurrentWrapper;

- (IBAction)changeYAxisScale:(id)sender;
- (IBAction)fftViewLinkedButton:(id)sender;
- (IBAction)fftViewLinkedPopUp:(id)sender;
@end

@interface AudioInspectorST (SonoAnalyze)
@end

@interface AudioInspectorST (AppearanceTab)
- (void)updateAppearanceFromCurrentWrapper;

- (IBAction)checkBoxAction:(id)sender;
- (IBAction)colorWellAction:(id)sender;
- (IBAction)sliderAction:(id)sender;
@end

@interface AudioInspectorST (CharacteristicsTab)
- (void)updateCharacteristicsFromCurrentWrapper;
@end

@interface AudioInspectorST (Notifications)
- (void)playerHeadHasChanged:(NSNotification*)notification;
- (void)selectionHasChanged:(NSNotification*)notification;
- (void)audioWrapperDidBecomeSelectNotif:(NSNotification*)notification;
@end
