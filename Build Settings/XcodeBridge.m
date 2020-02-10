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
- (instancetype)initWithXcodeBuildConfiguration:(XcodeBuildConfiguration *)configuration;
@property (nonatomic, strong) XcodeBuildConfiguration *configuration;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSDictionary<NSString *, NSString *> *buildSettings;
@property (nonatomic, weak, readwrite) XCDTarget *target;
@end

@interface XCDTarget ()
- (instancetype)initWithXcodeTarget:(XcodeTarget *)target;
@property (nonatomic, strong) XcodeTarget *target;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSArray<XCDConfiguration *> *configurations;
@property (nonatomic, weak, readwrite) XCDProject *project;
@end

@interface XCDProject ()
- (instancetype)initWithXcodeProject:(XcodeProject *)project;
@property (nonatomic, strong) XcodeProject *project;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSArray<XCDTarget *> *targets;
@end


@implementation XcodeBridge

+ (void)reloadAvailableTargets:(void(^)(NSArray<XCDProject *> * _Nullable, NSError * _Nullable))completionBlock
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
            XCDProject *project = [[XCDProject alloc] initWithXcodeProject:sbProject];
            project.name = sbProject.name;
            NSMutableArray<XCDTarget *> *targets = [[NSMutableArray alloc] init];
            [[sbProject targets] enumerateObjectsUsingBlock:^(XcodeTarget * _Nonnull sbTarget, NSUInteger idx, BOOL * _Nonnull stop) {
                XCDTarget *target = [[XCDTarget alloc] initWithXcodeTarget:sbTarget];
                target.name = sbTarget.name;
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


@implementation XCDConfiguration

- (instancetype)initWithXcodeBuildConfiguration:(XcodeBuildConfiguration *)configuration
{
    self = [super init];
    if (self) {
        _configuration = configuration;
    }
    return self;
}

- (void)updateBuildSettings:(void(^)(NSDictionary<NSString *, NSString *> *))completionBlock
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        
        __block NSArray<NSString *> *settingNames = nil;
        __block NSArray<NSString *> *settingValues = nil;
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            settingNames = [[self.configuration resolvedBuildSettings] arrayByApplyingSelector:@selector(name)];
        });
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            settingValues = [[self.configuration resolvedBuildSettings] arrayByApplyingSelector:@selector(value)];
        });
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            NSMutableDictionary *buildSettings = [NSMutableDictionary dictionary];
            for (NSUInteger i = 0; i<settingNames.count; i++) {
                [buildSettings setValue:settingValues[i] forKey:settingNames[i]];
            }
            self.buildSettings = buildSettings;
            completionBlock(buildSettings);
        });
        
    });
}

@end
@implementation XCDTarget
- (instancetype)initWithXcodeTarget:(XcodeTarget *)target
{
    self = [super init];
    if (self) {
        _target = target;
    }
    return self;
}

- (void)updateConfigurations:(void (^)(NSArray<XCDConfiguration *> * _Nonnull))completionBlock
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        
        NSArray<XcodeBuildConfiguration *> *buildConfigs = [self.target buildConfigurations];
        NSMutableArray<XCDConfiguration *> *configurations = [[NSMutableArray alloc] init];
        
        [buildConfigs enumerateObjectsUsingBlock:^(XcodeBuildConfiguration * _Nonnull sbConfig, NSUInteger idx, BOOL * _Nonnull stop) {
            XCDConfiguration *configuration = [[XCDConfiguration alloc] initWithXcodeBuildConfiguration:sbConfig];
            configuration.name = sbConfig.name;
            configuration.target = self;
            [configurations addObject:configuration];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.configurations = configurations;
            completionBlock(configurations);
        });
    });
    
}

@end

@implementation XCDProject
- (instancetype)initWithXcodeProject:(XcodeProject *)project
{
    self = [super init];
    if (self) {
        _project = project;
    }
    return self;
}
@end



