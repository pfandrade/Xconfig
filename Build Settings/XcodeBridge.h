//
//  XcodeBridge.h
//  Build Settings
//
//  Created by Paulo F. Andrade on 07/02/2020.
//  Copyright © 2020 Paulo F. Andrade. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XCDProject, XCDTarget, XCDConfiguration;

NS_ASSUME_NONNULL_BEGIN
extern NSString *const XcodeBridgeErrorDomain;
typedef NS_ERROR_ENUM(XcodeBridgeErrorDomain, XcodeBridgeError) {
    notRunning = 1,
    notAuthorized
};

@interface XcodeBridge : NSObject

+ (void)reloadAvailableTargets:(void(^)(NSArray<XCDProject *> * _Nullable, NSError * _Nullable))completionBlock;

@end







@interface XCDConfiguration: NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, nullable, readonly) NSDictionary<NSString *, NSString *> *buildSettings;
@property (nonatomic, weak, readonly) XCDTarget *target;
- (void)updateBuildSettings:(void(^)(NSDictionary<NSString *, NSString *> *))completionBlock;
@end

@interface XCDTarget: NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, nullable, readonly) NSArray<XCDConfiguration *> *configurations;
@property (nonatomic, weak, readonly) XCDProject *project;

- (void)updateConfigurations:(void(^)(NSArray<XCDConfiguration *> *))completionBlock;
@end

@interface XCDProject: NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSArray<XCDTarget *> *targets;

@end

NS_ASSUME_NONNULL_END
