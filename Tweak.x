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
	UIImage *nowPlayingImage;
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
	[nowPlayingImage release];
	[super dealloc];
}

- (NSString *)sectionIdentifier
{
	return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? @"com.apple.Music" : @"com.apple.mobileipod";
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
		NSData *data = [[mc _nowPlayingInfo] objectForKey:@"artworkData"];
		if (data) {
			UIImage *image = [[UIImage alloc] initWithData:data];
			[nowPlayingImage release];
			nowPlayingImage = image;
		} else {
			[nowPlayingImage release];
			nowPlayingImage = nil;
		}
		BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.apple.mobileipod/banner");
		if ([artist length] && [title length]) {
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
			bulletin.subtitle = album;
			bulletin.message = artist;
			NSDate *date = [NSDate date];
			bulletin.date = date;
			bulletin.lastInterruptDate = date;
			bulletin.primaryAttachmentType = nowPlayingImage ? 1 : 0;
			BBDataProviderAddBulletin(self, bulletin);
		}
	}
}

- (CGFloat)attachmentAspectRatioForRecordID:(NSString *)recordID
{
	if (nowPlayingImage) {
		CGSize size = nowPlayingImage.size;
		if (size.height > 0.0f)
			return size.width / size.height;
	}
	return 1.0f;
}

- (NSData *)attachmentPNGDataForRecordID:(NSString *)recordID sizeConstraints:(BBThumbnailSizeConstraints *)constraints
{
	if (constraints && nowPlayingImage) {
		CGSize imageSize = nowPlayingImage.size;
		CGSize maxSize;
		maxSize.width = constraints.fixedWidth;
		maxSize.height = constraints.fixedHeight;
		// Doesn't properly check constraintType, but this is good enough for now
		if (maxSize.width > 0.0f) {
			if (maxSize.height > 0.0f) {
				if (imageSize.width *maxSize.height > maxSize.width * imageSize.height)
					maxSize.height = maxSize.width * imageSize.height /  imageSize.width;
				else
					maxSize.width = maxSize.height * imageSize.width / imageSize.height;
			} else {
				maxSize.height = maxSize.width * imageSize.height /  imageSize.width;
			}
		} else {
			if (maxSize.height > 0.0f) {
				maxSize.width = maxSize.height * imageSize.width / imageSize.height;
			} else {
				// Fit image in 0x0? Wat.
				return nil;
			}
		}
		UIGraphicsBeginImageContextWithOptions(maxSize, NO, constraints.thumbnailScale);
		CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationDefault);
		[nowPlayingImage drawInRect:(CGRect){{0.0f,0.0f},maxSize}];
		UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		return UIImagePNGRepresentation(result);
	}
	return nil;
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
	%log;
	BOOL isPad;
	if ((format == 10) && [bundleIdentifier isEqualToString:(isPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? @"com.apple.Music" : @"com.apple.mobileipod"]) {
		// Try nc_icon.png, but fallback to generating an icon based on Icon-Small.png
		NSBundle *bundle = [NSBundle bundleWithPath:isPad ? @"/Applications/Music~ipad.app" : @"/Applications/Music~iphone.app"];
		return [UIImage imageNamed:@"nc_icon.png" inBundle:bundle] ?: [isPad ? [UIImage imageNamed:@"iPod.png" inBundle:[NSBundle bundleWithPath:@"/Applications/Preferences.app"]] : [UIImage imageNamed:@"Icon-Small.png" inBundle:bundle] _applicationIconImageForFormat:format precomposed:YES scale:scale];
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
