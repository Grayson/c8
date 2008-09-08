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
	
	v8::Handle<v8::ObjectTemplate> class_templ = ConvertClassToTemplate(c);
	v8::Handle<v8::Object> result = class_templ->NewInstance();
	result->Set(v8::String::New("className"), v8::String::New([arg UTF8String]));
	// v8::Handle<v8::External> ptr = v8::External::New(c);
	
	// NSLog(@"%d %d", class_templ->InternalFieldCount(), result->InternalFieldCount());

	// result->SetInternalField(0, ptr);
	
	return result;
}

v8::Handle<v8::Value> CallObjCClassMethod(const v8::Arguments& args) {
	NSLog(@"CallObjCClassMethod");
	
	v8::Local<v8::Object> obj = args.This();
	v8::String::AsciiValue str(obj->ToString());
	// v8::Local<v8::String> str = obj->ObjectProtoToString();
	
	NSLog(@"This: %s", *str);
	NSLog(@"%d", obj->InternalFieldCount());
	
	v8::Handle<v8::Value> value = obj->Get(v8::String::New("className"));
	v8::String::AsciiValue str5(value->ToString());
	NSString *className = [NSString stringWithUTF8String:*str5];
	
	NSLog(@"[%@ ]", className);
	
	v8::Local<v8::Function> func = args.Callee();
	v8::String::AsciiValue str3(func->ToString());
	NSLog(@"Callee: %s", *str3);
	
	v8::Local<v8::Value> data = args.Data();
	v8::String::AsciiValue str2(data->ToString());
	NSLog(@"Data: %s", *str2);

	v8::Local<v8::Value> holder = args.Holder();
	v8::String::AsciiValue str4(holder->ToString());
	NSLog(@"Holder: %s", *str4);


	
	for(size_t i = 0; i < args.Length(); ++i)
	{
		v8::String::AsciiValue str(args[i]);
		NSLog(@"Arg %d: %s", i, *str);
	}
	return v8::Undefined();
}

v8::Handle<v8::ObjectTemplate> ConvertClassToTemplate(Class c) {
	v8::HandleScope handle_scope;
	v8::Handle<v8::ObjectTemplate> class_templ = v8::ObjectTemplate::New();
	class_templ->SetInternalFieldCount(1);
	NSArray *methods = [c classMethods];
	NSEnumerator *methodEnumerator = [methods objectEnumerator];
	NSString *method;
	while (method = [methodEnumerator nextObject])
	{
		NSMutableString *tmp = [NSMutableString stringWithString:method];
		[tmp replaceOccurrencesOfString:@"$" withString:@"$$" options:0 range:NSMakeRange(0, [tmp length])];
		[tmp replaceOccurrencesOfString:@"_" withString:@"$_" options:0 range:NSMakeRange(0, [tmp length])];
		[tmp replaceOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [tmp length])];
		
		class_templ->Set(v8::String::New([tmp UTF8String]), v8::FunctionTemplate::New(CallObjCClassMethod));
	}
	
	return handle_scope.Close(v8::Persistent<v8::ObjectTemplate>::New(class_templ));
}