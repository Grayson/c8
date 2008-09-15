#import <Foundation/Foundation.h>

#import "JavascriptEngine.h"

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	JavascriptEngine *engine = [JavascriptEngine engine];
	NSString *result = [engine executeCode:@"print(\"in js\"); return 2;"];
	NSLog(@"%@", result);
	
	[pool drain];
	return 1;
}
