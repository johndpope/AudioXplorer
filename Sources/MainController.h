//
//  MainController.h
//  ProVoc
//
//  Created by bovet on Sat Feb 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface MainController : NSWindowController {
    IBOutlet NSTableView *mTableView;
    IBOutlet NSPopUpButton *mMotherL;
    IBOutlet NSPopUpButton *mOtherL;
}

- (IBAction)popUpAction:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)test:(id)sender;

@end
