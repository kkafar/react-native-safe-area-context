#import "RNCSafeAreaProvider.h"

#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>
#import "RNCSafeAreaUtils.h"

@implementation RNCSafeAreaProvider {
  UIEdgeInsets _currentSafeAreaInsets;
  CGRect _currentFrame;
  BOOL _initialInsetsSent;
}

- (instancetype)init
{
  if ((self = [super init])) {
#if !TARGET_OS_TV && !TARGET_OS_OSX
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(invalidateSafeAreaInsets)
                                               name:UIKeyboardDidShowNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(invalidateSafeAreaInsets)
                                               name:UIKeyboardDidHideNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(invalidateSafeAreaInsets)
                                               name:UIKeyboardDidChangeFrameNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(invalidateSafeAreaInsets)
                                               name:UIWindowDidBecomeVisibleNotification
                                             object:nil];
#endif
  }
  return self;
}

- (void)safeAreaInsetsDidChange
{
  [self invalidateSafeAreaInsets];
}

- (void)invalidateSafeAreaInsets
{
  // This gets called before the view size is set by react-native so
  // make sure to wait so we don't set wrong insets to JS.
  if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
    return;
  }

#if TARGET_OS_IPHONE
  UIEdgeInsets safeAreaInsets = self.safeAreaInsets;
#elif TARGET_OS_OSX
  NSEdgeInsets safeAreaInsets;
  if (@available(macOS 11.0, *)) {
    safeAreaInsets = self.safeAreaInsets;
  } else {
    safeAreaInsets = NSEdgeInsetsZero;
  }
#endif
  CGRect frame = [self convertRect:self.bounds toView:RNCParentViewController(self).view];

  if (_initialInsetsSent &&
#if TARGET_OS_IPHONE
      UIEdgeInsetsEqualToEdgeInsetsWithThreshold(safeAreaInsets, _currentSafeAreaInsets, 1.0 / RCTScreenScale()) &&
#elif TARGET_OS_OSX
      NSEdgeInsetsEqualToEdgeInsetsWithThreshold(safeAreaInsets, _currentSafeAreaInsets, 1.0 / RCTScreenScale()) &&
#endif
      CGRectEqualToRect(frame, _currentFrame)) {
    return;
  }

  _initialInsetsSent = YES;
  _currentSafeAreaInsets = safeAreaInsets;
  _currentFrame = frame;

  [NSNotificationCenter.defaultCenter postNotificationName:RNCSafeAreaDidChange object:self userInfo:nil];

  self.onInsetsChange(@{
    @"insets" : @{
      @"top" : @(safeAreaInsets.top),
      @"right" : @(safeAreaInsets.right),
      @"bottom" : @(safeAreaInsets.bottom),
      @"left" : @(safeAreaInsets.left),
    },
    @"frame" : @{
      @"x" : @(frame.origin.x),
      @"y" : @(frame.origin.y),
      @"width" : @(frame.size.width),
      @"height" : @(frame.size.height),
    },
  });
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  [self invalidateSafeAreaInsets];
}

@end
