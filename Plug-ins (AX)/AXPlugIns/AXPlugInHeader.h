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

//
//  History:
// 	Version 1.1 (28-May-2003):
//		- removed the base class and use only protocol.
// 	Version 1.0 (14-May-2003):
//		- initial release.

#import <Foundation/Foundation.h>

// Type constants
#define AXPLUGIN_TYPE_SINGLE 0
#define AXPLUGIN_TYPE_MULTIPLE 1

// Version constants
#define AXPLUGIN_AX_VERSION_100 100

// Macro used to get localized string from the plug-ins bundle
#define AXLocalized(string) [[NSBundle bundleForClass:[self class]] localizedStringForKey:string value:NULL table:NULL]

// Protocol of the required method
@protocol AXPlugInRequiredProtocol
- (long)supportAudioXplorerVersion;
- (long)versionID;
- (long)plugInType;
@end

// Protocol for single plug-in type
@protocol AXPlugInSingleProtocol <AXPlugInRequiredProtocol>
- (NSString*)methodTitle;
- (NSString*)methodName;

- (NSString*)aboutString;
- (NSString*)versionString;
- (NSString*)authorsString;
- (NSString*)descriptionString;

- (BOOL)plugInWillBeCalled;
@end

// Protocol for multiple plug-in type
@protocol AXPlugInMultipleProtocol <AXPlugInRequiredProtocol>
- (NSArray*)methodTitles;
- (NSArray*)methodNames;

- (NSString*)aboutStringOfMethod:(NSString*)methodName;
- (NSString*)versionStringOfMethod:(NSString*)methodName;
- (NSString*)authorsStringOfMethod:(NSString*)methodName;
- (NSString*)descriptionStringOfMethod:(NSString*)methodName;

- (BOOL)plugInWillBeCalledWithMethod:(NSString*)methodName;
@end

// Protocol of the parameter provided by AudioXplorer
@protocol AXPlugInParametersProtocol
- (unsigned short)channelCount;
- (float*)dataPointerOfChannel:(unsigned short)channel;
- (unsigned long)dataCountOfChannel:(unsigned short)channel;
- (void)setError:(long)error;
- (void)setCancelled:(BOOL)flag;
- (BOOL)firstTime;
@end
