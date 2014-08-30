//
//  AMAppDelegate.m
//  Amethyst
//
//  Created by Ian on 5/14/13.
//  Copyright (c) 2013 Ian Ynda-Hummel. All rights reserved.
//

#import "AMAppDelegate.h"

#import "AMConfiguration.h"
#import "AMHotKeyManager.h"
#import "AMPreferencesWindowController.h"
#import "AMWindowManager.h"

#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <CoreServices/CoreServices.h>
#import <IYLoginItem/NSBundle+LoginItem.h>
#import <Sparkle/SUUpdater.h>

@interface AMAppDelegate ()
@property (nonatomic, assign) IBOutlet AMPreferencesWindowController *preferencesWindowController;

@property (nonatomic, strong) AMWindowManager *windowManager;
@property (nonatomic, strong) AMHotKeyManager *hotKeyManager;

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) IBOutlet NSMenu *statusItemMenu;
@property (nonatomic, strong) IBOutlet NSMenuItem *startAtLoginMenuItem;

- (IBAction)toggleStartAtLogin:(id)sender;
- (IBAction)relaunch:(id)sender;
@end

@implementation AMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [DDLog addLogger:DDASLLogger.sharedInstance];
    [DDLog addLogger:DDTTYLogger.sharedInstance];

    [AMConfiguration.sharedConfiguration loadConfiguration];
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];

    if ([[AMConfiguration sharedConfiguration] useCanaryBuild]) {
        NSString *canaryAppcastURLString = [[NSBundle mainBundle] infoDictionary][@"SUCanaryFeedURL"];
        [[SUUpdater sharedUpdater] setFeedURL:[NSURL URLWithString:canaryAppcastURLString]];
    }

    RAC(self, statusItem.image) = [RACObserve(AMConfiguration.sharedConfiguration, tilingEnabled) map:^id(NSNumber *tilingEnabled) {
        if (tilingEnabled.boolValue) {
            if ([osxMode isEqualToString:@"Dark"]) {
                return [NSImage imageNamed:@"icon-statusitem-darkmode"];
            } else {
                return [NSImage imageNamed:@"icon-statusitem"];
            }
            
        }
        return [NSImage imageNamed:@"icon-statusitem-disabled"];
    }];

    self.windowManager = [[AMWindowManager alloc] init];
    self.hotKeyManager = [[AMHotKeyManager alloc] init];

    [AMConfiguration.sharedConfiguration setUpWithHotKeyManager:self.hotKeyManager windowManager:self.windowManager];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([osxMode isEqualToString:@"Dark"]) {
        self.statusItem.image = [NSImage imageNamed:@"icon-statusitem-darkmode"];
    } else {
        self.statusItem.image = [NSImage imageNamed:@"icon-statusitem"];
    }
    self.statusItem.menu = self.statusItemMenu;
    self.statusItem.highlightMode = YES;

    self.startAtLoginMenuItem.state = (NSBundle.mainBundle.isLoginItem ? NSOnState : NSOffState);
}

- (IBAction)toggleStartAtLogin:(id)sender {
    if (self.startAtLoginMenuItem.state == NSOffState) {
        [NSBundle.mainBundle addToLoginItems];
    } else {
        [NSBundle.mainBundle removeFromLoginItems];
    }
    self.startAtLoginMenuItem.state = (NSBundle.mainBundle.isLoginItem ? NSOnState : NSOffState);
}

- (IBAction)relaunch:(id)sender {
    NSString *myPath = [NSString stringWithFormat:@"%s", [[[NSBundle mainBundle] executablePath] fileSystemRepresentation]];
    [NSTask launchedTaskWithLaunchPath:myPath arguments:@[]];
    [NSApp terminate:self];
}

@end
