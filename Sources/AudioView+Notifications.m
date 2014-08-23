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
#import "AudioNotifications.h"
#import "AudioSynth.h"

@implementation AudioView (Notifications)

- (void)scaleHasChanged
{    
    [self invalidateCaches];
    [self refresh];
    if([mDelegate respondsToSelector:@selector(audioViewScaleHasChanged:)])
        [mDelegate performSelector:@selector(audioViewScaleHasChanged:) withObject:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioViewScaleHasChangedNotification object:self];
}

- (void)selectionHasChanged
{
    [self setNeedsDisplay:YES];
    if([mDelegate respondsToSelector:@selector(audioViewSelectionHasChanged:)])
        [mDelegate audioViewSelectionHasChanged:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioViewSelectionHasChangedNotification object:self];
}

- (void)cursorHasChanged
{    
    if(mViewType == VIEW_3D) {
        [mAudioSynth setFrequency:[self yCursorPosition]];
        [mAudioSynth setAmplitude:[mDataSource zValueNormalizedAtX:[self xCursorPosition] y:[self yCursorPosition]]];
    } else if(mViewType == VIEW_2D && [mDataSource kind] != KIND_AMPLITUDE) {
        [mAudioSynth setFrequency:[self xCursorPosition]];
        [mAudioSynth setAmplitude:[mDataSource yValueNormalizedAtX:[self xCursorPosition] channel:[self displayedChannel]]];
	}
        
    [self setNeedsDisplay:YES];
    if([mDelegate respondsToSelector:@selector(audioViewCursorHasChanged:)])
        [mDelegate audioViewCursorHasChanged:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioViewCursorHasChangedNotification object:self];
}

- (void)triggerCursorHasChanged
{    
    [self setNeedsDisplay:YES];
    if([mDelegate respondsToSelector:@selector(audioViewTriggerCursorHasChanged:)])
        [mDelegate performSelector:@selector(audioViewTriggerCursorHasChanged:) withObject:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioViewTriggerCursorHasChangedNotification object:self];
}

- (void)playerHeadHasChanged
{    
    [self setNeedsDisplay:YES];
    if([mDelegate respondsToSelector:@selector(audioViewPlayerHeadHasChanged:)])
        [mDelegate audioViewPlayerHeadHasChanged:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioViewPlayerHeadHasChangedNotification object:self];
}

- (void)viewHasUpdated
{    
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioViewHasUpdatedNotification object:self];
}

- (void)viewFrameHasChanged:(NSNotification*)notif
{
    if([notif object] == self)
    {
        [self setViewRect:[self bounds]];
        [self updateXAxisScrollerFrame];
        [self updateYAxisScrollerFrame];
        [self setToolTips];
    }
}

- (void)prefsCursorDirectionChanged:(NSNotification*)notif
{
    [self queryCursorDisplayPosition];
    [self setNeedsDisplay:YES];
}

- (void)prefsViewScrollerChanged:(NSNotification*)notif
{
    [self queryScrollerUsage];
    [self updateXAxisScroller];
    [self updateYAxisScroller];
    [self setNeedsDisplay:YES];
}

- (void)prefsUseToolTipsChanged:(NSNotification*)notif
{
    [self setToolTips];
}

@end
