/*
 *  v8_objc_bridge.mm
 *  Paperclip
 *
 *  Created by Grayson Hansard on 9/4/08.
 *  Copyright 2008 From Concentrate Software. All rights reserved.
 *
 */

#include "v8_objc_bridge.h"

BOOL v8_objc_bridge_init(v8::Handle<v8::ObjectTemplate> global) {
	// Set up objc.class() calls
	v8::Handle<v8::ObjectTemplate> objc_templ = v8::ObjectTemplate::New();
	objc_templ->Set(v8::String::New("class"), v8::FunctionTemplate::New(FetchObjCClass));
	global->Set(v8::String::New("objc"), objc_templ);
	return true;
}

v8::Handle<v8::Value> FetchObjCClass(const v8::Arguments& args) {
	if (args.Length() != 1) return v8::Undefined();
	v8::String::AsciiValue str(args[0]);
	NSString *arg = [NSString stringWithUTF8String:*str];
	Class c = NSClassFromString(arg);
	
	v8::Handle<v8::ObjectTemplate> class_templ = v8::ObjectTemplate::New();
	// class_templ->SetInternalFieldCount(1);
	
	// v8::Local<v8::Object> obj = class_templ.New();
	// obj->SetInternal(0, c);
	
	NSArray *methods = [c classMethods];
	NSEnumerator *methodEnumerator = [methods objectEnumerator];
	NSString *method;
	while (method = [methodEnumerator nextObject])
	{
		NSLog(@"%@", method);
		NSMutableString *tmp = [NSMutableString stringWithString:method];
		[tmp replaceOccurrencesOfString:@"$" withString:@"$$" options:0 range:NSMakeRange(0, [tmp length])];
		[tmp replaceOccurrencesOfString:@"_" withString:@"$_" options:0 range:NSMakeRange(0, [tmp length])];
		[tmp replaceOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [tmp length])];
		
		// class_templ->Set(v8::String::New([tmp UTF8String]), v8::FunctionTemplate::New(CallObjCClassMethod));
	}
	
	// return obj;
  // bool first = true;
  // for (int i = 0; i < args.Length(); i++) {
  //   v8::HandleScope handle_scope;
  //   if (first) {
  //     first = false;
  //   } else {
  //     printf(" ");
  //   }
  //   v8::String::AsciiValue str(args[i]);
  //   printf("%s", *str);
  // }
  // printf("\n");
  return v8::Undefined();
}

// v8::Handle<v8::ObjectTemplate> CallObjCClassMethod(const v8::Arguments& args) {
// 	return nil;
// }