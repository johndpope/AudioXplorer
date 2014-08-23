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

#import "AudioView+Categories.h"
#import "AudioDialogPrefs.h"

@implementation AudioView (Ranges)

- (void)setRangeForXAxisFrom:(FLOAT)inFrom to:(FLOAT)inTo
{
    mMinX = inFrom;
    mMaxX = inTo;
}

- (void)setRangeForYAxisFrom:(FLOAT)inFrom to:(FLOAT)inTo
{
    mMinY = inFrom;
    mMaxY = inTo;
}

- (void)setRangeForZAxisFrom:(FLOAT)inFrom to:(FLOAT)inTo
{
    mMinZ = inFrom;
    mMaxZ = inTo;
}

- (void)setVisualRangeForXAxisFrom:(FLOAT)inVisualFrom to:(FLOAT)inVisualTo
{
    if(mVisual_MinX!=inVisualFrom || mVisual_MaxX!=inVisualTo)
        [self invalidateCaches];

    mVisual_MinX = inVisualFrom;
    mVisual_MaxX = inVisualTo;

    [self updateXAxisScroller];
    [self updateVisualDisplayedXAxisParameters];
}

- (void)setVisualRangeForYAxisFrom:(FLOAT)inVisualFrom to:(FLOAT)inVisualTo
{
    if(mVisual_MinY!=inVisualFrom || mVisual_MaxY!=inVisualTo)
        [self invalidateCaches];

    mVisual_MinY = inVisualFrom;
    mVisual_MaxY = inVisualTo;

    [self updateYAxisScroller];
    [self updateVisualDisplayedYAxisParameters];
}

- (void)setVisualRangeForZAxisFrom:(FLOAT)inVisualFrom to:(FLOAT)inVisualTo
{
    if(mVisual_MinZ!=inVisualFrom || mVisual_MaxZ!=inVisualTo)
        [self invalidateCaches];

    mVisual_MinZ = inVisualFrom;
    mVisual_MaxZ = inVisualTo;

    [self updateVisualDisplayedZAxisParameters];
}

- (void)setSelectionRangeForXAxisFrom:(FLOAT)inSelFrom to:(FLOAT)inSelTo
{
    mSel_MinX = inSelFrom;
    mSel_MaxX = inSelTo;

    [self checkRanges];
}

- (void)setSelectionRangeForYAxisFrom:(FLOAT)inSelFrom to:(FLOAT)inSelTo
{
    mSel_MinY = inSelFrom;
    mSel_MaxY = inSelTo;
        
    [self checkRanges];
}

- (void)setCursorPositionX:(FLOAT)x positionY:(FLOAT)y
{
    if(mCursorChannel == STEREO_CHANNEL) return;
    
    mCursor_X = x;
    mCursor_Y = y;    
    [self checkRanges];

    SHORT displayChannel = [self displayedChannel];
    if(displayChannel == STEREO_CHANNEL)
        [self setProposedCursorPositionX:mCursor_X positionY:mCursor_Y channel:mCursorChannel];        
    else
        [self setProposedCursorPositionX:mCursor_X positionY:mCursor_Y channel:displayChannel];
}

- (void)setPlayerHeadPosition:(FLOAT)x
{
    mPlayerheadPosition = x;
}

- (FLOAT)xAxisRangeFrom
{
    return mMinX;
}
- (FLOAT)xAxisRangeTo
{
    return mMaxX;
}

- (FLOAT)yAxisRangeFrom
{
    return mMinY;
}
- (FLOAT)yAxisRangeTo
{
    return mMaxY;
}

- (FLOAT)xAxisVisualRangeFrom { return mVisual_MinX; }
- (FLOAT)xAxisVisualRangeTo { return mVisual_MaxX; }
- (FLOAT)yAxisVisualRangeFrom { return mVisual_MinY; }
- (FLOAT)yAxisVisualRangeTo { return mVisual_MaxY; }

- (FLOAT)xAxisSelectionRangeFrom { return mSel_MinX; }
- (FLOAT)xAxisSelectionRangeTo { return mSel_MaxX; }
- (FLOAT)yAxisSelectionRangeFrom { return mSel_MinY; }
- (FLOAT)yAxisSelectionRangeTo { return mSel_MaxY; }

- (FLOAT)xCursorPosition { return mCursor_X; }
- (FLOAT)yCursorPosition { return mCursor_Y; }
- (FLOAT)zCursorPosition { return mCursor_Z; }

- (FLOAT)playerHeadPosition { return mPlayerheadPosition; }

- (BOOL)selectionExists
{
    return [self xAxisSelectionRangeFrom] != [self xAxisSelectionRangeTo];
}

- (void)refreshRanges
{
    if([self displayedChannel] == LISSAJOUS_CHANNEL)
    {
        mMinX = [mDataSource minYOfChannel:LEFT_CHANNEL];
        mMaxX = [mDataSource maxYOfChannel:LEFT_CHANNEL];
        mMinY = [mDataSource minYOfChannel:RIGHT_CHANNEL];
        mMaxY = [mDataSource maxYOfChannel:RIGHT_CHANNEL];        
    } else
    {
        SHORT channel = LEFT_CHANNEL;
        if([mDataSource respondsToSelector:@selector(dataExistsForChannel:)])
            if([mDataSource dataExistsForChannel:channel] == NO)
                channel = RIGHT_CHANNEL;
            
        mMinX = [mDataSource minXOfChannel:channel];
        mMaxX = [mDataSource maxXOfChannel:channel];
        mMinY = [mDataSource minYOfChannel:channel];
        mMaxY = [mDataSource maxYOfChannel:channel];
        
        if(mViewType == VIEW_3D)
        {
            mMinZ = [mDataSource minZOfChannel:channel];
            mMaxZ = [mDataSource maxZOfChannel:channel];
        }
    }
    
    mVisual_MinX = mMinX;
    mVisual_MaxX = mMaxX;
    mVisual_MinY = mMinY;
    mVisual_MaxY = mMaxY;
    mVisual_MinZ = mMinZ;
    mVisual_MaxZ = mMaxZ;    
}

- (void)updateVisualDisplayedXAxisParameters
{
    BOOL lissajous = [self displayedChannel] == LISSAJOUS_CHANNEL;

    if(lissajous)
        mVisualDisplayedXAxisFactor = [mDataSource yAxisUnitFactorForRange:MAX(fabs(mVisual_MinX), fabs(mVisual_MaxX))];
    else
        mVisualDisplayedXAxisFactor = [mDataSource xAxisUnitFactorForRange:MAX(fabs(mVisual_MinX), fabs(mVisual_MaxX))];
    
    mVisualDisplayedMinX = mVisual_MinX*mVisualDisplayedXAxisFactor;
    mVisualDisplayedMaxX = mVisual_MaxX*mVisualDisplayedXAxisFactor;

    if(lissajous)
        mDisplayedXAxisUnit = [mDataSource yAxisUnitForRange:MAX(fabs(mVisual_MinX), fabs(mVisual_MaxX))];
    else
        mDisplayedXAxisUnit = [mDataSource xAxisUnitForRange:MAX(fabs(mVisual_MinX), fabs(mVisual_MaxX))];
}

- (void)updateVisualDisplayedYAxisParameters
{
    mVisualDisplayedYAxisFactor = [mDataSource yAxisUnitFactorForRange:MAX(fabs(mVisual_MinY), fabs(mVisual_MaxY))];

    mVisualDisplayedMinY = mVisual_MinY*mVisualDisplayedYAxisFactor;
    mVisualDisplayedMaxY = mVisual_MaxY*mVisualDisplayedYAxisFactor;
    
    mDisplayedYAxisUnit = [mDataSource yAxisUnitForRange:MAX(fabs(mVisual_MinY), fabs(mVisual_MaxY))];  
}

- (void)updateVisualDisplayedZAxisParameters
{
    if(mViewType == VIEW_3D)
    {
        mVisualDisplayedZAxisFactor = [mDataSource zAxisUnitFactorForRange:MAX(fabs(mVisual_MinZ), fabs(mVisual_MaxZ))];
    
        mVisualDisplayedMinZ = mVisual_MinZ*mVisualDisplayedZAxisFactor;
        mVisualDisplayedMaxZ = mVisual_MaxZ*mVisualDisplayedZAxisFactor;
                
        mDisplayedZAxisUnit = (NSString*)[mDataSource zAxisUnitForRange:MAX(fabs(mVisual_MinZ), fabs(mVisual_MaxZ))];  
    }
}

- (void)checkRanges
{
    if(mVisual_MaxX > mMaxX)	mVisual_MaxX = mMaxX;
    if(mVisual_MaxX < mMinX)	mVisual_MaxX = mMinX;
    
    if(mVisual_MinX > mMaxX)	mVisual_MinX = mMaxX;
    if(mVisual_MinX < mMinX)	mVisual_MinX = mMinX;

    if((mVisual_MaxX-mVisual_MinX)<1e-6)
    {
        if(mVisual_MinX==mMinX)
            mVisual_MaxX = mVisual_MinX+1e-6;
        else
            mVisual_MinX = mVisual_MaxX-1e-6;
    }
        
    if([[AudioDialogPrefs shared] yAxisFree] == NO)
    {
        if(mVisual_MaxY > mMaxY)	mVisual_MaxY = mMaxY;
        if(mVisual_MaxY < mMinY)	mVisual_MaxY = mMinY;
        
        if(mVisual_MinY > mMaxY)	mVisual_MinY = mMaxY;
        if(mVisual_MinY < mMinY)	mVisual_MinY = mMinY;
    }
    
    if(mCursor_X > mMaxX)	mCursor_X = mMaxX;
    if(mCursor_X < mMinX)	mCursor_X = mMinX;
    if(mCursor_Y > mMaxY)	mCursor_Y = mMaxY;
    if(mCursor_Y < mMinY)	mCursor_Y = mMinY;    
    
    [self updateVisualDisplayedXAxisParameters];
    [self updateVisualDisplayedYAxisParameters];
    [self updateVisualDisplayedZAxisParameters];
}

- (void)updateXAxisScrollerFrame
{
    NSRect r = [self xAxisSliderRect];
    [mXAxisScroller setFrame:r];
}

- (void)updateYAxisScrollerFrame
{
    NSRect r = [self yAxisSliderRect];
    [mYAxisScroller setFrame:r];
}

- (void)updateXAxisScroller
{
    float delta = (mMaxX-mMinX)-(mVisual_MaxX-mVisual_MinX);
    float p = 0;
    if(delta!=0)
        p = (mVisual_MinX-mMinX)/delta;
    float k = 0;
    if((mMaxX-mMinX)!=0)
        k = 1-delta/(mMaxX-mMinX);
    
    BOOL enabled = (delta>0) && mUseHorizontalScroller;
    if(enabled)
    {
        if(mXAxisScrollerVisible == NO)
        {
            [self addSubview:mXAxisScroller];
            [self updateXAxisScrollerFrame];
            mXAxisScrollerVisible = YES;
        }
        [mXAxisScroller setFloatValue:p knobProportion:k];
        [mXAxisScroller setEnabled:enabled];
    } else
    {
        [mXAxisScroller setEnabled:enabled];
        if(mXAxisScrollerVisible)
            [mXAxisScroller removeFromSuperview];
        mXAxisScrollerVisible = NO;
    }
}

- (void)updateYAxisScroller
{
    float delta = (mMaxY-mMinY)-(mVisual_MaxY-mVisual_MinY);
    float p = 0;
    if(delta!=0)
        p = 1-(mVisual_MinY-mMinY)/delta;
    float k = 0;
    if((mMaxY-mMinY)!=0)
        k = 1-delta/(mMaxY-mMinY);
    
    BOOL enabled = (delta>0) && mUseVerticalScroller;
    if(enabled)
    {
        if(mYAxisScrollerVisible == NO)
        {
            [self addSubview:mYAxisScroller];
            [self updateYAxisScrollerFrame];
            mYAxisScrollerVisible = YES;
        }
        [mYAxisScroller setFloatValue:p knobProportion:k];
        [mYAxisScroller setEnabled:enabled];
    } else
    {
        [mYAxisScroller setEnabled:enabled];
        if(mYAxisScrollerVisible)
            [mYAxisScroller removeFromSuperview];
        mYAxisScrollerVisible = NO;
    }
}

@end
