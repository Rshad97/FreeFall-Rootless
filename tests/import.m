#import "../freefallprefs/FFAudioImport.h"
#include <assert.h>
int main(int argc, const char **argv) { @autoreleasepool {
    assert(argc == 2);
    NSURL *source = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
    NSError *error = nil;
    NSData *data = FFTrimAudio(source, .1, .3, &error);
    if (!data) NSLog(@"Import failed: %@", error);
    assert(data);
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:data error:&error];
    assert(player && fabs(player.duration-.3)<.02);
    assert(player.numberOfChannels==1);
    assert(FFTrimAudio(source, -1, .3, &error)==nil);
    assert(FFTrimAudio(source, 0, 11, &error)==nil);
    assert(FFTrimAudio(source, 0, NAN, &error)==nil);
    assert(FFTrimAudio(source, 1000000, 1, &error)==nil);
    assert(FFTrimAudio([NSURL fileURLWithPath:@"/no-such-audio.wav"], 0, 1, &error)==nil);
    NSLog(@"PASS: production importer trims to mono WAV and rejects invalid input safely.");
} }
