//
//  MultiplePlugIn.h
//  MultiplePlugIn
//
//  Created by bovet on Wed May 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AXPlugInHeader.h"

// NOTICE:
// This plug-in is a multiple plug-in method (that is, several methods
// are implemented to perform several operation on audio data).
// Look at the SinglePlugIn project if you want to have only one method
// within one plug-in.

@interface MultiplePlugIn : NSObject <AXPlugInMultipleProtocol> {
    float mGain;
}

@end
