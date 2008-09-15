//
//  JavascriptEngine.mm
//  c8
//
//  Created by Grayson Hansard on 9/11/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import "JavascriptEngine.h"

v8::Handle<v8::Value> JSPrint(const v8::Arguments& args) {
	v8::HandleScope handle_scope;
	for(unsigned int i = 0; i < args.Length(); i++)
	{
		v8::String::AsciiValue str(args[i]);
		printf("%s\n", *str);
	}
	return v8::Undefined();
}

v8::Handle<v8::Value> JSImport(const v8::Arguments& args) {
	v8::HandleScope handle_scope;
	for (unsigned int i = 0; i < args.Length(); i++) {
		v8::String::AsciiValue filename(args[i]);
		return JSRunFile(filename);
	}
	return v8::Undefined();
}

v8::Handle<v8::Value> JSRunFile(v8::String::AsciiValue filename) {
	v8::HandleScope handle_scope;
	NSString *path = [[NSString stringWithUTF8String:*filename] stringByStandardizingPath];
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:path]) path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:path];
	if (![fm fileExistsAtPath:path]) return v8::Undefined();
	NSString *contents = [NSString stringWithContentsOfFile:path];
	v8::Local<v8::String> tmp = v8::String::New([contents UTF8String]);
	return JSExecuteCode(tmp);
}

v8::Handle<v8::Value> JSExecuteCode(v8::Local<v8::String> code) {
	v8::HandleScope handle_scope;
	v8::TryCatch try_catch;
	v8::Handle<v8::Script> script = v8::Script::Compile(code, v8::Undefined());
	if (script.IsEmpty()) JSThrowError( try_catch.Exception() );
	v8::Handle<v8::Value> result = script->Run();
	if (result.IsEmpty()) JSThrowError( try_catch.Exception() );
	return result;
}

void JSThrowError(v8::Handle<v8::Value> error) {
	v8::String::Utf8Value str(error);
	[NSException raise:@"Javascript error" format:@"%s", *str];
}

@implementation JavascriptEngine

+ (id)engine {
	return [[[self class] new] autorelease];
}

- (id)executeCode:(NSString *)code {
	v8::HandleScope handle_scope;
	v8::Context::Scope context_scope([self context]);
	
	v8::Local<v8::String> tmp = v8::String::New([code UTF8String]);
	@try { 
		v8::Handle<v8::Value> handle = JSExecuteCode(tmp); 
		return ConvertV8ValueToObjCObject(*handle);
	}
	@catch (NSException *e) { return e; }
	return nil;
}

- (id)runFile:(NSString *)path {
	v8::HandleScope handle_scope;
	v8::Context::Scope context_scope([self context]);
 	v8::String::AsciiValue tmp(v8::String::New([path UTF8String]));
	@try {
		v8::Handle<v8::Value> handle = JSRunFile(tmp);
		return ConvertV8ValueToObjCObject(*handle);
	}
	@catch (NSException *e) { return e; }
	return nil;
}

#pragma mark -
#pragma mark Getters/Setters


- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}

- (void)dealloc
{
	[self global].Dispose();
	[super dealloc];
}

- (v8::Handle<v8::Context>)context
{
 	return v8::Context::New(NULL, [self global]);
}

- (v8::Persistent<v8::ObjectTemplate>)global
{
	static v8::Persistent<v8::ObjectTemplate> global;
	if (global.IsEmpty()) {
		global = v8::Persistent<v8::ObjectTemplate>::New(v8::ObjectTemplate::New());
		v8_objc_bridge_init(global);
		global->Set(v8::String::New("print"), v8::FunctionTemplate::New(JSPrint));
		global->Set(v8::String::New("import"), v8::FunctionTemplate::New(JSImport));
	}
	return global;
}

@end
