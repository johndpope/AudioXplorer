
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

#import "AudioUtilities.h"
#import "AudioTypes.h"
#import "AudioView.h"

@implementation AudioUtilities

+ (AudioUtilities*)openActionProgressPanelPrompt:(NSString*)prompt parentWindow:(NSWindow*)window
{
    AudioUtilities *utils = [[AudioUtilities alloc] init];
    [utils openActionProgressPanelAsSheet:window prompt:prompt];
    return [utils autorelease];
}

- (id)init
{
    if(self = [super initWithWindowNibName:@"AudioUtilities"])
    {
        [self window];
    }
    return self;
}

- (void)openActionProgressPanelAsSheet:(NSWindow*)window prompt:(NSString*)prompt
{
    [mActionProgressPrompt setStringValue:prompt];
    [mActionProgressIndicator setUsesThreadedAnimation:YES];
    [mActionProgressIndicator startAnimation:self];
    [NSApp beginSheet:mActionProgressPanel modalForWindow:window modalDelegate:self
                    didEndSelector:NULL contextInfo:NULL];
}

- (void)closeActionProgressPanel
{
    [mActionProgressIndicator stopAnimation:self];
    [mActionProgressPanel orderOut:self];
    [NSApp endSheet:mActionProgressPanel returnCode:0];
}

@end

@implementation AudioUtilities (Coder)

+ (void*)decodeBufferFromCoder:(NSCoder*)coder
{
    void *ptr = NULL;
    BOOL hasData = NO;
    [coder decodeValueOfObjCType:@encode(BOOL) at:&hasData];
    if(hasData)
    {
        long size = 0;
        [coder decodeValueOfObjCType:@encode(long) at:&size];
        ptr = (void*)malloc(size);
        [coder decodeArrayOfObjCType:@encode(unsigned char) count:size at:ptr];       
    }
    return ptr;
}

+ (BOOL)encodeBufferAt:(const void*)ptr size:(long)size coder:(NSCoder*)coder
{
    BOOL hasData = ptr != NULL;
    [coder encodeValueOfObjCType:@encode(BOOL) at:&hasData];
    if(hasData)
    {
        [coder encodeValueOfObjCType:@encode(long) at:&size];
        [coder encodeArrayOfObjCType:@encode(unsigned char) count:size at:ptr];
    }
    return YES;
}

@end

@implementation AudioUtilities (String)

+ (NSString*)stringWithOSType:(OSType)type
{
    char *t = (char*)&type;
    return [NSString stringWithFormat:@"%c%c%c%c", t[0], t[1], t[2], t[3]];
}

@end

@implementation AudioUtilities (Windows)

+ (float)toolbarHeightForWindow:(NSWindow*)window
{
    NSToolbar *toolbar;
    float toolbarHeight = 0.0;
    NSRect windowFrame;
    
    toolbar = [window toolbar];
    
    if(toolbar && [toolbar isVisible])
    {
        windowFrame = [NSWindow contentRectForFrameRect:[window frame]
                                styleMask:[window styleMask]];
        toolbarHeight = NSHeight(windowFrame)
                        - NSHeight([[window contentView] frame]);
    }
    
    return toolbarHeight;
}

@end

@implementation AudioUtilities (Parameters)

+ (void)setFFTSizePopUp:(NSPopUpButton*)pop
{
    [pop removeAllItems];

    USHORT index;
    for(index=6; index<20; index++)
    {
        ULONG size = exp2(index);
        [pop addItemWithTitle:[[NSNumber numberWithInt:size] stringValue]];
    }
}

+ (void)selectFFTSizePopUp:(NSPopUpButton*)pop withSize:(ULONG)size
{
    SHORT index = log(size)/log(2)-6;
    [pop selectItemAtIndex:index];
}

+ (ULONG)fftSizePopUp:(NSPopUpButton*)pop
{
    return exp2([pop indexOfSelectedItem]+6);
}

@end

@implementation AudioUtilities (Internet)

+ (void)reportBug
{
    NSURL *url = [NSURL URLWithString:NSLocalizedString(@"mailto:audioxplorer@arizona-software.ch?subject=Comments%20about%20AudioXplorer", NULL)];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
