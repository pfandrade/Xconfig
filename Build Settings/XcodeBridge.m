//
//  XcodeBridge.m
//  Build Settings
//
//  Created by Paulo F. Andrade on 07/02/2020.
//  Copyright © 2020 Paulo F. Andrade. All rights reserved.
//

#import "Xcode.h"
#import "XcodeBridge.h"

#define XCODE_BUNDLE_ID @"com.apple.dt.Xcode"

NSString *const XcodeBridgeErrorDomain = @"com.outercorner.XcodeBridge.ErrorDomain";

@interface XCDConfiguration ()
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSDictionary<NSString *, NSString *> *buildSettings;
@property (nonatomic, weak, readwrite) XCDTarget *target;
@end

@interface XCDTarget ()
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSArray<XCDConfiguration *> *configurations;
@property (nonatomic, weak, readwrite) XCDProject *project;
@end

@interface XCDProject ()
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSArray<XCDTarget *> *targets;
@end


@implementation XcodeBridge

+ (void)reloadBuildSettings:(void(^)(NSArray<XCDProject *> * _Nullable, NSError * _Nullable))completionBlock
{
    XcodeApplication *xcode = [SBApplication applicationWithBundleIdentifier:XCODE_BUNDLE_ID];
    
    if (![xcode isRunning]) {
        return [self failWithCode:notRunning block:completionBlock];
    }
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSAppleEventDescriptor *targetAppEventDescriptor = [NSAppleEventDescriptor descriptorWithBundleIdentifier:XCODE_BUNDLE_ID];
        OSStatus status = AEDeterminePermissionToAutomateTarget(targetAppEventDescriptor.aeDesc, kCoreEventClass, typeWildCard, YES);
                
        if(status != noErr) {
            return [self failWithCode:notAuthorized block:completionBlock];
        }
       
        NSMutableArray<XcodeProject *> *sbProjects = [NSMutableArray array];
        [[xcode workspaceDocuments] enumerateObjectsUsingBlock:^(XcodeWorkspaceDocument * _Nonnull ws, NSUInteger idx, BOOL * _Nonnull stop) {
            [sbProjects addObjectsFromArray:[ws projects] ?: @[]];
        }];
        
        
        NSMutableArray<XCDProject *> *projects = [[NSMutableArray alloc] init];
        
        [sbProjects enumerateObjectsUsingBlock:^(XcodeProject * _Nonnull sbProject, NSUInteger idx, BOOL * _Nonnull stop) {
            XCDProject *project = [XCDProject new];
            project.name = sbProject.name;
            NSMutableArray<XCDTarget *> *targets = [[NSMutableArray alloc] init];
            NSLog(@"Parsing project %@", project.name);
            [[sbProject targets] enumerateObjectsUsingBlock:^(XcodeTarget * _Nonnull sbTarget, NSUInteger idx, BOOL * _Nonnull stop) {
                XCDTarget *target = [XCDTarget new];
                target.name = sbTarget.name;
                NSLog(@"Parsing target %@", target.name);
                NSMutableArray<XCDConfiguration *> *configurations = [[NSMutableArray alloc] init];
                [[sbTarget buildConfigurations] enumerateObjectsUsingBlock:^(XcodeBuildConfiguration * _Nonnull sbConfig, NSUInteger idx, BOOL * _Nonnull stop) {
                    XCDConfiguration *configuration = [XCDConfiguration new];
                    configuration.name = sbConfig.name;
                    NSLog(@"Parsing configuration %@", configuration.name);
                    // Using arrayByApplyingSelector: is much faster than iterating the build settings
                    NSArray<NSString *> *settingNames = [[sbConfig resolvedBuildSettings] arrayByApplyingSelector:@selector(name)];
                    NSArray<NSString *> *settingValues = [[sbConfig resolvedBuildSettings] arrayByApplyingSelector:@selector(value)];
                    NSMutableDictionary *buildSettings = [NSMutableDictionary dictionary];
                    for (NSUInteger i = 0; i<settingNames.count; i++) {
                        [buildSettings setValue:settingValues[i] forKey:settingNames[i]];
                    }
                    configuration.buildSettings = buildSettings;
                    configuration.target = target;
                    [configurations addObject:configuration];
                }];
                target.configurations = configurations;
                target.project = project;
                [targets addObject:target];
            }];
            project.targets = targets;
            [projects addObject:project];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(projects, nil);
        });
    });
}


+ (void)failWithCode:(NSUInteger)code block:(void(^)(NSArray * _Nullable, NSError * _Nullable))block
{
    NSError *error = [NSError errorWithDomain:XcodeBridgeErrorDomain code:code userInfo:nil];
    if ([NSThread isMainThread]) {
        block(nil, error);
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(nil, error);
        });
    }
}

@end




@implementation XCDConfiguration @end
@implementation XCDTarget @end
@implementation XCDProject @end
