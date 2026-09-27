#import <Preferences/PSListController.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <AVFoundation/AVFoundation.h>
#import "../FFShared.h"
#import "FFScreens.h"

@interface FFRRootListController : PSListController <UIDocumentPickerDelegate>
@property (nonatomic, strong) AVAudioPlayer *previewPlayer;
@property (nonatomic, copy) NSString *previousPreview;
@end
@implementation FFRRootListController
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    return _specifiers;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; [self reloadSpecifiers];
}
- (void)message:(NSString *)message {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"FreeFall" message:message preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)playName:(NSString *)name {
    if (![FFNames() containsObject:name]) name = @"FreeFallScream";
    [self.previewPlayer stop]; NSError *error = nil;
    self.previewPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:FFSoundPath(name)] error:&error];
    if (!self.previewPlayer || ![self.previewPlayer play]) [self message:@"Sound unavailable. Import Custom Sound first if selected. Also check device volume and silent mode."];
}
- (void)previewSound { [self playName:FFString(@"selectedSound", @"FreeFallScream")]; }
- (void)previewImpact { [self playName:FFString(@"impactSound", @"Zap")]; }
- (void)previewShuffle {
    NSMutableArray *pool = [NSMutableArray array];
    for (NSString *n in FFNames()) {
        if (FFBool([@"include_" stringByAppendingString:n], YES) && [[NSFileManager defaultManager] fileExistsAtPath:FFSoundPath(n)]) [pool addObject:n];
    }
    NSArray *choices = FFChoices(pool, self.previousPreview);
    if (!choices.count) { [self message:@"No available sounds selected for Shuffle. Enable at least one sound below."]; return; }
    NSString *name = choices[arc4random_uniform((uint32_t)choices.count)];
    self.previousPreview = name; [self playName:name];
}
- (void)importSound {
    [self.previewPlayer stop];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeAudio] asCopy:YES];
    picker.delegate = self; picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (!urls.count) return;
    FFImportController *vc = [FFImportController new]; vc.sourceURL = urls.firstObject;
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)showCalibration { [self.navigationController pushViewController:[FFCalibrationController new] animated:YES]; }
- (void)showHistory { [self.navigationController pushViewController:[FFHistoryController new] animated:YES]; }
- (void)viewWillDisappear:(BOOL)animated { [self.previewPlayer stop]; [super viewWillDisappear:animated]; }
@end
