//
//  JSObjects.mm
//  c8
//
//  Created by Grayson Hansard on 9/11/08.
//  Copyright 2008 From Concentrate Software. All rights reserved.
//

#import "JSObjects.h"


@implementation JSFunction

+ (id)wrapperWithFunction:(v8::Local<v8::Function>)function receiver:(v8::Local<v8::Object>)receiver
{
	JSFunction *f = [[JSFunction new] autorelease];
	[f setFunction:function];
	[f setReceiver:receiver];
	return f;
}

- (v8::Local<v8::Function>)function
{
	return *_function;
}

- (void)setFunction:(v8::Local<v8::Function>)newFunction
{
	_function = &newFunction;
}

- (v8::Local<v8::Object>)receiver
{
	return *_receiver;
}

- (void)setReceiver:(v8::Local<v8::Object>)newReceiver
{
	_receiver = &newReceiver;
}

- (id)call:(id)firstArgument, ... {
	NSMutableArray *array = [NSMutableArray array];
	id eachObject;
	va_list argumentList;
	if (firstArgument)
	{
		[array addObject: firstArgument];
		
		va_start(argumentList, firstArgument);
		while (eachObject = va_arg(argumentList, id)) [array addObject:eachObject];
		va_end(argumentList);
	}
	
	v8::Handle<v8::Value> argv[ [array count] ];
	NSEnumerator *argEnumerator = [array objectEnumerator];
	id arg;
	unsigned int i = 0;
	while (arg = [argEnumerator nextObject]) argv[i++] = ConvertObjCObjectToV8Value(arg);
	
	v8::Local<v8::Value> ret = [self function]->Call([self receiver], (int)[array count], argv);
	return ConvertV8ValueToObjCObject(ret);
}

@end
