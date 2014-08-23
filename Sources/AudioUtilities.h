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

#import <AppKit/AppKit.h>
#import "AudioTypes.h"

@class AudioView;

@interface AudioUtilities : NSWindowController {

    // Action progress panel
    
    IBOutlet NSPanel *mActionProgressPanel;
    IBOutlet NSTextField *mActionProgressPrompt;
    IBOutlet NSProgressIndicator *mActionProgressIndicator;     
}
+ (AudioUtilities*)openActionProgressPanelPrompt:(NSString*)prompt parentWindow:(NSWindow*)window;
- (void)openActionProgressPanelAsSheet:(NSWindow*)window prompt:(NSString*)prompt;
- (void)closeActionProgressPanel;
@end

@interface AudioUtilities (Coder)
+ (void*)decodeBufferFromCoder:(NSCoder*)coder;
+ (BOOL)encodeBufferAt:(const void*)ptr size:(long)size coder:(NSCoder*)coder;
@end

@interface AudioUtilities (String)
+ (NSString*)stringWithOSType:(OSType)type;
@end

@interface AudioUtilities (Windows)
+ (float)toolbarHeightForWindow:(NSWindow*)window;
@end

@interface AudioUtilities (Parameters)
+ (void)setFFTSizePopUp:(NSPopUpButton*)pop;
+ (void)selectFFTSizePopUp:(NSPopUpButton*)pop withSize:(ULONG)size;
+ (ULONG)fftSizePopUp:(NSPopUpButton*)pop;
@end

@interface AudioUtilities (Internet)
+ (void)reportBug;
@end
