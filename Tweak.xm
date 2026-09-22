#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>
#import <math.h>
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
@property (nonatomic, assign) SystemSoundID screamSound;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL inFall;
@property (nonatomic, assign) double fallSensitivity;
@property (nonatomic, assign) double impactSensitivity;
@property (nonatomic, assign) CFAbsoluteTime lastTrigger;
- (void)reloadPreferences;
- (void)startMonitoring;
- (void)stopMonitoring;
@end

@implementation FFRController

- (instancetype)init {
    self = [super init];
    if (self) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionQueue = [[NSOperationQueue alloc] init];
        _motionQueue.maxConcurrentOperationCount = 1;
        _screamSound = 0;
        _lastTrigger = 0;
        [self reloadPreferences];
    }
    return self;
}

- (void)dealloc {
    [self stopMonitoring];
    if (_screamSound != 0) {
        AudioServicesDisposeSystemSoundID(_screamSound);
        _screamSound = 0;
    }
}

- (void)reloadPreferences {
    CFPreferencesAppSynchronize(FFDomain);

    self.enabled = FFBoolForKey(CFSTR("enabled"), YES);
    self.fallSensitivity = FFDoubleForKey(CFSTR("fallingSensitivity"), 0.04);
    self.impactSensitivity = FFDoubleForKey(CFSTR("stoppingSensitivity"), 6.0);

    if (self.screamSound != 0) {
        AudioServicesDisposeSystemSoundID(self.screamSound);
        self.screamSound = 0;
    }

    NSString *soundPath = [ROOT_PATH_NS(@"/Library/FreeFallRootless") stringByAppendingPathComponent:@"FreeFallScream.wav"];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:soundPath]) {
        OSStatus soundStatus = AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &_screamSound);
        if (soundStatus != kAudioServicesNoError) {
            NSLog(@"[FreeFallRootless] Failed to create SystemSoundID (%d) for %@", (int)soundStatus, soundPath);
            _screamSound = 0;
        } else {
            NSLog(@"[FreeFallRootless] Loaded fall sound: %@", soundPath);
        }
    }

    [self stopMonitoring];
    if (self.enabled) {
        [self startMonitoring];
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
            if (selfRef.screamSound != 0) {
                AudioServicesPlaySystemSound(selfRef.screamSound);
            }
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
