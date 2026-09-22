include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = FreeFallRootlessPrefs
FreeFallRootlessPrefs_FILES = FFRRootListController.m
FreeFallRootlessPrefs_FRAMEWORKS = UIKit
FreeFallRootlessPrefs_INSTALL_PATH = /Library/PreferenceBundles
FreeFallRootlessPrefs_CFLAGS = -fobjc-arc

# Preferences is a private framework and is not present in modern public SDKs.
# Resolve PSListController dynamically when this bundle is loaded by Preferences.
FreeFallRootlessPrefs_LDFLAGS += -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
