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
	v8::Handle<v8::External> ptr = v8::External::New(c);
	
	result->SetInternalField(0, ptr);
	
	return result;
}

v8::Handle<v8::Value> CallObjCClassMethod(const v8::Arguments& args) {	
	v8::Local<v8::Object> obj = args.This();
	v8::Local<v8::External> ptr = v8::Local<v8::External>::Cast(obj->GetInternalField(0));
	
	v8::Local<v8::Value> data = args.Data();
	v8::String::AsciiValue str(data);

	Class c = (Class)ptr->Value();
	NSString *methodName = [NSString stringWithUTF8String:*str];
	SEL selector = NSSelectorFromString(methodName);
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[c methodSignatureForSelector:selector]];
	[invocation setTarget:c];
	[invocation setSelector:selector];
	for(size_t i = 0; i < args.Length(); ++i)
	{
		id arg = ConvertV8ValueToObjCObject(args[i]);
		[invocation setArgument:&arg atIndex:i+2];
		// (id *)ConvertV8ValueToObjCObject(args[i]) atIndex:i+2];
	}
	[invocation invoke];
	id ret;
	[invocation getReturnValue:&ret];	
	
	return v8::Undefined();
}

v8::Handle<v8::Value> CallObjCInstanceMethod(const v8::Arguments& args) {
	NSLog(@"CallObjCInstanceMethod");
	
	v8::Local<v8::Object> obj = args.This();
	v8::String::AsciiValue str(obj->ToString());
	// v8::Local<v8::String> str = obj->ObjectProtoToString();
	
	NSLog(@"This: %s", *str);
	NSLog(@"%d", obj->InternalFieldCount());
	v8::Local<v8::External> ptr = v8::Local<v8::External>::Cast(obj->GetInternalField(0));
	id objc = (id)ptr->Value();
	NSLog(@"!!%@", NSStringFromClass([objc class]));
	
	v8::Handle<v8::Value> value = obj->Get(v8::String::New("className"));
	v8::String::AsciiValue str5(value->ToString());
	NSString *className = [NSString stringWithUTF8String:*str5];
	
	
	v8::Local<v8::Function> func = args.Callee();
	v8::String::AsciiValue str3(func->ToString());
	NSLog(@"Callee: %s", *str3);
	
	v8::Local<v8::Value> data = args.Data();
	v8::String::AsciiValue str2(data);
	NSString *methodName = [NSString stringWithUTF8String:*str2];
	NSLog(@"Data: %s", *str2);

	v8::Local<v8::Value> holder = args.Holder();
	v8::String::AsciiValue str4(holder->ToString());
	NSLog(@"Holder: %s", *str4);

	NSLog(@"[%@ %@]", className, methodName);

	
	for(size_t i = 0; i < args.Length(); ++i)
	{
		v8::String::AsciiValue str(args[i]);
		NSLog(@"Arg %d: %s", i, *str);
	}
	return v8::Undefined();
}

v8::Handle<v8::Value> GetObjCClass(v8::Local<v8::String> property, const v8::AccessorInfo& info) {
	NSLog(@"GetObjCClass");
	v8::Local<v8::Object> self = info.Holder();
	v8::Local<v8::External> wrap = v8::Local<v8::External>::Cast(self->GetInternalField(0));
	void* ptr = wrap->Value();
	return v8::String::New([NSStringFromClass((Class)ptr) UTF8String]);
}

void SetObjCClass(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info) {
}

v8::Handle<v8::ObjectTemplate> ConvertClassToTemplate(Class c) {
	v8::HandleScope handle_scope;
	v8::Handle<v8::ObjectTemplate> class_templ = v8::ObjectTemplate::New();
	class_templ->SetInternalFieldCount(1);
	class_templ->SetAccessor(v8::String::New("objc_class"),
	 	GetObjCClass, 
		SetObjCClass, 
		v8::Undefined(), 
		v8::DEFAULT,
		v8::None);//, nil, v8::DEFAULT, v8::None);
	NSArray *methods = [c classMethods];
	NSEnumerator *methodEnumerator = [methods objectEnumerator];
	NSString *method;
	while (method = [methodEnumerator nextObject])
	{
		NSMutableString *tmp = [NSMutableString stringWithString:method];
		[tmp replaceOccurrencesOfString:@"$" withString:@"$$" options:0 range:NSMakeRange(0, [tmp length])];
		[tmp replaceOccurrencesOfString:@"_" withString:@"$_" options:0 range:NSMakeRange(0, [tmp length])];
		[tmp replaceOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [tmp length])];
		
		class_templ->Set(v8::String::New([tmp UTF8String]), v8::FunctionTemplate::New(CallObjCClassMethod, v8::String::New([method UTF8String])));
	}
	
	return handle_scope.Close(v8::Persistent<v8::ObjectTemplate>::New(class_templ));
}

v8::Handle<v8::ObjectTemplate> ConvertObjectToTemplate(id obj) {
	v8::HandleScope handle_scope;
	v8::Handle<v8::ObjectTemplate> obj_templ = v8::ObjectTemplate::New();
	obj_templ->SetInternalFieldCount(1);
	obj_templ->SetAccessor(v8::String::New("raw_object"),
		GetRawObjCObject,
		SetRawObjCObject,
		v8::Undefined(),
		v8::DEFAULT,
		v8::None);
	NSArray *methods = [obj instanceMethods];
	NSEnumerator *methodEnumerator = [methods objectEnumerator];
	NSString *method;
	while (method = [methodEnumerator nextObject])
	{
		NSMutableString *tmp = [NSMutableString stringWithString:method];
		[tmp replaceOccurrencesOfString:@"$" withString:@"$$" options:0 range:NSMakeRange(0, [tmp length])];
		[tmp replaceOccurrencesOfString:@"_" withString:@"$_" options:0 range:NSMakeRange(0, [tmp length])];
		[tmp replaceOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [tmp length])];
		
		obj_templ->Set(v8::String::New([tmp UTF8String]), v8::FunctionTemplate::New(CallObjCInstanceMethod, v8::String::New([method UTF8String])));
	}
	return handle_scope.Close(v8::Persistent<v8::ObjectTemplate>::New(obj_templ));
}

v8::Handle<v8::Value> GetRawObjCObject(v8::Local<v8::String> property, const v8::AccessorInfo& info) {
	NSLog(@"GetObjCClass");
	v8::Local<v8::Object> self = info.Holder();
	v8::Local<v8::External> wrap = v8::Local<v8::External>::Cast(self->GetInternalField(0));
	void* ptr = wrap->Value();
	return v8::Integer::New((int)ptr);
}

void SetRawObjCObject(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info) {
}

id ConvertV8ValueToObjCObject(v8::Local<v8::Value> v8Obj) {
	if (v8Obj->IsString()) {
		v8::String::AsciiValue str(v8Obj);
		NSLog(@"Argument: %s", *str);
		return [NSString stringWithUTF8String:*str];
	}
	return nil;
}