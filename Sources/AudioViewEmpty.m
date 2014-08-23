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

#import "AudioViewEmpty.h"

#import "AudioConstants.h"
#import "AudioNotifications.h"
#import "AudioView+Categories.h"

@implementation AudioViewEmpty

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        mIsTarget = NO;
        [self registerForDraggedTypes:[NSArray arrayWithObjects:AudioViewPtrPboardType, AudioDataPboardType, NULL]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {

    [[NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1.0] set];
    NSDrawGroove([self bounds], [self bounds]);

    NSString *message = NSLocalizedString(@"Generate or record a sound.\rDrag and drop any audio view here.", NULL);
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:[NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1.0] forKey:NSForegroundColorAttributeName];
    [attributes setObject:[NSFont fontWithName:@"Lucida Grande" size:22] forKey:NSFontAttributeName];
            
    [message drawInRect:NSInsetRect([self bounds], 10, 10) withAttributes:attributes];
    
    if(mIsTarget)
    {
        [[NSColor redColor] set];
        NSFrameRect(NSInsetRect([self bounds], 1, 1));
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
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

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    mIsTarget = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;

    mIsTarget = NO;
    [self setNeedsDisplay:YES];

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    return [AudioView performDrag:pboard fromView:self];
}

- (unsigned long)viewID
{
    return EMPTY_VIEW_ID;
}

@end
