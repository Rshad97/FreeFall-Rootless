#import <AVFoundation/AVFoundation.h>
// Converts one bounded section to mono/48kHz/16-bit WAV; never overwrites user data.
NSData *FFTrimAudio(NSURL *url, double start, double duration, NSError **error);
