
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

#import "AudioView.h"
#import "AudioView+Categories.h"

#import "AudioNotifications.h"
#import "AudioDialogPrefs.h"

#import "AudioSynth.h"

@implementation AudioView

- (id)initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect])
    {
        mViewType = VIEW_NOTDEF;
        
        mFeatures = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
        [self initDefaultFeatures];
        mLineWidth = 0;
		
        mViewRect = frameRect;
        mDrawableRect = NSZeroRect;
        
        mDelegate = NULL;
        mDataSource = NULL;
        
        mMinX = mMaxX = 0;
        mMinY = mMaxY = 0;
        mMinZ = mMaxZ = 0;
        mVisual_MinX = mVisual_MaxX = 0;
        mVisual_MinY = mVisual_MaxY = 0;
        mVisual_MinZ = mVisual_MaxZ = 0;

        mSel_MinX = mSel_MaxX = 0;
        mSel_MinY = mSel_MaxY = 0;
        
        mDisplayedXAxisUnit = NULL;
        mDisplayedYAxisUnit = NULL;
        mDisplayedZAxisUnit = NULL;
        
        mVisualDisplayedXAxisFactor = mVisualDisplayedYAxisFactor = mVisualDisplayedZAxisFactor = 1;
        mVisualDisplayedMinX = mVisualDisplayedMaxX = 0;
        mVisualDisplayedMinY = mVisualDisplayedMaxY = 0;
        mVisualDisplayedMinZ = mVisualDisplayedMaxZ = 0;

        mCursor_X = mCursor_Y = mCursor_Z = 0;

        mCursorDisplayHorizontal = YES;
        mCursorDisplayVertical = YES;

        mCursorChannel = LEFT_CHANNEL;
        mCursorHarmonicState = 0;
        
        mUseHorizontalScroller = YES;
        mUseVerticalScroller = YES;
        
        mPlayerheadPosition = 0;
        mPlayerIsRunning = NO;

        mOldPoint = NSMakePoint(0,0);
        mPointValue = 1;

        mNumberFormatter =  [[NSNumberFormatter alloc] init];
    
        [mNumberFormatter setFormat:@"#,##0.00;-#,##0.00"];
        [mNumberFormatter setThousandSeparator:@"'"];
    
        mDragAndDropDate = NULL;
        mDragAndDropPoint = NSMakePoint(0,0);
        mDragAndDropEvent = NULL;
        
        mIsSelected = NO;
        mIsTarget = NO;

        // Sound playback
        
        mAudioPlayer = [[AudioPlayer alloc] init];
        [mAudioPlayer setCompletionSelector:@selector(playCompleted:) fromObject:self];
        [mAudioPlayer setPlayingSelector:@selector(playing:) fromObject:self];
                                		
        // Synthesizer
        
        mAudioSynth = [AudioSynth shared];
        
        // Cache algorithm
        
        mDisplayForData = NO;
        
        mLayerBackgroundGridAndAxisCached = NO;
        mLayerBackgroundGridAndAxisImage = [[NSImage alloc] initWithSize:NSMakeSize(0,0)];
        mLayerBackgroundGridAndAxisImageRep = NULL;
        
        // Icon representation
        
        mViewIcon = NULL;

        // Scroller
        
        mXAxisScroller = [[NSScroller alloc] initWithFrame:NSMakeRect(0, 0, 100, 10)];
        [mXAxisScroller setTarget:self];
        [mXAxisScroller setAction:@selector(xAxisScrollerAction:)];
        [mXAxisScroller setControlSize:NSSmallControlSize];
        [mXAxisScroller setArrowsPosition:NSScrollerArrowsDefaultSetting];
        mXAxisScrollerVisible = NO;

        mYAxisScroller = [[NSScroller alloc] initWithFrame:NSMakeRect(0, 0, 10, 100)];
        [mYAxisScroller setTarget:self];
        [mYAxisScroller setAction:@selector(yAxisScrollerAction:)];
        [mYAxisScroller setControlSize:NSSmallControlSize];
        [mYAxisScroller setArrowsPosition:NSScrollerArrowsDefaultSetting];
        mYAxisScrollerVisible = NO;
        
        // Attributes
        
        [self queryCursorDisplayPosition];
        [self queryScrollerUsage];
        
        [self setToolTips];

        // Drag-and-drop
        
        [self registerForDraggedTypes:[NSArray arrayWithObjects:AudioViewPtrPboardType,
                                            AudioDataPboardType, nil]];        
        
        // Notifications
        
        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(prefsCursorDirectionChanged:)
        name:AudioPrefsCursorDirectionChangedNotification object:NULL];

        [[NSNotificationCenter defaultCenter] addObserver:self	selector:@selector(prefsViewScrollerChanged:)
        name:AudioPrefsViewScrollerChangedNotification object:NULL];

        [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(prefsUseToolTipsChanged:)
        name:AudioPrefsUseToolTipsChangedNotification object:NULL];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(viewFrameHasChanged:)
        name:NSViewFrameDidChangeNotification object:NULL];
    }
    return self;
}

- (void)dealloc
{	
	[mAudioSynth stop];
	[mAudioPlayer stop];
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [mXAxisScroller release];
    [mYAxisScroller release];
    [mViewIcon release];
    
    [mLayerBackgroundGridAndAxisImage release];
    [mLayerBackgroundGridAndAxisImageRep release];
    
    [mAudioPlayer release];
    [mNumberFormatter release];
    [mDataSource release];

    [super dealloc];
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)setViewFrame:(NSRect)frame
{
    [self setFrame:frame];
}

- (NSRect)viewFrame
{
    return [self frame];
}

- (void)setDelegate:(id)delegate
{
    mDelegate = delegate;
}

- (id)delegate
{
    return mDelegate;
}

- (void)setDataSource:(id)source
{
    [mDataSource autorelease];
    mDataSource = [source retain];
}

- (id)dataSource
{
    return mDataSource;
}

- (void)applyDataSourceToView
{
    SHORT channel = [self displayedChannel];
    
    if([mDataSource respondsToSelector:@selector(dataExistsForChannel:)])
    {
        if([mDataSource dataExistsForChannel:channel] == NO)
            channel = RIGHT_CHANNEL;
        if([mDataSource dataExistsForChannel:channel] == NO)
            channel = LEFT_CHANNEL;        
    }
    
    mMinX = [mDataSource minXOfChannel:channel];
    mMaxX = [mDataSource maxXOfChannel:channel];
    mMinY = [mDataSource minYOfChannel:channel];
    mMaxY = [mDataSource maxYOfChannel:channel];
    
    if(mViewType == VIEW_3D)
    {
        mMinZ = [mDataSource minZOfChannel:channel];
        mMaxZ = [mDataSource maxZOfChannel:channel];
    }
    
    [self setDisplayedChannel:channel];
}

- (void)setToolTips
{
    [self removeAllToolTips];
    if([[AudioDialogPrefs shared] useToolTips])
    {
        [self addToolTipRect:[self xAxisRect] owner:NSLocalizedString(@"X-axis tool-tips.", NULL) userData:NULL];
        [self addToolTipRect:[self yAxisRect] owner:NSLocalizedString(@"Y-axis tool-tips.", NULL) userData:NULL];
        [self addToolTipRect:[self drawableRect] owner:NSLocalizedString(@"Click to move the cursor.\rOption-click to move the playearhead.\rShift-click and move to select a portion of data.", NULL) userData:NULL];
        [self addToolTipRect:[self titleRect] owner:NSLocalizedString(@"Click to select the view.\rDrag-and-drop can be initiated by clicking in the title.", NULL) userData:NULL];
    }
}

@end
