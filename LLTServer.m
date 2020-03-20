#include "liblayout.h"

@interface LLTServer (Private)

@property (retain) NSMutableArray *providers;

+(instancetype)sharedInstance;

-(void)registerProvider:(LLTLayoutProvider *)provider;
-(NSNumber *)valueForItem:(NSString *)item forLocation:(NSString *)location;

@end
@implementation LLTServer 

+ (instancetype)sharedInstance
{
    static LLTServer *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

+ (NSNumber *)valueForItem:(NSString *)item forLocation:(NSString *)location 
{
    return [[LLTServer sharedInstance] valueForItem:item forLocation:location];
}

+(void)registerProvider:(LLTLayoutProvider *)provider 
{
    [[LLTServer sharedInstance] registerProvider:provider];
}

+(LLTLayoutProvider *)createProviderFor:(NSString *)iconLocation
                               withTopInset:(CGFloat *)topInset 
                              sideInset:(CGFloat *)sideInset 
                             pageOffset:(CGFloat *)pageOffset 
                      horizontalSpacing:(CGFloat *)horizontalSpacing
                        verticalSpacing:(CGFloat *)verticalSpacing
                                   rows:(CGFloat *)rows
                                columns:(CGFloat *)columns
{
    LLTLayoutProvider *provider = [[LLTLayoutProvider alloc] init];
    provider.iconLocation = iconLocation;
    provider.items = @{
        @"TopInset":[NSValue valueWithPointer:topInset],
        @"SideInset":[NSValue valueWithPointer:sideInset],
        @"PageOffset":[NSValue valueWithPointer:pageOffset],
        @"HorizontalSpacing":[NSValue valueWithPointer:horizontalSpacing],
        @"VerticalSpacing":[NSValue valueWithPointer:verticalSpacing],
        @"Rows":[NSValue valueWithPointer:rows],
        @"Columns":[NSValue valueWithPointer:columns],
    };
    provider.priority = -1;
    return provider;
}

-(NSNumber *)valueForItem:(NSString *)item forLocation:(NSString *)location 
{
    double value = 0;
    for (LLTLayoutProvider *provider in self.providers)
    {
        if ([provider.iconLocation isEqualToString:location])
        {
            CGFloat *num = [(NSValue*)provider.items[item] pointerValue];
            value+=*num;
        }
    }
    return [NSNumber numberWithDouble:value];
}

-(void)registerProvider:(LLTLayoutProvider *)provider 
{
    [self.providers addObject:provider];
}

@end