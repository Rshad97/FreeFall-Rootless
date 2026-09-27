#import "FFScreens.h"
#import "FFAudioImport.h"
#import "../FFShared.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>

static UIStackView *FFStack(UIViewController *vc) {
    vc.view.backgroundColor = UIColor.systemBackgroundColor;
    UIScrollView *scroll = [UIScrollView new]; scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [vc.view addSubview:scroll];
    UIStackView *stack = [UIStackView new]; stack.axis = UILayoutConstraintAxisVertical; stack.spacing = 18;
    stack.translatesAutoresizingMaskIntoConstraints = NO; [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:vc.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:vc.view.safeAreaLayoutGuide.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:20],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-20],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40]]];
    return stack;
}
static UILabel *FFLabel(NSString *text) {
    UILabel *label = [UILabel new]; label.text = text; label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody]; label.adjustsFontForContentSizeCategory = YES;
    return label;
}
static UIButton *FFButton(NSString *title, id target, SEL action) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem]; [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.numberOfLines = 0; [b addTarget:target action:action forControlEvents:UIControlEventTouchUpInside]; return b;
}

@interface FFCalibrationController ()
@property (nonatomic, strong) CMMotionManager *motion;
@property (nonatomic, strong) UILabel *reading, *values;
@property (nonatomic, strong) UISlider *fall, *impact;
@end
@implementation FFCalibrationController
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Live Calibration";
    UIStackView *s = FFStack(self);
    [s addArrangedSubview:FFLabel(@"Keep the phone in your hand. Resting is about 1 g; free fall approaches 0 g. Do not drop your phone. This is manual tuning, not an automatic guarantee of detection.")];
    self.reading = FFLabel(@"Waiting for motion…"); [s addArrangedSubview:self.reading];
    self.values = FFLabel(@""); [s addArrangedSubview:self.values];
    self.fall = [UISlider new]; self.fall.minimumValue = .01; self.fall.maximumValue = .25;
    self.fall.value = FFClamp(FFNumber(@"fallingSensitivity", .04), .01, .25, .04);
    self.fall.accessibilityLabel = @"Free fall threshold";
    self.impact = [UISlider new]; self.impact.minimumValue = 2; self.impact.maximumValue = 8;
    self.impact.value = FFClamp(FFNumber(@"stoppingSensitivity", 6), 2, 8, 6);
    self.impact.accessibilityLabel = @"Impact threshold";
    [s addArrangedSubview:self.fall]; [s addArrangedSubview:self.impact];
    [self.fall addTarget:self action:@selector(updateLabels) forControlEvents:UIControlEventValueChanged];
    [self.impact addTarget:self action:@selector(updateLabels) forControlEvents:UIControlEventValueChanged];
    [s addArrangedSubview:FFButton(@"Save thresholds", self, @selector(save))];
    [self updateLabels]; self.motion = [CMMotionManager new];
}
- (void)updateLabels { self.values.text = [NSString stringWithFormat:@"Free fall: %.3f g (higher is more sensitive)\nImpact: %.2f g", self.fall.value, self.impact.value]; }
- (void)save { FFSave(@"fallingSensitivity", @(self.fall.value)); FFSave(@"stoppingSensitivity", @(self.impact.value)); self.values.text = [self.values.text stringByAppendingString:@"\nSaved."]; }
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.motion.accelerometerAvailable) { self.reading.text = @"Accelerometer unavailable."; return; }
    self.motion.accelerometerUpdateInterval = .1;
    __weak typeof(self) weakSelf = self;
    [self.motion startAccelerometerUpdatesToQueue:NSOperationQueue.mainQueue withHandler:^(CMAccelerometerData *d, NSError *error) {
        if (error || !d) { weakSelf.reading.text = @"Motion data unavailable."; return; }
        CMAcceleration a = d.acceleration;
        weakSelf.reading.text = [NSString stringWithFormat:@"Live: %.3f g\nX %.2f · Y %.2f · Z %.2f", sqrt(a.x*a.x+a.y*a.y+a.z*a.z), a.x, a.y, a.z];
    }];
}
- (void)viewWillDisappear:(BOOL)animated { [self.motion stopAccelerometerUpdates]; [super viewWillDisappear:animated]; }
- (void)dealloc { [_motion stopAccelerometerUpdates]; }
@end

@implementation FFHistoryController
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Local Event History";
    UIStackView *s = FFStack(self);
    NSArray *events = [NSArray arrayWithContentsOfFile:[FFDataDirectory() stringByAppendingPathComponent:@"Events.plist"]];
    NSMutableString *body = [NSMutableString string];
    NSDictionary *counts = [NSDictionary dictionaryWithContentsOfFile:[FFDataDirectory() stringByAppendingPathComponent:@"Daily.plist"]];
    id count = counts[FFDayKey()];
    NSUInteger today = [count isKindOfClass:NSNumber.class] ? [count unsignedIntegerValue] : 0;
    NSDateFormatter *fmt = [NSDateFormatter new]; fmt.dateStyle = NSDateFormatterShortStyle; fmt.timeStyle = NSDateFormatterMediumStyle;
    for (id item in events.reverseObjectEnumerator) {
        if (![item isKindOfClass:NSDictionary.class] || ![item[@"date"] isKindOfClass:NSDate.class]) continue;
        [body appendFormat:@"%@ — %@\n%@ · %@\n\n", [fmt stringFromDate:item[@"date"]], item[@"type"] ?: @"Event", item[@"sound"] ?: @"None", item[@"status"] ?: @""];
    }
    [s addArrangedSubview:FFLabel([NSString stringWithFormat:@"Today's recorded falls: %lu\nLast 200 detailed events; daily totals kept for 90 days. Counts include only events detected while logging is enabled. Logging is %@. No data is uploaded.", (unsigned long)today, FFBool(@"eventLogging", NO) ? @"on" : @"off"])];
    [s addArrangedSubview:FFLabel(body.length ? body : @"No recorded events. Enable Event Logging to record future detections.")];
}
@end

@interface FFImportController ()
@property (nonatomic, strong) UITextField *start, *length;
@property (nonatomic, strong) UILabel *status;
@property (nonatomic, strong) AVAudioPlayer *preview;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic) BOOL importing;
@end
@implementation FFImportController
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Trim Custom Sound";
    UIStackView *s = FFStack(self);
    [s addArrangedSubview:FFLabel(@"One custom slot. Choose a start time and 0.2–10 seconds of audio. Preview before saving. A successful import replaces your previous custom sound; a failed import keeps it.")];
    self.start = [UITextField new]; self.start.borderStyle = UITextBorderStyleRoundedRect; self.start.text = @"0"; self.start.keyboardType = UIKeyboardTypeDecimalPad; self.start.accessibilityLabel = @"Start in seconds";
    self.length = [UITextField new]; self.length.borderStyle = UITextBorderStyleRoundedRect; self.length.text = @"2"; self.length.keyboardType = UIKeyboardTypeDecimalPad; self.length.accessibilityLabel = @"Duration in seconds";
    [s addArrangedSubview:FFLabel(@"Start (seconds)")]; [s addArrangedSubview:self.start];
    [s addArrangedSubview:FFLabel(@"Duration (seconds)")]; [s addArrangedSubview:self.length];
    [s addArrangedSubview:FFButton(@"Preview trimmed section", self, @selector(previewTrim))];
    self.saveButton = FFButton(@"Convert and save", self, @selector(saveTrim)); [s addArrangedSubview:self.saveButton];
    self.status = FFLabel(@"MP3, M4A and WAV supported when decodable by iOS. DRM-protected or unsupported files are rejected."); [s addArrangedSubview:self.status];
}
- (BOOL)start:(double *)start duration:(double *)duration {
    NSNumberFormatter *f = [NSNumberFormatter new]; f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *a = [f numberFromString:self.start.text], *b = [f numberFromString:self.length.text];
    *start = a.doubleValue; *duration = b.doubleValue;
    if (!a || !b || !isfinite(*start) || !isfinite(*duration) || *start < 0 || *duration < .2 || *duration > 10) {
        self.status.text = @"Enter a valid start (0 or greater) and duration (0.2–10 seconds)."; return NO;
    }
    return YES;
}
- (void)previewTrim {
    if (self.importing) return;
    double start, duration; if (![self start:&start duration:&duration]) return;
    [self.view endEditing:YES]; [self.preview stop];
    BOOL access = [self.sourceURL startAccessingSecurityScopedResource]; NSError *error = nil;
    self.preview = [[AVAudioPlayer alloc] initWithContentsOfURL:self.sourceURL error:&error];
    if (access) [self.sourceURL stopAccessingSecurityScopedResource];
    if (!self.preview || start + duration > self.preview.duration + .001) { self.status.text = @"Selected section exceeds the file or the audio cannot be decoded."; return; }
    self.preview.currentTime = start;
    if (![self.preview play]) { self.status.text = @"Could not play this file."; return; }
    AVAudioPlayer *player = self.preview;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [player stop]; });
}
- (void)saveTrim {
    if (self.importing) return;
    double start, duration; if (![self start:&start duration:&duration]) return;
    [self.view endEditing:YES]; [self.preview stop]; self.importing = YES; self.saveButton.enabled = NO;
    self.status.text = @"Converting locally…"; NSURL *url = self.sourceURL;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *failure = nil; NSError *error = nil;
        BOOL access = [url startAccessingSecurityScopedResource];
        NSData *data = FFTrimAudio(url, start, duration, &error);
        if (access) [url stopAccessingSecurityScopedResource];
        if (!data) failure = error.localizedDescription ?: @"Could not convert this audio.";
        else if (![[NSFileManager defaultManager] createDirectoryAtPath:FFDataDirectory() withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:&error] ||
                 ![data writeToFile:FFSoundPath(@"Custom") options:NSDataWritingAtomic error:&error]) {
            failure = @"Could not save the sound. Your previous sound was kept.";
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.importing = NO; self.saveButton.enabled = YES;
            if (failure) self.status.text = failure;
            else { FFSave(@"selectedSound", @"Custom"); self.status.text = @"Saved and selected Custom Sound. Shuffle still uses your selected pool when enabled."; }
        });
    });
}
- (void)viewWillDisappear:(BOOL)animated { [self.preview stop]; [super viewWillDisappear:animated]; }
@end
