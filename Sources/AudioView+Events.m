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
#import "AudioExchange.h"
#import "AudioPrinter.h"
#import "AudioSynth.h"

@implementation AudioView (Mouse)

- (void)handleMouseInDrawableRect:(NSEvent*)event first:(BOOL)first
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    unsigned int flags = [event modifierFlags];
    FLOAT cursorX = [self computeXRealValueFromXPixel:p.x];
    
    if(flags & NSShiftKeyMask)
    {
        if(first)
            mSel_MinX = mSel_MaxX = cursorX;
        else
            mSel_MaxX = cursorX;
        
        [self selectionHasChanged];
    } else if(flags & NSAlternateKeyMask && [mDataSource supportPlayback]
              && [mDataSource supportTrigger] == NO)
    {
        mPlayerheadPosition = cursorX;
        [self playerHeadHasChanged];
    } else if(flags & NSAlternateKeyMask && [mDataSource supportTrigger])
    {
        FLOAT cursorY = [self computeYRealValueFromYPixel:p.y];
        [mDataSource setTriggerOffset:cursorY];
        [self setShowTriggerCursor:YES];
        [self triggerCursorHasChanged];
    } else
    {
        [self setShowCursor:YES];
        [self setCursorPositionX:cursorX positionY:[self computeYRealValueFromYPixel:p.y]];
        [self cursorHasChanged];
    }
}

- (BOOL)handleXAxisResetZeroLocation:(NSPoint)p modifiers:(unsigned int)flags first:(BOOL)first
{
    if((flags & NSCommandKeyMask) && (flags & NSShiftKeyMask))
    {
        // Move coordinate 0 at cursor location
        
        FLOAT delta = mVisual_MaxX-mVisual_MinX;
        FLOAT percent = (p.x-mDrawableRect.origin.x)/mDrawableRect.size.width;
        
        // 0   -> min = 0, max = delta
        // 0.5 -> min = -delta/2 max = delta/2
        // 1   -> min = -delta max = 0
        
        mVisual_MinX = -percent*delta;
        mVisual_MaxX = (1-percent)*delta;
        
        [self scaleHasChanged];
        [self updateXAxisScroller];
        
        return YES;
    } else
        return NO;
}

- (BOOL)handleYAxisResetZeroLocation:(NSPoint)p modifiers:(unsigned int)flags first:(BOOL)first
{
    if((flags & NSCommandKeyMask) && (flags & NSShiftKeyMask))
    {
        // Move coordinate 0 at cursor location
        
        FLOAT delta = mVisual_MaxY-mVisual_MinY;
        FLOAT percent = (p.y-mDrawableRect.origin.y)/mDrawableRect.size.height;
        
        // 0   -> min = 0, max = delta
        // 0.5 -> min = -delta/2 max = delta/2
        // 1   -> min = -delta max = 0
        
        mVisual_MinY = -percent*delta;
        mVisual_MaxY = (1-percent)*delta;
        
        [self scaleHasChanged];
        [self updateYAxisScroller];
        
        return YES;
    } else
        return NO;
}

- (BOOL)handleXAxisOffsetLocation:(NSPoint)p modifiers:(unsigned int)flags first:(BOOL)first
{
    if(flags & NSCommandKeyMask && first == NO)
    {
        // Offset
        
        FLOAT delta = -((p.x-mOldPoint.x)/mDrawableRect.size.width)*(mVisual_MaxX-mVisual_MinX);
        mVisual_MinX += delta;
        mVisual_MaxX += delta;
        
        [self scaleHasChanged];
        [self updateXAxisScroller];
        
        mOldPoint = p;
        
        return YES;
    } else
        return NO;
}

- (BOOL)handleYAxisOffsetLocation:(NSPoint)p modifiers:(unsigned int)flags first:(BOOL)first
{
    if(flags & NSCommandKeyMask && first == NO)
    {
        // Offset
        
        FLOAT delta = -((p.y-mOldPoint.y)/mDrawableRect.size.height)*(mVisual_MaxY-mVisual_MinY);
        mVisual_MinY += delta;
        mVisual_MaxY += delta;
        
        [self scaleHasChanged];
        [self updateYAxisScroller];
        
        mOldPoint = p;
        
        return YES;
    } else
        return NO;
}

- (BOOL)handleXAxisScaleLimitLocation:(NSPoint)p modifiers:(unsigned int)flags first:(BOOL)first
{
    if(first && (flags & NSAlternateKeyMask))
    {
        mPointValue = [self computeXRealValueFromXPixel:p.x]-mVisual_MinX;
        return YES;
    } else if((flags & NSAlternateKeyMask) && (flags & NSShiftKeyMask))
    {
        // Strech lower limit
        FLOAT old_x = mVisual_MinX;
        mVisual_MinX = mVisual_MaxX-(mDrawableRect.size.width/(p.x-mDrawableRect.origin.x))*mPointValue;
        if(mVisual_MinX >= mVisual_MaxX)
            mVisual_MinX = old_x;
        
        mPointValue = [self computeXRealValueFromXPixel:p.x]-mVisual_MinX;
        
        [self scaleHasChanged];
        [self updateXAxisScroller];
        
        return YES;
    } else if(flags & NSAlternateKeyMask)
    {
        // Strech upper limit
        FLOAT old_x = mVisual_MaxX;
        mVisual_MaxX = (mDrawableRect.size.width/(p.x-mDrawableRect.origin.x))*mPointValue+mVisual_MinX;
        if(mVisual_MinX >= mVisual_MaxX)
            mVisual_MaxX = old_x;
        
        mPointValue = [self computeXRealValueFromXPixel:p.x]-mVisual_MinX;
        
        [self scaleHasChanged];
        [self updateXAxisScroller];
        
        return YES;
    } else
        return NO;
}

- (BOOL)handleYAxisScaleLimitLocation:(NSPoint)p modifiers:(unsigned int)flags first:(BOOL)first
{
    if(first && (flags & NSAlternateKeyMask))
    {
        mPointValue = [self computeYRealValueFromYPixel:p.y]-mVisual_MinY;
        return YES;
    } else if((flags & NSAlternateKeyMask) && (flags & NSShiftKeyMask))
    {
        // Strech lower limit
        FLOAT old_y = mVisual_MinY;
        mVisual_MinY = mVisual_MaxY-(mDrawableRect.size.height/(p.y-mDrawableRect.origin.y))*mPointValue;
        if(mVisual_MinY >= mVisual_MaxY)
            mVisual_MinY = old_y;
        
        mPointValue = [self computeYRealValueFromYPixel:p.y]-mVisual_MinY;
        
        [self scaleHasChanged];
        [self updateYAxisScroller];
        
        return YES;
    } else if(flags & NSAlternateKeyMask)
    {
        // Strech upper limit
        FLOAT old_y = mVisual_MaxY;
        mVisual_MaxY = (mDrawableRect.size.height/(p.y-mDrawableRect.origin.y))*mPointValue+mVisual_MinY;
        if(mVisual_MinY >= mVisual_MaxY)
            mVisual_MaxY = old_y;
        
        mPointValue = [self computeYRealValueFromYPixel:p.y]-mVisual_MinY;
        
        [self scaleHasChanged];
        [self updateYAxisScroller];
        
        return YES;
    } else
        return NO;
}

- (BOOL)handleXAxisScaleLocation:(NSPoint)p modifiers:(unsigned int)flags first:(BOOL)first
{
    if(first)
    {
        mScaleReset = NO;
        return YES;
    } else
    {
        // Scale
        
        FLOAT px = [self computeXRealValueFromXPixel:p.x];
        
        if(sign(px) == sign(mPointValue)
           && (sign(mPointValue) == 1 && px>1e-6
               || sign(mPointValue) == -1 && px<-1e-6))
        {
            if(mScaleReset)
            {
                mPointValue = px;
                mScaleReset = NO;
            } else
            {
                FLOAT maxX = mVisual_MaxX/(px/mPointValue);
                FLOAT minX = mVisual_MinX/(px/mPointValue);
                
                if(maxX>minX)
                {
                    mVisual_MinX = minX;
                    mVisual_MaxX = maxX;
                    mPointValue = [self computeXRealValueFromXPixel:p.x];
                }
            }
        } else
            mScaleReset = YES;
        
        [self scaleHasChanged];
        [self updateXAxisScroller];
        
        mOldPoint = p;
        
        return YES;
    }
}

- (BOOL)handleYAxisScaleLocation:(NSPoint)p modifiers:(unsigned int)flags first:(BOOL)first
{
    if(first)
    {
        mScaleReset = NO;
        return YES;
    } else
    {
        // Scale
        
        FLOAT py = [self computeYRealValueFromYPixel:p.y];
        
        if(sign(py) == sign(mPointValue)
           && (sign(mPointValue) == 1 && py>1e-6
               || sign(mPointValue) == -1 && py<-1e-6))
        {
            if(mScaleReset)
            {
                mPointValue = py;
                mScaleReset = NO;
            } else
            {
                FLOAT maxY = mVisual_MaxY/(py/mPointValue);
                FLOAT minY = mVisual_MinY/(py/mPointValue);
                
                if(maxY>minY)
                {
                    mVisual_MinY = minY;
                    mVisual_MaxY = maxY;
                    mPointValue = [self computeYRealValueFromYPixel:p.y];
                }
            }
        } else
            mScaleReset = YES;
        
        [self scaleHasChanged];
        [self updateYAxisScroller];
        
        mOldPoint = p;
        
        return YES;
    }
}

- (void)handleMouseInXAxisRect:(NSEvent*)event first:(BOOL)first
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    unsigned int flags = [event modifierFlags];
    
    if(first)
    {
        mOldPoint = p;
        mPointValue = [self computeXRealValueFromXPixel:p.x];
    }
    
    if([self handleXAxisResetZeroLocation:p modifiers:flags first:first]) return;
    if([self handleXAxisOffsetLocation:p modifiers:flags first:first]) return;
    if([self handleXAxisScaleLimitLocation:p modifiers:flags first:first]) return;
    if([self handleXAxisScaleLocation:p modifiers:flags first:first]) return;
}

- (void)handleMouseInYAxisRect:(NSEvent*)event first:(BOOL)first
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    unsigned int flags = [event modifierFlags];
    
    if(first)
    {
        mOldPoint = p;
        mPointValue = [self computeYRealValueFromYPixel:p.y];
    }
    
    if([self handleYAxisResetZeroLocation:p modifiers:flags first:first]) return;
    if([self handleYAxisOffsetLocation:p modifiers:flags first:first]) return;
    if([self handleYAxisScaleLimitLocation:p modifiers:flags first:first]) return;
    if([self handleYAxisScaleLocation:p modifiers:flags first:first]) return;
}

- (BOOL)handleMouse:(NSEvent*)event firstPoint:(NSPoint)firstPt first:(BOOL)first
{
    BOOL stop = FALSE;
    
    if(NSPointInRect(firstPt, [self drawableRect]))
        [self handleMouseInDrawableRect:event first:first];
    else if(NSPointInRect(firstPt, [self xAxisRect]))
        [self handleMouseInXAxisRect:event first:first];
    else if(NSPointInRect(firstPt, [self yAxisRect]))
        [self handleMouseInYAxisRect:event first:first];
    else if(NSPointInRect(firstPt, [self titleRect]))
    {
        if([[NSDate date] timeIntervalSinceDate:mDragAndDropDate]>=0.5)
        {
            [self beginDragOperation:event];
            stop = YES;
        }
    }
    
    return stop;
}

- (void)moveCursorOfDeltaX:(FLOAT)delta
{
    FLOAT cursorX = [self xCursorPosition]+delta;
    [self setCursorPositionX:cursorX positionY:[self yCursorPosition]];
    [self cursorHasChanged];
    [self setNeedsDisplay:YES];
}

- (void)moveCursorOfDeltaY:(FLOAT)delta
{
    FLOAT cursorY = [self yCursorPosition]+delta;
    [self setCursorPositionX:[self xCursorPosition] positionY:cursorY];
    [self cursorHasChanged];
    [self setNeedsDisplay:YES];
}

- (void)moveCursorToStart
{
    [self setCursorPositionX:[self xAxisVisualRangeFrom] positionY:[self yCursorPosition]];
    [self cursorHasChanged];
    [self setNeedsDisplay:YES];
}

- (void)moveCursorToEnd
{
    [self setCursorPositionX:[self xAxisVisualRangeTo] positionY:[self yCursorPosition]];
    [self cursorHasChanged];
    [self setNeedsDisplay:YES];
}

- (void)xAxisScrollerAction:(id)sender
{
    float range = mVisual_MaxX-mVisual_MinX;
    switch([sender hitPart]) {
        case NSScrollerKnob:
        case NSScrollerKnobSlot:
        {
            float delta = (mMaxX-mMinX)-range;
            float p = [sender floatValue]*delta;
            
            mVisual_MinX = mMinX+p;
            mVisual_MaxX = mVisual_MinX+range;
            break;
        }
        case NSScrollerDecrementLine:
            mVisual_MinX -= range*0.1;
            mVisual_MaxX -= range*0.1;
            [self updateXAxisScroller];
            break;
        case NSScrollerDecrementPage:
            mVisual_MinX -= range*0.5;
            mVisual_MaxX -= range*0.5;
            [self updateXAxisScroller];
            break;
        case NSScrollerIncrementLine:
            mVisual_MinX += range*0.1;
            mVisual_MaxX += range*0.1;
            [self updateXAxisScroller];
            break;
        case NSScrollerIncrementPage:
            mVisual_MinX += range*0.5;
            mVisual_MaxX += range*0.5;
            [self updateXAxisScroller];
            break;
        case NSScrollerNoPart:
            return;
            break;
    }
    [self scaleHasChanged];
}

- (void)yAxisScrollerAction:(id)sender
{
    float range = mVisual_MaxY-mVisual_MinY;
    switch([sender hitPart]) {
        case NSScrollerKnob:
        case NSScrollerKnobSlot:
        {
            float delta = (mMaxY-mMinY)-range;
            float p = (1-[sender floatValue])*delta;
            
            mVisual_MinY = mMinY+p;
            mVisual_MaxY = mVisual_MinY+range;
            break;
        }
        case NSScrollerDecrementLine:
            mVisual_MinY += range*0.1;
            mVisual_MaxY += range*0.1;
            [self updateYAxisScroller];
            break;
        case NSScrollerDecrementPage:
            mVisual_MinY += range*0.5;
            mVisual_MaxY += range*0.5;
            [self updateYAxisScroller];
            break;
        case NSScrollerIncrementLine:
            mVisual_MinY -= range*0.1;
            mVisual_MaxY -= range*0.1;
            [self updateYAxisScroller];
            break;
        case NSScrollerIncrementPage:
            mVisual_MinY -= range*0.5;
            mVisual_MaxY -= range*0.5;
            [self updateYAxisScroller];
            break;
        case NSScrollerNoPart:
            return;
            break;
    }
    [self scaleHasChanged];
}

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
    NSString *chars = [event charactersIgnoringModifiers];
    unsigned int flags = [event modifierFlags];
    
    if((flags & NSCommandKeyMask) == 0)
        return NO;
    
    if([chars intValue]>=0 && [chars intValue]<=9 && [mDelegate respondsToSelector:@selector(performInspectorKeyEquivalent:)]) {
        [mDelegate performSelector:@selector(performInspectorKeyEquivalent:) withObject:event];
        return NO;
    }
    return NO;
}

- (void)keyDown:(NSEvent*)event
{
    NSString *chars = [event charactersIgnoringModifiers];
    unsigned int flags = [event modifierFlags];
    unsigned int c = [chars characterAtIndex:0];
    
    FLOAT incr = 0;
    
    if(c == NSRightArrowFunctionKey || c == NSLeftArrowFunctionKey)
        incr = ([self xAxisVisualRangeTo]-[self xAxisVisualRangeFrom])/40;
    else if(c == NSUpArrowFunctionKey || c == NSDownArrowFunctionKey)
        incr = ([self yAxisVisualRangeTo]-[self yAxisVisualRangeFrom])/40;
    
    if((flags & NSShiftKeyMask)!=0)
        incr *= 1;
    else if((flags & NSAlternateKeyMask)!=0)
        incr /= 10;
    else
        incr /= 20;
    
    switch(c) {
        case 32:
            if(![self setPlayerState:!mPlayerIsRunning withSelection:(flags & NSAlternateKeyMask)!=0]
               && [mDelegate respondsToSelector:@selector(viewKeyDown:)])
                [mDelegate performSelector:@selector(viewKeyDown:) withObject:event];
            break;
        case 'c':	// Show/hide cursor
            mCursorChannel++;
            if(mCursorChannel == STEREO_CHANNEL)
                [self setAllowsCursor:NO];
            else if(mCursorChannel > STEREO_CHANNEL)
            {
                [self setAllowsCursor:YES];
                mCursorChannel = LEFT_CHANNEL;
            }
            [self moveCursorOfDeltaX:0];
            [self setNeedsDisplay:YES];
            break;
        case 'h':	// Show/hide harmonic cursor
            mCursorHarmonicState++;
            switch(mCursorHarmonicState) {
                case 1: // Show
                    [self setShowCursorHarmonic:YES];
                    break;
                case 2: // Show (no label)
                    [self setShowCursorHarmonic:YES];
                    break;
                case 3: // Hide
                    [self setShowCursorHarmonic:NO];
                    mCursorHarmonicState = 0;
                    break;
                default:
                    mCursorHarmonicState = 0;
            }
            [self setNeedsDisplay:YES];
            break;
        case 't':	// Show/hide trigger cursor
            [self setShowTriggerCursor:![self showTriggerCursor]];
            [self setNeedsDisplay:YES];
            break;
        case 'p':	// Play current frequency
            if([mDataSource kind] != KIND_AMPLITUDE)
                [mAudioSynth toggle];
            break;
            
        case '+': {
            float width = [self lineWidth];
            width++;
            if(width>10)
                width = 10;
            [self setLineWidth:width];
            break;
        }
            
        case '-': {
            float width = [self lineWidth];
            width--;
            if(width<0)
                width = 0;
            [self setLineWidth:width];
            break;
        }
            
        case NSRightArrowFunctionKey:
            [self moveCursorOfDeltaX:incr];
            break;
        case NSLeftArrowFunctionKey:
            [self moveCursorOfDeltaX:-incr];
            break;
        case NSUpArrowFunctionKey:
            if(mViewType == VIEW_3D)
                [self moveCursorOfDeltaY:incr];
            else
                [self moveCursorToStart];
            break;
            
        case NSHomeFunctionKey:
        case NSBeginFunctionKey:
            [self moveCursorToStart];
            break;
        case NSDownArrowFunctionKey:
            if(mViewType == VIEW_3D)
                [self moveCursorOfDeltaY:-incr];
            else
                [self moveCursorToEnd];
            break;
            
        case NSEndFunctionKey:
            [self moveCursorToEnd];
            break;
            
        default:
            [super keyDown:event];
            break;
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL keepOn = YES;
    NSPoint firstPt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    keepOn = ![self handleMouse:theEvent firstPoint:firstPt first:YES];
    [self setNeedsDisplay:YES];
    
    mDragAndDropDate = [[NSDate date] retain];
    mDragAndDropPoint = firstPt;
    mDragAndDropEvent = theEvent;
    
    while (keepOn) {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                    NSLeftMouseDraggedMask];
        
        switch ([theEvent type]) {
            case NSLeftMouseDragged:
                keepOn = ![self handleMouse:theEvent firstPoint:firstPt first:NO];
                [self setNeedsDisplay:YES];
                break;
            case NSLeftMouseUp:
                if(!mIsSelected)
                    [self setSelect:YES];
                keepOn = NO;
                break;
            default:
                /* Ignore any other kind of event. */
                break;
        }
    }
    
    [mDragAndDropDate release];
    mDragAndDropDate = NULL;
    
    return;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    // Submenu for copy to clipboard
    
    NSMenu *copyToClipboardMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Copy To Clipboard", NULL)];
    [copyToClipboardMenu addItemWithTitle:NSLocalizedString(@"As Image", NULL)
                                   action:@selector(cmCopyToClipboardAsImage:) keyEquivalent:@""];
    [copyToClipboardMenu addItemWithTitle:NSLocalizedString(@"As PDF", NULL)
                                   action:@selector(cmCopyToClipboardAsPDF:) keyEquivalent:@""];
    [copyToClipboardMenu addItemWithTitle:NSLocalizedString(@"As EPS", NULL)
                                   action:@selector(cmCopyToClipboardAsEPS:) keyEquivalent:@""];
    
    NSMenuItem *copyToClipboardItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy To Clipboard", NULL)
                                                                 action:NULL
                                                          keyEquivalent:@""];
    [copyToClipboardItem autorelease];
    
    // Contextual menu
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"View Menu"];
    [menu addItemWithTitle:NSLocalizedString(@"Print", NULL)
                    action:@selector(cmPrintView:) keyEquivalent:@""];
    
    [menu addItem:copyToClipboardItem];
    [menu setSubmenu:copyToClipboardMenu forItem:copyToClipboardItem];
    [copyToClipboardMenu release];
    
    if([AudioExchange canExportDataAsRawData:mDataSource])
        [menu addItemWithTitle:NSLocalizedString(@"Export As Raw Data", NULL)
                        action:@selector(cmExportRawData:) keyEquivalent:@""];
    if([AudioExchange canExportDataAsAIFF:mDataSource])
        [menu addItemWithTitle:NSLocalizedString(@"Export As AIFF", NULL)
                        action:@selector(cmExportAIFF:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Create audio fingerprint"
                    action:@selector(createFingerPrint:) keyEquivalent:@""];
    
    return [menu autorelease];
}

- (void)cmPrintView:(id)sender
{
    [[AudioPrinter shared] printView:self];
}

- (void)cmCopyToClipboardAsImage:(id)sender
{
    [AudioExchange exportDataToClipboardAsImageFromView:self];
}

- (void)cmCopyToClipboardAsPDF:(id)sender
{
    [AudioExchange exportDataToClipboardAsPDFFromView:self];
}

- (void)cmCopyToClipboardAsEPS:(id)sender
{
    [AudioExchange exportDataToClipboardAsEPSFromView:self];
}

- (void)cmExportRawData:(id)sender
{
    [AudioExchange exportDataAsRawDataFromView:self];
}

- (void)cmExportAIFF:(id)sender
{
    [AudioExchange exportDataAsAIFFFromView:self];
}

- (void)createFingerPrint:(id)sender
{
       [AudioExchange createFingerPrintFromView:self];
    
    NSLog(@"mDataSource:%@",[mDataSource class]);
}

@end
