#import "FitnessPlugin.h"
#if __has_include(<fitness/fitness-Swift.h>)
#import <fitness/fitness-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "fitness-Swift.h"
#endif

@implementation FitnessPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFitnessPlugin registerWithRegistrar:registrar];
}
@end
