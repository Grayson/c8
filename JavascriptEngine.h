//
//  JavascriptEngine.h
//  c8
//
//  Created by Grayson Hansard on 9/11/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NSObject+bridge.h"
#import "JSObjects.h"

#include "v8.h"

@interface JavascriptEngine : NSObject {
	v8::Handle<v8::Context> *_context;
	v8::Handle<v8::ObjectTemplate> *_global;
}

+ (id)engine;

- (id)executeCode:(NSString *)code;
- (id)runFile:(NSString *)path;

#pragma mark -
#pragma mark Getters/Setters

- (v8::Handle<v8::Context>)context;
- (void)setContext:(v8::Handle<v8::Context>)newContext;

- (v8::Handle<v8::ObjectTemplate>)global;
- (void)setGlobal:(v8::Handle<v8::ObjectTemplate>)newGlobal;

@end

v8::Handle<v8::Value> JSRunFile(v8::String::AsciiValue filename);
v8::Handle<v8::Value> JSImport(const v8::Arguments& args);
v8::Handle<v8::Value> JSPrint(const v8::Arguments& args);
v8::Handle<v8::Value> JSExecuteCode(v8::Local<v8::String> code);