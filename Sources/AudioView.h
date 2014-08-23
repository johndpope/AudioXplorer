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
#import "AudioProtocols.h"
#import "AudioDataWrapper.h"
#import "AudioConstants.h"
#import "AudioDataAmplitude.h"
#import "AudioPlayer.h"

@class AudioSynth;

#define REPRESENTATION_NORMAL 0
#define REPRESENTATION_LISSAJOU 1

@interface AudioView : NSView
{
    ULONG	mViewID;	// ID of the view
    
    SHORT mViewType;	// Type (2D, 3D, …)
    
    NSMutableDictionary *mFeatures;	// Features (colors, allows, etc.)
	
	// Feature speed cache (to access feature more rapidly)
	NSColor		*mLeftDataColor;
	NSColor		*mRightDataColor;
	SHORT		mDisplayedChannel;
    float		mLineWidth;
	
    NSRect mViewRect;			// The view rect
    NSRect mDrawableRect;		// Drawable rect

    id mDelegate;			// Delegate object
    id mDataSource;			// Data source
            
    FLOAT mMinX, mMaxX;			// Real world complete range for X-axis
    FLOAT mMinY, mMaxY;			// Real world complete range for Y-axis
    FLOAT mMinZ, mMaxZ;			// Real world complete range for Z-axis
    
    FLOAT mVisual_MinX, mVisual_MaxX;		// Real world visual range for X-axis
    FLOAT mVisual_MinY, mVisual_MaxY;		// Real world visual range for Y-axis
    FLOAT mVisual_MinZ, mVisual_MaxZ;		// Real world visual range for Z-axis
    
    FLOAT mSel_MinX, mSel_MaxX;			// Real world selection range for X-axis
    FLOAT mSel_MinY, mSel_MaxY;			// Real world selection range for Y-axis        

        // Real displayed values (depending on the unit, automatic scale, etc.)
        
    NSString *mDisplayedXAxisUnit, *mDisplayedYAxisUnit, *mDisplayedZAxisUnit;
    FLOAT mVisualDisplayedXAxisFactor, mVisualDisplayedYAxisFactor, mVisualDisplayedZAxisFactor;
    FLOAT mVisualDisplayedMinX, mVisualDisplayedMaxX;
    FLOAT mVisualDisplayedMinY, mVisualDisplayedMaxY;
    FLOAT mVisualDisplayedMinZ, mVisualDisplayedMaxZ;
    
    FLOAT mCursor_X, mCursor_Y, mCursor_Z;	// Real world cursor position        
    
    BOOL mCursorDisplayHorizontal;		// Cursor drawing
    BOOL mCursorDisplayVertical;
    
    USHORT mCursorChannel;			// Cursor attached to channel
    
    USHORT mCursorHarmonicState;		// State of the harmonic cursor
    
    FLOAT mPlayerheadPosition;			// Player position
    BOOL mPlayerIsRunning;			// Player is running ?
    
    NSPoint mOldPoint;				// Current cursor position (pixels)
    FLOAT mPointValue;				// Valeur réelle courante
    BOOL mScaleReset;
    
    NSNumberFormatter *mNumberFormatter;	// Formatter to define the rounding operation

    NSDate *mDragAndDropDate;			// Used to delay the drag-and-drop
    NSPoint mDragAndDropPoint;			// Initial mouse position
    NSEvent *mDragAndDropEvent;			// Initial mouse-down event
    
    BOOL mIsSelected;				// YES if the view is selected
    BOOL mIsTarget;				// YES if the view is currently a target
                                                // (i.e. drag-and-drop)
    
    AudioPlayer *mAudioPlayer;			// Player for audio data    
    AudioSynth	*mAudioSynth;			// Synthesizer
    
    // Cache algorithm
    
    BOOL mDisplayForData;			// Display only vectorized information for data
    BOOL mLayerBackgroundGridAndAxisCached;
    NSImage *mLayerBackgroundGridAndAxisImage;
    NSImageRep *mLayerBackgroundGridAndAxisImageRep;
    NSRect mLayerBackgroundGridAndAxisRect;    
    
    // Icon representation
    
    NSImage *mViewIcon;
    
    // X-axis slider
    
    NSScroller *mXAxisScroller;
    NSScroller *mYAxisScroller;
    BOOL mXAxisScrollerVisible;
    BOOL mYAxisScrollerVisible;
    BOOL mUseHorizontalScroller;
    BOOL mUseVerticalScroller;
}

- (void)setViewFrame:(NSRect)frame;
- (NSRect)viewFrame;

- (void)setDelegate:(id)delegate;
- (id)delegate;

- (void)setDataSource:(id)source;
- (id)dataSource;
- (void)applyDataSourceToView;

- (void)setToolTips;

@end






