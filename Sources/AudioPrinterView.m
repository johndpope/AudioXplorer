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

#import "AudioPrinterView.h"
#import "AudioView+Categories.h"

@implementation AudioPrinterView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        mViewArray = [[NSMutableArray alloc] init];
        mImageArray = [[NSMutableArray alloc] init];
        mPrintInfo = NULL;
    }
    return self;
}

- (void)dealloc
{
    [mViewArray release];
    [mImageArray release];
    [mPrintInfo release];
    [super dealloc];
}

- (void)reset
{
    [mViewArray removeAllObjects];
}

- (void)addView:(NSView*)view
{    
    [mViewArray addObject:view];
}

- (void)setPrintInfo:(NSPrintInfo*)printInfo
{
    [mPrintInfo autorelease];
    mPrintInfo = [printInfo retain];
}

- (NSRect)realPaperRect:(NSRect)rect
{    
    rect.origin.x += [mPrintInfo leftMargin];
    rect.origin.y += [mPrintInfo topMargin];
    rect.size.width -= [mPrintInfo leftMargin]+[mPrintInfo rightMargin];
    rect.size.height -= [mPrintInfo bottomMargin]+[mPrintInfo topMargin];

    return rect;
}

- (float)leftImageMargin
{
    return 10;
}

- (float)rightImageMargin
{
    return 10;
}

- (float)topImageMargin
{
    return 10;
}

- (float)bottomImageMargin
{
    return 10;
}

- (void)prepareForPrinting
{
    NSRect r = [self realPaperRect:[self bounds]];
    
    int numberOfViews = [mViewArray count];
    float heightOfView = r.size.height/numberOfViews;

    [mImageArray removeAllObjects];

    float dx = r.size.width-[self leftImageMargin]-[self rightImageMargin];
    float dy = heightOfView-[self topImageMargin]-[self bottomImageMargin];

    int index;
    for(index=0; index<numberOfViews; index++)
    {
        AudioView *view = [mViewArray objectAtIndex:index];
        NSRect oldViewRect = [view viewRect];
        
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(dx, dy)];
        [image lockFocus];
        [view setViewRect:NSMakeRect(0,0,dx,dy)];
        [view drawRect:NSMakeRect(0,0,dx,dy)];
        [view setViewRect:oldViewRect];
        [image unlockFocus];
        [mImageArray addObject:[image autorelease]];
    }
}

- (void)drawRect:(NSRect)rect
{
    NSRect r = [self realPaperRect:rect];
    
    int numberOfViews = [mViewArray count];
    float heightOfView = r.size.height/numberOfViews;
        
    int view;
    for(view=0; view<numberOfViews; view++)
    {
        float x = [mPrintInfo leftMargin]+[self leftImageMargin];
        float y = (numberOfViews-view-1)*heightOfView+[mPrintInfo topMargin]+[self topImageMargin];
        [[mImageArray objectAtIndex:view] compositeToPoint:NSMakePoint(x,y) operation:NSCompositeCopy];
    }
}

// Return the number of pages available for printing
- (BOOL)knowsPageRange:(NSRangePointer)range {
    range->location = 1;
    range->length = 1;
    return YES;
}

// Return the drawing rectangle for a particular page number
- (NSRect)rectForPage:(int)page {
    // Obtain the print info object for the current operation
    NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];

    // Calculate the page height in points
    NSSize paperSize = [pi paperSize];
    
    return NSMakeRect(0, 0, paperSize.width, paperSize.height);
}

@end
