//
//  XcodeBridge.h
//  Build Settings
//
//  Created by Paulo F. Andrade on 07/02/2020.
//  Copyright © 2020 Outer Corner. All rights reserved.
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

+ (void)reloadBuildSettings:(void(^)(NSArray<XCDProject *> * _Nullable, NSError * _Nullable))completionBlock;

@end







@interface XCDConfiguration: NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> *buildSettings;
@property (nonatomic, weak, readonly) XCDTarget *target;

@end

@interface XCDTarget: NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSArray<XCDConfiguration *> *configurations;
@property (nonatomic, weak, readonly) XCDProject *project;

@end

@interface XCDProject: NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSArray<XCDTarget *> *targets;

@end

NS_ASSUME_NONNULL_END
