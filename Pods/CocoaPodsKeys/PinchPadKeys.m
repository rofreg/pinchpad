//
// Generated by CocoaPods-Keys
// on 25/05/2020
// For more information see https://github.com/orta/cocoapods-keys
//

#import <Foundation/NSDictionary.h>
#import "PinchPadKeys.h"

@interface PinchPadKeys ()

@property (nonatomic, copy) NSString *twitterConsumerKey;
@property (nonatomic, copy) NSString *twitterConsumerSecret;
@property (nonatomic, copy) NSString *tumblrConsumerKey;
@property (nonatomic, copy) NSString *tumblrConsumerSecret;


@end

@implementation PinchPadKeys

- (instancetype)init
{
    if (!(self = [super init])) { return nil; }

    
    char twitterConsumerKeyCString[8] = { [PinchPadKeysData characterAtIndex:505], [PinchPadKeysData characterAtIndex:669], [PinchPadKeysData characterAtIndex:716], [PinchPadKeysData characterAtIndex:145], [PinchPadKeysData characterAtIndex:592], [PinchPadKeysData characterAtIndex:206], [PinchPadKeysData characterAtIndex:737], '\0' };
    _twitterConsumerKey = 
        
          [NSString stringWithCString:twitterConsumerKeyCString encoding:NSUTF8StringEncoding];
        
      
    
    char twitterConsumerSecretCString[7] = { [PinchPadKeysData characterAtIndex:1], [PinchPadKeysData characterAtIndex:606], [PinchPadKeysData characterAtIndex:717], [PinchPadKeysData characterAtIndex:328], [PinchPadKeysData characterAtIndex:550], [PinchPadKeysData characterAtIndex:685], '\0' };
    _twitterConsumerSecret = 
        
          [NSString stringWithCString:twitterConsumerSecretCString encoding:NSUTF8StringEncoding];
        
      
    
    char tumblrConsumerKeyCString[8] = { [PinchPadKeysData characterAtIndex:708], [PinchPadKeysData characterAtIndex:280], [PinchPadKeysData characterAtIndex:194], [PinchPadKeysData characterAtIndex:9], [PinchPadKeysData characterAtIndex:547], [PinchPadKeysData characterAtIndex:37], [PinchPadKeysData characterAtIndex:235], '\0' };
    _tumblrConsumerKey = 
        
          [NSString stringWithCString:tumblrConsumerKeyCString encoding:NSUTF8StringEncoding];
        
      
    
    char tumblrConsumerSecretCString[8] = { [PinchPadKeysData characterAtIndex:392], [PinchPadKeysData characterAtIndex:502], [PinchPadKeysData characterAtIndex:140], [PinchPadKeysData characterAtIndex:676], [PinchPadKeysData characterAtIndex:66], [PinchPadKeysData characterAtIndex:287], [PinchPadKeysData characterAtIndex:387], '\0' };
    _tumblrConsumerSecret = 
        
          [NSString stringWithCString:tumblrConsumerSecretCString encoding:NSUTF8StringEncoding];
        
      
    
    
    return self;
}

static NSString *PinchPadKeysData = @"FuTO0mIXnno8Tb2EkBDhHKjJhfWZkf5Svk5DpwiPCaHFwMqMk7GG4g6Zxdm9G5+eg4ozkGkmuqK4BAkP9HYl9LIzHLOr/PAGvEahaBrTmVyqhnisvMleKjQc6h3PjGyqR33dgC8C2eaBk8rvvnVu1oEPhvvYy+7U3hn6thgcknJtq93hbgsoBIlFH4EDnyNY8bkdG8QQbrV6BJwLpzZn28T4iD23IvqWrv+LRyEjCV4nhISnTgfA4mxpGKy92bMhNEENb2xniMXV7f8NTrrliXEHnoHviYMwGF+9wdUM5P9Yr3wV5zM9iMkB9I5QSSK1rG7RU0YpoVbwEHmLZjLzfuUHtY2deRO+7WG7n6pNFp9avqBIZpnW+gFaNImOkaHNaJCntqi9uf7b94+s0CPBTCj0eTIhmKQDYNyFjAIrGCpI8K7lsRfExp78asY5419PuT5TFVBh/uLFKJhc/S67goKdVuOpVhWqiv1L/SVIkwNSy3TvV/v5pfnz7u6dm6dC8fD2ewRj6BjjtwR9CniJ2bsMI/k1QMr54LEoGlw30LfsVmU3OGK8IrtnElg9RTLLz4DhwD8oWVtYFsEEo/xQSfe1YKBlFinujTQIzwljU+lixRHqgx1T1lLMw3WPqHv5uw4PDY7aGVv+3WR+BSZ3iOmmD9/mrn1TrWjUnzTPU2u3Gnz59YGK3uAJ295PZsCA8oOhujtKlxv4kkNEFTrtyQ+mIZMEJeSbdnC0OJwHZUO5/q45nHNr\\\"";

- (NSString *)description
{
  return [@{
            @"twitterConsumerKey": self.twitterConsumerKey,
            @"twitterConsumerSecret": self.twitterConsumerSecret,
            @"tumblrConsumerKey": self.tumblrConsumerKey,
            @"tumblrConsumerSecret": self.tumblrConsumerSecret,
  } description];
}

- (id)debugQuickLookObject
{
  return [self description];
}

@end
