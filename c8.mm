#import <Foundation/Foundation.h>

#include "v8shell.h"
#include "v8_objc_bridge.h"

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// v8::V8::SetFlagsFromCommandLine(&argc, (char *)argv, true);
	v8::HandleScope handle_scope;
	v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New();
	
	setupV8Shell(global);
	
	v8_objc_bridge_init(global);
	
	v8::Handle<v8::Context> context = v8::Context::New(NULL, global);
	v8::Context::Scope context_scope(context);
	
	int ret = runShell(global, argc, argv);
	
	[pool drain];
	return ret;
}
