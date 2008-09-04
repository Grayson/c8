//
//  NSObject+bridge.h
//  c8
//
//  Created by Grayson Hansard on 9/4/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/objc-class.h>

@interface NSObject (bridge)

- (NSArray *)instanceMethods;
+ (NSArray *)classMethods;

@end
