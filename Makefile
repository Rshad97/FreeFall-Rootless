ARCHS = arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FreeFallRootless
FreeFallRootless_FILES = Tweak.xm
FreeFallRootless_FRAMEWORKS = Foundation CoreMotion AudioToolbox
FreeFallRootless_CFLAGS = -fobjc-arc -fblocks

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += freefallprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

.PHONY: wilhelm-audio
wilhelm-audio:
	@./scripts/fetch-wilhelm-scream.sh
