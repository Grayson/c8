print("Beginning test");
var NSString = objc.class("NSString");
print(NSString.stringWithString_("hello world"));

var NSDictionary = objc.class("NSDictionary");
var d = NSDictionary.dictionaryWithObject_forKey_("qwer", "key");
print("Dictionary: " + d);
print(d.objectForKey_("key"));

var arr = new Array(1, 2, 3);
arr['test'] = 4;
print("Array: " + objc.class("NSArray").arrayWithArray_(arr));
print(arr.test);

print("Ending test");