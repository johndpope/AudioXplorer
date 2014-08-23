//
//  SinglePlugIn.h
//  SinglePlugIn
//
//  Created by bovet on Wed May 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AXPlugInHeader.h"

// NOTICE:
// This plug-in is a single plug-in method (that is, only one method
// is implemented to perform one operation on audio data).
// Look at the MultiplePlugIn project if you want to have multiple method
// within one plug-in.

@interface SinglePlugIn : NSObject <AXPlugInSingleProtocol> {
}

@end
