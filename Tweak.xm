#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>
#import "FFShared.h"

@interface FFRController : NSObject {
    FFState _state;
}
@property (nonatomic, strong) CMMotionManager *motion;
@property (nonatomic, strong) NSMutableDictionary<NSString *, AVAudioPlayer *> *sounds;
@property (nonatomic, strong) AVAudioPlayer *playing;
@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic, strong) NSMutableDictionary *daily;
@property (nonatomic, strong) dispatch_queue_t logQueue;
@property (nonatomic, copy) NSArray<NSString *> *pool;
@property (nonatomic, copy) NSString *selected;
@property (nonatomic, copy) NSString *impactSound;
@property (nonatomic, copy) NSString *lastSound;
@property (nonatomic, strong) NSDate *customDate;
@property (nonatomic) BOOL enabled, shuffle, impactEnabled, pocket, logging, quiet, ownsProximity;
@property (nonatomic) NSInteger quietStart, quietEnd;
@property (nonatomic) double fallThreshold, impactThreshold;
- (void)reloadPreferences;
- (void)handleEvent:(int)event magnitude:(double)g;
@end

@implementation FFRController
- (instancetype)init {
    if ((self = [super init])) {
        _motion = [CMMotionManager new];
        _sounds = [NSMutableDictionary dictionary];
        _logQueue = dispatch_queue_create("com.rashad.freefallrootless.log", DISPATCH_QUEUE_SERIAL);
        NSArray *saved = [NSArray arrayWithContentsOfFile:[FFDataDirectory() stringByAppendingPathComponent:@"Events.plist"]];
        _events = [NSMutableArray array];
        for (id event in saved) {
            if ([event isKindOfClass:NSDictionary.class] && [event[@"date"] isKindOfClass:NSDate.class]) [_events addObject:event];
        }
        while (_events.count > 200) [_events removeObjectAtIndex:0];
        _daily = [[NSDictionary dictionaryWithContentsOfFile:[FFDataDirectory() stringByAppendingPathComponent:@"Daily.plist"]] mutableCopy] ?: [NSMutableDictionary dictionary];
        _state = (FFState){false, -1, -100};
        [self reloadPreferences];
    }
    return self;
}
- (void)reloadPreferences {
    CFPreferencesAppSynchronize((__bridge CFStringRef)FFDomainName);
    self.enabled = FFBool(@"enabled", YES);
    self.shuffle = FFBool(@"shuffle", NO);
    self.impactEnabled = FFBool(@"impactEnabled", NO);
    self.pocket = FFBool(@"pocketMode", NO);
    self.logging = FFBool(@"eventLogging", NO);
    self.quiet = FFBool(@"quietEnabled", NO);
    self.quietStart = (NSInteger)FFClamp(FFNumber(@"quietStart", 22), 0, 23, 22);
    self.quietEnd = (NSInteger)FFClamp(FFNumber(@"quietEnd", 7), 0, 23, 7);
    self.fallThreshold = FFClamp(FFNumber(@"fallingSensitivity", .04), .01, .25, .04);
    self.impactThreshold = FFClamp(FFNumber(@"stoppingSensitivity", 6), 2, 8, 6);
    self.selected = FFString(@"selectedSound", @"FreeFallScream");
    self.impactSound = FFString(@"impactSound", @"Zap");
    for (NSString *name in FFNames()) {
        NSString *path = FFSoundPath(name);
        BOOL custom = [name isEqualToString:@"Custom"];
        NSDate *modified = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileModificationDate];
        if (self.sounds[name] && (!custom || [self.customDate isEqual:modified])) continue;
        if (custom) { [self.sounds removeObjectForKey:name]; self.customDate = modified; }
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (!data) continue;
        NSError *error = nil;
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:data error:&error];
        if (player && player.duration > 0 && player.duration <= 30) {
            [player prepareToPlay]; self.sounds[name] = player;
        } else NSLog(@"[FreeFallRootless] Cannot load %@: %@", name, error);
    }
    NSMutableArray *pool = [NSMutableArray array];
    for (NSString *name in FFNames()) {
        if (self.sounds[name] && FFBool([@"include_" stringByAppendingString:name], YES)) [pool addObject:name];
    }
    self.pool = pool;
    UIDevice *device = UIDevice.currentDevice;
    if (self.enabled && self.pocket && !device.proximityMonitoringEnabled) {
        device.proximityMonitoringEnabled = YES;
        self.ownsProximity = device.proximityMonitoringEnabled;
    } else if ((!self.enabled || !self.pocket) && self.ownsProximity) {
        device.proximityMonitoringEnabled = NO; self.ownsProximity = NO;
    }
    [self.motion stopAccelerometerUpdates];
    _state.falling = false; _state.lowSince = -1;
    if (!self.enabled) { [self.playing stop]; return; }
    if (!self.motion.accelerometerAvailable) return;
    self.motion.accelerometerUpdateInterval = .01;
    __weak typeof(self) weakSelf = self;
    [self.motion startAccelerometerUpdatesToQueue:NSOperationQueue.mainQueue withHandler:^(CMAccelerometerData *data, NSError *error) {
        FFRController *s = weakSelf;
        if (!s || !s.enabled || !data || error) return;
        CMAcceleration a = data.acceleration;
        double g = sqrt(a.x*a.x + a.y*a.y + a.z*a.z);
        BOOL blocked = s.pocket && UIDevice.currentDevice.proximityState;
        int event = FFStep(&s->_state, g, data.timestamp, s.fallThreshold, s.impactThreshold, s.pocket ? .06 : 0, blocked);
        if (event) [s handleEvent:event magnitude:g];
    }];
}
- (void)handleEvent:(int)event magnitude:(double)g {
    NSInteger hour = [NSCalendar.currentCalendar component:NSCalendarUnitHour fromDate:NSDate.date];
    BOOL quietNow = self.quiet && FFQuietHour((int)hour, (int)self.quietStart, (int)self.quietEnd);
    NSString *name = event == 2 ? self.impactSound : self.selected;
    if (event == 1 && self.shuffle) {
        NSArray *choices = FFChoices(self.pool, self.lastSound);
        if (choices.count) name = choices[arc4random_uniform((uint32_t)choices.count)];
        else name = nil; // Empty pool is silent; never play an excluded sound.
    }
    if (name && !self.sounds[name]) name = self.sounds[@"FreeFallScream"] ? @"FreeFallScream" : nil;
    BOOL audible = !quietNow && (event == 1 || self.impactEnabled) && name != nil;
    NSString *reason = quietNow ? @"Quiet hours" : (event == 2 && !self.impactEnabled ? @"Impact sound off" : (!name ? @"No selected audio" : @"Played"));
    if (audible) {
        [self.playing stop];
        self.playing = self.sounds[name]; self.playing.currentTime = 0;
        if (![self.playing play]) reason = @"Playback failed";
        if (event == 1) self.lastSound = name;
    }
    NSLog(@"[FreeFallRootless] %@: %@ (%@)", event == 1 ? @"Fall" : @"Impact", name ?: @"none", reason);
    if (self.logging) {
        [self.events addObject:@{@"date":NSDate.date, @"type":event == 1 ? @"Fall" : @"Impact", @"g":@(g), @"sound":name ?: @"None", @"status":reason}];
        while (self.events.count > 200) [self.events removeObjectAtIndex:0];
        if (event == 1) {
            NSString *day = FFDayKey();
            id previous = self.daily[day];
            self.daily[day] = @(([previous isKindOfClass:NSNumber.class] ? [previous unsignedIntegerValue] : 0) + 1);
            NSArray *days = [self.daily.allKeys sortedArrayUsingSelector:@selector(compare:)];
            for (NSUInteger i = 0; i + 90 < days.count; i++) [self.daily removeObjectForKey:days[i]];
        }
        NSArray *snapshot = [self.events copy];
        NSDictionary *counts = [self.daily copy];
        dispatch_async(self.logQueue, ^{
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:FFDataDirectory() withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:&error];
            if (![snapshot writeToFile:[FFDataDirectory() stringByAppendingPathComponent:@"Events.plist"] atomically:YES]) NSLog(@"[FreeFallRootless] Could not save local history: %@", error);
            if (![counts writeToFile:[FFDataDirectory() stringByAppendingPathComponent:@"Daily.plist"] atomically:YES]) NSLog(@"[FreeFallRootless] Could not save daily count");
        });
    }
}
@end
static FFRController *gController;
static void FFChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef info) {
    dispatch_async(dispatch_get_main_queue(), ^{ [gController reloadPreferences]; });
}
__attribute__((constructor)) static void FFInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        gController = [FFRController new];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, FFChanged, (__bridge CFStringRef)FFNotifyName, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    });
}
