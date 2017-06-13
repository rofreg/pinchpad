#import "TMPodspec.h"

static NSString * const PodspecKeyName = @"name";
static NSString * const PodspecKeyVersion = @"version";
static NSString * const PodspecKeySummary = @"summary";
static NSString * const PodspecKeyHomepageURL = @"homepage";

@interface TMPodspec ()

@property (nonatomic) NSDictionary *dictionary;

@end

@implementation TMPodspec

#pragma mark - Initialization

- (instancetype)initWithFileURL:(NSURL *)fileURL {
    if (self = [super init]) {
        if (!fileURL) {
            return nil;
        }
        
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        
        if (!data) {
            NSLog(@"No file at URL: %@", fileURL);
            return nil;
        }
        
        NSError *error;
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (error) {
            NSLog(@"Error parsing file (%@) as JSON: %@", fileURL, error);
            return nil;
        }
        
        if (![object isKindOfClass:[NSDictionary class]]) {
            NSLog(@"File (%@) must map to an `NSDictionary` type", fileURL);
            return nil;
        }
        
        _dictionary = object;
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithFileURL:nil];
}

#pragma mark - Properties

- (NSString *)name {
    return [self stringForKey:PodspecKeyName];
}

- (NSString *)version {
    return [self stringForKey:PodspecKeyVersion];
}

- (NSString *)summary {
    return [self stringForKey:PodspecKeySummary];
}

- (NSURL *)homepageURL {
    return [NSURL URLWithString:[self stringForKey:PodspecKeyHomepageURL]];
}

#pragma mark - Private

- (NSString *)stringForKey:(NSString *)key {
    id value = [self.dictionary valueForKey:key];
    
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    else {
        return nil;
    }
}

@end
