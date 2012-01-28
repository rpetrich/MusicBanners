TWEAK_NAME = MusicBanners
MusicBanners_FILES = Tweak.x
MusicBanners_FRAMEWORKS = UIKit QuartzCore
MusicBanners_PRIVATE_FRAMEWORKS = BulletinBoard
MusicBanners_LDFLAGS = -lactivator

THEOS_IPHONEOS_DEPLOYMENT_VERSION = 5.0

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
