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

#import "AudioDialogHelp.h"
#import "AudioApp.h"

@implementation AudioDialogHelp

+ (AudioDialogHelp*)shared
{
    static AudioDialogHelp *_sharedAudioDialogHelp = NULL;
    
    if(!_sharedAudioDialogHelp)
    {
        _sharedAudioDialogHelp = [[AudioDialogHelp alloc] init];
        [AudioApp addStaticObject:_sharedAudioDialogHelp];
    }
    
    return _sharedAudioDialogHelp;
}

- (id)init
{
    if(self = [self initWithWindowNibName:@"Help"])
    {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *path = [mainBundle pathForResource:@"HelpFiles" ofType:@"xml" inDirectory:@""];
        NSArray *array = [NSArray arrayWithContentsOfFile:path];
        
        mTopicTitleArray = [[NSMutableArray alloc] init];
        mTopicPathArray = [[NSMutableArray alloc] init];
        
        SHORT index;
        for(index=0; index<[array count]; index++)
        {
            [mTopicTitleArray addObject:[array objectAtIndex:index++]];
            [mTopicPathArray addObject:[array objectAtIndex:index]];
        }
    }
    return self;
}

- (void)dealloc
{
    [mTopicTitleArray release];
    [mTopicPathArray release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [mTopicPopUpButton removeAllItems];
    [mTopicPopUpButton addItemsWithTitles:mTopicTitleArray];
    
    [self changeTopic:0];    
}

- (void)changeTopic:(SHORT)index
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[mTopicPathArray objectAtIndex:index] ofType:@"rtfd" inDirectory:@""];
    if(path==NULL)
        path = [[NSBundle mainBundle] pathForResource:[mTopicPathArray objectAtIndex:index] ofType:@"rtf" inDirectory:@""];
                
    NSTextStorage *textStorage = [mTextView textStorage];
    [textStorage beginEditing];
    [textStorage setAttributedString:[[[NSAttributedString alloc] initWithPath:path documentAttributes:NULL] autorelease]];
    [textStorage endEditing];
}

- (IBAction)changeTopicAction:(id)sender
{
    [self changeTopic:[sender indexOfSelectedItem]];
}

@end
