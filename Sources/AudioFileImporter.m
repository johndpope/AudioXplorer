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

#import "AudioFileImporter.h"
#import "AudioDialogPrefs.h"
#import "AIFFCodec.h"
#import "ARFileUtilities.h"
#import <QuickTime/QuickTime.h>

@implementation AudioFileImporter

- (id)init
{
    if(self = [super init])
    {
        mProgressPanel = NULL;
        mSourceFile = NULL;
        mTempFile = NULL;
        mAmplitude = NULL;
        mErrorMessage = [[NSMutableString string] retain];
        mDelegate = NULL;
        mCancelFlag = NO;
    }
    return self;
}

- (void)dealloc
{
    [mSourceFile release];
    [mTempFile release];
    [mAmplitude release];
    [mErrorMessage release];
    [super dealloc];
}

- (NSString*)errorMessage
{
    return mErrorMessage;
}

- (NSString*)sourceFile
{
    return mSourceFile;
}

// Callback when QuickTime is doing something
OSErr AudioExchangeMovieProgressProc (
     Movie    theMovie,
     short    message,
     short    whatOperation,
     Fixed    percentDone,
     long     refcon )
{
    AudioFileImporter *importer = (AudioFileImporter*)refcon;
    ARProgressPanel *progPanel = importer->mProgressPanel;
    
    [progPanel setDeterminate:YES];
    if(message = movieProgressUpdatePercent)
        [progPanel setProgressValue:Fix2X(percentDone)];
    [progPanel setProgressPrompt:NSLocalizedString(@"Converting...", NULL)];
    
    if(importer->mCancelFlag)
        return 1; // Non-zero value to cancel the operation
    else
        return noErr;
}

// Called when an error occurs
- (void)cancelConvertWithError:(NSString*)error
{
    [self performSelectorOnMainThread:@selector(convertCancelledWithError:)
                            withObject:error
                            waitUntilDone:NO];
}

/*ComponentResult GetExportSettings(Movie inMovie, Track inTrack,
     QTAtomContainer *outSettings)
{
    Component c = 0;
    ComponentInstance theExporter = 0;
    ComponentDescription cd = { MovieExportType,
                                kQTFileTypeAIFF,
                                StandardCompressionSubTypeSound,
                                hasMovieExportUserInterface,
                                hasMovieExportUserInterface };
    ComponentResult err = invalidComponentID;
    Boolean ignore;

    c = FindNextComponent(0, &cd);
    if (c == 0) goto bail;

    err = OpenAComponent(c, &theExporter);
    if (err || theExporter == 0) goto bail;

    err = MovieExportDoUserDialog(theExporter, inMovie,
         inTrack, 0,
      GetTrackDuration(inTrack), &ignore);
    if (err) goto bail;

    err = MovieExportGetSettingsAsAtomContainer(theExporter,
         outSettings);

bail:
    if (theExporter)
        CloseComponent(theExporter);

    return err;
}*/

// Convert any file to an AIFF file
- (BOOL)convertUsingQuickTimeStep1:(id)object
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Initialize QuickTime
    OSErr err = noErr;
    FSSpec sourceSpec;
    short sourceRefNum;

    err = EnterMovies();
    if(err != noErr) {
        [self cancelConvertWithError:[NSString stringWithFormat:@"EnterMovies() error %d", err]];
        goto error;
    }
    
    // Make the FSSpec
    err = [ARFileUtilities makeFSSpec:&sourceSpec fromPath:mSourceFile];
    if(err != noErr) {
        [self cancelConvertWithError:[NSString stringWithFormat:@"makeFSSpec error %d", err]];
        goto error;
    }
    
    // Open the file
    err = OpenMovieFile(&sourceSpec, &sourceRefNum, fsRdPerm);
    if(err != noErr) {
        [self cancelConvertWithError:[NSString stringWithFormat:@"OpenMovieFile() error %", err]];
        goto error;
    }

    // Create the movie
    Movie theMovie = nil;

    err = NewMovieFromFile(&theMovie, sourceRefNum, 0, nil, 0, nil);
    if(err != noErr) {
        [self cancelConvertWithError:[NSString stringWithFormat:@"NewMovieFromFile() error %d", err]];
        goto error;
    }

    CloseMovieFile(sourceRefNum);
             
    // Create the target file
    FSSpec targetSpec;
    
    err = [ARFileUtilities makeNewFSSpec:&targetSpec fromPath:mTempFile];
    if(err != noErr) {
        [self cancelConvertWithError:[NSString stringWithFormat:@"makeFSSpec error %d", err]];
        goto error;
    }

    // Convert and save to an AIFF file
    MovieProgressUPP upp = NewMovieProgressUPP(AudioExchangeMovieProgressProc);

    SetMovieProgressProc(theMovie, upp, (long)self);
    
    err = ConvertMovieToFile( theMovie,               // the movie to convert
                        nil,                   // all tracks in the movie
                        &targetSpec,        // the output file
                        kQTFileTypeAIFF,        // the output file type
                        FOUR_CHAR_CODE('TVOD'), // the output file creator
                        smSystemScript,         // the script
                        nil,                   // no resource ID 
                                                //   to be returned
                        0L,                     // no flags
                        nil);                  // no specific component

    if(err != noErr && mCancelFlag == NO) {
        [self cancelConvertWithError:[NSString stringWithFormat:@"ConvertMovieToFile() error %d", err]];
        goto error;
    }

    // Dispose and clean QuickTime
    DisposeMovie(theMovie);
    ExitMovies();

    if(mCancelFlag == NO)
    {
        // Perform the last step method on the main thread
        [self performSelectorOnMainThread:@selector(convertUsingQuickTimeStep1Finished:)
                                withObject:NULL
                                waitUntilDone:NO];
    } else {
        [self performSelectorOnMainThread:@selector(convertCancelled)
                                withObject:NULL
                                waitUntilDone:NO];
    }
    
    // Release the auto-release pool for the current thread
   [pool release];    
    return YES;

error:  [pool release];
    return NO;
}

// First step is executed in another thread
- (BOOL)importAnyAudioFileUsingQuickTime_Step1
{
    [mProgressPanel setCancelButtonEnabled:YES];
    [NSThread detachNewThreadSelector:@selector(convertUsingQuickTimeStep1:) toTarget:self withObject:self];
    return YES;
}

// Second step executed in the main thread
- (BOOL)importAnyAudioFileUsingQuickTime_Step2
{
    [mProgressPanel setProgressPrompt:NSLocalizedString(@"Reading the converted data...", NULL)];
    [mProgressPanel setDeterminate:NO];
    [mProgressPanel setCancelButtonEnabled:NO];
    
    AIFFCodec *codec = [[AIFFCodec alloc] initWithContentsOfFile:mTempFile errorMessage:mErrorMessage];
    BOOL success = codec != NULL;
    if(success)
    {
        ULONG bufferSize = 0;
        AIFF32BitsBufferPtr leftBuffer = NULL;
        AIFF32BitsBufferPtr rightBuffer = NULL;
        success = [codec extractSoundData32BitsAnd44KhzOfSize:&bufferSize
                        leftBuffer:&leftBuffer rightBuffer:&rightBuffer
                        scaleFactor:[[AudioDialogPrefs shared] fullScaleVoltage]*0.5];
        [codec release];
    
        if(success)
        {
            mAmplitude = [[AudioDataAmplitude alloc] init];
            
            if(leftBuffer)
                [mAmplitude setDataBuffer:leftBuffer size:bufferSize channel:LEFT_CHANNEL];
            if(rightBuffer)
                [mAmplitude setDataBuffer:rightBuffer size:bufferSize channel:RIGHT_CHANNEL];            
        }
    } else
        NSLog(@"*** importAnyAudioFileUsingQuickTime_Step2: coder is NULL");
    
    [self convertUsingQuickTimeStep2Finished:self];
    
    return YES;
}

// Called when the step 1 is completed (sent from the converter thread)
- (void)convertUsingQuickTimeStep1Finished:(id)object
{
    // Read the AIFF file into an AudioDataAmplitude
    [self importAnyAudioFileUsingQuickTime_Step2];
}

// Called when the step 2 is completed
- (void)convertUsingQuickTimeStep2Finished:(id)object
{
    // Delete the temp file
    [[NSFileManager defaultManager] removeFileAtPath:mTempFile handler:NULL];

    // Close the progress panel
    [mProgressPanel close];
    [mProgressPanel release];
    
    // Call the endSelector to return the amplitude
    [mDelegate performSelector:@selector(amplitudeFromAnyFileCompletedWithAmplitude:) withObject:mAmplitude];
}

// Called when the import operation is cancelled due to an error
- (void)convertCancelledWithError:(NSString*)error
{
    [mProgressPanel close];
    [mProgressPanel release];

    NSRunAlertPanel(NSLocalizedString(@"Unable to import the file", NULL), error, NSLocalizedString(@"OK", NULL), NULL, NULL, NULL);    
}

// Called when the import operation is cancelled
- (void)convertCancelled
{
    [mProgressPanel close];
    [mProgressPanel release];
}

// Called when an file conversion is needed
- (BOOL)amplitudeFromAnyFile:(NSString*)sourceFile delegate:(id)delegate parentWindow:(NSWindow*)window
{
    // Set converter variable
    mSourceFile = [sourceFile retain];
    mTempFile = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"audioxplorer.aif"] retain];
    mDelegate = delegate;
    
    // Open converter progress panel
    mProgressPanel = [[ARProgressPanel progressPanelWithParentWindow:window delegate:self] retain];
    
    [mProgressPanel setProgressPrompt:NSLocalizedString(@"Preparing...", NULL)];
    [mProgressPanel setProgressValue:0.0];
    [mProgressPanel setDeterminate:NO];
    [mProgressPanel open];
    
    // Convert the file to an AIFF file using QuickTime
    return [self importAnyAudioFileUsingQuickTime_Step1];
}

// Called if the user cancels the progress panel
- (void)progressPanelCancelled:(id)progressPanel
{
    mCancelFlag = YES;
}

@end
