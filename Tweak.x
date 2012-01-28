#import <Foundation/Foundation.h>
#import <SpringBoard/SpringBoard.h>
#import "BulletinBoard/BulletinBoard.h"

%config(generator=internal)

__attribute__((visibility("hidden")))
@interface MusicBannersProvider : NSObject<BBDataProvider> {
@private
	BBBulletinRequest *bulletin;
	NSString *nowPlayingTitle;
	NSString *nowPlayingArtist;
	NSString *nowPlayingAlbum;
}

@end

@implementation MusicBannersProvider

static MusicBannersProvider *sharedProvider;

+ (MusicBannersProvider *)sharedProvider
{
	return [[sharedProvider retain] autorelease];
}

- (id)init
{
	if ((self = [super init])) {
		sharedProvider = self;
	}
	return self;
}

- (void)dealloc
{
	sharedProvider = nil;
	[bulletin release];
	[nowPlayingTitle release];
	[nowPlayingArtist release];
	[nowPlayingAlbum release];
	[super dealloc];
}

- (NSString *)sectionIdentifier
{
	return @"com.apple.mobileipod";
}

- (NSArray *)sortDescriptors
{
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
}

- (NSArray *)bulletinsFilteredBy:(unsigned)by count:(unsigned)count lastCleared:(id)cleared
{
	return nil;
}

// Optional

- (NSString *)sectionDisplayName
{
	return @"Music";
}

- (BBSectionInfo *)defaultSectionInfo
{
	BBSectionInfo *sectionInfo = [BBSectionInfo defaultSectionInfoForType:0];
	sectionInfo.notificationCenterLimit = 10;
	sectionInfo.sectionID = [self sectionIdentifier];
	return sectionInfo;
}

- (void)dataProviderDidLoad
{
	BOOL hasChanges = NO;
	SBMediaController *mc = [%c(SBMediaController) sharedInstance];
	NSString *title = mc.nowPlayingTitle;
	if ((title != nowPlayingTitle) && ![title isEqualToString:nowPlayingTitle]) {
		[nowPlayingTitle release];
		nowPlayingTitle = [title copy];
		hasChanges = YES;
	}
	NSString *artist = mc.nowPlayingArtist;
	if ((artist != nowPlayingArtist) && ![artist isEqualToString:nowPlayingArtist]) {
		[nowPlayingArtist release];
		nowPlayingArtist = [artist copy];
		hasChanges = YES;
	}
	NSString *album = mc.nowPlayingAlbum;
	if ((album != nowPlayingArtist) && ![album isEqualToString:nowPlayingAlbum]) {
		[nowPlayingAlbum release];
		nowPlayingAlbum = [album copy];
		hasChanges = YES;
	}
	if (hasChanges) {
		BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.apple.mobileipod/banner");
		if (!bulletin) {
			bulletin = [[BBBulletinRequest alloc] init];
			bulletin.sectionID = @"com.apple.mobileipod/banner";
			bulletin.defaultAction = [BBAction actionWithLaunchURL:[NSURL URLWithString:@"music://"] callblock:nil];
			bulletin.bulletinID = @"com.apple.mobileipod/banner";
			bulletin.publisherBulletinID = @"com.apple.mobileipod/banner";
			bulletin.recordID = @"com.apple.mobileipod/banner";
			bulletin.showsUnreadIndicator = NO;
		}
		bulletin.title = title;
		bulletin.subtitle = artist;
		bulletin.message = album;
		NSDate *date = [NSDate date];
		bulletin.date = date;
		bulletin.lastInterruptDate = date;
		BBDataProviderAddBulletin(self, bulletin);
	}
}

@end

%hook BBServer

- (void)_loadAllDataProviderPluginBundles
{
	%orig;
	MusicBannersProvider *p = [[MusicBannersProvider alloc] init];
	[self _addDataProvider:p sortSectionsNow:YES];
	[p release];
}

%end

%hook UIImage

+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale
{
	if ((format == 10) && [bundleIdentifier isEqualToString:@"com.apple.mobileipod"]) {
		// Try nc_icon.png, but fallback to generating an icon based on Icon-Small.png
		NSBundle *bundle = [NSBundle bundleWithPath:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"/Applications/Music~ipad.app" : @"/Applications/Music~iphone.app"];
		return [UIImage imageNamed:@"nc_icon.png" inBundle:bundle] ?: [[UIImage imageNamed:@"Icon-Small.png" inBundle:bundle] _applicationIconImageForFormat:format precomposed:YES scale:scale];
	}
	return %orig;
}

%end

%hook SBMediaController

- (void)_nowPlayingInfoChanged
{
	%orig;
	[sharedProvider dataProviderDidLoad];
}

- (void)setNowPlayingInfo:(id)newValue
{
	%orig;
	[sharedProvider dataProviderDidLoad];
}

%end
