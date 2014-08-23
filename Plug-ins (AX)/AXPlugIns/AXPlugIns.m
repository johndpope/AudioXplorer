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

#import "AXPlugIns.h"
#import "AXPlugInsGainController.h"

@implementation AXPlugIns

// The version of AudioXplorer this plug-ins supports

- (long)supportAudioXplorerVersion
{
    return 100;	// Version 1.00
}

// The version ID number of this plug-ins

- (long)versionID
{
    return 1;
}

- (long)plugInType
{
    return AXPLUGIN_TYPE_MULTIPLE;
}

// An array of all available method title for AudioXplorer

- (NSArray*)methodTitles
{
    return [NSArray arrayWithObjects:AXLocalized(@"Reverse"),
                                    AXLocalized(@"Gain..."),
                                    NULL];
}

// An array of available method name for AudioXplorer

- (NSArray*)methodNames
{
    return [NSArray arrayWithObjects:@"axReverse:",
                                    @"axGain:",
                                    NULL];
}

// The about string

- (NSString*)aboutStringOfMethod:(NSString*)methodName
{
    if([methodName isEqualToString:@"axReverse:"])
        return AXLocalized(@"About Reverse");
    else if([methodName isEqualToString:@"axGain:"])
        return AXLocalized(@"About Gain");
    else
        return @"";
}

// The version string (for human reading)

- (NSString*)versionStringOfMethod:(NSString*)methodName
{
    return @"1.0, (c) 2003 Arizona";
}

// The authors string

- (NSString*)authorsStringOfMethod:(NSString*)methodName
{
    return @"Jean Bovet";
}

// The description string

- (NSString*)descriptionStringOfMethod:(NSString*)methodName
{
    if([methodName isEqualToString:@"axReverse:"])
        return AXLocalized(@"Description Reverse");
    else if([methodName isEqualToString:@"axGain:"])
        return AXLocalized(@"Description Gain");
    else
        return @"";
}

// This method is called before calling the plug-ins method.
// You can display a dialog if the plug-ins method require one or do
// anything to setup your plug-ins method

- (BOOL)plugInWillBeCalledWithMethod:(NSString*)methodName
{
    if([methodName isEqualToString:@"axReverse:"])
        return YES;	// Nothing special required, go on.
    else if([methodName isEqualToString:@"axGain:"])
        return [AXPlugInsGainController askUserForGain:&mGain];	// Ask the user for the gain.
    else
        return NO;	// Unknow method name, cancel.
}

@end

@implementation AXPlugIns (Effects)

// This effect reverse the sound data

- (void)axReverse:(id<AXPlugInParametersProtocol>)sender
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

// This effect apply a gain to the sound data

- (void)axGain:(id<AXPlugInParametersProtocol>)sender
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

@end
