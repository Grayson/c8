/*
 *  v8_objc_bridge.h
 *  Paperclip
 *
 *  Created by Grayson Hansard on 9/4/08.
 *  Copyright 2008 From Concentrate Software. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import "NSObject+bridge.h"
#include "v8.h"

BOOL v8_objc_bridge_init(v8::Handle<v8::ObjectTemplate> global);

v8::Handle<v8::Value> FetchObjCClass(const v8::Arguments& args);
v8::Handle<v8::Value> CallObjCClassMethod(const v8::Arguments& args);
v8::Handle<v8::ObjectTemplate> ConvertClassToTemplate(Class c);
v8::Handle<v8::Value> GetObjCClass(v8::Local<v8::String> property, v8::AccessorInfo& info);