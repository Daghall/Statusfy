//
//  SFYAppDelegate.m
//  Statusfy
//
//  Created by Paul Young on 4/16/14.
//  Copyright (c) 2014 Paul Young. All rights reserved.
//

#import "SFYAppDelegate.h"

static int const titleMaxLength = 42;

@interface SFYAppDelegate ()

@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) NSMenuItem *playPauseMenuItem;
@property (nonatomic, strong) NSMenuItem *trackInfoMenuItem;
@property (nonatomic, strong) NSMenuItem *playNextTrackMenuItem;
@property (nonatomic, strong) NSMenuItem *dockIconMenuItem;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property NSString *stateAndTrack;

@end

@implementation SFYAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification * __unused)aNotification
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.highlightMode = YES;

    self.menu = [[NSMenu alloc] initWithTitle:@""];

    self.playPauseMenuItem = [[NSMenuItem alloc] initWithTitle:[self determinePlayPauseMenuItemTitle] action:@selector(togglePlayState) keyEquivalent:@""];

    self.trackInfoMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@"" ];

    self.playNextTrackMenuItem = [[NSMenuItem alloc] initWithTitle:@"▶❘\tNext" action:@selector(playNextTrack) keyEquivalent:@"" ];

    NSMenuItem *copySpotifyLinkMenuItem = [[NSMenuItem alloc] initWithTitle:@"Copy Spotify Link" action:@selector(copySpotifyLinkToClipboard) keyEquivalent:@"" ];

    [self.menu addItem:self.trackInfoMenuItem];
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItem:self.playPauseMenuItem];
    [self.menu addItem:self.playNextTrackMenuItem];
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItem:copySpotifyLinkMenuItem];
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItemWithTitle:NSLocalizedString(@"Quit", nil) action:@selector(quit) keyEquivalent:@"q"];

    [self.statusItem setMenu:self.menu];

    [self setStatusItemTitle];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setStatusItemTitle) userInfo:nil repeats:YES];
}

#pragma mark - Setting title text

- (void)setStatusItemTitle
{
    NSString *trackName = [[self executeAppleScript:@"get name of current track"] stringValue];
    NSString *artistName = [[self executeAppleScript:@"get artist of current track"] stringValue];
    NSString *playerState = [self determinePlayerState];
    NSString *titleText = [NSString stringWithFormat:@"%@ %@ – %@", playerState, trackName, artistName];

    NSString *stateAndTrack = [NSString stringWithFormat:@"%@%@%@", playerState, trackName, artistName];

    if (trackName && artistName) {
        if (![self.stateAndTrack isEqualToString:stateAndTrack]) {
            self.stateAndTrack = stateAndTrack;
            [self setTrackInfoMenuItem:artistName :trackName];
            [self setPlayPauseMenuItemTitle];
        } else {
            return;
        }

        if (titleText.length > titleMaxLength) {
            titleText = [[titleText substringToIndex:titleMaxLength] stringByAppendingString:@"…"];
        }

        if (self.statusItem.menu != self.menu) {
            [self.statusItem setMenu:self.menu];
        }

        self.statusItem.image = nil;
        self.statusItem.title = titleText;
    } else {
        NSImage *image = [NSImage imageNamed:@"status_icon"];
        [image setTemplate:true];
        self.statusItem.image = image;
        self.statusItem.title = nil;
        [self showDisabledMenu];
    }
}

- (void)showDisabledMenu
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];

    [menu addItemWithTitle:NSLocalizedString(@"Spotify not running", nil) action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:NSLocalizedString(@"Quit", nil) action:@selector(quit) keyEquivalent:@"q"];

    [self.statusItem setMenu:menu];
}

#pragma mark - Setting title text

- (void)setTrackInfoMenuItem:(NSString *)artistName :(NSString *)trackName
{
    NSString *album = [[self executeAppleScript:@"get album of current track"] stringValue];
    NSString *formatString = [NSString stringWithFormat:@"Track\t%@\nArtist\t%@\nAlbum\t%@", trackName, artistName, album];

    self.trackInfoMenuItem.attributedTitle = [[NSAttributedString alloc] initWithString:formatString];
}

#pragma mark - Executing AppleScript

- (NSAppleEventDescriptor *)executeAppleScript:(NSString *)command
{
    command = [NSString stringWithFormat:@"if application \"Spotify\" is running then tell application \"Spotify\" to %@", command];
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:command];
    NSAppleEventDescriptor *eventDescriptor = [appleScript executeAndReturnError:NULL];
    return eventDescriptor;
}

- (void)togglePlayState
{
    [self executeAppleScript:@"playpause"];
    [self setPlayPauseMenuItemTitle];
}


- (void)playNextTrack
{
    [self executeAppleScript:@"play next track"];
}

- (void)setPlayPauseMenuItemTitle
{
    self.playPauseMenuItem.title = [self determinePlayPauseMenuItemTitle];
}

- (NSString *)determinePlayPauseMenuItemTitle
{
    return [[self determinePlayerState] isEqualToString:@"►"] ? NSLocalizedString(@"❚❚\tPause ", nil) : NSLocalizedString(@"►\tPlay", nil);
}

- (void)copySpotifyLinkToClipboard
{
    NSString *spotifyId = [[[self executeAppleScript:@"get spotify url of current track"] stringValue] substringFromIndex:14];
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"https://open.spotify.com/track/%@", spotifyId] forType:NSPasteboardTypeString];
}

- (NSString *)determinePlayerState
{
    NSString *playerStateText = nil;
    NSString *playerStateConstant = [[self executeAppleScript:@"get player state"] stringValue];

    if ([playerStateConstant isEqualToString:@"kPSP"]) {
        playerStateText = NSLocalizedString(@"►", nil);
    }
    else if ([playerStateConstant isEqualToString:@"kPSp"]) {
        playerStateText = NSLocalizedString(@"❚❚", nil);
    }
    else {
        playerStateText = NSLocalizedString(@"◼", nil);
    }

    return playerStateText;
}

#pragma mark - Quit

- (void)quit
{
    [[NSApplication sharedApplication] terminate:self];
}

@end
