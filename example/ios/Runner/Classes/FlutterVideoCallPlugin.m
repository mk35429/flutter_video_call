#import "FlutterVideoCallPlugin.h"
#if __has_include(<flutter_video_call/flutter_video_call-Swift.h>)
#import <flutter_video_call/flutter_video_call-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_video_call-Swift.h"
#endif

@implementation FlutterVideoCallPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterVideoCallPlugin registerWithRegistrar:registrar];
}
@end
