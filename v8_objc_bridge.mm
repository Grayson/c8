/*
 *  v8_objc_bridge.mm
 *  Paperclip
 *
 *  Created by Grayson Hansard on 9/4/08.
 *  Copyright 2008 From Concentrate Software. All rights reserved.
 *
 */

#include "v8_objc_bridge.h"

// Entry point for injecting the bridge into a given context.  Basically, this just sets up the "objc" object.
BOOL v8_objc_bridge_init(v8::Handle<v8::ObjectTemplate> global) {
	v8::Handle<v8::ObjectTemplate> objc_templ = v8::ObjectTemplate::New();
	objc_templ->Set(v8::String::New("class"), v8::FunctionTemplate::New(FetchObjCClass));
	global->Set(v8::String::New("objc"), objc_templ);
	return true;
}

// Called from javascript using `objc.class("<some class name>")`.  Looks up that class by the provided name and
// converts it into a template in order to pass back to v8.
v8::Handle<v8::Value> FetchObjCClass(const v8::Arguments& args) {
	if (args.Length() != 1) return v8::Undefined();
	v8::String::AsciiValue str(args[0]);
	NSString *arg = [NSString stringWithUTF8String:*str];
	Class c = NSClassFromString(arg);
	if (!c) return v8::Undefined();
	return ConvertClassToTemplate(c);
}

// This method turns a class into a javascript template object that v8 can understand.  It does this by creating 
// a ObjectTemplate, setting an accessor (`objc_class`) that directly references this class 
// and then iterates over all of the class methods, adding them to the object template as a function template.
// These functions are renamed according to Apple's rules for Objective-C naming given in their Dashboard widget
// plugin guide.  The ObjectTemplate is then converted to a Persistent object and the className is set (for easy 
// lookup later).
v8::Handle<v8::Value> ConvertClassToTemplate(Class c) {
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
	
	v8::Handle<v8::ObjectTemplate> pers_templ = v8::Persistent<v8::ObjectTemplate>::New(class_templ);
	v8::Handle<v8::Object> result = pers_templ->NewInstance();
	result->Set(v8::String::New("className"), v8::String::New([NSStringFromClass(c) UTF8String]));
	v8::Handle<v8::External> ptr = v8::External::New(c);
	
	result->SetInternalField(0, ptr);
	
	return handle_scope.Close(result);
}

// This converts an Objective-C object similar to how ConvertClassToTemplate wraps a Class.  A blank ObjectTemplate is
// created and an internal field is set to the actual object.  Methods are added as FunctionTemplates (following a 
// renaming convention, see ConvertClassToTemplate) and the object template is returned.
v8::Handle<v8::Value> ConvertObjectToTemplate(id obj) {
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
	v8::Handle<v8::ObjectTemplate> pers_templ = v8::Persistent<v8::ObjectTemplate>::New(obj_templ);
	v8::Handle<v8::Object> result = pers_templ->NewInstance();
	v8::Handle<v8::External> ptr = v8::External::New(obj);
	
	result->SetInternalField(0, ptr);
	
	return handle_scope.Close(result);
}

// When a javascript variable that represents a class calls a function, this gets called.  First, it gets the 
// class from the internal field of the template and the function name from the data passed when creating a template
// It then builds an NSInvocation call form those components and the arguments passed.
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
	}
	[invocation invoke];
	id ret;
	[invocation getReturnValue:&ret];	
	
	return ConvertObjCObjectToV8Value(ret);
}

// This is almost identically similar to CallObjCClassMethod.  The only real change is that any reference to 
// "Class" are replaced with "id".  Some names have been changed to represent this change in type.
v8::Handle<v8::Value> CallObjCInstanceMethod(const v8::Arguments& args) {
	v8::Local<v8::Object> tmp = args.This();
	v8::Local<v8::External> ptr = v8::Local<v8::External>::Cast(tmp->GetInternalField(0));
	
	v8::Local<v8::Value> data = args.Data();
	v8::String::AsciiValue str(data);

 	id obj = (id)ptr->Value();
	NSString *methodName = [NSString stringWithUTF8String:*str];
	SEL selector = NSSelectorFromString(methodName);
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:selector]];
	[invocation setTarget:obj];
	[invocation setSelector:selector];
	for(size_t i = 0; i < args.Length(); ++i)
	{
		id arg = ConvertV8ValueToObjCObject(args[i]);
		[invocation setArgument:&arg atIndex:i+2];
	}
	[invocation invoke];
	id ret;
	[invocation getReturnValue:&ret];	
	
	return ConvertObjCObjectToV8Value(ret);
}

// The Getter method for a class's `objc_class` property.  Returns it as a string.
v8::Handle<v8::Value> GetObjCClass(v8::Local<v8::String> property, const v8::AccessorInfo& info) {
	v8::Local<v8::Object> self = info.Holder();
	v8::Local<v8::External> wrap = v8::Local<v8::External>::Cast(self->GetInternalField(0));
	void* ptr = wrap->Value();
	return v8::String::New([NSStringFromClass((Class)ptr) UTF8String]);
}

// Stub setter for a class's `objc_class` property in javascript.  Shouldn't change the `objc_class`.
void SetObjCClass(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info) {
}

// Getter for an object template's `raw_object` property.  Returns the address of the pointer.
v8::Handle<v8::Value> GetRawObjCObject(v8::Local<v8::String> property, const v8::AccessorInfo& info) {
	v8::Local<v8::Object> self = info.Holder();
	v8::Local<v8::External> wrap = v8::Local<v8::External>::Cast(self->GetInternalField(0));
	void* ptr = wrap->Value();
	return v8::Integer::New((int)ptr);
}

// Stub for an object template's `raw_object` property.  Shouldn't change the raw_object.
void SetRawObjCObject(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::AccessorInfo& info) {
}

// Given a v8 value, convert it to it's appropriate COcoa/Objective-C type.
id ConvertV8ValueToObjCObject(v8::Local<v8::Value> v8Obj) {
	if (v8Obj->IsString()) {
		v8::String::AsciiValue str(v8Obj);
		return [NSString stringWithUTF8String:*str];
	}
	else if (v8Obj->IsNull()) return [NSNull null];
	else if (v8Obj->IsTrue() || v8Obj->IsFalse()) return [NSNumber numberWithBool:v8Obj->IsTrue()];
	else if (v8Obj->IsBoolean()) return [NSNumber numberWithBool:v8Obj->BooleanValue()];
	else if (v8Obj->IsNumber()) return [NSNumber numberWithDouble:v8Obj->NumberValue()];
	else if (v8Obj->IsInt32()) return [NSNumber numberWithLong:v8Obj->Int32Value()];
	else if (v8Obj->IsArray()) {
		NSMutableArray *array = [NSMutableArray array];
		v8::Local<v8::Array> v8array = v8::Local<v8::Array>::Cast( v8Obj->ToObject() );
		for(size_t i = 0; i < v8array->Length(); ++i)
			[array addObject:ConvertV8ValueToObjCObject(v8array->Get(v8::Number::New(i)))];
		return array;
	}
	else if (v8Obj->IsFunction()) {
		v8::Local<v8::Function> func = v8::Local<v8::Function>::Cast( v8Obj->ToObject() );
		return [JSFunction wrapperWithFunction:func receiver:v8Obj->ToObject()];
	}
	else if (v8Obj->IsExternal()) {
		NSLog(@"Found an external");
		// Wrap external?
	}
	return nil;
}

// Given a Cocoa/Objective-C object, convert it to a v8 value.
v8::Handle<v8::Value> ConvertObjCObjectToV8Value(id obj) {
	if ([obj isKindOfClass:[NSString class]]) {
		return v8::String::New([obj UTF8String]);
	}
	else if ([obj isKindOfClass:[NSNull class]]) return v8::Null();
	else if ([obj isKindOfClass:[NSNumber class]]) return v8::Number::New([obj doubleValue]);
	else if ([obj isKindOfClass:[NSArray class]]) {
		v8::Local<v8::Array> array = v8::Array::New([obj count]);
		NSEnumerator *objectEnumerator = [obj objectEnumerator];
		id elem;
		unsigned int i=0;
		while (elem = [objectEnumerator nextObject])
			array->Set(v8::Number::New(i++), ConvertObjCObjectToV8Value(elem));
		return array;
	}
	return ConvertObjectToTemplate(obj);
}