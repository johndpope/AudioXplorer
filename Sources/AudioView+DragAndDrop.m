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
#import "AudioNotifications.h"

@implementation AudioView (DragAndDrop)

- (NSPoint)imageLocation
{
    return NSMakePoint(0, 0);
}

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if([theEvent type] == NSLeftMouseDown && NSPointInRect(pt, [self titleRect]))
        return YES;
    else
        return NO;
}

- (void)beginDragOperation:(NSEvent*)theEvent
{
    NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSSize dragOffset = NSMakeSize(pt.x-mDragAndDropPoint.x, pt.y-mDragAndDropPoint.y);
    	
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:NSTIFFPboardType, AudioDataPboardType,
                            AudioViewFeaturesPboardType, AudioViewPtrPboardType, NULL] owner:self];
    [pboard setData:[[self imageFraction:1.0] TIFFRepresentation] forType:NSTIFFPboardType];
    [pboard setData:[NSArchiver archivedDataWithRootObject:[NSNumber numberWithLong:(long)self]] forType:AudioViewPtrPboardType];
	
    [self dragImage:[self imageFraction:0.5] at:[self imageLocation] offset:dragOffset 
        event:mDragAndDropEvent pasteboard:pboard source:self slideBack:YES];
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
    if([type isEqualToString:AudioDataPboardType])
        [sender setData:[NSArchiver archivedDataWithRootObject:mDataSource] forType:AudioDataPboardType];
    else if([type isEqualToString:AudioViewFeaturesPboardType])
        [sender setData:[NSArchiver archivedDataWithRootObject:mFeatures] forType:AudioViewFeaturesPboardType];
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    [self setNeedsDisplay:YES];

    if ([[pboard types] containsObject:AudioViewPtrPboardType] ||
    [[pboard types] containsObject:AudioDataPboardType])
    {
        mIsTarget = YES;
        return NSDragOperationMove;
    } else
    {
        mIsTarget = NO;
        return NSDragOperationNone;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    mIsTarget = NO;
    [self setNeedsDisplay:YES];
}

+ (BOOL)performDrag:(NSPasteboard*)pboard fromView:(NSView*)view
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSNumber *targetViewPtr = [NSNumber numberWithLong:(long)view];

    [dictionary setObject:[view window] forKey:@"Window"];
    
    BOOL result = NO;
    
    if ([[pboard types] containsObject:AudioViewPtrPboardType])
    {
        id sourceViewPtr = [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:AudioViewPtrPboardType]];

        [dictionary setObject:sourceViewPtr forKey:@"SourceViewPtr"];
        [dictionary setObject:targetViewPtr forKey:@"TargetViewPtr"];
                
        result = YES;
    }
    
    if ([[pboard types] containsObject:AudioDataPboardType])
    {
        id sourceDataObject = [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:AudioDataPboardType]];

        if([sourceDataObject respondsToSelector:@selector(optimize)])
            [sourceDataObject performSelector:@selector(optimize)];
            
        [dictionary setObject:sourceDataObject forKey:@"SourceDataObject"];
        [dictionary setObject:targetViewPtr forKey:@"TargetViewPtr"];

        if ([[pboard types] containsObject:AudioViewFeaturesPboardType] )
        {
            id features = [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:AudioViewFeaturesPboardType]];
            [dictionary setObject:features forKey:@"ViewFeaturesObject"];
        }
        
        result = YES;
    } 
    
    if(result)
        [[NSNotificationCenter defaultCenter] postNotificationName:AudioViewShouldBeReplacedNotification object:dictionary];

    return result;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;

    mIsTarget = NO;
    [self setNeedsDisplay:YES];
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    return [AudioView performDrag:pboard fromView:self];
}

@end
