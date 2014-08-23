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

#import "ARFileUtilities.h"

@implementation ARFileUtilities

+ (OSErr)makeNewFSSpec:(FSSpec *)outSpecPtr fromPath:(NSString *)inPath
{
    FSRef fsref;
    OSErr err = FSPathMakeRef([[inPath stringByDeletingLastPathComponent] fileSystemRepresentation],&fsref, NULL);
    if (err != noErr) {
        NSLog(@"Cannot make new FSSpec for '%@' (error %i)", inPath, err);
        return err;
    }
    FSCatalogInfo info;
    err = FSGetCatalogInfo(&fsref, kFSCatInfoNodeID | kFSCatInfoVolume, &info, NULL, NULL, NULL);
    if (err != noErr) {
        NSLog(@"Cannot get catalog info for new FSSpec '%@' (error %i)", inPath, err);
        return err;
    }
    NSString *lastComponent = [inPath lastPathComponent];
    char name[100];
    [lastComponent getCString:&name[1]];
    name[0] = [lastComponent length];
    err = FSMakeFSSpec(info.volume, info.nodeID, name, outSpecPtr);
    if (err != noErr && err != fnfErr) {
        NSLog(@"Cannot make new FSSpec (2) for '%@' (error %i)", inPath, err);
        return err;
    }
    return noErr;
}

+ (OSErr)makeFSSpec:(FSSpec *)outSpecPtr fromPath:(NSString *)inPath
{
    FSRef fsref;
    OSErr err = FSPathMakeRef([inPath fileSystemRepresentation],&fsref, NULL);
    if (err != noErr) {
        NSLog(@"Cannot make FSSpec for '%@' (error %i)", inPath, err);
        return err;
    }
    err = FSGetCatalogInfo(&fsref, kFSCatInfoNone,NULL, NULL, outSpecPtr, NULL);
    if (err != noErr) {
        NSLog(@"Cannot get catalog info for FSSpec '%@' (error %i)", inPath, err);
        return err;
    }
    return noErr;
}

@end
