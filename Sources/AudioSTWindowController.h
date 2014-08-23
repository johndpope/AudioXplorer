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
#import "AudioDialogGenerator.h"
#import "AudioDialogRecord.h"
#import "AudioDialogFFTParameters.h"
#import "AudioDialogSonoParameters.h"
#import "AudioDialogOperations.h"
#import "AudioDialogDisplayChannelOptions.h"
#import "AudioViewEmpty.h"
#import "AudioFullScreenWindow.h"
#import "AudioFileImporter.h"

@class AudioDataUndo;

@interface AudioSTWindowController : NSWindowController <AudioSTWindowControllerProtocol>
{
    IBOutlet NSSplitView *mSplitView;
    IBOutlet NSTableView *mAudioViewList;
    IBOutlet NSBox *mPageLayoutBox;

    // View Layout

    USHORT mPageLayoutID;
    
    NSMutableArray *mPageLayoutViewArray;	// The view(s) in the layout    
    NSMutableArray *mPageLayoutEmptyViewArray;	// The empty views used in the layout
    NSMutableArray *mPageLayoutBoxArray;	// The boxes in the layout (as container for view)
    NSMutableArray *mPageLayoutSplitViewArray;	// The split-views of the layout
    
    // View list
    
    USHORT mAudioViewListDisplayType;
    NSCell *mDefaultTextCell;
    
    // Fullscreen

    AudioFullScreenWindow *mFullScreenWindow;
    
    BOOL mWindowDisplayedInFullScreen;
    BOOL mViewDisplayedInFullScreen;
    
    NSView *mFullScreenContentViewForView;	// View for full-screen view
    NSView *mFullScreenContentViewForWindow;	// View for full-screen window

    IBOutlet NSPanel *mFullScreenPanelForView;
    IBOutlet NSPanel *mFullScreenPanelForWindow;
    IBOutlet NSBox *mFullScreenBoxForView;
    IBOutlet NSBox *mFullScreenBoxForWindow;
    
    SHORT mFullScreenCurrentViewIndex;
    
    IBOutlet NSButton *mFirstViewButton;
    IBOutlet NSButton *mPreviousViewButton;
    IBOutlet NSButton *mNextViewButton;
    IBOutlet NSButton *mLastViewButton;
    
        // Toolbar

    IBOutlet NSView *mViewListDisplayModeView;
    IBOutlet NSPopUpButton *mViewListDisplayPopUp;

    IBOutlet NSView *mViewLayoutView;
    IBOutlet NSPopUpButton *mViewLayoutPopUp;
    
        // Progress indicator
        
    IBOutlet NSBox *mProgressBox;
    IBOutlet NSView *mProgressView;
    IBOutlet NSProgressIndicator *mProgressIndicator;
    IBOutlet NSTextField *mProgressTextField;
    
        // Data
        
    NSMutableArray *mAudioDataWrapperArray;
    AudioDataWrapper *mCurrentWrapper;
    
    ULONG mViewAbsoluteCount;
    
		// Undo
	
	AudioDataUndo *mAudioDataUndo;
	
        // Dialogs
        
    AudioDialogFFTParameters *mFFTParametersPanel;
    AudioDialogSonoParameters *mSonoParametersPanel;
    AudioDialogOperations *mOperationsPanel;
    
    AudioDialogDisplayChannelOptions *mAudioDisplayChannelOptionsPanel;
    AudioDialogDisplayChannelOptions *mCurrentDisplayChannelOptionsPanel;
    
    AudioDialogRecord *mAudioDialogRecord;
    AudioDialogGenerator *mAudioDialogGenerate;
    
        // Importer
    
    AudioFileImporter *mAudioFileImporter;
    
        // Keyboard
        
    unsigned int mLastModifierFlags;
}

- (NSWindow*)window;
- (void)loadPersistentData;
- (id)persistentData;

- (void)displayProgressText:(NSString*)text;
- (void)displayProgressStatus:(BOOL)flag;

- (void)documentChangeDone;
- (void)documentChangeCleared;

- (void)viewHasChanged;

- (void)setToolTips;

@end

@interface AudioSTWindowController (ToolbarAction)
- (void)changeViewListDisplay:(USHORT)listID;
- (IBAction)changeAudioViewListDisplay:(id)sender;
- (IBAction)changeAudioViewLayout:(id)sender;
@end

@interface AudioSTWindowController (PageLayout)
- (void)initPageLayout;
- (void)deallocPageLayout;
- (void)pageLayoutDidLoad;
- (void)setPageLayoutViewIDArray:(NSArray*)array;
- (NSArray*)pageLayoutViewIDArray;
- (AudioView*)pageLayoutViewForViewID:(long)viewID;
- (void)pageLayoutRemoveView:(AudioView*)view;
- (NSBox*)pageLayoutSetView:(AudioView*)view atIndex:(int)index;
- (int)pageLayoutIndexForView:(AudioView*)view;
- (void)pageLayoutReplaceView:(AudioView*)target byView:(AudioView*)source;
- (void)pageLayoutAddView:(AudioView*)view parentView:(AudioView*)parentView;
- (void)changePageLayout:(USHORT)layout;
@end

@interface AudioSTWindowController (Options)
- (void)openDisplayChannelOptionPanelForWrapper:(AudioDataWrapper*)wrapper;
@end

@interface AudioSTWindowController (Data)

- (void)fillWrapperPopUp:(NSPopUpButton*)popUp withWrapperOfKind:(SHORT)kind;
- (void)selectWrapperPopUp:(NSPopUpButton*)popUp ofKind:(SHORT)kind withWrapperID:(ULONG)wrapperID;
- (AudioDataWrapper*)wrapperOfPopUp:(NSPopUpButton*)popUp ofKind:(SHORT)kind;

- (void)insertWrapper:(AudioDataWrapper*)wrapper atIndex:(SHORT)index;
- (void)exchangeViewFromIndex:(USHORT)from toIndex:(USHORT)to;
- (void)deleteAudioDataWrapper:(AudioDataWrapper*)wrapper;

- (AudioView*)createViewForWrapper:(AudioDataWrapper*)wrapper parentWrapper:(AudioDataWrapper*)parent byAddingView:(BOOL)addView;
- (void)addViewToVisibleArea:(AudioView*)source replacingView:(AudioView*)target;
- (void)addViewToVisibleArea:(AudioView*)view parentView:(AudioView*)parent;
- (void)_addNewAudioWrapper:(AudioDataWrapper*)wrapper parentWrapper:(AudioDataWrapper*)parent byAddingView:(BOOL)addView;

- (void)createViewForAudioDataWrapper:(AudioDataWrapper*)wrapper parentWrapper:(AudioDataWrapper*)parent;
- (void)addAudioDataWrapperArrayFromDisk:(NSMutableArray*)wrappers;

- (USHORT)viewCount;
- (SHORT)indexOfView:(AudioView*)view;
- (AudioView*)viewAtIndex:(USHORT)index;

- (AudioView*)currentAudioView;
- (AudioDataWrapper*)currentAudioWrapper;
- (NSArray*)amplitudeWrapperArray;
- (BOOL)ownsWrapper:(AudioDataWrapper*)wrapper;
- (BOOL)ownsView:(AudioView*)view;
@end

@interface AudioSTWindowController (FullScreen)
- (void)updateFullScreenWindowInterface;
- (IBAction)closeFullScreenForView:(id)sender;
- (IBAction)browseViewAction:(id)sender;
@end

@interface AudioSTWindowController (FileMenu)
- (IBAction)importSoundFile:(id)sender;
@end

@interface AudioSTWindowController (ViewMenu)
- (IBAction)currentViewFullScreen:(id)sender;
- (IBAction)deleteCurrentView:(id)sender;
- (IBAction)deleteSelectedViews:(id)sender;
@end

@interface AudioSTWindowController (SoundMenu)
- (IBAction)playSound:(id)sender;
- (IBAction)playSoundSelection:(id)sender;
- (IBAction)movePlayerheadToCursor:(id)sender;

- (IBAction)recordSound:(id)sender;
- (IBAction)generateSound:(id)sender;

@end

@interface AudioSTWindowController (AnalyzeMenu)
- (void)computeOperation:(SHORT)op;
- (IBAction)computeFFTOfCursorLocation:(id)sender;
- (IBAction)computeFFTOfSelection:(id)sender;
- (IBAction)fftParameters:(id)sender;

- (IBAction)computeSonoOfVisualRange:(id)sender;
- (IBAction)computeSonoOfSelection:(id)sender;
- (IBAction)sonoParameters:(id)sender;

- (IBAction)operations:(id)sender;
@end

@interface AudioSTWindowController (WindowMenu)
- (IBAction)closeFullScreenForWindow:(id)sender;
- (IBAction)currentWindowFullScreen:(id)sender;
@end

@interface AudioSTWindowController (TableViewDelegate)
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;
- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation;
@end

@interface AudioSTWindowController (DragAndDrop)
@end

@interface AudioSTWindowController (Notification)
@end

@interface AudioSTWindowController (Toolbar)
- (void)setupToolbar;
@end