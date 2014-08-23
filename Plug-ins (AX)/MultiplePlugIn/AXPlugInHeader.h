//
//  AXPlugInProtocols.h
//  AudioXplorer Plug-in Protocols
//
//  History:
// 	Version 1.1 (28-May-2003):
//		- removed the base class and use only protocol.
// 	Version 1.0 (14-May-2003):
//		- initial release.
//
//  Copyright (c) 2003 Arizona. All rights reserved.
//

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
