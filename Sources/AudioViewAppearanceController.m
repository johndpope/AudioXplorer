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

#import "AudioViewAppearanceController.h"
#import "AudioViewAppearanceConstants.h"
#import "AudioAppearanceTableColumn.h"
#import "AudioColorCell.h"

#define NO_KEY @"NO_KEY"

#define COLUMN_ID_DISPLAY @"DISPLAY"
#define COLUMN_ID_LABEL @"LABEL"
#define COLUMN_ID_COLOR @"COLOR"

@implementation AudioViewAppearanceController

+ (AudioViewAppearanceController*)shared
{
    static AudioViewAppearanceController *_appearanceController = NULL;
    if(_appearanceController == NULL)
        _appearanceController = [[AudioViewAppearanceController alloc] init];
    return _appearanceController;
}

- (id)init
{
    self = [super initWithWindowNibName:@"AudioViewAppearance"];
    if(self)
    {
        mView = NULL;
        mColumnTitleArray = NULL;
        mColumnTypeArray = NULL;
        mColumnIdentifierArray = NULL;
        mLabelDictionary = [[NSMutableDictionary dictionary] retain];
        mColorDictionary = [[NSMutableDictionary dictionary] retain];
        mDisplayDictionary = [[NSMutableDictionary dictionary] retain];
        mLabelKeyArray = NULL;
        mColorKeyArray = NULL;
        mDisplayKeyArray = NULL;
        
        mAppearanceColorCellDictionary = [[NSMutableDictionary dictionary] retain];
        
        [self window];
        [self initTableView];
        [self initDefaultAppearance];
    }
    return self;
}

- (void)dealloc
{
    [mAppearanceColorCellDictionary release];
    [mLabelKeyArray release];
    [mColorKeyArray release];
    [mDisplayKeyArray release];
    [mColorDictionary release];
    [mDisplayDictionary release];
    [mLabelDictionary release];
    [mColumnTitleArray release];
    [mColumnTypeArray release];
    [mColumnIdentifierArray release];
    [mView release];
    [super dealloc];
}

- (void)setObjectColor:(NSColor*)color forKey:(NSString*)key
{
    if(color)
        [mColorDictionary setObject:color forKey:key];
}

- (void)setObjectDisplay:(NSNumber*)flag forKey:(NSString*)key
{
    if(flag)
        [mDisplayDictionary setObject:flag forKey:key];
}

- (void)setObjectDisplayValue:(BOOL)flag forKey:(NSString*)key
{
    [self setObjectDisplay:[NSNumber numberWithBool:flag] forKey:key];
}

- (NSColor*)objectColorForKey:(NSString*)key
{
    return [mColorDictionary objectForKey:key];
}

- (NSNumber*)objectDisplayForKey:(NSString*)key
{
    return [mDisplayDictionary objectForKey:key];
}

- (BOOL)displayValueForKey:(NSString*)key
{
    return [[self objectDisplayForKey:key] boolValue];
}

- (void)initDefaultAppearance
{
    [self setObjectColor:[NSColor whiteColor] forKey:TitleColorKey];
    [self setObjectColor:[NSColor blackColor] forKey:BackgroundColorKey];
    [self setObjectColor:[NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:0.5] forKey:GridColorKey];
    [self setObjectColor:[NSColor colorWithDeviceRed:0 green:1 blue:0 alpha:1] forKey:LeftDataColorKey];
    [self setObjectColor:[NSColor colorWithDeviceRed:0 green:0.8 blue:1 alpha:1] forKey:RightDataColorKey];
    [self setObjectColor:[NSColor whiteColor] forKey:CursorColorKey];
    [self setObjectColor:[NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:0.5] forKey:SelectionColorKey];
    [self setObjectColor:[NSColor yellowColor] forKey:PlayerheadColorKey];
    [self setObjectColor:[NSColor whiteColor] forKey:XAxisColorKey];
    [self setObjectColor:[NSColor whiteColor] forKey:YAxisColorKey];

    [self setObjectDisplayValue:YES forKey:AllowsTitleKey];
    [self setObjectDisplayValue:YES forKey:AllowsGridKey];
    [self setObjectDisplayValue:YES forKey:AllowsCursorKey];
    [self setObjectDisplayValue:YES forKey:AllowsSelectionKey];
    [self setObjectDisplayValue:YES forKey:AllowsPlayerheadKey];
    [self setObjectDisplayValue:YES forKey:AllowsXAxisKey];
    [self setObjectDisplayValue:YES forKey:AllowsYAxisKey];
}

- (void)setDefaultAppearanceFromData:(id)array
{
    if(array == NULL) return;
        
    NSDictionary *colorDic = [NSUnarchiver unarchiveObjectWithData:[array objectAtIndex:0]];
    NSDictionary *numberDic = [NSUnarchiver unarchiveObjectWithData:[array objectAtIndex:1]];
        
    [self setObjectColor:[colorDic objectForKey:TitleColorKey] forKey:BackgroundColorKey];
    [self setObjectColor:[colorDic objectForKey:BackgroundColorKey] forKey:BackgroundColorKey];
    [self setObjectColor:[colorDic objectForKey:GridColorKey] forKey:GridColorKey];
    [self setObjectColor:[colorDic objectForKey:LeftDataColorKey] forKey:LeftDataColorKey];
    [self setObjectColor:[colorDic objectForKey:RightDataColorKey] forKey:RightDataColorKey];
    [self setObjectColor:[colorDic objectForKey:CursorColorKey] forKey:CursorColorKey];
    [self setObjectColor:[colorDic objectForKey:SelectionColorKey] forKey:SelectionColorKey];
    [self setObjectColor:[colorDic objectForKey:PlayerheadColorKey] forKey:PlayerheadColorKey];
    [self setObjectColor:[colorDic objectForKey:XAxisColorKey] forKey:XAxisColorKey];
    [self setObjectColor:[colorDic objectForKey:YAxisColorKey] forKey:YAxisColorKey];

    [self setObjectDisplay:[numberDic objectForKey:AllowsTitleKey] forKey:AllowsTitleKey];
    [self setObjectDisplay:[numberDic objectForKey:AllowsGridKey] forKey:AllowsGridKey];
    [self setObjectDisplay:[numberDic objectForKey:AllowsCursorKey] forKey:AllowsCursorKey];
    [self setObjectDisplay:[numberDic objectForKey:AllowsSelectionKey] forKey:AllowsSelectionKey];
    [self setObjectDisplay:[numberDic objectForKey:AllowsPlayerheadKey] forKey:AllowsPlayerheadKey];
    [self setObjectDisplay:[numberDic objectForKey:AllowsXAxisKey] forKey:AllowsXAxisKey];
    [self setObjectDisplay:[numberDic objectForKey:AllowsYAxisKey] forKey:AllowsYAxisKey];
}

- (id)defaultAppearanceData
{
    NSMutableDictionary *colorDic = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *numberDic = [[NSMutableDictionary alloc] init];
    
    [colorDic setObject:[self objectColorForKey:TitleColorKey] forKey:BackgroundColorKey];
    [colorDic setObject:[self objectColorForKey:BackgroundColorKey] forKey:BackgroundColorKey];
    [colorDic setObject:[self objectColorForKey:GridColorKey] forKey:GridColorKey];
    [colorDic setObject:[self objectColorForKey:LeftDataColorKey] forKey:LeftDataColorKey];
    [colorDic setObject:[self objectColorForKey:RightDataColorKey] forKey:RightDataColorKey];
    [colorDic setObject:[self objectColorForKey:CursorColorKey] forKey:CursorColorKey];
    [colorDic setObject:[self objectColorForKey:SelectionColorKey] forKey:SelectionColorKey];
    [colorDic setObject:[self objectColorForKey:PlayerheadColorKey] forKey:PlayerheadColorKey];
    [colorDic setObject:[self objectColorForKey:XAxisColorKey] forKey:XAxisColorKey];
    [colorDic setObject:[self objectColorForKey:YAxisColorKey] forKey:YAxisColorKey];
    
    [numberDic setObject:[self objectDisplayForKey:AllowsTitleKey] forKey:AllowsTitleKey];
    [numberDic setObject:[self objectDisplayForKey:AllowsGridKey] forKey:AllowsGridKey];
    [numberDic setObject:[self objectDisplayForKey:AllowsCursorKey] forKey:AllowsCursorKey];
    [numberDic setObject:[self objectDisplayForKey:AllowsSelectionKey] forKey:AllowsSelectionKey];
    [numberDic setObject:[self objectDisplayForKey:AllowsPlayerheadKey] forKey:AllowsPlayerheadKey];
    [numberDic setObject:[self objectDisplayForKey:AllowsXAxisKey] forKey:AllowsXAxisKey];
    [numberDic setObject:[self objectDisplayForKey:AllowsYAxisKey] forKey:AllowsYAxisKey];

    NSData *colorData = [NSArchiver archivedDataWithRootObject:[colorDic autorelease]];

    NSData *numberData = [NSArchiver archivedDataWithRootObject:[numberDic autorelease]];

    return [NSArray arrayWithObjects:colorData, numberData, NULL];
}

- (void)setContainerBox:(NSBox*)box
{
    [box setContentView:mAppearanceView];
}

- (void)setView:(AudioView*)view
{
    [mView autorelease];
    if(view)
    {
        mView = [view retain];

        [self setObjectColor:[mView titleColor] forKey:TitleColorKey];
        [self setObjectColor:[mView backgroundColor] forKey:BackgroundColorKey];
        [self setObjectColor:[mView gridColor] forKey:GridColorKey];
        [self setObjectColor:[mView leftDataColor] forKey:LeftDataColorKey];
        [self setObjectColor:[mView rightDataColor] forKey:RightDataColorKey];
        [self setObjectColor:[mView cursorColor] forKey:CursorColorKey];
        [self setObjectColor:[mView selectionColor] forKey:SelectionColorKey];
        [self setObjectColor:[mView playerheadColor] forKey:PlayerheadColorKey];
        [self setObjectColor:[mView xAxisColor] forKey:XAxisColorKey];
        [self setObjectColor:[mView yAxisColor] forKey:YAxisColorKey];

        [self setObjectDisplayValue:[mView allowsTitle] forKey:AllowsTitleKey];
        [self setObjectDisplayValue:[mView allowsGrid] forKey:AllowsGridKey];
        [self setObjectDisplayValue:[mView allowsCursor] forKey:AllowsCursorKey];
        [self setObjectDisplayValue:[mView allowsSelection] forKey:AllowsSelectionKey];
        [self setObjectDisplayValue:[mView allowsPlayerhead] forKey:AllowsPlayerheadKey];
        [self setObjectDisplayValue:[mView allowsXAxis] forKey:AllowsXAxisKey];
        [self setObjectDisplayValue:[mView allowsYAxis] forKey:AllowsYAxisKey];
    } else
    {
        [[NSColorPanel sharedColorPanel] setTarget:NULL];
        [[NSColorPanel sharedColorPanel] setAction:NULL];
        mView = NULL;
    }
}

- (NSView*)view
{
    return mAppearanceView;
}

- (void)applyToView
{
    [mView setTitleColor:[self objectColorForKey:TitleColorKey]];
    [mView setBackgroundColor:[self objectColorForKey:BackgroundColorKey]];
    [mView setGridColor:[self objectColorForKey:GridColorKey]];
    [mView setLeftDataColor:[self objectColorForKey:LeftDataColorKey]];
    [mView setRightDataColor:[self objectColorForKey:RightDataColorKey]];
    [mView setCursorColor:[self objectColorForKey:CursorColorKey]];
    [mView setSelectionColor:[self objectColorForKey:SelectionColorKey]];
    [mView setPlayerheadColor:[self objectColorForKey:PlayerheadColorKey]];
    [mView setXAxisColor:[self objectColorForKey:XAxisColorKey]];
    [mView setYAxisColor:[self objectColorForKey:YAxisColorKey]];
    
    [mView setAllowsTitle:[self displayValueForKey:AllowsTitleKey]];
    [mView setAllowsGrid:[self displayValueForKey:AllowsGridKey]];
    [mView setAllowsCursor:[self displayValueForKey:AllowsCursorKey]];
    [mView setAllowsSelection:[self displayValueForKey:AllowsSelectionKey]];
    [mView setAllowsPlayerhead:[self displayValueForKey:AllowsPlayerheadKey]];
    [mView setAllowsXAxis:[self displayValueForKey:AllowsXAxisKey]];
    [mView setAllowsYAxis:[self displayValueForKey:AllowsYAxisKey]];
    
    [mView setNeedsDisplay:YES];
}

- (void)colorCellAction:(id)sender
{
    // sender is the tableview (should have been the AudioColorCell, but...)
    
    NSColor *color = [self objectColorForKey:[mColorKeyArray objectAtIndex:[sender selectedRow]]];
    [[NSColorPanel sharedColorPanel] setColor:color];
    [[NSColorPanel sharedColorPanel] setTarget:self];
    [[NSColorPanel sharedColorPanel] setAction:@selector(colorHasChanged:)];
    [[NSColorPanel sharedColorPanel] orderFront:self];
}

- (void)colorHasChanged:(id)sender
{
    NSColor *color = [sender color];
    int row = [mAppearanceTableView selectedRow];
    [[mAppearanceColorCellDictionary objectForKey:[NSString stringWithFormat:@"%d", row]] setObjectValue:color];
    [mAppearanceTableView setNeedsDisplay:YES];

    [self setObjectColor:color forKey:[mColorKeyArray objectAtIndex:row]];
    [self applyToView];
}

@end

@implementation AudioViewAppearanceController (TableView)

- (void)initTableViewData
{
    [mLabelKeyArray release];
    mLabelKeyArray = [[NSArray arrayWithObjects:NSLocalizedString(@"Title", NULL),
                                            NSLocalizedString(@"Background", NULL),
                                            NSLocalizedString(@"Grid", NULL),
                                            NSLocalizedString(@"Left", NULL),
                                            NSLocalizedString(@"Right", NULL),
                                            NSLocalizedString(@"Selection", NULL),
                                            NSLocalizedString(@"Cursor", NULL),
                                            NSLocalizedString(@"Playerhead", NULL),
                                            NSLocalizedString(@"X-axis", NULL),
                                            NSLocalizedString(@"Y-axis", NULL),
                                            NULL] retain];
    
    [mColorKeyArray release];
    mColorKeyArray = [[NSArray arrayWithObjects:TitleColorKey,
                                            BackgroundColorKey,
                                            GridColorKey,
                                            LeftDataColorKey,
                                            RightDataColorKey,
                                            SelectionColorKey,
                                            CursorColorKey,
                                            PlayerheadColorKey,
                                            XAxisColorKey,
                                            YAxisColorKey,
                                            NULL] retain];
    
    [mDisplayKeyArray release];
    mDisplayKeyArray = [[NSArray arrayWithObjects:AllowsTitleKey,
                                            NO_KEY,
                                            AllowsGridKey,
                                            NO_KEY,
                                            NO_KEY,
                                            AllowsCursorKey,
                                            AllowsSelectionKey,
                                            AllowsPlayerheadKey,
                                            AllowsXAxisKey,
                                            AllowsYAxisKey,
                                            NULL] retain];    
}

- (void)buildTableView
{
    NSArray *columns = [[[mAppearanceTableView tableColumns] copy] autorelease];
    NSEnumerator *enumerator = [columns objectEnumerator];
    NSTableColumn *column;
    
    while(column = [enumerator nextObject])
        [mAppearanceTableView removeTableColumn:column];
    
    [mAppearanceTableView setRowHeight:17];
    
    short index;
    for(index=0; index<[mColumnTitleArray count]; index++)
    {
        AudioAppearanceTableColumn *theColumn = [[AudioAppearanceTableColumn alloc] init];
        [theColumn setTitle:[mColumnTitleArray objectAtIndex:index]];
        [theColumn setType:[[mColumnTypeArray objectAtIndex:index] intValue]];
        [theColumn setIdentifier:[mColumnIdentifierArray objectAtIndex:index]];
        float width = [[mColumnTitleArray objectAtIndex:index] sizeWithAttributes:NULL].width+index*30;
        switch(index) {
            case 0:
                width += 30;
                break;
            case 1:
                width += 100;
                break;
            case 2:
                width += 200;
                break;
        }
        [theColumn setMaxWidth:width];
        [mAppearanceTableView addTableColumn:theColumn];     
        [theColumn release];
    }  
}

- (void)initTableViewArrays
{
    mColumnTitleArray = [NSArray arrayWithObjects:NSLocalizedString(@"Display", NULL),
                                                    NSLocalizedString(@"Label", NULL),
                                                    NSLocalizedString(@"Color", NULL),
                                                    NULL];
    [mColumnTitleArray retain];
    
    mColumnTypeArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:COLUMN_CHECKBOX],
                                                [NSNumber numberWithInt:COLUMN_LABEL],
                                                [NSNumber numberWithInt:COLUMN_COLOR],
                                                    NULL];
    [mColumnTypeArray retain];

    mColumnIdentifierArray = [NSArray arrayWithObjects:COLUMN_ID_DISPLAY,
                                                    COLUMN_ID_LABEL,
                                                    COLUMN_ID_COLOR,
                                                    NULL];
    [mColumnIdentifierArray retain];
}

- (void)initTableView
{
    [self initTableViewData];
    [self initTableViewArrays];
    [self buildTableView];
}

- (int)numberOfRowsInTableView:(NSTableView *)theTableView
{
    return [mLabelKeyArray count];
}

- (NSMutableDictionary*)dictionaryForColumnIdentifier:(NSString*)identifier
{
    if([identifier isEqualToString:COLUMN_ID_LABEL])
        return mLabelDictionary;
    else if([identifier isEqualToString:COLUMN_ID_COLOR])
        return mColorDictionary;
    else if([identifier isEqualToString:COLUMN_ID_DISPLAY])
        return mDisplayDictionary;
    
    return NULL;
}

- (NSString*)keyForRowIndex:(int)rowIndex columnIdentifier:(NSString*)identifier
{
    if([identifier isEqualToString:COLUMN_ID_LABEL])
        return NULL;
    else if([identifier isEqualToString:COLUMN_ID_COLOR])
        return [mColorKeyArray objectAtIndex:rowIndex];
    else if([identifier isEqualToString:COLUMN_ID_DISPLAY])
        return [mDisplayKeyArray objectAtIndex:rowIndex];
    
    return NULL;
}

- (id)tableView:(NSTableView *)theTableView
        objectValueForTableColumn:(NSTableColumn *)theColumn
        row:(int)rowIndex
{
    NSString *identifier = [theColumn identifier];
    NSString *key = [self keyForRowIndex:rowIndex columnIdentifier:identifier];
    
    if([identifier isEqualToString:COLUMN_ID_LABEL])
        return [mLabelKeyArray objectAtIndex:rowIndex];
    else if([identifier isEqualToString:COLUMN_ID_COLOR])
        return [mColorDictionary objectForKey:key];
    else if([identifier isEqualToString:COLUMN_ID_DISPLAY])
        return [mDisplayDictionary objectForKey:key];

    return NULL;
}

- (void)tableView:(NSTableView *)theTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)theColumn row:(int)rowIndex
{
    NSString *identifier = [theColumn identifier];
    NSString *key = [self keyForRowIndex:rowIndex columnIdentifier:identifier];
    
    if([identifier isEqualToString:COLUMN_ID_DISPLAY])
        [mDisplayDictionary setObject:[NSNumber numberWithBool:[anObject boolValue]] forKey:key];
    else if([identifier isEqualToString:COLUMN_ID_LABEL])
        [mLabelDictionary setObject:anObject forKey:key];
    else if([identifier isEqualToString:COLUMN_ID_COLOR])
        [mColorDictionary setObject:anObject forKey:key];

    [self applyToView];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    // Is there a best method to set the target/action of a cell ?
    
    BOOL enabled = [[self keyForRowIndex:row columnIdentifier:[tableColumn identifier]] isEqualToString:NO_KEY] == NO;
    
    if([cell isKindOfClass:[AudioColorCell class]])
    {
        [cell setEnabled:enabled];
        [cell setTarget:self];
        [cell setAction:@selector(colorCellAction:)];
        [cell setTag:row];
        [mAppearanceColorCellDictionary setObject:cell forKey:[NSString stringWithFormat:@"%d", row]];
    } else if([cell isKindOfClass:[NSButtonCell class]])
        [cell setEnabled:enabled];
}

@end
