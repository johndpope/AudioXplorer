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

@implementation AudioView (Images)

- (void)invalidateCaches
{
    mLayerBackgroundGridAndAxisCached = NO;
    [self updateXAxisScrollerFrame];
    [self updateYAxisScrollerFrame];
    [self invalidateIcon];
}

- (void)invalidateIcon
{
    [mViewIcon release];
    mViewIcon = NULL;
}

- (NSImage*)imageIconWithName:(BOOL)name size:(NSSize)size
{   
    if(mViewIcon == NULL || NSEqualSizes([mViewIcon size], size) == NO)
    {
        // Create the original image without title and axis
        
        NSSize imageSize = [self viewRect].size;   
        NSRect rect = NSMakeRect(0,0,imageSize.width, imageSize.height);
        NSImage *image = [[NSImage alloc] initWithSize:imageSize];

        [image lockFocus];
        [[NSColor whiteColor] set];
        NSRectFill(rect);
    
        BOOL allowsTitle = [self allowsTitle];
        BOOL allowsXAxis = [self allowsXAxis];
        BOOL allowsYAxis = [self allowsYAxis];
        
        [self setAllowsTitle:NO];
        [self setAllowsXAxis:NO];
        [self setAllowsYAxis:NO];
        
        [self drawRect:rect];
        
        [self setAllowsTitle:allowsTitle];
        [self setAllowsXAxis:allowsXAxis];
        [self setAllowsYAxis:allowsYAxis];
        
        [image unlockFocus];
    
        // Create icon
        
        NSSize iconSize = size;
        imageSize = size;
        imageSize.width -= 10;
        if(name)
            imageSize.height -= 15;
                    
        [mViewIcon release];
        mViewIcon = [[NSImage alloc] initWithSize:iconSize];
        
        rect = NSMakeRect(0, 0, iconSize.width, iconSize.height);
        rect.origin.x += 5;
        rect.size.width -= 10;
        if(name)
        {
            rect.origin.y += 15;
            rect.size.height -= 15;
        }
        
        [mViewIcon lockFocus];
        [[NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:1.0] set];
        NSDrawGroove(rect, rect);
        NSImageRep *rep = [image bestRepresentationForDevice:NULL];
        [rep drawInRect:rect];
        if(name)
        {
            NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:[NSColor blackColor]
                                        forKey:NSForegroundColorAttributeName];
            
            [attributes setObject:[NSFont fontWithName:@"Arial" size:12] forKey:NSFontAttributeName];
            
            NSString *text = [self viewName];
            NSSize textSize = [text sizeWithAttributes:attributes];
            [text drawAtPoint:NSMakePoint(iconSize.width*0.5-textSize.width*0.5,0) withAttributes:attributes];
        }
        [mViewIcon unlockFocus];
        
        [image release];
    }
    
    return mViewIcon;
}

- (NSImage*)imageOfSize:(NSSize)size
{
    size.width = MAX(size.width,10);
    size.height = MAX(size.height,10);

    NSImage *temp = [[NSImage alloc] initWithSize:size];
    NSImage *image = [[NSImage alloc] initWithSize:size];

    NSRect r = NSMakeRect(0,0,size.width, size.height);
    NSRect oldr = [self viewRect];
    
    [temp lockFocus];
    [[NSColor whiteColor] set];
    NSRectFill(r);
    [self setViewRect:r];
    [self drawRect:r];
    [self setViewRect:oldr];
    [temp unlockFocus];

    [image lockFocus];
    [temp dissolveToPoint:NSMakePoint(0,0) fraction:1.0];
    [image unlockFocus];
    
    [temp release];
    
    return [image autorelease];
}

- (NSImage*)imageFraction:(FLOAT)fraction
{
    NSSize size = [self viewRect].size;
    size.width = MAX(size.width,10);
    size.height = MAX(size.height,10);
    NSImage *temp = [[NSImage alloc] initWithSize:size];
    NSImage *image = [[NSImage alloc] initWithSize:size];
    
    [temp lockFocus];
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(0,0,size.width, size.height));
    [self drawRect:NSMakeRect(0,0,size.width, size.height)];
    [temp unlockFocus];

    [image lockFocus];
    [temp dissolveToPoint:NSMakePoint(0,0) fraction:fraction];
    [image unlockFocus];
    
    [temp release];
    
    return [image autorelease];
}

@end
