#import "FFAudioImport.h"
#include <math.h>
static void FFAudioError(NSError **error, NSString *message) {
    if (error) *error = [NSError errorWithDomain:@"FreeFallAudio" code:1 userInfo:@{NSLocalizedDescriptionKey:message}];
}
NSData *FFTrimAudio(NSURL *url, double start, double duration, NSError **error) {
    if (!isfinite(start) || !isfinite(duration) || start < 0 || duration < .2 || duration > 10) {
        FFAudioError(error, @"Invalid trim range (duration must be 0.2–10 seconds)."); return nil;
    }
    NSString *temp = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"wav"]];
    NSData *resultData = nil;
    @try {
        AVAudioFile *source = [[AVAudioFile alloc] initForReading:url commonFormat:AVAudioPCMFormatFloat32 interleaved:NO error:error];
        if (!source) return nil;
        AVAudioFormat *format = source.processingFormat;
        double rate = format.sampleRate;
        if (rate < 8000 || rate > 192000 || format.channelCount < 1 || format.channelCount > 8 || start + duration > (double)source.length/rate + .001) {
            FFAudioError(error, @"Unsupported audio or selected section exceeds its duration."); return nil;
        }
        source.framePosition = (AVAudioFramePosition)(start*rate);
        AVAudioPCMBuffer *input = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:(AVAudioFrameCount)ceil(duration*rate)];
        if (![source readIntoBuffer:input error:error] || !input.frameLength) return nil;
        AVAudioFormat *target = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:48000 channels:1 interleaved:NO];
        AVAudioPCMBuffer *output = [[AVAudioPCMBuffer alloc] initWithPCMFormat:target frameCapacity:(AVAudioFrameCount)ceil(duration*48000)+1024];
        AVAudioConverter *converter = [[AVAudioConverter alloc] initFromFormat:format toFormat:target];
        if (!converter) { FFAudioError(error, @"Audio converter unavailable."); return nil; }
        __block BOOL supplied = NO;
        AVAudioConverterOutputStatus status = [converter convertToBuffer:output error:error withInputFromBlock:^AVAudioBuffer *(AVAudioPacketCount count, AVAudioConverterInputStatus *inputStatus) {
            if (supplied) { *inputStatus = AVAudioConverterInputStatus_EndOfStream; return nil; }
            supplied = YES; *inputStatus = AVAudioConverterInputStatus_HaveData; return input;
        }];
        if (status == AVAudioConverterOutputStatus_Error || !output.frameLength) return nil;
        if (output.frameLength > (AVAudioFrameCount)(duration*48000)) output.frameLength = (AVAudioFrameCount)(duration*48000);
        NSDictionary *settings = @{AVFormatIDKey:@(kAudioFormatLinearPCM), AVSampleRateKey:@48000, AVNumberOfChannelsKey:@1, AVLinearPCMBitDepthKey:@16, AVLinearPCMIsFloatKey:@NO, AVLinearPCMIsBigEndianKey:@NO};
        AVAudioFile *file = [[AVAudioFile alloc] initForWriting:[NSURL fileURLWithPath:temp] settings:settings commonFormat:AVAudioPCMFormatFloat32 interleaved:NO error:error];
        BOOL written = file && [file writeFromBuffer:output error:error]; file = nil;
        NSData *data = written ? [NSData dataWithContentsOfFile:temp] : nil;
        AVAudioPlayer *check = data ? [[AVAudioPlayer alloc] initWithData:data error:error] : nil;
        if (!check || check.duration < .19 || check.duration > 10.01 || fabs(check.duration-duration) > .05) FFAudioError(error, @"Converted sound failed duration validation.");
        else resultData = data;
    } @catch (NSException *exception) { FFAudioError(error, @"Unsupported audio could not be processed safely."); }
    @finally { [[NSFileManager defaultManager] removeItemAtPath:temp error:nil]; }
    return resultData;
}
