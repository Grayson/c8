//
//  NSObject+bridge.m
//  c8
//
//  Created by Grayson Hansard on 9/4/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import "NSObject+bridge.h"


@implementation NSObject (bridge)

// Borrowed from Nu.
+ (NSArray *)classMethods {
	NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int method_count;
    // #ifdef DARWIN
    Method *method_list = class_copyMethodList(object_getClass([self class]), &method_count);
    // #else
    // Method_t *method_list = class_copyMethodList(object_get_class([self class]), &method_count);
    // #endif
    int i;
    for (i = 0; i < method_count; i++) {
		NSString *methodName = [NSString stringWithCString:(sel_getName(method_getName(method_list[i]))) encoding:NSUTF8StringEncoding];
        [array addObject:methodName];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
    
}

- (NSArray *) instanceMethods
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int method_count;
    // #ifdef DARWIN
    Method *method_list = class_copyMethodList([self class], &method_count);
    // #else
    // Method_t *method_list = class_copyMethodList([self class], &method_count);
    // #endif
    int i;
    for (i = 0; i < method_count; i++) {
		NSString *methodName = [NSString stringWithCString:(sel_getName(method_getName(method_list[i]))) encoding:NSUTF8StringEncoding];
        [array addObject:methodName];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}


@end
