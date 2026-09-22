#import <Preferences/PSListController.h>

@interface FFRRootListController : PSListController
@end

@implementation FFRRootListController
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}
@end
