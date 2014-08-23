//
//  GainController.h
//  GainController
//
//  Created by bovet on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

// NOTE: this controller let you display a dialog to the user so he can change
//	 your plug-in parameters.

@interface GainController : NSWindowController {
    IBOutlet NSTextField *mGainTextField;
    unsigned short mLastUnit;
}

+ (BOOL)askUserForGain:(float*)gain;

- (IBAction)gainUnitPopUpAction:(id)sender;
- (IBAction)cancelPanel:(id)sender;
- (IBAction)okPanel:(id)sender;

@end
