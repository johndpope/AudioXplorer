//
//  SinglePlugIn.m
//  SinglePlugIn
//
//  Created by bovet on Wed May 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SinglePlugIn.h"

@implementation SinglePlugIn

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
    // This plug-in is based on a single method
    return AXPLUGIN_TYPE_SINGLE;
}

// Returns the method title (used in the AudioXplorer menus)    
- (NSString*)methodTitle
{
    // Use the AXLocalized macro to localize string using
    // the Localizable.strings file
    return AXLocalized(@"SingleReverse");
}

// Returns the method name to be called
- (NSString*)methodName
{
    return @"plugSingleReverse:";
}

// Returns the plug-in about string (used in the about dialog)
- (NSString*)aboutString
{
    return AXLocalized(@"About SingleReverse");
}

// Returns the plug-in version string (used in the about dialog)
- (NSString*)versionString
{
    return @"version 1.0";
}

// Returns the plug-in author(s) string (used in the about dialog)
- (NSString*)authorsString
{
    return @"me";
}

// Returns the plug-in description string (used in the about dialog)
- (NSString*)descriptionString
{
    return AXLocalized(@"This plug-in has been written to show how to write a single method plug-in for AudioXplorer");
}

// This method is called just before the process method (returned by methodName)
// will be called. It allows to perform any necessary setup before processing
// the audio data.
- (BOOL)plugInWillBeCalled
{
    return YES;	// Nothing special to do, so return YES.
                // Return NO to cancel the future call to the process method.
}

// This method, which has been defined by methodName, will be called by AudioXplorer
// after plugInWillBeCalled method has been called.

- (void)plugSingleReverse:(id<AXPlugInParametersProtocol>)sender
{
    // sender is an object containing all necessary parameters
    // (see AXPlugInBaseClass for more information about the protocol)
    
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
