#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "bg_charm" asset catalog image resource.
static NSString * const ACImageNameBgCharm AC_SWIFT_PRIVATE = @"bg_charm";

/// The "blue_bird" asset catalog image resource.
static NSString * const ACImageNameBlueBird AC_SWIFT_PRIVATE = @"blue_bird";

/// The "blue_fish" asset catalog image resource.
static NSString * const ACImageNameBlueFish AC_SWIFT_PRIVATE = @"blue_fish";

/// The "close_normal" asset catalog image resource.
static NSString * const ACImageNameCloseNormal AC_SWIFT_PRIVATE = @"close_normal";

/// The "img001" asset catalog image resource.
static NSString * const ACImageNameImg001 AC_SWIFT_PRIVATE = @"img001";

/// The "recharge_diamond" asset catalog image resource.
static NSString * const ACImageNameRechargeDiamond AC_SWIFT_PRIVATE = @"recharge_diamond";

/// The "topup_bg_daimond" asset catalog image resource.
static NSString * const ACImageNameTopupBgDaimond AC_SWIFT_PRIVATE = @"topup_bg_daimond";

#undef AC_SWIFT_PRIVATE
