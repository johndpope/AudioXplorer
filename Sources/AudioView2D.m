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

#import "AudioView2D.h"

@implementation AudioView2D

- (id)initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect])
    {
        mLeftPathArray = NULL;
        mRightPathArray = NULL;
        mPathArrayCount = 0;
        mViewType = VIEW_2D;
    }
    return self;
}

- (void)dealloc
{
    if(mLeftPathArray)
        free(mLeftPathArray);
    if(mRightPathArray)
        free(mRightPathArray);
        
    [super dealloc];
}

- (void)setDataSource:(id)source
{
    [super setDataSource:source];
    [self applyDataSourceToView];
    [self refreshSelf];
}

- (void)drawHarmonicCursorSelf
{
    FLOAT intervalWidth = [self computeXPixelFromXRealValue:mCursor_X*2]
                            -[self computeXPixelFromXRealValue:mCursor_X];

    SHORT index = 2;
    FLOAT cursor_x = mCursor_X*index++;
    FLOAT cursor = [self computeXPixelFromXRealValue:cursor_x];
    NSPoint px1 = NSMakePoint(cursor, mDrawableRect.origin.y);
    NSPoint px2 = NSMakePoint(cursor, mDrawableRect.size.height+mDrawableRect.origin.y);

    BOOL label = mCursorHarmonicState != 2;
    
    [self drawCursorAtX:mCursor_X y:mCursor_Y rotateIfNoRoom:YES restrictWidth:intervalWidth label:label];

    [self drawCursorAtX:cursor_x y:[self computeYRealValueFromXRealValue:cursor_x channel:LEFT_CHANNEL] rotateIfNoRoom:YES restrictWidth:intervalWidth  label:label];

    while(px1.x<=mDrawableRect.origin.x+mDrawableRect.size.width)
    {
        cursor_x = mCursor_X*index++;
        [NSBezierPath strokeLineFromPoint:px1 toPoint:px2];
        cursor = [self computeXPixelFromXRealValue:cursor_x];
        px1 = NSMakePoint(cursor, mDrawableRect.origin.y);
        px2 = NSMakePoint(cursor, mDrawableRect.size.height+mDrawableRect.origin.y);
        [self drawCursorAtX:cursor_x y:[self computeYRealValueFromXRealValue:cursor_x channel:LEFT_CHANNEL] rotateIfNoRoom:YES restrictWidth:intervalWidth  label:label];
    }
}

- (void)drawPathArray:(PathElementPtr)pathArray count:(ULONG)count
{
    if(pathArray == NULL) return;
    
    ULONG point;
    for(point = 1; point<mPathArrayCount; point++)
    {
        FLOAT x0, y0, x1, y1;
        
        if([mDataSource kind] == KIND_FFT)
        {
            x0 = pathArray[point-1].x;
            y0 = pathArray[point-1].maxY;
            x1 = pathArray[point].x;
            y1 = pathArray[point].maxY;    
        } else
        {
            x0 = pathArray[point-1].x;
            y0 = pathArray[point-1].maxY;
            x1 = pathArray[point].x;
            y1 = pathArray[point].minY;
        }            
       // [NSBezierPath strokeRect:NSMakeRect(round(x1)-0.5, round(y1)-0.5, 0.5, 0.5)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(round(x0)-0.5, round(y0)-0.5)
                                    toPoint:NSMakePoint(round(x1)-0.5, round(y1)-0.5)];
    }
}

- (void)drawLissajouPathArray
{
    if(mLissajouPathArray == NULL) return;
    
    ULONG point;
    for(point = 1; point<mPathArrayCount; point++)
    {
        FLOAT x0, y0, x1, y1;
        
        x0 = mLissajouPathArray[point-1].x;
        y0 = mLissajouPathArray[point-1].y;
        x1 = mLissajouPathArray[point].x;
        y1 = mLissajouPathArray[point].y;        

        [NSBezierPath strokeLineFromPoint:NSMakePoint(round(x0)-0.5, round(y0)-0.5)
                                        toPoint:NSMakePoint(round(x1)-0.5, round(y1)-0.5)];
    }
}

- (void)drawSelf
{    
    NSRectClip(NSInsetRect([self drawableRect],-1,-1));
    
    NSColor *leftColor = [self leftDataColor];
    NSColor *rightColor = [self rightDataColor];
    
    SHORT displayChannel = [self displayedChannel];
    
	float defaultLineWidth = [NSBezierPath defaultLineWidth];
	[NSBezierPath setDefaultLineWidth:[self lineWidth]];
	
    if(displayChannel == LISSAJOUS_CHANNEL)
    {
        [leftColor set];
        [self drawLissajouPathArray];
    }
    if(displayChannel == LEFT_CHANNEL || displayChannel == STEREO_CHANNEL)
    {
        [leftColor set];
        [self drawPathArray:mLeftPathArray count:mPathArrayCount];
    }
    if(displayChannel == RIGHT_CHANNEL || displayChannel == STEREO_CHANNEL)
    {
        [rightColor set];
        [self drawPathArray:mRightPathArray count:mPathArrayCount];        
    }
	
	[NSBezierPath setDefaultLineWidth:defaultLineWidth];
}

- (void)fillLissajouPathArray
{
    FLOAT tmin = [self lissajousFrom];
    FLOAT tmax = [self lissajousTo];

    if(tmin==-1 && tmax==-1)
    {
        tmin = 0;
        tmax = [mDataSource maxXOfChannel:LEFT_CHANNEL];
        [self setLissajousFrom:tmin];
        [self setLissajousTo:tmax];
    }
    
    FLOAT minStep = 1.0/[mDataSource dataRate];
    FLOAT maxStep = minStep*100;
    FLOAT tstep = minStep+(100-[self lissajousQuality])/100*(maxStep-minStep);
    
    mPathArrayCount = (FLOAT)(tmax-tmin)/tstep;
    if(mLissajouPathArray)
    {
        free(mLissajouPathArray);
        mLissajouPathArray = NULL;
    }
    mLissajouPathArray = (PathElementPtr)malloc(mPathArrayCount*sizeof(PathElement));

    ULONG p = 0;
    FLOAT t;
    for(t=tmin; t<tmax; t+=tstep)
    {
        FLOAT leftValue = [mDataSource yValueAtX:t channel:LEFT_CHANNEL];
        FLOAT rightValue = [mDataSource yValueAtX:t channel:RIGHT_CHANNEL];
                
        mLissajouPathArray[p].x = viewOX+deltaX*(leftValue-mVisual_MinX);
        mLissajouPathArray[p].y = viewOY+deltaY*(rightValue-mVisual_MinY);

        p++;
    }
}

- (void)fillPathArray:(PathElementPtr)path channel:(SHORT)channel
{
    long points = -1;
			
	//NSLog(@"%f %f", mVisual_MinX, mVisual_MaxX);
	
	float x;
    for(x=mVisual_MinX; x<=mVisual_MaxX; x+=xStep)
    {		
		float real_x = [self computeXRealValueFromXValue:x];
		
		FLOAT value = [mDataSource yValueAtX:real_x channel:channel];
		FLOAT min = value;
		FLOAT max = value;
		
		if([mDataSource kind] == KIND_FFT)
		{
			ULONG index;
			ULONG minIndex = [mDataSource indexOfXValue:real_x channel:channel];
			ULONG maxIndex = [mDataSource indexOfXValue:real_x+xStep channel:channel];
			for(index=minIndex; index<maxIndex; index++)
			{
				value = [mDataSource yValueAtIndex:index channel:channel];
				min = MIN(min, value);
				max = MAX(max, value);
			}
		}
		
		points++;
		if(points>=mPathArrayCount)
			points = mPathArrayCount-1;
				
		path[points].x = viewOX+deltaX*(x-mVisual_MinX);
		path[points].minY = viewOY+deltaY*(min-mVisual_MinY);
		path[points].maxY = viewOY+deltaY*(max-mVisual_MinY);        			
    }

    mPathArrayCount = points+1;
}

- (void)refreshSelf
{  
    // Refresh path only if data available

    [self checkRanges];

    if(mVisual_MinX == mVisual_MaxX) return;
    if(mVisual_MinY == mVisual_MaxY) return;
    
    if(mVisual_MaxX < mVisual_MinX)
    {
        FLOAT temp = mVisual_MinX;
        mVisual_MinX = mVisual_MaxX;
        mVisual_MaxX = temp;
    }
    
    // View properties
 
    NSRect viewRect = [self drawableRect];   
    viewOX = viewRect.origin.x;
    viewOY = viewRect.origin.y;
    viewDX = viewRect.size.width;
    viewDY = viewRect.size.height;
           
    // Set the graphic factors
                
    deltaX = viewDX / (mVisual_MaxX-mVisual_MinX);
    deltaY = viewDY / (mVisual_MaxY-mVisual_MinY);
    
    xStep = ((mVisual_MaxX-mVisual_MinX)*2) / viewDX;
    yStep = ((mVisual_MaxY-mVisual_MinY)*2) / viewDY;
                                                
    // Create the path
    
    if([self displayedChannel] == LISSAJOUS_CHANNEL)
    {
        if(mLeftPathArray)
        {
            free(mLeftPathArray);
            mLeftPathArray = NULL;
        }
        if(mRightPathArray)
        {
            free(mRightPathArray);
            mRightPathArray = NULL;
        }

        [self fillLissajouPathArray];
    } else
    {
        if(mLissajouPathArray)
        {
            free(mLissajouPathArray);
            mLissajouPathArray = NULL;
        }
        
        ULONG count = (FLOAT)(mVisual_MaxX-mVisual_MinX)/xStep+2;
        if(mPathArrayCount != count)
        {
            mPathArrayCount = count;
            if(mLeftPathArray)
            {
                free(mLeftPathArray);
                mLeftPathArray = NULL;
            }
            if(mRightPathArray)
            {
                free(mRightPathArray);
                mRightPathArray = NULL;
            }
            
            if(mPathArrayCount < 1)
                return;
                        
            if([mDataSource dataExistsForChannel:LEFT_CHANNEL])
                mLeftPathArray = (PathElementPtr)malloc(mPathArrayCount*sizeof(PathElement));
            if([mDataSource dataExistsForChannel:RIGHT_CHANNEL])
                mRightPathArray = (PathElementPtr)malloc(mPathArrayCount*sizeof(PathElement));
        }
        
        if([mDataSource dataExistsForChannel:LEFT_CHANNEL] && mLeftPathArray)
            [self fillPathArray:mLeftPathArray channel:LEFT_CHANNEL];
        if([mDataSource dataExistsForChannel:RIGHT_CHANNEL] && mRightPathArray)
            [self fillPathArray:mRightPathArray channel:RIGHT_CHANNEL];  
    }
}

- (void)setProposedCursorPositionX:(FLOAT)x positionY:(FLOAT)y channel:(SHORT)channel
{
    if(channel == LISSAJOUS_CHANNEL)
    {
        mCursor_X = x;
        mCursor_Y = y;
    } else
    {
        mCursor_X = x;
        mCursor_Y = [self computeYRealValueFromXRealValue:x channel:channel];
    }
    
    [self checkRanges];
}

- (NSString*)composeCursorLabelStringForXValue:(FLOAT)x yValue:(FLOAT)y zValue:(FLOAT)z
{
    NSString *label;
    label = [[self roundFloatToString:x*mVisualDisplayedXAxisFactor maxValue:mVisualDisplayedMaxX]
                stringByAppendingString:mDisplayedXAxisUnit];
    label = [label stringByAppendingString:@", "];
    label = [label stringByAppendingString:[self roundFloatToString:y*mVisualDisplayedYAxisFactor maxValue:mVisualDisplayedMaxY]];
    label = [label stringByAppendingString:mDisplayedYAxisUnit];
    
    return label;
}

@end
