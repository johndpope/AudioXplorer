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

#import "AudioView+Categories.h"
#import "AudioViewAppearanceController.h"
#import "AudioViewAppearanceConstants.h"
#import "AudioDialogPrefs.h"

@implementation AudioView (Features)

#define ViewNameKey @"ViewName"
#define ViewIDKey @"ViewID"
#define XAxisAutoGridSpaceKey @"XAxisAutoGridSpace"
#define XAxisCustomGridSpaceKey @"XAxisCustomGridSpace"

#define AllowsViewSelectKey @"AllowsViewSelectKey"
#define AllowsPlaybackKey @"AllowsPlaybackKey"

#define ShowCursorKey @"ShowCursorKey"
#define ShowCursorHarmonicKey @"ShowCursorHarmonicKey"
#define ShowTriggerCursorKey @"ShowCursorTrigger"

#define DisplayedChannelKey @"DisplayedChannelKey"

#define XAxisUnitKey @"XAxisUnit"
#define YAxisUnitKey @"YAxisUnit"
#define ZAxisUnitKey @"YAxisUnit"
#define XAxisNameKey @"XAxisName"
#define YAxisNameKey @"YAxisName"
#define ZAxisNameKey @"YAxisName"

#define LissajousFromKey @"LissajousFrom"
#define LissajousToKey @"LissajousTo"
#define LissajousQualityKey @"LissajousQuality"

#define LineWidthKey @"LineWidthKey"

- (void)initDefaultFeatures
{
    [self setViewName:@""];
    [self setViewID:0];
    
    [self setXAxisUnit:@""];
    [self setYAxisUnit:@""];
    [self setZAxisUnit:@""];
    
    [self setXAxisName:@""];
    [self setYAxisName:@""];
    [self setZAxisName:@""];

    [self setXAxisAutoGridSpace:YES];
    [self setXAxisCustomGridSpace:1.0];
    
    [self setShowCursor:NO];
    [self setShowCursorHarmonic:NO];
    [self setShowTriggerCursor:NO];

    [self setDisplayedChannel:LEFT_CHANNEL];
    
    [self setLissajousFrom:-1];
    [self setLissajousTo:-1];
    [self setLissajousQuality:80];

    [self setAllowsViewSelect:YES];
    [self setAllowsPlayback:YES];

    AudioViewAppearanceController *appearance = [AudioViewAppearanceController shared];
    
    [self setAllowsTitle:[appearance displayValueForKey:AllowsTitleKey]];
    [self setAllowsSelection:[appearance displayValueForKey:AllowsSelectionKey]];
    [self setAllowsCursor:[appearance displayValueForKey:AllowsCursorKey]];
    [self setAllowsPlayerhead:[appearance displayValueForKey:AllowsPlayerheadKey]];
    [self setAllowsXAxis:[appearance displayValueForKey:AllowsXAxisKey]];
    [self setAllowsYAxis:[appearance displayValueForKey:AllowsYAxisKey]];
    [self setAllowsGrid:[appearance displayValueForKey:AllowsGridKey]];

    [self setTitleColor:[appearance objectColorForKey:TitleColorKey]];
    [self setBackgroundColor:[appearance objectColorForKey:BackgroundColorKey]];
    [self setGridColor:[appearance objectColorForKey:GridColorKey]];
    [self setLeftDataColor:[appearance objectColorForKey:LeftDataColorKey]];
    [self setRightDataColor:[appearance objectColorForKey:RightDataColorKey]];
    [self setCursorColor:[appearance objectColorForKey:CursorColorKey]];
    [self setSelectionColor:[appearance objectColorForKey:SelectionColorKey]];
    [self setPlayerheadColor:[appearance objectColorForKey:PlayerheadColorKey]];
    [self setXAxisColor:[appearance objectColorForKey:XAxisColorKey]];
    [self setYAxisColor:[appearance objectColorForKey:YAxisColorKey]];
	
	[self setLineWidth:0];
}

- (void)setFeatures:(NSMutableDictionary*)features
{
    if(features)
    {
        [mFeatures autorelease];
        mFeatures = [features retain];
    }
}

- (NSMutableDictionary*)features
{
    return mFeatures;
}

- (void)queryCursorDisplayPosition
{
    mCursorDisplayHorizontal = [[AudioDialogPrefs shared] horizontalCursor];
    mCursorDisplayVertical = [[AudioDialogPrefs shared] verticalCursor];        
}

- (void)queryScrollerUsage
{
    mUseHorizontalScroller = [[AudioDialogPrefs shared] horizontalScroller];
    mUseVerticalScroller = [[AudioDialogPrefs shared] verticalScroller];
}

- (void)setViewName:(NSString*)name
{
    [mFeatures setObject:name forKey:ViewNameKey];
    [self invalidateCaches];
}

- (NSString*)viewName
{
    return [mFeatures objectForKey:ViewNameKey];
}

- (void)setViewID:(ULONG)viewID
{
    [mFeatures setObject:[NSNumber numberWithUnsignedLong:viewID] forKey:ViewIDKey];
}

- (ULONG)viewID
{
    return [[mFeatures objectForKey:ViewIDKey] unsignedLongValue];
}

- (void)setXAxisUnit:(NSString*)unit
{
    [mFeatures setObject:unit forKey:XAxisUnitKey];
}

- (NSString*)xAxisUnit { return [mFeatures objectForKey:XAxisUnitKey]; }

- (void)setYAxisUnit:(NSString*)unit
{
    [mFeatures setObject:unit forKey:YAxisUnitKey];
}

- (NSString*)yAxisUnit { return [mFeatures objectForKey:YAxisUnitKey]; }

- (void)setZAxisUnit:(NSString*)unit
{
    [mFeatures setObject:unit forKey:ZAxisUnitKey];
}

- (NSString*)zAxisUnit { return [mFeatures objectForKey:ZAxisUnitKey]; }

- (void)setXAxisName:(NSString*)name
{
    [mFeatures setObject:name forKey:XAxisNameKey];
}

- (NSString*)xAxisName
{
    return [mFeatures objectForKey:XAxisNameKey];
}

- (void)setYAxisName:(NSString*)name
{
    [mFeatures setObject:name forKey:YAxisNameKey];
}

- (NSString*)yAxisName
{
    return [mFeatures objectForKey:YAxisNameKey];
}

- (void)setZAxisName:(NSString*)name
{
    [mFeatures setObject:name forKey:ZAxisNameKey];
}

- (NSString*)zAxisName
{
    return [mFeatures objectForKey:ZAxisNameKey];
}

- (void)setXAxisAutoGridSpace:(BOOL)state
{
    [mFeatures setObject:[NSNumber numberWithBool:state] forKey:XAxisAutoGridSpaceKey];
}

- (BOOL)xAxisAutoGridSpace
{
    return [[mFeatures objectForKey:XAxisAutoGridSpaceKey] boolValue];
}

- (void)setXAxisCustomGridSpace:(FLOAT)space
{
    [mFeatures setObject:[NSNumber numberWithFloat:space] forKey:XAxisCustomGridSpaceKey];
}

- (FLOAT)xAxisCustomGridSpace
{
    return [[mFeatures objectForKey:XAxisCustomGridSpaceKey] floatValue];
}

- (void)setAllowsTitle:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:AllowsTitleKey];
}

- (BOOL)allowsTitle
{
    return [[mFeatures objectForKey:AllowsTitleKey] boolValue];
}

- (void)setAllowsSelection:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:AllowsSelectionKey];
}

- (BOOL)allowsSelection
{
    return [[mFeatures objectForKey:AllowsSelectionKey] boolValue];
}

- (void)setAllowsCursor:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:AllowsCursorKey];
}

- (BOOL)allowsCursor
{
    return [[mFeatures objectForKey:AllowsCursorKey] boolValue];
}

- (void)setAllowsPlayerhead:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:AllowsPlayerheadKey];
}

- (BOOL)allowsPlayerhead
{
    return [[mFeatures objectForKey:AllowsPlayerheadKey] boolValue];
}

- (void)setAllowsXAxis:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:AllowsXAxisKey];
    [self invalidateCaches];
}

- (BOOL)allowsXAxis
{
    return [[mFeatures objectForKey:AllowsXAxisKey] boolValue];
}

- (void)setAllowsYAxis:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:AllowsYAxisKey];
    [self invalidateCaches];
}

- (BOOL)allowsYAxis
{
    return [[mFeatures objectForKey:AllowsYAxisKey] boolValue];
}

- (void)setAllowsGrid:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:AllowsGridKey];
    [self invalidateCaches];
}

- (BOOL)allowsGrid
{
    return [[mFeatures objectForKey:AllowsGridKey] boolValue];
}

- (void)setAllowsViewSelect:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:AllowsViewSelectKey];
}

- (BOOL)allowsViewSelect
{
    return [[mFeatures objectForKey:AllowsViewSelectKey] boolValue];
}

- (void)setAllowsPlayback:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:AllowsPlaybackKey];
}

- (BOOL)allowsPlayback
{
    return [[mFeatures objectForKey:AllowsPlaybackKey] boolValue];
}

- (void)setShowCursor:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:ShowCursorKey];
}

- (BOOL)showCursor
{
    return [[mFeatures objectForKey:ShowCursorKey] boolValue];
}

- (void)setShowCursorHarmonic:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:ShowCursorHarmonicKey];
}

- (BOOL)showCursorHarmonic
{
    return [[mFeatures objectForKey:ShowCursorHarmonicKey] boolValue];
}

- (void)setShowTriggerCursor:(BOOL)flag
{
    [mFeatures setObject:[NSNumber numberWithBool:flag] forKey:ShowTriggerCursorKey];
}

- (BOOL)showTriggerCursor
{
    return [[mFeatures objectForKey:ShowTriggerCursorKey] boolValue];
}

- (void)setDisplayedChannel:(SHORT)channel
{
    BOOL refreshRanges = (channel == LISSAJOUS_CHANNEL) && [self displayedChannel] != LISSAJOUS_CHANNEL
                    || (channel != LISSAJOUS_CHANNEL) && [self displayedChannel] == LISSAJOUS_CHANNEL;
                        
    [mFeatures setObject:[NSNumber numberWithInt:channel] forKey:DisplayedChannelKey];
	mDisplayedChannel = channel;
    if(refreshRanges)
    {
        [self refreshRanges];
        [self invalidateCaches];
    }    
}

- (SHORT)displayedChannel
{
	return mDisplayedChannel;
   // return [[mFeatures objectForKey:DisplayedChannelKey] intValue];
}

- (void)setTitleColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:TitleColorKey];
    [self invalidateCaches];
}

- (void)setBackgroundColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:BackgroundColorKey];
    [self invalidateCaches];
}

- (void)setGridColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:GridColorKey];
    [self invalidateCaches];
}

- (void)setLeftDataColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:LeftDataColorKey];
	mLeftDataColor = color;
    [self invalidateCaches];
}

- (void)setRightDataColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:RightDataColorKey];
	mRightDataColor = color;
    [self invalidateCaches];
}

- (void)setCursorColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:CursorColorKey];
    [self invalidateCaches];
}

- (void)setSelectionColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:SelectionColorKey];
    [self invalidateCaches];
}

- (void)setPlayerheadColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:PlayerheadColorKey];
    [self invalidateCaches];
}

- (void)setXAxisColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:XAxisColorKey];
    [self invalidateCaches];
}

- (void)setYAxisColor:(NSColor*)color
{
    [mFeatures setObject:color forKey:YAxisColorKey];
    [self invalidateCaches];
}

- (NSColor*)titleColor
{
    return [mFeatures objectForKey:TitleColorKey];
}
- (NSColor*)backgroundColor
{
    return [mFeatures objectForKey:BackgroundColorKey];
}
- (NSColor*)gridColor
{
    return [mFeatures objectForKey:GridColorKey];
}
- (NSColor*)leftDataColor
{
	return mLeftDataColor;
    //return [mFeatures objectForKey:LeftDataColorKey];
}
- (NSColor*)rightDataColor
{
	return mRightDataColor;
    //return [mFeatures objectForKey:RightDataColorKey];
}
- (NSColor*)cursorColor
{
    return [mFeatures objectForKey:CursorColorKey];
}
- (NSColor*)selectionColor
{
    return [mFeatures objectForKey:SelectionColorKey];
}
- (NSColor*)playerheadColor
{
    return [mFeatures objectForKey:PlayerheadColorKey];
}
- (NSColor*)xAxisColor
{
    return [mFeatures objectForKey:XAxisColorKey];
}
- (NSColor*)yAxisColor
{
    return [mFeatures objectForKey:YAxisColorKey];
}

- (void)setLissajousFrom:(FLOAT)from
{
    [mFeatures setObject:[NSNumber numberWithFloat:from] forKey:LissajousFromKey];
}
- (FLOAT)lissajousFrom
{
    NSNumber *number = [mFeatures objectForKey:LissajousFromKey];
    if(number)
        return [number floatValue];
    else
        return 0;
}

- (void)setLissajousTo:(FLOAT)to
{
    [mFeatures setObject:[NSNumber numberWithFloat:to] forKey:LissajousToKey];
}
- (FLOAT)lissajousTo
{
    NSNumber *number = [mFeatures objectForKey:LissajousToKey];
    if(number)
        return [number floatValue];
    else
        return mMaxX;
}

- (void)setLissajousQuality:(FLOAT)quality
{
    [mFeatures setObject:[NSNumber numberWithFloat:quality] forKey:LissajousQualityKey];
}

- (FLOAT)lissajousQuality
{
    NSNumber *number = [mFeatures objectForKey:LissajousQualityKey];
    if(number)
        return [number floatValue];
    else
        return 50;
}

- (void)setLineWidth:(FLOAT)width
{
    [mFeatures setObject:[NSNumber numberWithFloat:width] forKey:LineWidthKey];
	mLineWidth = width;
}

- (FLOAT)lineWidth
{
	return mLineWidth;
    /*NSNumber *number = [mFeatures objectForKey:LineWidthKey];
    if(number)
        return [number floatValue];
    else
        return 0;*/
}

@end
