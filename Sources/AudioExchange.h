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

#import <Cocoa/Cocoa.h>
#import "AudioProtocols.h"
#import "AudioDataAmplitude.h"

@class AudioView;

@interface AudioExchange : NSWindowController {
    NSWindow *mWindow;
    id<DataSourceProtocol> mDataSource;

    // View contextual menu action
    
    AudioView *mAudioView;
    
    FLOAT mFromX, mToX;
    
    // Panel (Export As Image)
    
    int mExportImageResolution;
    
    IBOutlet NSPanel *mExportAsImagePanel;
    IBOutlet NSComboBox *mExportAsImageResolutionComboBox;
    
    // Accessory view for save panel (Export Raw Data)
    
    IBOutlet NSView *mExportRawDataSavePanelView;
    IBOutlet NSPopUpButton *mExportRawDataChannelPopUp;
    IBOutlet NSPopUpButton *mExportRawDataDelimitersPopUp;
    IBOutlet NSButton *mExportRawDataSelectionOnlyButton;

    // Accessory view for save panel (Export AIFF)
    
    IBOutlet NSView *mExportAIFFSavePanelView;
    IBOutlet NSPopUpButton *mExportAIFFChannelPopUp;
    IBOutlet NSButton *mExportAIFFSelectionOnlyButton;
}

- (void)prepareDataRangeWithSelection:(BOOL)selectionOnly;

@end

@interface AudioExchange (ExportToClipboard)
+ (void)exportDataToClipboardAsImageFromView:(AudioView*)view;
- (IBAction)exportAsImageCancel:(id)sender;
- (IBAction)exportAsImageCopy:(id)sender;

+ (void)exportDataToClipboardAsPDFFromView:(AudioView*)view;
+ (void)exportDataToClipboardAsEPSFromView:(AudioView*)view;
@end

@interface AudioExchange (ExportAIFF)
+ (BOOL)canExportDataAsAIFF:(id)data;
+ (void)exportDataAsAIFFFromView:(AudioView*)view;
@end

@interface AudioExchange (ExportRawData)
+ (BOOL)canExportDataAsRawData:(id)data;
+ (void)exportDataAsRawDataFromView:(AudioView*)view;
@end
