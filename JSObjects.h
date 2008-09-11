//
//  JSObjects.h
//  c8
//
//  Created by Grayson Hansard on 9/11/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "v8.h"
#import "v8_objc_bridge.h"

@interface JSFunction : NSObject {
 	v8::Local<v8::Function> *_function;
	v8::Local<v8::Object> *_receiver;
}

+ (id)wrapperWithFunction:(v8::Local<v8::Function>)function receiver:(v8::Local<v8::Object>)receiver;

- (v8::Local<v8::Function>)function;
- (void)setFunction:(v8::Local<v8::Function>)newFunction;

- (v8::Local<v8::Object>)receiver;
- (void)setReceiver:(v8::Local<v8::Object>)newReceiver;

- (id)call:(id)firstArgument, ...;

@end
