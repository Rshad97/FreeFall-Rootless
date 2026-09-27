#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>
#import <math.h>
#import <stdlib.h>
#import <rootless.h>

static CFStringRef const FFDomain = CFSTR("com.rashad.freefallrootless");
static CFStringRef const FFReloadNotification = CFSTR("com.rashad.freefallrootless/ReloadPrefs");

static BOOL FFBoolForKey(CFStringRef key, BOOL fallback) {
    Boolean exists = false;
    Boolean value = CFPreferencesGetAppBooleanValue(key, FFDomain, &exists);
    return exists ? (BOOL)value : fallback;
}

static double FFDoubleForKey(CFStringRef key, double fallback) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(key, FFDomain);
    if (!value) return fallback;

    double result = fallback;
    if (CFGetTypeID(value) == CFNumberGetTypeID()) {
        CFNumberGetValue((CFNumberRef)value, kCFNumberDoubleType, &result);
    }
    CFRelease(value);
    return result;
}

@interface FFRController : NSObject
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *motionQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *sounds;
@property (nonatomic, copy) NSString *selectedSound;
@property (nonatomic, copy) NSString *lastSound;
@property (nonatomic, assign) BOOL shuffle;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL inFall;
@property (nonatomic, assign) double fallSensitivity;
@property (nonatomic, assign) double impactSensitivity;
@property (nonatomic, assign) CFAbsoluteTime lastTrigger;
- (void)reloadPreferences;
- (void)playFallSound;
- (void)startMonitoring;
- (void)stopMonitoring;
@end

@implementation FFRController

- (instancetype)init {
    self = [super init];
    if (self) {
        _motionManager = [[CMMotionManager alloc] init];
        // Serialize motion callbacks, preference reloads and sound playback.
        _motionQueue = [NSOperationQueue mainQueue];
        _sounds = [NSMutableDictionary dictionary];
        _lastTrigger = 0;
        [self reloadPreferences];
    }
    return self;
}

- (void)dealloc {
    [self stopMonitoring];
    for (NSNumber *sound in _sounds.allValues) {
        AudioServicesDisposeSystemSoundID(sound.unsignedIntValue);
    }
}

- (void)reloadPreferences {
    CFPreferencesAppSynchronize(FFDomain);

    self.enabled = FFBoolForKey(CFSTR("enabled"), YES);
    self.fallSensitivity = FFDoubleForKey(CFSTR("fallingSensitivity"), 0.04);
    self.impactSensitivity = FFDoubleForKey(CFSTR("stoppingSensitivity"), 6.0);

    self.shuffle = FFBoolForKey(CFSTR("shuffle"), NO);
    CFPropertyListRef selected = CFPreferencesCopyAppValue(CFSTR("selectedSound"), FFDomain);
    self.selectedSound = (selected && CFGetTypeID(selected) == CFStringGetTypeID())
        ? [(__bridge NSString *)selected copy] : @"FreeFallScream";
    if (selected) CFRelease(selected);

    // Keep IDs alive during live preference changes, including active playback.
    // Only allow known bundled filenames, never a user-supplied path.
    NSArray<NSString *> *names = @[@"FreeFallScream", @"RashadDrop", @"Laser", @"Phaser",
                                  @"PowerDown", @"Zap", @"Alarm"];
    for (NSString *name in names) {
        if (self.sounds[name]) continue;
        NSString *path = [ROOT_PATH_NS(@"/Library/FreeFallRootless")
            stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"wav"]];
        SystemSoundID sound = 0;
        OSStatus status = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path], &sound);
        if (status == kAudioServicesNoError && sound != 0) {
            self.sounds[name] = @(sound);
            NSLog(@"[FreeFallRootless] Loaded fall sound: %@", name);
        } else {
            NSLog(@"[FreeFallRootless] Sound unavailable: %@ (%d)", name, (int)status);
        }
    }
    if (!self.sounds[self.selectedSound]) self.selectedSound = @"FreeFallScream";

    [self stopMonitoring];
    if (self.enabled) {
        [self startMonitoring];
    }
}

- (void)playFallSound {
    NSString *name = self.selectedSound;
    if (self.shuffle) {
        NSMutableArray<NSString *> *choices = [self.sounds.allKeys mutableCopy];
        // Avoid consecutive repeats when more than one playable sound exists.
        if (choices.count > 1 && self.lastSound) [choices removeObject:self.lastSound];
        if (choices.count) name = choices[arc4random_uniform((uint32_t)choices.count)];
    }
    NSNumber *sound = self.sounds[name] ?: self.sounds[@"FreeFallScream"] ?: self.sounds.allValues.firstObject;
    if (sound) {
        self.lastSound = name;
        AudioServicesPlaySystemSound(sound.unsignedIntValue);
        NSLog(@"[FreeFallRootless] Playing %@ (Shuffle %@)", name, self.shuffle ? @"on" : @"off");
    }
}

- (void)startMonitoring {
    if (!self.motionManager.accelerometerAvailable || self.motionManager.accelerometerActive) {
        return;
    }

    self.motionManager.accelerometerUpdateInterval = 0.01;
    __weak typeof(self) weakSelf = self;
    [self.motionManager startAccelerometerUpdatesToQueue:self.motionQueue
                                              withHandler:^(CMAccelerometerData *data, NSError *error) {
        FFRController *selfRef = weakSelf;
        if (!selfRef || !selfRef.enabled || error || !data) return;

        CMAcceleration a = data.acceleration;
        double magnitude = sqrt((a.x * a.x) + (a.y * a.y) + (a.z * a.z));
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

        if (!selfRef.inFall && magnitude < selfRef.fallSensitivity && (now - selfRef.lastTrigger) > 1.0) {
            selfRef.inFall = YES;
            selfRef.lastTrigger = now;
            [selfRef playFallSound];
            return;
        }

        if (selfRef.inFall && (magnitude > selfRef.impactSensitivity || (now - selfRef.lastTrigger) > 2.5)) {
            selfRef.inFall = NO;
        }
    }];
}

- (void)stopMonitoring {
    if (self.motionManager.accelerometerActive) {
        [self.motionManager stopAccelerometerUpdates];
    }
    self.inFall = NO;
}

@end

static FFRController *gFreeFallController = nil;

static void FFPreferencesChanged(CFNotificationCenterRef center,
                                 void *observer,
                                 CFStringRef name,
                                 const void *object,
                                 CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [gFreeFallController reloadPreferences];
    });
}

__attribute__((constructor)) static void FFInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        gFreeFallController = [[FFRController alloc] init];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        FFPreferencesChanged,
                                        FFReloadNotification,
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    });
}
