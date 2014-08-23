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

#import "AudioView3D.h"

@implementation AudioView3D

- (id)initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect])
    {
        mViewType = VIEW_3D;
    }
    return self;
}

- (void)setDataSource:(id)source
{
    [super setDataSource:source];
    [self applyDataSourceToView];
    [self checkRanges];
}

- (void)drawHarmonicCursorSelf
{
    BOOL label = mCursorHarmonicState != 2;
    SHORT index = 2;
    FLOAT cursor_y = mCursor_Y*index++;
    FLOAT cursor = [self computeYPixelFromYRealValue:cursor_y];
    NSPoint px1 = NSMakePoint(mDrawableRect.origin.x, cursor);
    NSPoint px2 = NSMakePoint(mDrawableRect.size.width+mDrawableRect.origin.x, cursor);

    [self drawCursorAtX:mCursor_X y:mCursor_Y rotateIfNoRoom:NO restrictWidth:0 label:label];
    [self drawCursorAtX:mCursor_X y:cursor_y rotateIfNoRoom:NO restrictWidth:0 label:label];

    while(px1.y<=mDrawableRect.origin.y+mDrawableRect.size.height)
    {
        cursor_y = mCursor_Y*index++;
        [NSBezierPath strokeLineFromPoint:px1 toPoint:px2];
        cursor = [self computeYPixelFromYRealValue:cursor_y];
        px1 = NSMakePoint(mDrawableRect.origin.x, cursor);
        px2 = NSMakePoint(mDrawableRect.size.width+mDrawableRect.origin.x, cursor);
        if(px1.y<=mDrawableRect.origin.y+mDrawableRect.size.height)
            [self drawCursorAtX:mCursor_X y:cursor_y rotateIfNoRoom:NO restrictWidth:0 label:label];
    }
}

- (void)drawSelf
{
    NSRect r = [self drawableRect];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    FLOAT xRatio = mDrawableRect.size.width/(mVisual_MaxX-mVisual_MinX);
    FLOAT yRatio = mDrawableRect.size.height/(mVisual_MaxY-mVisual_MinY);    
    CGRect rect = CGRectMake(r.origin.x-(mVisual_MinX-mMinX)*xRatio,
                            r.origin.y-(mVisual_MinY-mMinY)*yRatio,
                            (mMaxX-mMinX)*xRatio,
                            (mMaxY-mMinY)*yRatio);
                            
    NSRectClip(r);
        
    CGImageRef imageRef = [mDataSource imageQ2D];
    if(imageRef)
        CGContextDrawImage(context, rect, imageRef);
}

- (void)setProposedCursorPositionX:(FLOAT)x positionY:(FLOAT)y
{
    mCursor_X = x;
    mCursor_Y = y;
    mCursor_Z = [mDataSource zValueAtX:mCursor_X y:mCursor_Y];
    
    [self checkRanges];
}

- (NSString*)composeCursorLabelStringForXValue:(FLOAT)x yValue:(FLOAT)y zValue:(FLOAT)z
{
    NSString *label;
        
    label = [[self roundFloatToString:x*mVisualDisplayedXAxisFactor maxValue:mVisualDisplayedMaxX] stringByAppendingString:mDisplayedXAxisUnit];
    label = [label stringByAppendingString:@", "];
    label = [label stringByAppendingString:[self roundFloatToString:y*mVisualDisplayedYAxisFactor maxValue:mVisualDisplayedMaxY]];
    label = [label stringByAppendingString:mDisplayedYAxisUnit];
    label = [label stringByAppendingString:@", "];
    label = [label stringByAppendingString:[self roundFloatToString:z*mVisualDisplayedZAxisFactor maxValue:mVisualDisplayedMaxZ]];
    label = [label stringByAppendingString:mDisplayedZAxisUnit];
    
    return label;
}

@end
