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

#import "AudioDocument.h"
#import "AudioSTWindowController.h"
#import "AudioInspectorController.h"
#import "AudioOperator.h"
#import "AudioDialogPrefs.h"
#import "AIFFCodec.h"
#import "AudioUtilities.h"
#import "AudioView3D.h"
#import "AudioNotifications.h"
#import "AudioExchange.h"
#import "AudioPrinter.h"
#import "AudioEffectController.h"
#import "AudioSplitView.h"
#import "AudioDataUndo.h"

#define FULL_SCREEN 1 // 0 for debug

@implementation AudioSTWindowController

- (id)init
{
    if(self = [super initWithWindowNibName:@"AudioSTWindow"])
    {
        [self setShouldCascadeWindows:NO];
        
        mAudioDataWrapperArray = [[NSMutableArray alloc] init];
        mCurrentWrapper = NULL;
        
		mAudioDataUndo = [[AudioDataUndo alloc] init];
		
        mViewAbsoluteCount = 0;
        
        mAudioViewListDisplayType = 0;
        mDefaultTextCell = NULL;
        
        mFFTParametersPanel = [[AudioDialogFFTParameters alloc] init];
        mSonoParametersPanel = [[AudioDialogSonoParameters alloc] init];
        mOperationsPanel = [[AudioDialogOperations alloc] init];

        mAudioDisplayChannelOptionsPanel = [[AudioDialogDisplayChannelOptions alloc] init];
        mCurrentDisplayChannelOptionsPanel = NULL;
        
        mAudioDialogRecord = [[AudioDialogRecord alloc] init];
        mAudioDialogGenerate = [[AudioDialogGenerator alloc] init];   
        
        mWindowDisplayedInFullScreen = NO;
        mViewDisplayedInFullScreen = NO;
        mFullScreenWindow = NULL;     
        
        mLastModifierFlags = 0;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(mainWindowChanged:) 
                                                    name:NSWindowDidBecomeMainNotification
                                                    object:NULL];
    
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(audioViewShouldBeReplaced:)
                                                name:AudioViewShouldBeReplacedNotification
                                                object:NULL];
    
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                selector:@selector(audioWrapperDidBecomeSelectNotif:)
                                                    name:AudioWrapperDidBecomeSelectNotification
                                                    object:NULL];
    
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(prefsUseToolTipsChanged:) 
                                                    name:AudioPrefsUseToolTipsChangedNotification
                                                    object:NULL];

        [self initPageLayout];
    }
    return self;
}

- (void)dealloc
{
	[[AudioInspectorController shared] windowControllerWillClose:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [mDefaultTextCell release];
        
    [mSonoParametersPanel release];
    [mFFTParametersPanel release];
    [mOperationsPanel release];
    [mAudioDisplayChannelOptionsPanel release];
    
    [mAudioDialogRecord release];
    [mAudioDialogGenerate release];
    
    [mFullScreenContentViewForView release];
    [mFullScreenContentViewForWindow release];
    
	[mAudioDataUndo release];
	
    [self deallocPageLayout];
    
    [super dealloc];
}

- (void)windowDidLoad
{
    [[self window] useOptimizedDrawing:YES];
        
    mFullScreenContentViewForView = [[mFullScreenPanelForView contentView] retain];
    mFullScreenContentViewForWindow = [[mFullScreenPanelForWindow contentView] retain];

//    [mAudioViewList registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, nil]];        
    
    [self setToolTips];
    [self setupToolbar];
        
    [mFFTParametersPanel windowDidLoad];
    [mSonoParametersPanel windowDidLoad];
        
    mDefaultTextCell = [[[mAudioViewList tableColumns] objectAtIndex:0] dataCell];
    [mDefaultTextCell retain];
    
    mAudioDataWrapperArray = [[[self document] documentModel] dataWrappers];
    if([mAudioDataWrapperArray count]>0)
        [self addAudioDataWrapperArrayFromDisk:mAudioDataWrapperArray];
    
    [self loadPersistentData];
    [self pageLayoutDidLoad];
    [self changeViewListDisplay:mAudioViewListDisplayType];
    [self documentChangeCleared];
}

- (void)audioDialogRecordHasFinished:(AudioDataWrapper*)wrapper
{
    if(wrapper)
        [mAudioViewList selectRow:[mAudioDataWrapperArray indexOfObjectIdenticalTo:wrapper]
                        byExtendingSelection:NO];
}

- (void)audioDialogGenerateHasFinished:(AudioDataWrapper*)wrapper
{
    if(wrapper)
        [mAudioViewList selectRow:[mAudioDataWrapperArray indexOfObjectIdenticalTo:wrapper]
                        byExtendingSelection:NO];
}

- (NSWindow*)window
{
    if(mWindowDisplayedInFullScreen)
        return mFullScreenWindow;
    else
        return [super window];
}

- (void)loadPersistentData
{
    NSArray *array = [[[self document] documentModel] staticWindowPersistentData];
    if(array)
    {
        [self setPageLayoutViewIDArray:[array objectAtIndex:0]];
        mViewAbsoluteCount = [[array objectAtIndex:1] unsignedLongValue];
        mPageLayoutID = [[array objectAtIndex:2] unsignedShortValue];
        mAudioViewListDisplayType = [[array objectAtIndex:3] unsignedShortValue];
    }
}

- (id)persistentData
{
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:[self pageLayoutViewIDArray]];
    [array addObject:[NSNumber numberWithUnsignedLong:mViewAbsoluteCount]];
    [array addObject:[NSNumber numberWithUnsignedShort:mPageLayoutID]];
    [array addObject:[NSNumber numberWithUnsignedShort:mAudioViewListDisplayType]];
    return array;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    SEL action = [menuItem action];
    AudioDataWrapper *wrapper = [self currentAudioWrapper];
        
    if(action == @selector(exportAsAIFF:))
        return [AudioExchange canExportDataAsAIFF:[wrapper data]];
    if(action == @selector(exportAsRawData:))
        return [AudioExchange canExportDataAsRawData:[wrapper data]];
    
    if(action == @selector(duplicate:))
        return wrapper != NULL;

    if(action == @selector(performUndo:))
        return [mAudioDataUndo canUndoOnData:[wrapper data]] && [mAudioDataUndo hasUndoData];

    if(action == @selector(currentViewFullScreen:))
        return mWindowDisplayedInFullScreen == NO
     && mViewDisplayedInFullScreen == NO && [self viewCount]>0;

    if(action == @selector(doReverseXAxisScale:))
        return wrapper && [wrapper kind] != KIND_FFT;
        
    if(action == @selector(deleteCurrentView:))
        return [self viewCount]>0;
    if(action == @selector(deleteSelectedViews:))
        return [mAudioViewList numberOfSelectedRows]>0;
    
    if(action == @selector(playSound:))
        return [wrapper supportPlayback];
    if(action == @selector(playSoundSelection:))
        return [wrapper supportPlayback];
    if(action == @selector(movePlayerheadToCursor:))
        return [wrapper supportPlayback];

    if(action == @selector(computeFFTOfCursorLocation:))
        return [wrapper supportFFT] &&
        ([wrapper displayedChannel]!=LISSAJOUS_CHANNEL);
    if(action == @selector(computeFFTOfSelection:))
        return [wrapper supportFFT] && [wrapper selectionExist] &&
        ([wrapper displayedChannel]!=LISSAJOUS_CHANNEL);
    if(action == @selector(fftParameters:))
        return [wrapper supportFFT] &&
        ([wrapper displayedChannel]!=LISSAJOUS_CHANNEL);

    if(action == @selector(computeSonoOfVisualRange:))
        return [wrapper supportSono] &&
        ([wrapper displayedChannel]==LEFT_CHANNEL || [wrapper displayedChannel]==RIGHT_CHANNEL);

    if(action == @selector(computeSonoOfSelection:))
        return [wrapper supportSono] && [wrapper selectionExist] &&
        ([wrapper displayedChannel]==LEFT_CHANNEL || [wrapper displayedChannel]==RIGHT_CHANNEL);
    if(action == @selector(sonoParameters:))
        return [wrapper supportSono] &&
        ([wrapper displayedChannel]==LEFT_CHANNEL || [wrapper displayedChannel]==RIGHT_CHANNEL);

    if(action == @selector(createLinkedFFTView:))
        return wrapper && [wrapper kind] == KIND_SONO;

    if(action == @selector(operations:))
        return [self viewCount]>0;

    if(action == @selector(redoLastEffect:))
        return wrapper && [wrapper kind] == KIND_AMPLITUDE
        && [[AudioEffectController shared] canRedoLastEffect];
    if(action == @selector(performEffect:))
        return wrapper && [wrapper kind] == KIND_AMPLITUDE;

    if(action == @selector(currentWindowFullScreen:))
        return mWindowDisplayedInFullScreen == NO
     && mViewDisplayedInFullScreen == NO;

    return YES;
}

- (void)addAudioDataWrapper:(id)wrapper parentWrapper:(id)parent
{
    [self createViewForAudioDataWrapper:wrapper parentWrapper:parent];
}

- (void)displayProgressText:(NSString*)text
{
    [mProgressTextField setStringValue:text];
}

- (void)displayProgressStatus:(BOOL)flag
{
    if(flag)
    {
        [mProgressBox setContentView:mProgressView];
        [mProgressIndicator setUsesThreadedAnimation:YES];
        [mProgressIndicator startAnimation:self];
    } else
    {
        [mProgressBox setContentView:NULL];
        [mProgressIndicator stopAnimation:self];
    }
}

- (void)documentChangeDone
{
    [[self document] updateChangeCount:NSChangeDone];
}

- (void)documentChangeCleared
{
    [[self document] updateChangeCount:NSChangeCleared];
}

- (void)viewHasChanged
{
    [mSplitView setNeedsDisplay:YES];
    [mAudioViewList reloadData];
    [self documentChangeDone];
}

- (void)setToolTips
{
    [mAudioViewList removeAllToolTips];
    if([[AudioDialogPrefs shared] useToolTips])
        [mAudioViewList setToolTip:NSLocalizedString(@"Drag any item to one of the right view.", NULL)];
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
    return YES;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
    return [sender isVertical]?100:100;
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
    return [sender isVertical]?proposedMax-200:proposedMax-100;
}

@end

@implementation AudioSTWindowController (ToolbarAction)

- (void)invalidateViewIcon
{
    NSEnumerator *enumerator = [mAudioDataWrapperArray objectEnumerator];
    id object = NULL;
    while(object = [enumerator nextObject])
        [(AudioView*)[object view] invalidateIcon];
}

- (void)changeViewListDisplay:(USHORT)listID
{
    NSTableColumn *column = [[mAudioViewList tableColumns] objectAtIndex:0];
    
    NSCell *cell = [mDefaultTextCell copy];
    FLOAT height = 14;
    
    mAudioViewListDisplayType = listID;
    [mViewListDisplayPopUp selectItemAtIndex:mAudioViewListDisplayType];
    
    switch(mAudioViewListDisplayType) {
        case 0:	// Text
            height = 14;
            break;
        
        case 1: // Icon
			if(cell) [cell release];
            cell = [[NSImageCell alloc] init];
            [cell setType:NSImageCellType];
            height = 80;
            break;

        case 2: // Icon & Text
			if(cell) [cell release];
            cell = [[NSImageCell alloc] init];
            [cell setType:NSImageCellType];
            height = 80;
            break;
    }

    [self invalidateViewIcon];
    
    [column setDataCell:cell];
    [mAudioViewList setRowHeight:height];
    [mAudioViewList reloadData];
    
    [cell release];
}

- (IBAction)changeAudioViewListDisplay:(id)sender
{
    [self changeViewListDisplay:[sender indexOfSelectedItem]];
}

- (IBAction)changeAudioViewLayout:(id)sender
{
    [self changePageLayout:[sender indexOfSelectedItem]];
}

@end

@implementation AudioSTWindowController (PageLayout)

- (void)initPageLayout
{
    mPageLayoutID = 1;
    
    mPageLayoutViewArray = [[NSMutableArray alloc] init];
    mPageLayoutEmptyViewArray = [[NSMutableArray alloc] init];
    mPageLayoutBoxArray = [[NSMutableArray alloc] init];
    
    int page;
    for(page=0; page<4; page++)
    {
        AudioViewEmpty *empty = [[AudioViewEmpty alloc] initWithFrame:NSMakeRect(0,0,100,100)];
        [mPageLayoutViewArray addObject:empty];
        [mPageLayoutEmptyViewArray addObject:empty];
        [empty release];
        
        NSBox *box = [[NSBox alloc] initWithFrame:NSMakeRect(0,0,100,100)];
        [box setBorderType:NSNoBorder];
        [box setTitlePosition:NSNoTitle];
        [mPageLayoutBoxArray addObject:[box autorelease]];
    }
}

- (void)deallocPageLayout
{
    [mPageLayoutViewArray makeObjectsPerformSelector:@selector(removeFromSuperview)];

    [mPageLayoutViewArray release];
    [mPageLayoutEmptyViewArray release];
    [mPageLayoutBoxArray release];
}

- (void)pageLayoutDidLoad
{
    [mPageLayoutBox setBorderType:NSNoBorder];
    [mPageLayoutBox setTitlePosition:NSNoTitle];
    
    [self changePageLayout:mPageLayoutID];
}

- (void)setPageLayoutViewIDArray:(NSArray*)array
{
    int index;
    for(index=0; index<[array count]; index++)
    {
        long viewID = [[array objectAtIndex:index] longValue];
        if(viewID == EMPTY_VIEW_ID)
            [self pageLayoutSetView:[mPageLayoutEmptyViewArray objectAtIndex:index] atIndex:index];
        else
            [self pageLayoutSetView:[self pageLayoutViewForViewID:viewID] atIndex:index];
    }
}

- (NSArray*)pageLayoutViewIDArray
{
    NSMutableArray *array = [NSMutableArray array];
    int index;
    for(index=0; index<[mPageLayoutViewArray count]; index++)
    {
        [array addObject:[NSNumber numberWithLong:[[mPageLayoutViewArray objectAtIndex:index] viewID]]];
    }
    return array;
}

- (int)pageLayoutFirstEmptyViewIndex
{
    int index;
    for(index=0; index<=MIN([mPageLayoutViewArray count]-1, mPageLayoutID); index++)
    {
        if([[mPageLayoutViewArray objectAtIndex:index] viewID] == EMPTY_VIEW_ID)
            return index;
    }
    
    return 0;
}

// Return the view object of the first non-empty view number 'number'
- (id)pageLayoutNonEmptyViewAtNumber:(int)number
{
    NSEnumerator *enumerator = [mPageLayoutViewArray objectEnumerator];
    id view = NULL;
    int count = 0;
    while(view = [enumerator nextObject])
    {
        count++;
        if([view viewID] != EMPTY_VIEW_ID && count == number)
            return view;
    }
        // Return an empty view if not found
    return [mPageLayoutEmptyViewArray objectAtIndex:number-1];
}

- (void)pageLayoutRemoveView:(AudioView*)view
{
    int index = [self pageLayoutIndexForView:view];
	if(index != NSNotFound)
		[self pageLayoutSetView:[mPageLayoutEmptyViewArray objectAtIndex:index] atIndex:index];
}

- (NSBox*)pageLayoutSetView:(AudioView*)view atIndex:(int)index
{    		
    // Assign the view to the corresponding box
    NSBox *box = [mPageLayoutBoxArray objectAtIndex:index];
    [box setContentView:view];
    
    // Add the view to the page layout array
    [mPageLayoutViewArray replaceObjectAtIndex:index withObject:view];
    
    return box;
}

- (NSBox*)pageLayoutSetEmptyViewAtIndex:(int)index
{
	if(index == NSNotFound)
		return NULL;
	else
		return [self pageLayoutSetView:[mPageLayoutEmptyViewArray objectAtIndex:index] atIndex:index];
}

// Returns the layout index for the given view
- (int)pageLayoutIndexForView:(AudioView*)view
{
    int index;
    for(index=0; index<[mPageLayoutViewArray count]; index++) {
        if(view == [mPageLayoutViewArray objectAtIndex:index])
            return index;
    }

    return NSNotFound;
}

// Returns the audio view for the corresponding view ID
- (AudioView*)pageLayoutViewForViewID:(long)viewID
{
    int index;
    for(index=0; index<[mAudioDataWrapperArray count]; index++)
    {
        if([[mAudioDataWrapperArray objectAtIndex:index] viewID] == viewID)
            return [(AudioDataWrapper*)[mAudioDataWrapperArray objectAtIndex:index] view];
    }
    return NULL;
}

- (void)pageLayoutReplaceView:(AudioView*)target byView:(AudioView*)source
{
    if(target == source) return;
    
    int sourceIndex = [self pageLayoutIndexForView:source];
    if(sourceIndex!=NSNotFound)
        [self pageLayoutSetEmptyViewAtIndex:sourceIndex];
        
    int index = [self pageLayoutIndexForView:target];
    [self pageLayoutSetView:source atIndex:index];
}

- (void)pageLayoutAddView:(AudioView*)view parentView:(AudioView*)parentView
{
    // First, the simple situation
    if(mPageLayoutID == 0)
    {
        [self pageLayoutSetView:view atIndex:0];
        return;
    } else if(parentView == NULL)
    {
        [self pageLayoutSetView:view atIndex:[self pageLayoutFirstEmptyViewIndex]];
        return;
    }
        
    // Is there any room below the parent view ?
    int parentIndex = [self pageLayoutIndexForView:parentView];
    if(parentIndex==mPageLayoutID)
    {
        // No. Offset all views to the top to make a room for the new view.
        
        int index;
        for(index=0; index<parentIndex; index++)
        {
            [self pageLayoutSetView:[mPageLayoutViewArray objectAtIndex:index+1] atIndex:index];
        }
        [self pageLayoutSetView:view atIndex:parentIndex];
    } else
    {
        // Yes, there is room. Offset needed views to the bottom.
        
        int targetIndex = parentIndex+1;
        
        int index;
        for(index=mPageLayoutID; index>targetIndex; index--)
        {
            [self pageLayoutSetView:[mPageLayoutViewArray objectAtIndex:index-1] atIndex:index];
        }
        [self pageLayoutSetView:view atIndex:targetIndex];
    }
}

// Set the one-view page layout
- (void)changePageLayoutOne
{
    id view = [self pageLayoutNonEmptyViewAtNumber:1];
    [mPageLayoutBox setContentView:[self pageLayoutSetView:view atIndex:0]];
}

// Set the two-views page layout
- (void)changePageLayoutTwo
{
    AudioSplitView *sv = [[AudioSplitView alloc] initWithFrame:[mPageLayoutBox frame]];
    [sv setDelegate:self];
    
    NSRect frame = [sv frame];
    NSRect a = frame;
    NSRect b = frame;

    a.size.height *= 0.5;
    a.origin.y += a.size.height;
    
    b.size.height *= 0.5;
    
    [mPageLayoutBox setContentView:sv];

    NSBox *b1 = [mPageLayoutBoxArray objectAtIndex:0];
    NSBox *b2 = [mPageLayoutBoxArray objectAtIndex:1];

    [sv addSubview:b1];
    [sv addSubview:b2];
    [sv adjustSubviews];

    AudioView *v1 = [self pageLayoutNonEmptyViewAtNumber:1];
    AudioView *v2 = [self pageLayoutNonEmptyViewAtNumber:2];

    [v1 setFrame:a];
    [v2 setFrame:b];

    [self pageLayoutSetView:v1 atIndex:0];
    [self pageLayoutSetView:v2 atIndex:1];
}

// Set the three-views page layout
- (void)changePageLayoutThree
{
    NSRect r1 = [mPageLayoutBox frame];
    NSRect r2 = [mPageLayoutBox frame];
    
    r1.size.height *= 0.5;
    r1.origin.y += r1.size.height;
    
    AudioSplitView *sv1 = [[AudioSplitView alloc] initWithFrame:r1];
    AudioSplitView *sv2 = [[AudioSplitView alloc] initWithFrame:r2];
    [sv1 setDelegate:self];
    [sv2 setDelegate:self];
    [sv1 setVertical:YES];

    NSRect v1r = r1;
    NSRect v2r = r1;
    NSRect v3r = r2;

    v1r.size.width *= 0.5;
    
    v2r.size.width *= 0.5;
    v2r.origin.x += v2r.size.width;
    
    v3r.size.height *= 0.5;
        
    [mPageLayoutBox setContentView:sv2];

    NSBox *b1 = [mPageLayoutBoxArray objectAtIndex:0];
    NSBox *b2 = [mPageLayoutBoxArray objectAtIndex:1];
    NSBox *b3 = [mPageLayoutBoxArray objectAtIndex:2];

    [b1 setFrame:v1r];
    [b2 setFrame:v2r];
    [b3 setFrame:v3r];
    
    [sv1 addSubview:b1];
    [sv1 addSubview:b2];
    [sv1 adjustSubviews];

    [sv2 addSubview:sv1];
    [sv2 addSubview:b3];
    [sv2 adjustSubviews];

    AudioView *v1 = [self pageLayoutNonEmptyViewAtNumber:1];
    AudioView *v2 = [self pageLayoutNonEmptyViewAtNumber:2];
    AudioView *v3 = [self pageLayoutNonEmptyViewAtNumber:3];

    [v1 setFrame:v1r];
    [v2 setFrame:v2r];
    [v3 setFrame:v3r];

    [self pageLayoutSetView:v1 atIndex:0];
    [self pageLayoutSetView:v2 atIndex:1];
    [self pageLayoutSetView:v3 atIndex:2];
}

// Set the four-views page layout
- (void)changePageLayoutFour
{
    NSRect r1 = [mPageLayoutBox frame];
    NSRect r2 = [mPageLayoutBox frame];
    NSRect r3 = [mPageLayoutBox frame];
    
    r1.size.height *= 0.5;
    r1.origin.y += r1.size.height;    

    r2.size.height *= 0.5;    
    
    AudioSplitView *sv1 = [[AudioSplitView alloc] initWithFrame:r1];
    AudioSplitView *sv2 = [[AudioSplitView alloc] initWithFrame:r2];
    AudioSplitView *sv3 = [[AudioSplitView alloc] initWithFrame:r3];
    
    [sv1 setDelegate:self];
    [sv2 setDelegate:self];
    [sv3 setDelegate:self];
    
    [sv1 setVertical:YES];
    [sv2 setVertical:YES];

    NSRect v1r = r1;
    NSRect v2r = r1;
    NSRect v3r = r2;
    NSRect v4r = r2;

    v1r.size.width *= 0.5;
    
    v2r.size.width *= 0.5;
    v2r.origin.x += v2r.size.width;
    
    v3r.size.width *= 0.5;

    v4r.size.width *= 0.5;
    v4r.origin.x += v4r.size.width;
        
    [mPageLayoutBox setContentView:sv3];

    NSBox *b1 = [mPageLayoutBoxArray objectAtIndex:0];
    NSBox *b2 = [mPageLayoutBoxArray objectAtIndex:1];
    NSBox *b3 = [mPageLayoutBoxArray objectAtIndex:2];
    NSBox *b4 = [mPageLayoutBoxArray objectAtIndex:3];

    [b1 setFrame:v1r];
    [b2 setFrame:v2r];
    [b3 setFrame:v3r];
    [b4 setFrame:v4r];
    
    [sv1 addSubview:b1];
    [sv1 addSubview:b2];
    [sv1 adjustSubviews];

    [sv2 addSubview:b3];
    [sv2 addSubview:b4];
    [sv2 adjustSubviews];

    [sv3 addSubview:sv1];
    [sv3 addSubview:sv2];
    [sv3 adjustSubviews];

    AudioView *v1 = [self pageLayoutNonEmptyViewAtNumber:1];
    AudioView *v2 = [self pageLayoutNonEmptyViewAtNumber:2];
    AudioView *v3 = [self pageLayoutNonEmptyViewAtNumber:3];
    AudioView *v4 = [self pageLayoutNonEmptyViewAtNumber:4];

    [v1 setFrame:v1r];
    [v2 setFrame:v2r];
    [v3 setFrame:v3r];
    [v4 setFrame:v4r];

    [self pageLayoutSetView:v1 atIndex:0];
    [self pageLayoutSetView:v2 atIndex:1];
    [self pageLayoutSetView:v3 atIndex:2];
    [self pageLayoutSetView:v4 atIndex:3];
}

- (void)changePageLayout:(USHORT)layout
{
    mPageLayoutID = layout;
    
    switch(mPageLayoutID) {
        case 0:	// One view
            [self changePageLayoutOne];
            break;
        case 1:	// Two views
            [self changePageLayoutTwo];
            break;
        case 2:	// Three views
            [self changePageLayoutThree];
            break;
        case 3:	// Four views
            [self changePageLayoutFour];
            break;
    }
    
    [mViewLayoutPopUp selectItemAtIndex:mPageLayoutID];
    [self documentChangeDone];
}

@end

@implementation AudioSTWindowController (Options)

- (void)displayChannelOptionPanelEnded:(NSNumber*)canceled
{
    if([canceled boolValue] == NO)
        [self documentChangeDone];
        
    mCurrentDisplayChannelOptionsPanel = NULL;
}

- (void)openDisplayChannelOptionPanelForWrapper:(AudioDataWrapper*)wrapper
{
    if(mCurrentDisplayChannelOptionsPanel == NULL)
    {
        mCurrentDisplayChannelOptionsPanel = mAudioDisplayChannelOptionsPanel;
        [mCurrentDisplayChannelOptionsPanel openPanelForWrapper:wrapper parentWindow:self
                            endSelector:@selector(displayChannelOptionPanelEnded:)];
    }
}

@end

@implementation AudioSTWindowController (Data)

- (void)fillWrapperPopUp:(NSPopUpButton*)popUp withWrapperOfKind:(SHORT)kind
{
    [popUp removeAllItems];
    
    NSEnumerator *enumerator = [mAudioDataWrapperArray objectEnumerator];
    AudioDataWrapper *wrapper = NULL;
    while(wrapper = [enumerator nextObject])
    {
        if([wrapper kind] == kind)
            [popUp addItemWithTitle:[wrapper viewName]];
    }
}

- (void)selectWrapperPopUp:(NSPopUpButton*)popUp ofKind:(SHORT)kind withWrapperID:(ULONG)wrapperID
{
    short index = 0;
    NSEnumerator *enumerator = [mAudioDataWrapperArray objectEnumerator];
    AudioDataWrapper *wrapper = NULL;
    while(wrapper = [enumerator nextObject])
    {
        if([wrapper kind] == kind && [wrapper viewID] == wrapperID)
        {
            [popUp selectItemAtIndex:index];
            break;
        }
    }
}

- (AudioDataWrapper*)wrapperOfPopUp:(NSPopUpButton*)popUp ofKind:(SHORT)kind
{
    short index = 0;
    NSEnumerator *enumerator = [mAudioDataWrapperArray objectEnumerator];
    AudioDataWrapper *wrapper = NULL;
    while(wrapper = [enumerator nextObject])
    {
        if([wrapper kind] == kind)
        {
            if(index == [popUp indexOfSelectedItem])
                return wrapper;
            index++;
        }
    }
    return NULL;
}

- (void)insertWrapper:(AudioDataWrapper*)wrapper atIndex:(SHORT)index
{    
    [mAudioDataWrapperArray insertObject:wrapper atIndex:index];
    [self documentChangeDone];
}

- (void)exchangeViewFromIndex:(USHORT)from toIndex:(USHORT)to
{
    [mAudioDataWrapperArray exchangeObjectAtIndex:from withObjectAtIndex:to];
    [self documentChangeDone];
}

- (void)deleteAudioDataWrapper:(AudioDataWrapper*)wrapper
{
    [self pageLayoutRemoveView:[wrapper view]];
        
    [[wrapper view] setSelect:NO];
    int index = [mAudioDataWrapperArray indexOfObjectIdenticalTo:wrapper];
    if(index != NSNotFound)
    {
        if(mCurrentWrapper == wrapper)
            mCurrentWrapper = NULL;
        
        [mAudioDataWrapperArray removeObjectAtIndex:index];
        [self documentChangeDone];
        
        index--;
        if(index>=0)
            [[(AudioDataWrapper*)[mAudioDataWrapperArray objectAtIndex:index] view] setSelect:YES];
        else if([NSApp mainWindow] == [self window])
			[[AudioInspectorController shared] setMainWindow:[self window]];
    }
}

- (AudioView*)createViewForWrapper:(AudioDataWrapper*)wrapper parentWrapper:(AudioDataWrapper*)parent byAddingView:(BOOL)addView
{
    AudioView *view = NULL;

   /* if([[ARRegManager sharedRegManager] isRegistered] == NO && [mAudioDataWrapperArray count]>=4)
    {
        NSRunAlertPanel(NSLocalizedString(@"Cannot create more than 4 views", NULL), NSLocalizedString(@"Register AudioXplorer to remove this limitation.", NULL), NSLocalizedString(@"OK", NULL), NULL, NULL, NULL);    
        return NULL;
    }*/
    
    NSRect viewFrame = NSMakeRect(0, 0, 100, 100); //[mTargetBox frame];
        
    switch([wrapper kind]) {
        case KIND_AMPLITUDE:
        case KIND_FFT:
            view =  [[AudioView2D alloc] initWithFrame:viewFrame];
            break;
            
        case KIND_SONO:
            view =  [[AudioView3D alloc] initWithFrame:viewFrame];
            [wrapper setAllowsFFTSize:NO];
            break;
        
        default:
            NSLog(@"_addNewAudioWrapper: Unsupported operation");
            return NULL;
            break;
    }

    if(addView)
    {
        [view setViewID:++mViewAbsoluteCount];
        if(parent)
        {
            SHORT index = [mAudioDataWrapperArray indexOfObjectIdenticalTo:parent]+1;
            [self insertWrapper:wrapper atIndex:index];
        } else
        {
            [mAudioDataWrapperArray addObject:wrapper];
            [self documentChangeDone];
        }
        [mAudioViewList reloadData]; 
    }
    
    if([wrapper viewName] == NULL)
        [wrapper setViewName:[NSString stringWithFormat:@"%@ (%d)", [[wrapper data] name], [view viewID]]
                    always:YES];
    else
        [wrapper setViewName:[NSString stringWithFormat:@"%@ (%d)", [wrapper viewName], [view viewID]]
        always:NO];
        
    [wrapper setView:view];
    [wrapper setViewFrame:viewFrame];
    
    [view setDataSource:[wrapper data]];
    [view applyDataSourceToView];
    [view setDelegate:wrapper];
    
    [wrapper applyDataToView];
    [wrapper applyToView];

    [view setSelect:YES];

    return [view autorelease];
}

- (void)addViewToVisibleArea:(AudioView*)source replacingView:(AudioView*)target
{
    [self pageLayoutReplaceView:target byView:source];
}

- (void)addViewToVisibleArea:(AudioView*)view parentView:(AudioView*)parent
{
    [self pageLayoutAddView:view parentView:parent];    
}

- (void)_addNewAudioWrapper:(AudioDataWrapper*)wrapper parentWrapper:(AudioDataWrapper*)parent byAddingView:(BOOL)addView
{
    AudioView *view = [self createViewForWrapper:wrapper parentWrapper:parent byAddingView:addView];
    if(view)
    {    
        [self addViewToVisibleArea:view parentView:[parent view]];
    
        mCurrentWrapper = wrapper;
            
        if([NSApp mainWindow] == [self window])
            [[AudioInspectorController shared] setMainWindow:[self window]];            
    }  
}

- (void)createViewForAudioDataWrapper:(AudioDataWrapper*)wrapper parentWrapper:(AudioDataWrapper*)parent
{    
    if([[AudioDialogPrefs shared] addViewAtEnd])
        parent = NULL;
          
    [self _addNewAudioWrapper:wrapper parentWrapper:parent byAddingView:YES];
}

- (void)addAudioDataWrapperArrayFromDisk:(NSMutableArray*)wrappers
{
    USHORT index;
    for(index=0; index<[wrappers count]; index++)
    {
        AudioDataWrapper* wrapper = [wrappers objectAtIndex:index];
        [wrapper setViewNameImmutable:YES];

        [self createViewForWrapper:wrapper parentWrapper:NULL byAddingView:NO];
    }
}

- (USHORT)viewCount
{
    return [mAudioDataWrapperArray count];
}

- (SHORT)indexOfView:(AudioView*)view
{
    USHORT index;
    for(index=0; index<[mAudioDataWrapperArray count]; index++)
    {
        if([(AudioDataWrapper*)[mAudioDataWrapperArray objectAtIndex:index] view] == view)
            return index;
    }
    return -1;
}

- (AudioView*)viewAtIndex:(USHORT)index
{
    return [(AudioDataWrapper*)[mAudioDataWrapperArray objectAtIndex:index] view];
}

- (AudioView*)currentAudioView
{
    return [mCurrentWrapper view];
}

- (AudioDataWrapper*)currentAudioWrapper
{
    return mCurrentWrapper;
}

- (NSArray*)amplitudeWrapperArray
{
    NSMutableArray *array = [[NSMutableArray alloc] init];

    NSEnumerator *enumerator = [mAudioDataWrapperArray objectEnumerator];
    AudioDataWrapper *wrapper;
        
    while(wrapper = [enumerator nextObject])
    {
        if([wrapper kind] == KIND_AMPLITUDE)
            [array addObject:wrapper];
    }    

    return [array autorelease];
}

- (BOOL)ownsWrapper:(AudioDataWrapper*)wrapper
{
    return ([mAudioDataWrapperArray indexOfObjectIdenticalTo:wrapper]!=NSNotFound);
}

- (BOOL)ownsView:(AudioView*)view
{
    NSEnumerator *enumerator = [mAudioDataWrapperArray objectEnumerator];
    AudioDataWrapper *wrapper;
        
    while(wrapper = [enumerator nextObject])
    {
        if([wrapper view] == view)
            return YES;
    }    

    return NO;
}

@end

@implementation AudioSTWindowController (FileMenu)

- (void)amplitudeFromAnyFileCompletedWithAmplitude:(AudioDataAmplitude*)amplitude
{
    if(amplitude)
    {
        AudioDataWrapper *wrapper = [AudioDataWrapper initWithAudioData:amplitude];
        [wrapper setViewName:[[[mAudioFileImporter sourceFile] stringByDeletingPathExtension] lastPathComponent] always:YES];
        [self addAudioDataWrapper:wrapper parentWrapper:NULL];    
    } else
    {
        NSBeginAlertSheet(NSLocalizedString(@"Unable to import data from file.", NULL),
                            NSLocalizedString(@"OK", NULL), NULL, NULL, [self window], self,
                            NULL, NULL, NULL, [mAudioFileImporter errorMessage]);    
    }
    [mAudioFileImporter release];
}

- (void)importSoundFile_:(NSTimer*)timer
{   
    mAudioFileImporter = [[AudioFileImporter alloc] init];
        
    BOOL success = [mAudioFileImporter amplitudeFromAnyFile:[timer userInfo]
                                    delegate:self
                                    parentWindow:[self window]];

    if(success == NO)
    {
        NSBeginAlertSheet(NSLocalizedString(@"An error has occured when trying to launch the importer process.", NULL),
                            NSLocalizedString(@"OK", NULL), NULL, NULL, [self window], self,
                            NULL, NULL, NULL, [mAudioFileImporter errorMessage]); 
        [mAudioFileImporter release];
    }
}

- (void)importSoundFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode==NSOKButton)
    {
        NSArray *files = [sheet filenames];
        if([files count]>0)
        {
            // Invoke with an NSTimer to let the Open Dialog sheet close
            [NSTimer scheduledTimerWithTimeInterval:0 target:self
                        selector:@selector(importSoundFile_:) userInfo:[files objectAtIndex:0] repeats:NO];
        }
    }
}

- (IBAction)importSoundFile:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel beginSheetForDirectory:NULL file:NULL
				types:[NSArray arrayWithObjects:@"aif", @"aiff", @"mp4", @"mp3", @"mov", @"m4a", @"snd", @"wav", nil]
				modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(importSoundFilePanelDidEnd:returnCode:contextInfo:)
				contextInfo:NULL];
}

- (IBAction)exportAsAIFF:(id)sender
{
    [AudioExchange exportDataAsAIFFFromView:[mCurrentWrapper view]];
}

- (IBAction)exportAsRawData:(id)sender
{
    [AudioExchange exportDataAsRawDataFromView:[mCurrentWrapper view]];
}

- (IBAction)printDocument:(id)sender
{
    [[AudioPrinter shared] setPrintInfo:[[self document] printInfo]];

    NSEnumerator *enumerator = [mAudioViewList selectedRowEnumerator];
    NSNumber *object = NULL;

    NSMutableArray *array = [NSMutableArray array];
    while(object = [enumerator nextObject])
        [array addObject:[[mAudioDataWrapperArray objectAtIndex:[object intValue]] view]];        

    [[AudioPrinter shared] printViews:array];
}

@end

@implementation AudioSTWindowController (FullScreen)

- (void)updateFullScreenWindowInterface
{
    [mFirstViewButton setEnabled:mFullScreenCurrentViewIndex>0];
    [mPreviousViewButton setEnabled:mFullScreenCurrentViewIndex>0];
    [mNextViewButton setEnabled:mFullScreenCurrentViewIndex<[self viewCount]-1];
    [mLastViewButton setEnabled:mFullScreenCurrentViewIndex<[self viewCount]-1];
}

- (IBAction)closeFullScreenForView:(id)sender
{
    [self changePageLayout:mPageLayoutID];
    
    [mFullScreenWindow orderOut:self];
    [mFullScreenWindow close];

    mViewDisplayedInFullScreen = NO;

    [[[AudioInspectorController shared] window] setLevel:NSFloatingWindowLevel];

    if(FULL_SCREEN)
    {
        if (CGDisplayRelease( kCGDirectMainDisplay ) != kCGErrorSuccess) {
                NSLog( @"Couldn't release the display(s)!" );
                // Note: if you display an error dialog here, make sure you set
                // its window level to the same one as the shield window level,
                // or the user won't see anything.
        }
    }
}

- (IBAction)browseViewAction:(id)sender
{
    switch([sender tag]) {
        case 0: // <<
            mFullScreenCurrentViewIndex = 0;
            break;
        case 1: // <
            if(mFullScreenCurrentViewIndex>0)
                mFullScreenCurrentViewIndex--;
            break;
        case 2: // >
            if(mFullScreenCurrentViewIndex<[self viewCount]-1)
                mFullScreenCurrentViewIndex++;
            break;
        case 3: // >>
            mFullScreenCurrentViewIndex = [self viewCount]-1;
            break;
    }

    [mFullScreenBoxForView setContentView:[self viewAtIndex:mFullScreenCurrentViewIndex]];
    
    [self updateFullScreenWindowInterface];
}

@end

@implementation AudioSTWindowController (EditMenu)

- (IBAction)performUndo:(id)sender
{
	if([mAudioDataUndo canUndoOnData:[mCurrentWrapper data]] && [mAudioDataUndo hasUndoData]) {
		[mAudioDataUndo performUndoOnData:[mCurrentWrapper data]];
		[[mCurrentWrapper view] refresh];
		[self documentChangeDone];
	}
}

- (IBAction)duplicate:(id)sender
{
    [self computeOperation:OPERATION_COPY];
}

@end

@implementation AudioSTWindowController (ViewMenu)

- (IBAction)currentViewFullScreen:(id)sender
{
    NSRect screenRect;
    int windowLevel;
    
    if(FULL_SCREEN)
    {
        if (CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess) {
            NSLog( @"Couldn't capture the main display!" );
            return;
        }
    
        windowLevel = CGShieldingWindowLevel();
    
        screenRect = [[NSScreen mainScreen] frame];
    } else
        screenRect = NSMakeRect(100,100,800,600);

    mFullScreenWindow = [[AudioFullScreenWindow alloc] initWithContentRect:screenRect
                                styleMask:NSBorderlessWindowMask
                                backing:NSBackingStoreBuffered
                                defer:NO screen:[NSScreen mainScreen]];

    if(FULL_SCREEN)
        [mFullScreenWindow setLevel:windowLevel];
        
    [mFullScreenWindow setDelegate:self];
    [mFullScreenWindow setContentView:mFullScreenContentViewForView];
            
    [mFullScreenBoxForView setContentView:[mCurrentWrapper view]];
    [mFullScreenWindow makeKeyAndOrderFront:nil];
    
    [[[AudioInspectorController shared] window] setLevel:windowLevel];
    
    mFullScreenCurrentViewIndex = [mAudioDataWrapperArray indexOfObjectIdenticalTo:mCurrentWrapper];

    [self updateFullScreenWindowInterface];

    mViewDisplayedInFullScreen = YES;
}

- (void)doReverseXAxisScale:(id)sender
{
    AudioDataAmplitude *data = [[self currentAudioWrapper] data];
    [data setReverseXAxis:![data reverseXAxis]];
    [mCurrentWrapper resetXAxis];
}

- (void)deleteCurrentViewAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode==NSOKButton)
    {
        [self deleteAudioDataWrapper:[self currentAudioWrapper]];
        [mAudioViewList reloadData];
    }
}

- (IBAction)deleteCurrentView:(id)sender
{	
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Do you really want to delete the view '%@' ?", NULL), [[self currentAudioWrapper] viewName]];
    
    NSBeginAlertSheet(title, NSLocalizedString(@"Delete", NULL), NSLocalizedString(@"Cancel", NULL), NULL, [self window], self, @selector(deleteCurrentViewAlertSheetDidEnd:returnCode:contextInfo:), NULL, NULL, NSLocalizedString(@"This action cannot be undone.", NULL));    
}

- (void)deleteSelectedViewsAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode==NSOKButton)
    {
        NSEnumerator *enumerator = [mAudioViewList selectedRowEnumerator];
        NSEnumerator *reverseEnumerator = [[enumerator allObjects] reverseObjectEnumerator];
        NSNumber *object = NULL;
        
        while(object = [reverseEnumerator nextObject])
            [self deleteAudioDataWrapper:[mAudioDataWrapperArray objectAtIndex:[object intValue]]];        
        [mAudioViewList reloadData];
    }
}

- (IBAction)deleteSelectedViews:(id)sender
{	    
    NSBeginAlertSheet(NSLocalizedString(@"Do you really want to delete all selected views ?", NULL), NSLocalizedString(@"Delete", NULL), NSLocalizedString(@"Cancel", NULL), NULL, [self window], self, @selector(deleteSelectedViewsAlertSheetDidEnd:returnCode:contextInfo:), NULL, NULL, NSLocalizedString(@"This action cannot be undone.", NULL));    
}

@end

@implementation AudioSTWindowController (SoundMenu)

- (IBAction)playSound:(id)sender
{
    [[self currentAudioView] playSound];
}

- (IBAction)playSoundSelection:(id)sender
{
    [[self currentAudioView] playSoundSelection];
}

- (IBAction)movePlayerheadToCursor:(id)sender
{
    [[self currentAudioView] movePlayerheadToCursor];
}

- (IBAction)recordSound:(id)sender
{
    if([[AudioDeviceManager shared] inputDeviceAvailable] == NO)
        NSBeginAlertSheet(NSLocalizedString(@"Unable to record sound", NULL), NSLocalizedString(@"OK", NULL), NULL, NULL, [self window], self, NULL, NULL, NULL, NSLocalizedString(@"No record device detected.", NULL));    
    else
    {
        NSString *name = [NSString stringWithFormat:@"%@%d", NSLocalizedString(@"Sound", NULL),
                                                                        mViewAbsoluteCount+1];
        [mAudioDialogRecord openAsSheet:self defaultName:name];
    }
}

- (IBAction)generateSound:(id)sender
{
    NSString *name = [NSString stringWithFormat:@"%@%d", NSLocalizedString(@"Sound", NULL),
                                                                    mViewAbsoluteCount+1];
    [mAudioDialogGenerate openAsSheet:self defaultName:name];
}

@end

@implementation AudioSTWindowController (AnalyzeMenu)

- (void)computeOperation_:(NSTimer*)timer
{
    SHORT op = [[timer userInfo] intValue];

    AudioDataWrapper *wrapper = [[AudioOperator shared] computeOperation:op
                                            withWrapper:[self currentAudioWrapper]];

    [self addAudioDataWrapper:wrapper parentWrapper:[self currentAudioWrapper]];

    [mAudioViewList selectRow:[mAudioDataWrapperArray indexOfObjectIdenticalTo:wrapper]
                    byExtendingSelection:NO];

    [[self window] makeFirstResponder:mAudioViewList];

    [self displayProgressStatus:NO];
}

- (void)computeOperation:(SHORT)op
{
    NSString *operation = @"";
    switch(op) {
        case OPERATION_FFT_CURSOR:
        case OPERATION_FFT_SELECTION:
            operation = NSLocalizedString(@"Computing spectrum", NULL);
            break;
        case OPERATION_SONO:
        case OPERATION_SONO_SELECTION:
            operation = NSLocalizedString(@"Computing sonogram", NULL);
            break;
        case OPERATION_COPY:
            operation = NSLocalizedString(@"Copying", NULL);
            break;        
    }
    [self displayProgressText:operation];
    [self displayProgressStatus:YES];

    [NSTimer scheduledTimerWithTimeInterval:0 target:self
                selector:@selector(computeOperation_:) userInfo:[NSNumber numberWithInt:op] repeats:NO];    
}

- (IBAction)computeFFTOfCursorLocation:(id)sender
{
    [self computeOperation:OPERATION_FFT_CURSOR];
}

- (IBAction)computeFFTOfSelection:(id)sender
{
    [self computeOperation:OPERATION_FFT_SELECTION];
}

- (IBAction)fftParameters:(id)sender
{
    [mFFTParametersPanel openPanelForWrapper:[self currentAudioWrapper] parentWindow:[self window]];
}

- (IBAction)computeSonoOfVisualRange:(id)sender
{
    [self computeOperation:OPERATION_SONO];
}

- (IBAction)computeSonoOfSelection:(id)sender
{
    [self computeOperation:OPERATION_SONO_SELECTION];
}

- (IBAction)sonoParameters:(id)sender
{
    [mSonoParametersPanel openPanelForWrapper:[self currentAudioWrapper] parentWindow:[self window]];
}

- (IBAction)createLinkedFFTView:(id)sender
{
    [self computeOperation:OPERATION_LINKED_FFT];
}

- (IBAction)operations:(id)sender
{
    [mOperationsPanel openPanelForWindow:self];
}

@end

@implementation AudioSTWindowController (EffectsMenu)

- (IBAction)redoLastEffect:(id)sender
{
	if([[AudioEffectController shared] willRedoEffect]) {
		[mAudioDataUndo setUndo:[mCurrentWrapper data]];
	}

    if([[AudioEffectController shared] redoLastEffectOnData:[mCurrentWrapper data]
													channel:[mCurrentWrapper displayedChannel]
												parentWindow:[self window]])
    {
        [[mCurrentWrapper view] refresh];
        [self documentChangeDone];
    }
}

- (IBAction)performEffect:(id)sender
{
	if([[AudioEffectController shared] willPerformEffect:sender]) {
		[mAudioDataUndo setUndo:[mCurrentWrapper data]];
	}
	
    if([[AudioEffectController shared] performEffect:sender
                                              onData:[mCurrentWrapper data]
                                             channel:[mCurrentWrapper displayedChannel]
                                        parentWindow:[self window]])
    {
        [[mCurrentWrapper view] refresh];
        [self documentChangeDone];
    }
}

/*- (IBAction)performAudioUnitEffect:(id)sender
{
    return;
    BOOL openUIOnly = (mLastModifierFlags & NSAlternateKeyMask)>0;
    if(openUIOnly)
        [[AXAUManager shared] openEffectUI:sender parentWindow:[self window]];
    else
    {
        [[AXAUManager shared] performEffect:sender
                                    onData:[mCurrentWrapper data]
                                    channel:[mCurrentWrapper displayedChannel]
                                    parentWindow:[self window]];
        [[mCurrentWrapper view] refresh];
        [self documentChangeDone];
    }
}*/

- (void)flagsChanged:(NSEvent *)theEvent
{
    mLastModifierFlags = [theEvent modifierFlags];
    [[AudioEffectController shared] modifierChanged:mLastModifierFlags];
}

@end

@implementation AudioSTWindowController (WindowMenu)

- (IBAction)currentWindowFullScreen:(id)sender
{
    NSRect screenRect;
    int windowLevel;
    
    if(FULL_SCREEN)
    {
        if (CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess) {
            NSLog( @"Couldn't capture the main display!" );
            return;
        }
    
        windowLevel = CGShieldingWindowLevel();
    
        screenRect = [[NSScreen mainScreen] frame];
    } else
        screenRect = NSMakeRect(100,100,800,600);

    mFullScreenWindow = [[AudioFullScreenWindow alloc] initWithContentRect:screenRect
                                styleMask:NSBorderlessWindowMask | NSTexturedBackgroundWindowMask
                                backing:NSBackingStoreBuffered
                                defer:NO screen:[NSScreen mainScreen]];

    if(FULL_SCREEN)
        [mFullScreenWindow setLevel:windowLevel];
        
    [mFullScreenWindow setDelegate:self];
    [mFullScreenWindow setContentView:mFullScreenContentViewForWindow];
    [mFullScreenWindow setMovableByWindowBackground:NO];
    
    [mFullScreenBoxForWindow setContentView:[mPageLayoutBox contentView]];    
    [mFullScreenWindow makeKeyAndOrderFront:nil];
    
    [[[AudioInspectorController shared] window] setLevel:windowLevel];

    mWindowDisplayedInFullScreen = YES;
}

- (IBAction)closeFullScreenForWindow:(id)sender
{
    mWindowDisplayedInFullScreen = NO;
    [mPageLayoutBox setContentView:[mFullScreenBoxForWindow contentView]];
    
    [mFullScreenWindow orderOut:self];
    [mFullScreenWindow close];

    [[[AudioInspectorController shared] window] setLevel:NSFloatingWindowLevel];

    if(FULL_SCREEN)
    {
        if (CGDisplayRelease( kCGDirectMainDisplay ) != kCGErrorSuccess) {
                NSLog( @"Couldn't release the display(s)!" );
                // Note: if you display an error dialog here, make sure you set
                // its window level to the same one as the shield window level,
                // or the user won't see anything.
        }
    }
}

@end

@implementation AudioSTWindowController (TableViewDelegate)

- (NSData *)encodeDataRepresentationForObjects:(NSArray *)objects
{
    NSData *data;
    NSMutableDictionary *root = [[NSMutableDictionary alloc] init];
    NSString *plist;

    [root setObject:objects forKey:@"ROOT"];
    plist = [root description];
    data = [plist dataUsingEncoding:NSASCIIStringEncoding];
    [root release];
    return data;
}

- (NSArray *)decodeDataRepresentation:(NSData *)data
{
    NSDictionary *root;
    NSString *plist;

    plist = [[NSString allocWithZone:[self zone]] initWithData:data encoding:NSASCIIStringEncoding];
    root = [plist propertyList];
    [plist release];
    return [root objectForKey:@"ROOT"];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [mAudioDataWrapperArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    AudioDataWrapper *cell = [mAudioDataWrapperArray objectAtIndex:rowIndex];
    if([(NSCell*)[aTableColumn dataCell] type] == NSTextCellType)
        return [[cell view] viewName];
    else
        return [[cell view] imageIconWithName:mAudioViewListDisplayType == 2
                        size:NSMakeSize([aTableColumn width], [aTableView rowHeight])];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    AudioDataWrapper *wrapper = [mAudioDataWrapperArray objectAtIndex:rowIndex];
    [wrapper setViewName:anObject always:YES];
    [[wrapper view] viewHasUpdated];
    [[wrapper view] setNeedsDisplay:YES];
    [self documentChangeDone];
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pb
{
    NSMutableArray *rowArray = [[NSMutableArray alloc] init];
    NSEnumerator *enumerator = [rows objectEnumerator];
    NSData *rowData;
    id object;
    
    while(object = [enumerator nextObject])
    {
        NSMutableData *rowNumData = [NSMutableData data];
        
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:rowNumData];
        [archiver encodeInt:[object intValue] forKey:@"ROW_NUM"];
        [archiver finishEncoding];
        [archiver release];        

        [rowArray addObject:rowNumData];
    }
    
    rowData = [self encodeDataRepresentationForObjects:rowArray];
    
    [pb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, AudioViewPtrPboardType, nil] owner:self];
    [pb setData:rowData forType:NSStringPboardType];
    
    long ptr = (long)[[mAudioDataWrapperArray objectAtIndex:[[rows objectAtIndex:0] intValue]] view];
    NSData *data= [NSArchiver archivedDataWithRootObject:[NSNumber numberWithLong:ptr]];
    [pb setData:data forType:AudioViewPtrPboardType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *rowsData = [pboard dataForType:NSStringPboardType];
    NSArray *rows = [self decodeDataRepresentation:rowsData];
    NSEnumerator *enumerator = [rows objectEnumerator];
    id record;
    
    if(record = [enumerator nextObject])
    {
        NSKeyedUnarchiver *unarchiver;
        int sourceRow;
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:record];
        sourceRow = [unarchiver decodeIntForKey:@"ROW_NUM"];
        [unarchiver finishDecoding];
        [unarchiver release];
        
        if(row<0) row = 0;
        if(sourceRow!=row)
        {
            [self exchangeViewFromIndex:sourceRow toIndex:row];
            [tv setNeedsDisplay:YES];
        }
    }
            
    return YES;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell
        forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex 
{
  /*  [cell setDrawsBackground:YES];
    if (rowIndex % 2) 
        [cell setBackgroundColor:[NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:1]]; 
    else 
        [cell setBackgroundColor:[NSColor whiteColor]]; */
} 

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    
}

@end

@implementation AudioSTWindowController (DragAndDrop)

@end

@implementation AudioSTWindowController (Notification)

- (void)mainWindowChanged:(NSNotification*)notification
{
    if([notification object] == [self window])
    {
        [NSPrintInfo setSharedPrintInfo:[[self document] printInfo]];
    }
}

- (void)audioWrapperDidBecomeSelectNotif:(NSNotification*)notif
{
    AudioDataWrapper *wrapper = [notif object];
    if(mCurrentWrapper!=wrapper && [mAudioDataWrapperArray indexOfObjectIdenticalTo:wrapper]!=NSNotFound)
    {
        [[mCurrentWrapper view] setSelect:NO];
        mCurrentWrapper = wrapper;    
    }
}

- (void)replaceAudioViewPtr:(long)targetPtr byViewPtr:(long)sourcePtr
{
    [self pageLayoutReplaceView:(AudioView*)targetPtr byView:(AudioView*)sourcePtr];
}

- (void)createAudioViewInPlaceOfViewPtr:(long)targetPtr fromData:(id)data features:(id)features
{
    // Create a new view and replace the target view by the newly created view
    
    AudioDataWrapper *wrapper = [AudioDataWrapper initWithAudioData:data];
    if(wrapper == NULL) return;
    
    AudioView *view = [self createViewForWrapper:wrapper parentWrapper:NULL byAddingView:YES];
    if(view == NULL) return;
        
    [self addViewToVisibleArea:view replacingView:(AudioView*)targetPtr];

    if(features)
        [wrapper setViewFeatures:features];
        
    [wrapper setViewName:[[wrapper view] viewName] always:YES];
    [[wrapper view] setAllowsViewSelect:YES];
    [[wrapper view] setAllowsPlayerhead:YES];
    [[wrapper view] setAllowsPlayback:YES];
    [[wrapper view] setAllowsSelection:YES];
    if([data kind] == KIND_AMPLITUDE)
        [data setTriggerState:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioViewHasUpdatedNotification object:view];
}

- (BOOL)viewBelongsToWindow:(AudioView*)view
{
    NSEnumerator *enumerator = [mAudioDataWrapperArray objectEnumerator];
    AudioDataWrapper *wrapper;
    while(wrapper = [enumerator nextObject])
    {
        if([wrapper view] == view)
            return YES;
    }
    return NO;
}

- (void)audioViewShouldBeReplaced:(NSNotification*)notif
{
    NSDictionary *dictionary = [notif object];
    
    if([dictionary objectForKey:@"Window"] != [self window]) return;
    
    id sourceViewObject = [dictionary objectForKey:@"SourceViewPtr"];
    id targetViewObject = [dictionary objectForKey:@"TargetViewPtr"];
    id sourceDataObject = [dictionary objectForKey:@"SourceDataObject"];

    if(sourceViewObject && sourceDataObject)
    {
        // Try to find if the view is from our window or not.

        if([self viewBelongsToWindow:(AudioView*)[sourceViewObject longValue]] == NO)
            // View from another window.
            sourceViewObject = NULL;
    }
    
    if(sourceViewObject)
    {
        // View from our window
        
        long sourceViewPtr = [sourceViewObject longValue];
        long targetViewPtr = [targetViewObject longValue];
        
        [self replaceAudioViewPtr:targetViewPtr byViewPtr:sourceViewPtr];
    } else
    {
        // View from another window

        long targetViewPtr = [targetViewObject longValue];
        id featuresObject = [dictionary objectForKey:@"ViewFeaturesObject"];
        
        [self createAudioViewInPlaceOfViewPtr:targetViewPtr fromData:sourceDataObject features:featuresObject];
    }
}

- (void)prefsUseToolTipsChanged:(NSNotification*)notif
{
    [self setToolTips];
}

@end

@implementation AudioSTWindowController (Toolbar)

static NSString* 	AudioSTWindowToolbarIdentifier = @"AudioSTWindow Toolbar Identifier";
static NSString*	ViewListDisplayModeToolbarIdentifier = @"View List Display Mode Item Identifier";
static NSString*	ViewLayoutToolbarIdentifier = @"View Layout Item Identifier";

- (void)setupToolbar
{
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: AudioSTWindowToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: allow customization, give a default display mode
    // and remember state in user defaults 
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method   Given an item identifier, self method returns an item 
    // The toolbar will use self method to obtain toolbar items that can be displayed
    // in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];

    if ([itemIdent isEqual: ViewListDisplayModeToolbarIdentifier])
    {
        NSSize itemSize = [mViewListDisplayModeView frame].size;
        
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"View List Display Mode Button", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change the display mode of the view list", nil)];
	
	// Use a custom view 
	[toolbarItem setView:mViewListDisplayModeView];
	[toolbarItem setMinSize:itemSize];
	[toolbarItem setMaxSize:itemSize];
    } else if ([itemIdent isEqual: ViewLayoutToolbarIdentifier])
    {
        NSSize itemSize = [mViewLayoutView frame].size;
        
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"", nil)];
	//[toolbarItem setPaletteLabel: NSLocalizedString(@"View List Display Mode Button", nil)];
	//[toolbarItem setToolTip: NSLocalizedString(@"Change the display mode of the view list", nil)];
	
	// Use a custom view 
	[toolbarItem setView:mViewLayoutView];
	[toolbarItem setMinSize:itemSize];
	[toolbarItem setMaxSize:itemSize];
    } else {
	// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
	// Returning nil will inform the toolbar self kind of item is not supported 
	toolbarItem = nil;
    }
    
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:
    // Returns the ordered list of items to be shown in the toolbar by default 
       
    // If during the toolbar's initialization, no overriding values are found in the user defaults,
    // or if the user chooses to revert to the default items self set will be used

    return [NSArray arrayWithObjects:	ViewListDisplayModeToolbarIdentifier,
                                        NSToolbarFlexibleSpaceItemIdentifier,
                                        ViewLayoutToolbarIdentifier,
                                        nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:
    // Returns the list of all allowed items by identifier. By default, the toolbar 
    // does not assume any items are allowed, even the separator.
    // So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette

    return [NSArray arrayWithObjects:	ViewListDisplayModeToolbarIdentifier,
                                        ViewLayoutToolbarIdentifier,
                                        NSToolbarSeparatorItemIdentifier, 
                                        NSToolbarSpaceItemIdentifier,
                                        NSToolbarFlexibleSpaceItemIdentifier, nil];
}

@end