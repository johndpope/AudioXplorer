//
//  MultiplePlugIn.m
//  MultiplePlugIn
//
//  Created by bovet on Wed May 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MultiplePlugIn.h"
#import "GainController.h"

@implementation MultiplePlugIn

// Tells AudioXplorer which version this plug-ins supports
- (long)supportAudioXplorerVersion
{
    return AXPLUGIN_AX_VERSION_100;	// Supports AudioXplorer 1.0.0
}

// The plug-in version
- (long)versionID
{
    return 1;
}

// The plug-in type (see AXPlugInBaseClass.h for more information)
- (long)plugInType
{
    // This plug-in contains multiple methods
    return AXPLUGIN_TYPE_MULTIPLE;
}

// Returns an array of method titles (used in the AudioXplorer menus)    
- (NSArray*)methodTitles
{
    // Use the AXLocalized macro to localize string using
    // the Localizable.strings file
    return [NSArray arrayWithObjects:AXLocalized(@"MultipleGain..."),
                                    AXLocalized(@"MultipleDelay"),
                                    NULL];
}

// Returns an array of method names to be called
- (NSArray*)methodNames
{
    return [NSArray arrayWithObjects:@"plugMultipleGain:",
                                    @"plugMultipleDelay:",
                                    NULL];
}

// Returns the plug-in about string (used in the about dialog)
// As you may notice, the method name is passed as parameter in order
// to customize the string depending on the method.
- (NSString*)aboutStringOfMethod:(NSString*)method
{
    if([method isEqualToString:@"plugMultipleGain:"])
        return AXLocalized(@"About MultipleGain");
    else if([method isEqualToString:@"plugMultipleDelay:"])
        return AXLocalized(@"About MultipleDelay");
    else
        return NULL;
}

// Returns the plug-in version string (used in the about dialog)
- (NSString*)versionStringOfMethod:(NSString*)method
{
    return @"version 1.0";
}

// Returns the plug-in author(s) string (used in the about dialog)
- (NSString*)authorsStringOfMethod:(NSString*)method
{
    return @"me";
}

// Returns the plug-in description string (used in the about dialog)
- (NSString*)descriptionStringOfMethod:(NSString*)method
{
    if([method isEqualToString:@"plugMultipleGain:"])
        return AXLocalized(@"This plug-in method changes the gain of the audio data. It is part of the MultiplePlugIn project.");
    else if([method isEqualToString:@"plugMultipleDelay:"])
        return AXLocalized(@"This plug-in method delays the audio data. It is part of the MultiplePlugIn project.");
    else
        return NULL;
}

// This method is called before calling the plug-ins method.
// You can display a dialog if the plug-ins method require one or do
// anything to setup your plug-ins method
- (BOOL)plugInWillBeCalledWithMethod:(NSString*)methodName
{
    if([methodName isEqualToString:@"plugMultipleGain:"])
        // Ask the user for the gain (call the GainController class)
        return [GainController askUserForGain:&mGain];
    else if([methodName isEqualToString:@"plugMultipleDelay:"])
        return YES;	// Nothing special required, go on.
    else
        return NO;	// Unknow method name, cancel.
}

@end

// This category is used to group visually the process methods
@implementation MultiplePlugIn (Effects)

// This effect changes the gain of the sound data
- (void)plugMultipleGain:(id<AXPlugInParametersProtocol>)sender
{
    unsigned short channel;
    for(channel=0; channel<[sender channelCount]; channel++)
    {
        // Get the pointer to the sound data
        float* dataPtr = [sender dataPointerOfChannel:channel];
        unsigned long dataIndexCount = [sender dataCountOfChannel:channel];
        
        // Perform the operation
        unsigned long index;
        for(index=0; index<dataIndexCount; index++)
            dataPtr[index] *= mGain;
    }
    
    [sender setError:0];
}

// This effect delays the sound data
- (void)plugMultipleDelay:(id<AXPlugInParametersProtocol>)sender
{
    // Reverse every channel available
    unsigned short channel;
    for(channel=0; channel<[sender channelCount]; channel++)
    {
        // Get the sound data pointer
        float* dataPtr = [sender dataPointerOfChannel:channel];
        unsigned long dataIndexCount = [sender dataCountOfChannel:channel];
        
        // Perform the reverse operation
        unsigned long index;
        for(index=0; index<dataIndexCount*0.5; index++)
        {
            float temp = dataPtr[index];
            unsigned long swapIndex = MAX(0, (dataIndexCount-1)-index);
            swapIndex = MIN(dataIndexCount-1, swapIndex);
            dataPtr[index] = dataPtr[swapIndex];
            dataPtr[swapIndex] = temp;
        }
    }
    
    [sender setError:0];
}

@end
