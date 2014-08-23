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

#import "AudioExchange.h"
#import "AudioConstants.h"
#import "AudioUtilities.h"
#import "AudioDataAmplitude.h"
#import "AudioView.h"
#import "AudioView+Categories.h"
#import "AIFFCodec.h"
#import "AudioDialogPrefs.h"

@implementation AudioExchange

- (id)init
{
    if(self = [super initWithWindowNibName:@"AudioExchange"])
    {
        mWindow = NULL;
        mDataSource = NULL;
        
        [self window];
    }
    return self;
}

- (void)prepareDataRangeWithSelection:(BOOL)selectionOnly
{
    if(selectionOnly && [mAudioView selectionExists])
    {
        mFromX = [mAudioView xAxisSelectionRangeFrom];
        mToX = [mAudioView xAxisSelectionRangeTo];
    } else
    {
        mFromX = [mAudioView xAxisVisualRangeFrom];
        mToX = [mAudioView xAxisVisualRangeTo];
    }
}

@end

@implementation AudioExchange (ExportToClipboard)

- (void)exportAsImageDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode==1)
    {
        NSSize size = [mAudioView viewRect].size;
        size.width *= (float)mExportImageResolution/72;
        size.height *= (float)mExportImageResolution/72;
        NSImage *image = [mAudioView imageOfSize:size];
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
        [pb setData:[image TIFFRepresentation] forType:NSTIFFPboardType];
    }
}

- (void)exportViewToClipboardAsImage:(AudioView*)view
{
    mAudioView = view;
    [NSApp beginSheet:mExportAsImagePanel modalForWindow:[view window]
        modalDelegate:self didEndSelector:@selector(exportAsImageDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

+ (void)exportDataToClipboardAsImageFromView:(AudioView*)view
{
    AudioExchange *exchange = [[AudioExchange alloc] init];
    [exchange exportViewToClipboardAsImage:view];
}

- (IBAction)exportAsImageCancel:(id)sender
{
    [mExportAsImagePanel orderOut:self];
    [NSApp endSheet:mExportAsImagePanel returnCode:0];
}

- (IBAction)exportAsImageCopy:(id)sender
{
    mExportImageResolution = [mExportAsImageResolutionComboBox intValue];
    [mExportAsImagePanel orderOut:self];
    [NSApp endSheet:mExportAsImagePanel returnCode:1];
}

+ (void)exportDataToClipboardAsPDFFromView:(AudioView*)view
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObject:NSPDFPboardType] owner:self];
    [pb setData:[view viewDataAsPDF] forType:NSPDFPboardType];

    NSData *data = [view viewDataAsPDF];
    [pb setData:data forType:NSPDFPboardType];
    
    [data writeToFile:@"/users/bovet/desktop/audiox.pdf" atomically:YES];
}

+ (void)exportDataToClipboardAsEPSFromView:(AudioView*)view
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObject:NSPostScriptPboardType] owner:self];
    
    NSData *data = [view viewDataAsEPS];
    [pb setData:data forType:NSPostScriptPboardType];
    
    [data writeToFile:@"/users/bovet/desktop/audiox.eps" atomically:YES];
}

@end

@implementation AudioExchange (ExportAIFF)

- (ULONG)aiffCodecIndexOffsetOfChannel:(USHORT)channel
{
    return [mDataSource indexOfXValue:mFromX channel:channel];
}

- (FLOAT)aiffCodecValueAtIndex:(ULONG)index channel:(USHORT)channel
{
    FLOAT value = [mDataSource yValueAtIndex:index channel:channel];
    value /= MAX(fabs([mDataSource maxYOfChannel:channel]), fabs([mDataSource minYOfChannel:channel]));
    return value;
}

- (void)exportProblemSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [self autorelease];
}

- (void)exportAIFFFile_:(NSTimer*)timer
{
    AudioUtilities *utils = [[AudioUtilities openActionProgressPanelPrompt:
                                NSLocalizedString(@"Exporting to AIFF file", NULL)
                                parentWindow:mWindow] retain];

    NSString *path = [timer userInfo];

    USHORT channel = [mExportAIFFChannelPopUp indexOfSelectedItem];
    BOOL selectionOnly = [mExportAIFFSelectionOnlyButton state] == NSOnState;
    
    [self prepareDataRangeWithSelection:selectionOnly];
    
    ULONG from = [mDataSource indexOfXValue:mFromX channel:channel==STEREO_CHANNEL?LEFT_CHANNEL:channel];
    ULONG to = [mDataSource indexOfXValue:mToX channel:channel==STEREO_CHANNEL?LEFT_CHANNEL:channel];
    ULONG dataSize;
    if(to>from)
        dataSize = (to-from)*SOUND_DATA_SIZE;
    else
        dataSize = ([mDataSource maxIndex]-from+to)*SOUND_DATA_SIZE;
        
    AIFFCodec *codec = [[AIFFCodec alloc] init];
    [codec setExportDataProvider:self];
	
	#warning pourquoi pas 32 bits ? Paramétrable ?
    [codec setExportSampleSize:16];

    BOOL success = codec != NULL;
    if(codec)
    {
        NSData *data = [codec export32BitsSoundDataChannel:channel size:dataSize];
        [data retain];
        [codec release];
        
        success = [data writeToFile:path atomically:YES];
            
        [data release];
    }

    [utils closeActionProgressPanel];
    [utils release];
    
    if(success == NO)
        NSBeginAlertSheet(NSLocalizedString(@"Unable to export data to file.", NULL), NSLocalizedString(@"OK", NULL), NULL, NULL, mWindow, self, @selector(exportProblemSheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"");
    else
        [self autorelease];
}

- (void)exportAIFFPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode==NSOKButton)
        // Invoke with an NSTimer to let the Open Dialog sheet close
        [NSTimer scheduledTimerWithTimeInterval:0 target:self
                    selector:@selector(exportAIFFFile_:) userInfo:[sheet filename] repeats:NO];
    else
        [self autorelease];
}

+ (BOOL)canExportDataAsAIFF:(id)data
{
    return [data kind] == KIND_AMPLITUDE;
}

- (void)exportDataAsAIFFFromView_:(AudioView*)view
{
    mWindow = [view window];
    mDataSource = [view dataSource];
    mAudioView = view;

    [mExportAIFFChannelPopUp selectItemAtIndex:[mAudioView displayedChannel]];
    [mExportAIFFSelectionOnlyButton setEnabled:[mAudioView selectionExists]];
    [mExportAIFFSelectionOnlyButton setState:[mAudioView selectionExists]?NSOnState:NSOffState];

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:NSLocalizedString(@"Export", NULL)];
    [savePanel setTitle:NSLocalizedString(@"Export", NULL)];
    [savePanel setRequiredFileType:@"aif"];
    [savePanel setAccessoryView:mExportAIFFSavePanelView];
    [savePanel beginSheetForDirectory:NULL file:NULL modalForWindow:mWindow modalDelegate:self didEndSelector:@selector(exportAIFFPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

+ (void)exportDataAsAIFFFromView:(AudioView*)view
{
    AudioExchange *ex = [[AudioExchange alloc] init];
    [ex exportDataAsAIFFFromView_:view];
}

@end

@implementation AudioExchange (ExportRawData)

- (void)exportRawDataFromView:(NSTimer*)timer
{
    AudioUtilities *utils = [[AudioUtilities openActionProgressPanelPrompt:NSLocalizedString(@"Exporting raw data", NULL)
                                parentWindow:mWindow] retain];

    NSString *path = [timer userInfo];

    USHORT channel = [mExportRawDataChannelPopUp indexOfSelectedItem];
    BOOL selectionOnly = [mExportRawDataSelectionOnlyButton state] == NSOnState;
    NSString *delimiter = [[mExportRawDataDelimitersPopUp selectedItem] title];
    
    [self prepareDataRangeWithSelection:selectionOnly];
    
    ULONG from = [mDataSource indexOfXValue:mFromX channel:LEFT_CHANNEL];
    ULONG to = [mDataSource indexOfXValue:mToX channel:LEFT_CHANNEL];

    NSString *rawData = [mDataSource stringOfRawDataFromIndex:from to:to channel:channel delimiter:delimiter];
    
    [rawData writeToFile:path atomically:NO];
    
    [utils closeActionProgressPanel];
    [utils release];
    [self autorelease];
}

- (void)exportRawDataFromView:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode==NSOKButton)
        // Invoke with an NSTimer to let the sheet close
        [NSTimer scheduledTimerWithTimeInterval:0 target:self
                    selector:@selector(exportRawDataFromView:) userInfo:[sheet filename] repeats:NO];
}

- (void)exportDataAsRawDataFromView_:(AudioView*)view
{
    mWindow = [view window];
    mDataSource = [view dataSource];
    mAudioView = view;

    [mExportRawDataChannelPopUp selectItemAtIndex:[mAudioView displayedChannel]];
    [mExportRawDataSelectionOnlyButton setEnabled:[mAudioView selectionExists]];
    [mExportRawDataSelectionOnlyButton setState:[mAudioView selectionExists]?NSOnState:NSOffState];

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:NSLocalizedString(@"Export", NULL)];
    [savePanel setTitle:NSLocalizedString(@"Export", NULL)];
    [savePanel setRequiredFileType:@"txt"];
    [savePanel setAccessoryView:mExportRawDataSavePanelView];
    [savePanel beginSheetForDirectory:NULL file:NULL modalForWindow:mWindow modalDelegate:self
        didEndSelector:@selector(exportRawDataFromView:returnCode:contextInfo:) contextInfo:NULL];
}

+ (BOOL)canExportDataAsRawData:(id)data
{
    if([data respondsToSelector:@selector(supportRawDataExport)])	
        return [data supportRawDataExport];
    else
        return NO;
}

+ (void)exportDataAsRawDataFromView:(AudioView*)view;
{
    AudioExchange *utils = [[AudioExchange alloc] init];
    [utils exportDataAsRawDataFromView_:view];
}

@end