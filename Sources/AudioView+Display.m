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

@implementation AudioView (Display)

- (void)drawXTicksFor:(FLOAT)time
{
    NSRect rect = [self xAxisRect];
    NSPoint p0 = NSMakePoint(round(rect.origin.x+(time-mVisualDisplayedMinX)/(mVisualDisplayedMaxX-mVisualDisplayedMinX)*rect.size.width)-0.5, round(rect.origin.y+[self xAxisMargin])-0.5);

    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[self xAxisColor]
                                forKey:NSForegroundColorAttributeName];
    
	if([mDataSource respondsToSelector:@selector(xAxisScale)] && [mDataSource xAxisScale] == XAxisLogScale) {
		time = [self computeXRealValueFromXValue:time/mVisualDisplayedXAxisFactor]*mVisualDisplayedXAxisFactor;
	}

	NSString *label = [self roundFloatToString:time maxValue:MAX(fabs(mVisualDisplayedMinX), fabs(mVisualDisplayedMaxX))];    
	NSSize labelSize = [label sizeWithAttributes:attributes];
    
    [label drawAtPoint:NSMakePoint(p0.x-labelSize.width*0.5, p0.y-labelSize.height-5)
                withAttributes:attributes];    

    [[self xAxisColor] set];
    [NSBezierPath strokeLineFromPoint:p0 toPoint:NSMakePoint(p0.x, p0.y-5)];
}

- (void)drawYTicksFor:(FLOAT)time
{
    NSRect rect = [self yAxisRect];
    NSPoint p0 = NSMakePoint(round(rect.origin.x+rect.size.width)-0.5, round(rect.origin.y+(time-mVisualDisplayedMinY)/(mVisualDisplayedMaxY-mVisualDisplayedMinY)*rect.size.height)-0.5);

    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[self yAxisColor]
                                forKey:NSForegroundColorAttributeName];

    NSString *label = [self roundFloatToString:time maxValue:MAX(fabs(mVisualDisplayedMinY), fabs(mVisualDisplayedMaxY))];
    NSSize labelSize = [label sizeWithAttributes:attributes];
    
    [label drawAtPoint:NSMakePoint(p0.x-labelSize.width-6, p0.y-labelSize.height*0.5) 
                withAttributes:attributes];

    [[self yAxisColor] set];
    [NSBezierPath strokeLineFromPoint:p0 toPoint:NSMakePoint(p0.x-5, p0.y)];
}

- (void)drawXGridFor:(FLOAT)time
{
    if(mViewType == VIEW_3D) return;

    NSRect rect = [self xAxisRect];
    NSPoint p0 = NSMakePoint(round(rect.origin.x+(time-mVisualDisplayedMinX)/(mVisualDisplayedMaxX-mVisualDisplayedMinX)*rect.size.width)-0.5, round(rect.origin.y+[self xAxisMargin])-0.5);
    
    [[self gridColor] set];
    [NSBezierPath strokeLineFromPoint:p0 toPoint:NSMakePoint(p0.x, p0.y+[self drawableRect].size.height+2)];
}

- (void)drawYGridFor:(FLOAT)time
{
    if(mViewType == VIEW_3D) return;

    NSRect rect = [self yAxisRect];
    NSPoint p0 = NSMakePoint(round(rect.origin.x+rect.size.width)-0.5, round(rect.origin.y+(time-mVisualDisplayedMinY)/(mVisualDisplayedMaxY-mVisualDisplayedMinY)*rect.size.height)-0.5);

    [[self gridColor] set];
    [NSBezierPath strokeLineFromPoint:p0 toPoint:NSMakePoint(p0.x+[self drawableRect].size.width+2, p0.y)];
}

- (void)drawXAxisTitle
{
    NSRect r = [self drawableRect];
    NSSize size = [[self xAxisName] sizeWithAttributes:NULL];
    NSPoint p = NSMakePoint(r.origin.y,-(r.origin.x+r.size.width+size.height));
    NSAffineTransform *tr = [NSAffineTransform transform];
    NSString *title = [self xAxisName];

    if([self displayedChannel] == LISSAJOUS_CHANNEL)
        title = [self yAxisName];

    if(mDisplayedXAxisUnit && [mDisplayedXAxisUnit isEqualToString:@""] == NO)
    {
        title = [title stringByAppendingString:@" ["];
        title = [title stringByAppendingString:mDisplayedXAxisUnit];
        title = [title stringByAppendingString:@"]"];
    }
    
    [tr rotateByDegrees:90];
    [tr concat];

    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[self xAxisColor]
                                forKey:NSForegroundColorAttributeName];
    [title drawAtPoint:p withAttributes:attributes];
    
    [tr invert];
    [tr concat];
}

- (void)drawYAxisTitle
{
    NSRect r = [self drawableRect];
    NSPoint p = NSMakePoint(r.origin.x, r.origin.y+r.size.height);
    NSString *title = [self yAxisName];    

    if(mDisplayedYAxisUnit && [mDisplayedYAxisUnit isEqualToString:@""] == NO)
    {
        title = [title stringByAppendingString:@" ["];
        title = [title stringByAppendingString:mDisplayedYAxisUnit];
        title = [title stringByAppendingString:@"]"];
    }

    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[self yAxisColor]
                                forKey:NSForegroundColorAttributeName];
    [title drawAtPoint:p withAttributes:attributes];
}

- (FLOAT)spaceOfAxisValue:(FLOAT)value horizontal:(BOOL)horizontal
{
    NSString *label = [self roundFloatToString:value maxValue:value];
    if(horizontal)
        return [label sizeWithAttributes:NULL].width;
    else
        return [label sizeWithAttributes:NULL].height;
}

- (FLOAT)stepAndNumber:(SHORT*)number room:(FLOAT)room min:(FLOAT*)min max:(FLOAT*)max horizontal:(BOOL)horizontal
{   
    float delta = *max-*min;
    if(delta==0)
    {
        number = 0;
        return 0;
    }
    
    float step = 0;
    if(fabs(delta)<1)
    {
        float factor = pow(10,trunc(log10(fabs(delta)))+1);
        float delta_ = fabs(delta)*factor;
        step = pow(10, trunc(log10(fabs(delta_))));
        step /= factor;
    } else
        step = pow(10, trunc(log10(fabs(delta))));
        
    step *= sign(delta);

    float space = MAX([self spaceOfAxisValue:*min horizontal:horizontal],
                [self spaceOfAxisValue:*max horizontal:horizontal]);
        
    unsigned short checkCount = 0;
    if((space+5)*((float)delta/step)<=room)
    {
        do
        {
            checkCount++;
            step *= 0.5;
            *number = (float)delta/step;
        } while((space+5)*(*number)<=room && checkCount<1000);

        step *= 2;
    } else
    {
        do
        {
            checkCount++;
            step *= 2;
            *number = (float)delta/step;
        } while((space+5)*(*number)>room && checkCount<1000);
    }
    
    if(fmod(*min,step) != 0)
        *min = *min-step;
    if(fmod(*max,step) != 0)
        *max = *max+step;
    
    return step;
}

- (void)drawXAxis
{    
    BOOL axis = [self allowsXAxis];
    BOOL grid = [self allowsGrid];
        
    if(axis || grid)
    {
        FLOAT min = mVisualDisplayedMinX;
        FLOAT max = mVisualDisplayedMaxX;

        SHORT number = 0;
        FLOAT step = [self stepAndNumber:&number room:[self xAxisRect].size.width
										min:&min max:&max horizontal:YES];			
		
        min = round(min/step)*step;	// To have always the 0 displayed

        SHORT n;
        for(n=0; n<number+1; n++)
        {
            FLOAT time = min+step*n;
            if(time>=mVisualDisplayedMinX && time<=mVisualDisplayedMaxX)
            {
                if(axis)
                    [self drawXTicksFor:time];
                if(grid)
                    [self drawXGridFor:time];
            }
        }

        if(axis)
            [self drawXAxisTitle];
    }
}

- (void)drawYAxis
{    
    BOOL axis = [self allowsYAxis];
    BOOL grid = [self allowsGrid];
    
    if(axis || grid)
    {
        FLOAT min = mVisualDisplayedMinY;
        FLOAT max = mVisualDisplayedMaxY;
        SHORT number = 0;
        FLOAT step = [self stepAndNumber:&number room:[self yAxisRect].size.height
                        min:&min max:&max horizontal:NO];
                                        
        min = round(min/step)*step;	// To have always the 0 displayed
        
        SHORT n;
        for(n=0; n<number+1; n++)
        {
            FLOAT time = min+step*n;

            if(time>=mVisualDisplayedMinY && time<=mVisualDisplayedMaxY
            || fabs(mVisualDisplayedMaxY-time)<=1e-4) // To prevent rounding error after 4 digits
            {
                if(axis)
                    [self drawYTicksFor:time];
                if(grid)
                    [self drawYGridFor:time];
            }
        }

        if(axis)
            [self drawYAxisTitle];
    }
}

- (void)drawCursorAtX:(FLOAT)x y:(FLOAT)y rotateIfNoRoom:(BOOL)rotateIfNoRoom restrictWidth:(FLOAT)restrictWidth label:(BOOL)label
{
    NSRect rect = [self drawableRect];
    BOOL rotate = NO;
    FLOAT margin = 2;
    
    if([mDataSource respondsToSelector:@selector(zValueAtX:y:)])
        mCursor_Z = [mDataSource zValueAtX:x y:y];
    
    NSPoint cursor = NSMakePoint([self computeXPixelFromXRealValue:x],
                            [self computeYPixelFromYRealValue:y]);
    
    NSPoint px1 = NSMakePoint(round(cursor.x)-0.5, round(mDrawableRect.origin.y)-0.5);
    NSPoint px2 = NSMakePoint(round(cursor.x)-0.5, round(mDrawableRect.size.height+mDrawableRect.origin.y)-0.5);
    NSPoint py1 = NSMakePoint(round(mDrawableRect.origin.x)-0.5, round(cursor.y)-0.5);
    NSPoint py2 = NSMakePoint(round(mDrawableRect.origin.x+mDrawableRect.size.width)-0.5, round(cursor.y)-0.5);
            
    [[self cursorColor] set];
	[NSBezierPath setDefaultLineWidth:0.5];
    if(mCursorDisplayVertical)
        [NSBezierPath strokeLineFromPoint:px1 toPoint:px2];
    if(mCursorDisplayHorizontal)
        [NSBezierPath strokeLineFromPoint:py1 toPoint:py2];
    
    if(label)
    {
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:[self cursorColor]
                                    forKey:NSForegroundColorAttributeName];
    
#warning added [self computeXRealValueFromXValue] to handle x-axis log
        NSString *labelString = [self composeCursorLabelStringForXValue:[self computeXRealValueFromXValue:x] yValue:y zValue:mCursor_Z];
    
        NSSize size = [labelString sizeWithAttributes:attributes];
        if(py1.y+size.height>rect.origin.y+rect.size.height)
            py1.y = rect.origin.y+rect.size.height-size.height;
    
        if(px1.x+size.width>rect.origin.x+rect.size.width)
        {
            if(rotateIfNoRoom)
                rotate = YES;
            else
                px1.x = rect.origin.x+rect.size.width-size.width;
        }
        if(size.width>restrictWidth && restrictWidth>0)
            rotate = YES;
            
        if(rotate)
        {
            NSAffineTransform *tr = [NSAffineTransform transform];
            FLOAT x = py1.y;
            FLOAT y = -px1.x;
            
            [tr rotateByDegrees:90];
            [tr concat];
        
            if(x+size.width>rect.origin.y+rect.size.height)
                x = rect.origin.y+rect.size.height-size.width;
                
            [labelString drawAtPoint:NSMakePoint(x+margin,y+margin) withAttributes:attributes];
            
            [tr invert];
            [tr concat];
        } else
            [labelString drawAtPoint:NSMakePoint(px1.x+margin,py1.y+margin) withAttributes:attributes];
    }
}

- (void)drawHarmonicCursorSelf
{
}

- (void)drawCursor
{
    if(![self allowsCursor]) return;
    if(![self showCursor]) return;

    [self setCursorPositionX:mCursor_X positionY:mCursor_Y];
		
    if([self showCursorHarmonic] && [mDataSource supportHarmonicCursor])
        [self drawHarmonicCursorSelf];
    else
        [self drawCursorAtX:mCursor_X y:mCursor_Y rotateIfNoRoom:YES restrictWidth:0 label:YES];
}

- (void)drawTriggerCursor
{
    if([mDataSource supportTrigger] == NO) return;
    if([self showTriggerCursor] == NO) return;

    float cursorY = [self computeYPixelFromYRealValue:[mDataSource triggerOffset]];
    
    NSPoint py1 = NSMakePoint(round(mDrawableRect.origin.x)-0.5, round(cursorY)-0.5);
    NSPoint py2 = NSMakePoint(round(mDrawableRect.origin.x+mDrawableRect.size.width)-0.5, round(cursorY)-0.5);

    [[NSColor orangeColor] set];
    [NSBezierPath strokeLineFromPoint:py1 toPoint:py2];
}

- (void)drawSelection
{
    if(![self allowsSelection]) return;
    if(mSel_MinX==0 && mSel_MaxX==0) return;
    
    NSRect r = [self drawableRect];
    FLOAT deltaVisual = mVisual_MaxX-mVisual_MinX;
            
    NSPoint p1 = NSMakePoint((mSel_MinX-mVisual_MinX)/deltaVisual*
                            r.size.width+r.origin.x, r.origin.y);
    NSPoint p2 = NSMakePoint((mSel_MaxX-mVisual_MinX)/deltaVisual*
                        r.size.width+r.origin.x, r.size.height+r.origin.y);    
    
    NSRectClip(r);
    [[self selectionColor] set];
    [NSBezierPath fillRect:NSMakeRect(p1.x, p1.y, p2.x-p1.x, p2.y)];        
}

- (void)drawTitle
{
    if(![self allowsTitle]) return;
    
    NSRect r = [self titleRect];
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    NSAffineTransform *tr = [NSAffineTransform transform];

    if(mIsSelected)
        [[NSColor orangeColor] set];
    else
        [[NSColor blackColor] set];
    NSRectFill(r);

    [tr rotateByDegrees:90];
    [tr concat];
    
    [attrs setObject:[self titleColor] forKey:NSForegroundColorAttributeName];
    [attrs setObject:[NSFont menuFontOfSize:18] forKey:NSFontAttributeName];

    NSSize size = [[self viewName] sizeWithAttributes:attrs];
    NSPoint p = NSMakePoint(r.size.height/2-size.width/2, -(r.size.width/2+size.height/2));

    [[self viewName] drawAtPoint:p withAttributes:attrs];
    
    [tr invert];
    [tr concat];
}

- (void)drawPlayerCursor
{
    if(![self allowsPlayerhead]) return;
    if(![mDataSource supportPlayback]) return;
    
    NSPoint cursor = NSMakePoint([self computeXPixelFromXRealValue:mPlayerheadPosition],
                            [self computeYPixelFromYRealValue:0]);
    
    NSPoint px1 = NSMakePoint(round(cursor.x)-0.5, round(mDrawableRect.origin.y)-0.5);
    NSPoint px2 = NSMakePoint(round(cursor.x)-0.5, round(mDrawableRect.size.height+mDrawableRect.origin.y)-0.5);
            
    [[self playerheadColor] set];
    [NSBezierPath strokeLineFromPoint:px1 toPoint:px2];
}

- (void)drawDrawableFrame
{
    NSRect yr = [self yAxisRect];
    NSRect xr = [self xAxisRect];
    NSRect r;
    r.origin.x = round(yr.origin.x+yr.size.width)-0.5;
    r.origin.y = round(xr.origin.y+xr.size.height)-0.5;
    r.size = [self drawableRect].size;
    r.size.width = round(r.size.width+2)+0.5;
    r.size.height = round(r.size.height+2)+0.5;
    
    [[self gridColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(r.origin.x, r.origin.y)
                            toPoint:NSMakePoint(r.origin.x+r.size.width, r.origin.y)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(r.origin.x, r.origin.y)
                            toPoint:NSMakePoint(r.origin.x, r.origin.y+r.size.height)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(round(r.origin.x+r.size.width)-0.5, r.origin.y)
                            toPoint:NSMakePoint(round(r.origin.x+r.size.width)-0.5, r.origin.y+r.size.height)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(r.origin.x, round(r.origin.y+r.size.height)-0.5)
                            toPoint:NSMakePoint(r.origin.x+r.size.width,
                                                round(r.origin.y+r.size.height)-0.5)];
}

- (void)drawBackground
{
    [[self backgroundColor] set];
    [NSBezierPath fillRect:mDrawableRect];

    [[NSColor blackColor] set];
    NSFrameRect(mDrawableRect);
    
    [self drawDrawableFrame];
}

- (void)drawBackgroundGridAndAxis
{
    NSRect r = [self viewRect];

    NSDrawGroove(r, r);

    [[self backgroundColor] set];
    [NSBezierPath fillRect:NSInsetRect(r,1,1)];
    
    [self drawBackground];
    [self drawXAxis];
    [self drawYAxis];
    [self drawTitle];
}

- (void)drawLayerBackgroundGridAndAxis
{
    NSRect r = [self viewRect];

    if(mLayerBackgroundGridAndAxisCached == NO && r.size.width !=0 && r.size.height != 0)
    {	
        mLayerBackgroundGridAndAxisCached = YES;

        [mLayerBackgroundGridAndAxisImage setSize:r.size];
    
        [mLayerBackgroundGridAndAxisImage lockFocus];
        [self drawBackgroundGridAndAxis];
        [mLayerBackgroundGridAndAxisImage unlockFocus];
        
        mLayerBackgroundGridAndAxisRect = r;
    }

    if(mDisplayForData)
        [self drawBackgroundGridAndAxis];
    else
        if(mLayerBackgroundGridAndAxisCached)
        {
            NSPoint p = NSMakePoint(mLayerBackgroundGridAndAxisRect.origin.x, 
                                    mLayerBackgroundGridAndAxisRect.origin.y);
                    
            if([self inLiveResize])
            {
                mLayerBackgroundGridAndAxisRect = [self viewRect];
                [mLayerBackgroundGridAndAxisImageRep drawInRect:mLayerBackgroundGridAndAxisRect];
            } else
                [mLayerBackgroundGridAndAxisImage compositeToPoint:p operation:NSCompositeCopy];
        }
}

- (void)drawNotRegisteredText
{    
    NSRect viewRect = [self drawableRect];

    NSString *label = NSLocalizedString(@"Not Registered", NULL);
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:0.8] forKey:NSForegroundColorAttributeName];
    
    float fontSize = viewRect.size.width/[label length];
    [attributes setObject:[NSFont fontWithName:@"Arial" size:fontSize] forKey:NSFontAttributeName];
    NSSize labelSize = [label sizeWithAttributes:attributes];
    while(labelSize.width<viewRect.size.width && labelSize.height<viewRect.size.height)
    {
        [attributes setObject:[NSFont fontWithName:@"Arial" size:++fontSize] forKey:NSFontAttributeName];
        labelSize = [label sizeWithAttributes:attributes];
    }

    NSPoint p = NSMakePoint(viewRect.origin.x+viewRect.size.width/2-labelSize.width/2,
                            viewRect.origin.y+viewRect.size.height/2-labelSize.height/2);
    [label drawAtPoint:p withAttributes:attributes];    
}

- (void)viewWillStartLiveResize
{
    mLayerBackgroundGridAndAxisImageRep = [[[self imageFraction:1.0] bestRepresentationForDevice:NULL] retain];
}

- (void)viewDidEndLiveResize
{
    [mLayerBackgroundGridAndAxisImageRep release];
    mLayerBackgroundGridAndAxisImageRep = NULL;
    [self invalidateCaches];
    [self refreshSelf];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    if(mDataSource == NULL) return;
        
    BOOL invalidate = NO;
    
    if(!NSEqualRects([self drawableRect], mDrawableRect))
    {
        mDrawableRect = [self drawableRect];
        invalidate = invalidate || ([self inLiveResize] == NO);
    }

    if(invalidate)
    {
        [self invalidateCaches];
        [self refreshSelf];
    }
    
    [self drawLayerBackgroundGridAndAxis];

    if([self inLiveResize] == NO)
    {
        if(mIsTarget)
        {
            [[NSColor redColor] set];
            NSFrameRect(NSInsetRect([self viewRect], 1, 1));
        }
    
        [self drawSelf];
        [mDelegate drawCustomRect:mDrawableRect];
        
        [self drawSelection];
        [self drawCursor];
        [self drawPlayerCursor];
        [self drawTriggerCursor];
    }    

    if([NSGraphicsContext currentContextDrawingToScreen] == NO || mDisplayForData)
    {
        // Printing the view
       // if([[ARRegManager sharedRegManager] isRegistered] == NO)
       //     [self drawNotRegisteredText];
    }
}

- (void)refresh
{
    [self checkRanges];
    [self refreshSelf];
    [self setCursorPositionX:mCursor_X positionY:mCursor_Y];
    [self setNeedsDisplay:YES];
}

- (void)setDisplayForData:(BOOL)flag
{
    mDisplayForData = flag;
}

- (NSData*)viewDataAsPDF
{
    [self setDisplayForData:YES];
    NSData *data = [self dataWithPDFInsideRect:[self viewRect]];
    [self setDisplayForData:NO];
    return data;
}

- (NSData*)viewDataAsEPS
{
    [self setDisplayForData:YES];
    NSData *data = [self dataWithEPSInsideRect:[self viewRect]];
    [self setDisplayForData:NO];
    return data;
}

@end
