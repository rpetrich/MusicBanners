BUNDLE_NAME = MusicBanners
MusicBanners_FILES = Tweak.x
MusicBanners_FRAMEWORKS = UIKit QuartzCore CoreGraphics
MusicBanners_PRIVATE_FRAMEWORKS = BulletinBoard
MusicBanners_INSTALL_PATH = /Library/WeeLoader/BulletinBoardPlugins

THEOS_IPHONEOS_DEPLOYMENT_VERSION = 5.0

include framework/makefiles/common.mk
include framework/makefiles/bundle.mk
