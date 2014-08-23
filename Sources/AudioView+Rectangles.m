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

@implementation AudioView (Rectangles)

- (void)setViewRect:(NSRect)rect
{
    mViewRect = rect;
}

- (NSRect)viewRect
{
    return mViewRect;
}

- (FLOAT)xAxisSliderHeight
{
    return mUseHorizontalScroller?15:0;
}

- (FLOAT)yAxisSliderWidth
{
    return mUseVerticalScroller?15:0;
}

- (FLOAT)xAxisMargin
{
    if([self allowsXAxis])
        return kXAxisMargin;
    else
        return 0;
}

- (FLOAT)yAxisMargin
{
    if([self allowsYAxis])
        return kYAxisMargin;
    else
        return 0;
}

- (FLOAT)xAxisMarginTitle
{
    if([self allowsXAxis])
        return 20;
    else
        return 0;
}

- (FLOAT)yAxisMarginTitle
{
    if([self allowsYAxis])
        return 20;
    else
        return 0;
}

- (FLOAT)xTitleMargin
{
    if([self allowsTitle])
        return kTitleXMargin;
    else
        return 0;
}

- (NSRect)drawableRect
{
    NSRect bounds = [self viewRect];
    
    bounds.origin.x++;
    bounds.origin.y++;
    bounds.size.width-=2;
    bounds.size.height-=2;
    
    bounds.origin.x += [self yAxisMargin] + [self yAxisSliderWidth];
    bounds.origin.y += [self xAxisMargin] + [self xAxisSliderHeight];
    bounds.size.width -= [self yAxisMargin]+[self xAxisMarginTitle] + [self yAxisSliderWidth];
    bounds.size.height -= [self xAxisMargin]+[self yAxisMarginTitle] + [self xAxisSliderHeight];
    
    bounds.origin.x += [self xTitleMargin];
    bounds.size.width -= [self xTitleMargin];
        
    return bounds;
}

- (NSRect)xAxisSliderRect
{
    NSRect bounds = [self viewRect];
    NSRect rect = NSMakeRect(bounds.origin.x+[self yAxisMargin], bounds.origin.y,
                        bounds.size.width-[self yAxisMargin]-[self xAxisMarginTitle], [self xAxisSliderHeight]);

    rect.origin.x += [self xTitleMargin]+[self yAxisSliderWidth];
    rect.size.width -= [self xTitleMargin]+[self yAxisSliderWidth];

    return rect;
}

- (NSRect)yAxisSliderRect
{
    NSRect bounds = [self viewRect];
    NSRect rect = NSMakeRect(bounds.origin.x, bounds.origin.y,
                        [self yAxisSliderWidth], bounds.size.height-[self yAxisMarginTitle]);

    rect.origin.x += [self xTitleMargin];
 
    rect.origin.y += [self xAxisMargin]+[self xAxisSliderHeight];
    rect.size.height -= [self xAxisMargin]+[self xAxisSliderHeight];

    return rect;
}

- (NSRect)xAxisRect
{
    NSRect bounds = [self viewRect];
    NSRect rect = NSMakeRect(bounds.origin.x+[self yAxisMargin], bounds.origin.y,
                        bounds.size.width-[self yAxisMargin]-[self xAxisMarginTitle], [self xAxisMargin]);

    rect.origin.x += [self xTitleMargin] + [self yAxisSliderWidth];
    rect.size.width -= [self xTitleMargin] + [self yAxisSliderWidth];

    rect.origin.y += [self xAxisSliderHeight];

    return rect;
}

- (NSRect)yAxisRect
{  
    NSRect bounds = [self viewRect];  
    NSRect rect = NSMakeRect(bounds.origin.x, bounds.origin.y,
                        [self yAxisMargin], bounds.size.height-[self yAxisMarginTitle]);

    rect.origin.x += [self xTitleMargin] + [self yAxisSliderWidth];
    
    rect.origin.y += [self xAxisMargin] + [self xAxisSliderHeight];
    rect.size.height -= [self xAxisMargin] + [self xAxisSliderHeight];
    
    return rect;
}

- (NSRect)titleRect
{
    NSRect bounds = [self viewRect];  

    bounds.origin.x++;
    bounds.origin.y++;
    bounds.size.width-=2;
    bounds.size.height-=2;

    return NSMakeRect(bounds.origin.x, bounds.origin.y, kTitleXMargin, bounds.size.height);
}

- (NSCursor*)crossCursor
{
    return [[[NSCursor alloc] initWithImage:[NSImage imageNamed:@"CursorCross"]
            hotSpot:NSMakePoint(7, 7)] autorelease];
}

- (NSCursor*)resizeHorizontalCursor
{
    return [[[NSCursor alloc] initWithImage:[NSImage imageNamed:@"CursorResizeHorizontal"]
            hotSpot:NSMakePoint(7, 7)] autorelease];
}

- (NSCursor*)resizeVerticalCursor
{
    return [[[NSCursor alloc] initWithImage:[NSImage imageNamed:@"CursorResizeVertical"]
            hotSpot:NSMakePoint(7, 7)] autorelease];
}

- (NSCursor*)handCursor
{
    return [[[NSCursor alloc] initWithImage:[NSImage imageNamed:@"CursorHand"]
            hotSpot:NSMakePoint(7, 7)] autorelease];
}

- (void)resetCursorRects
{
    [self addCursorRect:[self xAxisRect] cursor:[self resizeHorizontalCursor]];
    [self addCursorRect:[self yAxisRect] cursor:[self resizeVerticalCursor]];
    [self addCursorRect:[self titleRect] cursor:[self handCursor]];
}

@end
