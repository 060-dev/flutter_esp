#import "FlutterEspPlugin.h"
#if __has_include(<flutter_esp/flutter_esp-Swift.h>)
#import <flutter_esp/flutter_esp-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_esp-Swift.h"
#endif

@implementation FlutterEspPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterEspPlugin registerWithRegistrar:registrar];
}
@end
