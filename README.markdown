# About c8

c8 (pronounced, "Kate", please, although I'll also accept "see eight") is a simple bridge between Objective-C and Google's Javascript engine, V8.  At this moment, the project is merely a proof of concept that creating a bridge is possible.  I cannot recommend c8 for anything except for playing around at the moment but I would eventually like to be able to produce application components in javascript using V8.

## Current status of the project

As of right now, c8 is a glorified version of the shell application is compiled from v8's source.  It introduces a new global object (`objc`) that contains a single function (`class`).  You may pass the name of an Objective-C class loaded into the application (currently, only Cocoa's Foundation library is loaded) and receive the class in Javascript:

	var NSDictionary = objc.class("NSDictionary");
	var dict = NSDictionary.dictionaryWithObject_ForKeys_('demo-object', 'demo-key');

Note that calling an Objective-C method follows the [naming convention that Apple outlined][1] for Webkit/Dashboard plug-ins.

In addition, the bridge attempts to convert primitive types.  Javascript strings, numbers, booleans, nulls, and arrays are converted to NSStrings, NSNumbers, NSNulls, and NSArrays as appropriate.  Also, NS* objects are converted to their javascript equivalent when possible.  There's also some wrapper classes provided for Javascript functions that are designed to make it easier to interact with them but this is currently completely untested.

## Dependencies and usage

You must [download and compile v8][2].  Once you have built v8, you may need to re-add `libv8.a` and `v8.h` to the Xcode project.  Once both of these items are correctly noticed by Xcode and libv8.a is properly linked, you should be able to Build & Run the command line application.  This application will run a modified v8 shell on `test.js`, displaying some information in the Console.

You can play around with c8 by changing test.js or by running the built command line tool against another javascript file.  Note that the command line tool is also called "c8" because I was lazy.

I cannot recommend using c8 to add javascript to Cocoa applications at this time.

## Contact info

Grayson Hansard  
[info@fromconcentratesoftware.com][3]  
[From Concentrate Software][4]


[1]: http://developer.apple.com/documentation/AppleApplications/Conceptual/Dashboard_ProgTopics/ObjCFromJavaScript.html#//apple_ref/doc/uid/30001215
[2]: http://code.google.com/apis/v8/build.html
[3]: mailto:info@fromconcentratesoftware.com
[4]: http://www.fromconcentratesoftware.com/