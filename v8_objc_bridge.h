/*
 *  v8_objc_bridge.h
 *  Paperclip
 *
 *  Created by Grayson Hansard on 9/4/08.
 *  Copyright 2008 From Concentrate Software. All rights reserved.
 *
 */

#include "v8.h"
#import <Foundation/Foundation.h>
#import "NSObject+bridge.h"
#import "JSObjects.h"

BOOL v8_objc_bridge_init(v8::Handle<v8::ObjectTemplate> global);

v8::Handle<v8::Value> FetchObjCClass(const v8::Arguments& args);

v8::Handle<v8::Value> CallObjCClassMethod(const v8::Arguments& args);
v8::Handle<v8::Value> CallObjCInstanceMethod(const v8::Arguments& args);

v8::Handle<v8::Value> ConvertClassToTemplate(Class c);
v8::Handle<v8::Value> ConvertObjectToTemplate(id obj);

v8::Handle<v8::Value> GetObjCClass(v8::Local<v8::String> property, const v8::AccessorInfo& info);
void SetObjCClass(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info);

v8::Handle<v8::Value> GetRawObjCObject(v8::Local<v8::String> property, const v8::AccessorInfo& info);
void SetRawObjCObject(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info);

id ConvertV8ValueToObjCObject(v8::Local<v8::Value> v8Obj);
v8::Handle<v8::Value> ConvertObjCObjectToV8Value(id obj);