// iOS 13 Code to Modify HomeScreen layout without performance/api overhead
#include "liblayout.h"

#define GetLoadoutValueInteger(location, item) [[[LLTServer] valueForItem:item forLocation:location] integerValue];
#define GetLoadoutValueFloat(location, item) [[[LLTServer] valueForItem:item forLocation:location] floatValue];

@interface SBIconListGridLayoutConfiguration

@property (nonatomic, assign) NSString *iconLocation;
@property (nonatomic, retain) NSDictionary *managerValues;
@property (nonatomic, assign) UIEdgeInsets customInsets;

- (void)getLatestValuesFromManager;
- (NSUInteger)numberOfPortraitColumns;
- (NSUInteger)numberOfPortraitRows;
- (UIEdgeInsets)portraitLayoutInsets;
@end

@interface SBIconListFlowLayout : NSObject
@property (nonatomic, retain) NSString *liblayout_iconLocation;
- (void)liblayout_updateCachedConfiguration;
@property (nonatomic, retain) SBIconListGridLayoutConfiguration *liblayout_cachedConfiguration;
@property (nonatomic, retain) SBIconListGridLayoutConfiguration *liblayout_cachedDefault;
@end
@interface SBIconListView : UIView 
@property (nonatomic, retain) NSString *iconLocation;
@property (nonatomic, retain) SBIconListFlowLayout *layout;
@end

%hook SBIconListView 

- (id)initWithModel:(id)arg1 orientation:(id)arg2 viewMap:(id)arg3 
{
    id o = %orig(arg1, arg2, arg3);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutIconsNow) name:LTT_REFRESH object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutIconsNowWithAnimation) name:LTT_REFRESH_ANIMATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(liblayout_updateCache) name:LLT_UPDATE object:nil];

    return o;
}

%new 
- (void)liblayout_updateCache 
{
    [[self layout] liblayout_updateCachedConfiguration];
}

%new 
- (void)liblayout_layoutIconsNowWithAnimation
{
    [UIView animateWithDuration:(0.15) delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self layoutIconsNow];
    } completion:NULL];
}

- (BOOL)automaticallyAdjustsLayoutMetricsToFit
{
    return NO;
}

- (id)layout 
{
    SBIconListFlowLayout *x = %orig;
    x.liblayout_iconLocation = [self iconLocation];
    return x;
}

%end


%hook SBIconListFlowLayout

%property (nonatomic, retain) NSString *iconLocation;
%property (nonatomic, retain) SBIconListGridLayoutConfiguration *liblayout_cachedConfiguration;
%property (nonatomic, retain) SBIconListGridLayoutConfiguration *liblayout_cachedDefault;

%new 
- (void)liblayout_updateCachedConfiguration
{
    if (!self.liblayout_cachedConfiguration)
        self.liblayout_cachedConfiguration = [[%c(SBIconListGridLayoutConfiguration) alloc] init];

    [self.liblayout_cachedConfiguration setNumberOfPortraitColumns:GetLoadoutValueInteger(self.liblayout_iconLocation, @"Columns") 
                    ?: [self.liblayout_cachedDefault numberOfPortraitColumns]];

    // rows

    [self.liblayout_cachedConfiguration setNumberOfPortraitRows:GetLoadoutValueInteger(self.liblayout_iconLocation, @"Rows") 
                    ?: [self.liblayout_cachedDefault numberOfPortraitRows]];
    
    UIEdgeInsets x = [self.liblayout_cachedDefault portraitLayoutInsets];
    UIEdgeInsets y;
   
    y = UIEdgeInsetsMake(
        x.top + (GetLoadoutValueFloat(self.liblayout_iconLocation, @"TopInset")?:0) ,
        x.left + (GetLoadoutValueFloat(self.liblayout_iconLocation, @"SideInset")?:0)*-2,
        x.bottom - (GetLoadoutValueFloat(self.liblayout_iconLocation, @"TopInset")?:0) + (GetLoadoutValue(self.liblayout_iconLocation, @"VerticalSpacing")?:0) *-2,
        x.right + (GetLoadoutValueFloat(self.liblayout_iconLocation, @"SideInset")?:0)*-2
    );
    
    [self.liblayout_cachedConfiguration setPortraitLayoutInsets:y];
}

- (id)layoutConfiguration
{
    if (!self.liblayout_cachedDefault)
    {
        self.liblayout_cachedDefault = %orig;
    }
    if (!self.liblayout_cachedConfiguration)
    {
        [self liblayout_updateCachedConfiguration];
    }
    return self.liblayout_cachedConfiguration;
}
- (UIEdgeInsets)layoutInsetsForOrientation:(NSInteger)arg1 
{
    return [self.liblayout_cachedConfiguration portraitLayoutInsets];
}
- (NSUInteger)numberOfRowsForOrientation:(NSInteger)arg1
{
    NSInteger x = %orig(arg1);
    
    return GetLoadoutValueInteger(self.liblayout_iconLocation, @"Rows") ?: x;
}

- (NSUInteger)numberOfColumnsForOrientation:(NSInteger)arg1
{
    NSInteger x = %orig(arg1);

    return GetLoadoutValueInteger(self.liblayout_iconLocation, @"Columns") ?: x;
}

%end