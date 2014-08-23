
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

#import "AudioApp.h"
#import "AudioDocument.h"
#import "AudioInspectorController.h"
#import "AudioRTWindowController.h"
#import "AudioDialogPrefs.h"
#import "AudioDialogHelp.h"
#import "AudioUtilities.h"
#import "AudioVersions.h"
#import "AudioTipsPanel.h"
#import "AudioEffectController.h"
#import <ARCheckForUpdates/ARCheckForUpdates.h>

@implementation AudioApp

static NSMutableArray *_staticObjectArray = NULL;

+ (void)initialize
{
    [AudioDialogPrefs initDefaultValues];       
}

- (id)init
{
    if(self = [super init])
    {
        _staticObjectArray = [[NSMutableArray alloc] init];
        //NSSetUncaughtExceptionHandler(AXExceptionHandler); 
    }
    return self;
}

- (void)loadingPanelOpen
{
    mLoadingWindow = [[NSPanel alloc] initWithContentRect:[mLoadingView frame] styleMask:/*NSTexturedBackgroundWindowMask*/NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];

    [mLoadingWindow setFloatingPanel:YES];
    [mLoadingWindow setContentView:mLoadingView];
    [mAXVersionTextField setStringValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [mLoadingPromptTextField setStringValue:NSLocalizedString(@"Initializing...", NULL)];
    [mLoadingProgressIndicator setUsesThreadedAnimation:YES];
    [mLoadingProgressIndicator startAnimation:self];
    [mLoadingWindow setHasShadow:YES];
    [mLoadingWindow flushWindowIfNeeded];
    [mLoadingWindow center];
    [mLoadingWindow orderFront:self];
}

- (void)loadingPanelClose
{
   // [mLoadingProgressIndicator stopAnimation:self];
    [mLoadingWindow close];
}

- (void)loadingPanelDisplay:(NSString*)display
{
    [mLoadingPromptTextField setStringValue:display];
    [mLoadingPromptTextField displayIfNeeded];
}

- (void)initVersionChecker
{
    ARUpdateManager *manager = [ARUpdateManager sharedManager];
    [manager setServerName:@"www.arizona-software.ch"];
    [manager setServerPath:@"/updates/"];
    [manager setLocalPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/Updates/"]];
    [manager setName:@"AudioXplorer"];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    // Open the loading panel
    [self loadingPanelOpen];

    // Create the VersionCheck object and register
    [self loadingPanelDisplay:NSLocalizedString(@"Initializing...", NULL)];
    [self initVersionChecker];

    // Initialize and load the preferences
    [self loadingPanelDisplay:NSLocalizedString(@"Loading Preferences...", NULL)];
    [[AudioDialogPrefs shared] load];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{        
    // Initialize the effect controller
    [self loadingPanelDisplay:NSLocalizedString(@"Loading Effects...", NULL)];
    [[AudioEffectController shared] setEffectsMenu:mEffectsMenu];
    [[AudioEffectController shared] setAboutMenu:mAboutMenu];
    [[AudioEffectController shared] load];

    // Create the inspector window (don't show it now)
    [[AudioInspectorController shared] window];
    
    // Allows color panel to have alpha value
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    [panel setShowsAlpha:YES];

    // Close the loading panel
    [self loadingPanelClose];
        
    // Open Action Panel
    if([[AudioDialogPrefs shared] shouldDisplayOpenActionDialog])
        [NSApp runModalForWindow:mFirstLaunchPanel];

    // Tips Panel    
    [AudioTipsPanel showPanel];

    // Open Action
    switch([[AudioDialogPrefs shared] openAction]) {
        case OPEN_STATIC_WINDOW:
            [NSApp sendAction:@selector(newDocument:) to:NULL from:self];
            break;
        case OPEN_RT_WINDOW:
            [NSApp sendAction:@selector(createRTWindow:) to:NULL from:self];
            break;
        case OPEN_LAST_FILE:
            {
                NSArray *array = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
                if([array count]>0)
                {
                    NSURL *url = [array objectAtIndex:0];
                    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES];
                }
            }
            break;
    }        
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[ARUpdateManager sharedManager] terminate];

    [[AudioDialogPrefs shared] save];
    [[AudioDeviceManager shared] release];
    [_staticObjectArray release];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    return NO;
}

- (IBAction)checkForUpdate:(id)sender
{
    [[ARUpdateManager sharedManager] checkForUpdates:sender];
}

- (IBAction)downloadPlugIns:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.arizona-software.ch/applications/audioxplorer"]];
}

- (IBAction)howToInstallPlugIns:(id)sender
{
    [NSApp runModalForWindow:mHowToInstalPlugInsPanel];
}

- (IBAction)closeHowToInstallPlugInsPanel:(id)sender
{
    [mHowToInstalPlugInsPanel orderOut:self];
    [NSApp endSheet:mHowToInstalPlugInsPanel returnCode:0];
}

- (IBAction)showInspector:(id)sender
{
    [[AudioInspectorController shared] showWindow:sender];
}

- (IBAction)showPrefs:(id)sender
{
    [[AudioDialogPrefs shared] showWindow:sender];
}

- (IBAction)createRTWindow:(id)sender
{
    if([[AudioDeviceManager shared] inputDeviceAvailable] == NO)
        NSRunAlertPanel(NSLocalizedString(@"Unable to open real-time window", NULL), NSLocalizedString(@"No record device detected.", NULL), NSLocalizedString(@"OK", NULL), NULL, NULL, NULL);    
    else
        [[[AudioRTWindowController alloc] init] showWindow:sender];
}

- (IBAction)importSoundFile:(id)sender
{
	AudioDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"AudioXplorer Document" display:YES];
	if(doc) {
		AudioSTWindowController *controller = [doc documentStaticWindow];
		[controller importSoundFile:sender];
	}
}

- (IBAction)showHelp:(id)sender
{
    [[AudioDialogHelp shared] showWindow:self];
}

- (void)aboutEffect:(id)sender
{
    [[AudioEffectController shared] aboutEffect:sender];
}

+ (void)addStaticObject:(id)object
{
    [_staticObjectArray addObject:object];
}

@end

@implementation AudioApp (Registration)

- (IBAction)reportBugsToArizona:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:
        NSLocalizedString(@"http://www.arizona-software.ch/contact/en/", @"")]];
}

@end

@implementation AudioApp (FirstLaunchPanel)

- (IBAction)continueAction:(id)sender
{
    [mFirstLaunchPanel orderOut:self];
    [NSApp endSheet:mFirstLaunchPanel returnCode:0];
    
    SHORT action = [[mOpenActionButtonMatrix selectedCell] tag];
    [[AudioDialogPrefs shared] setOpenAction:action];

    [[AudioDialogPrefs shared] setShouldDisplayOpenActionDialog:NO];
}

@end
