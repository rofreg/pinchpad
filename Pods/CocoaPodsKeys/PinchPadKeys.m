//
// Generated by CocoaPods-Keys
// on 18/06/2020
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

    
    char twitterConsumerKeyCString[8] = { [PinchPadKeysData characterAtIndex:603], [PinchPadKeysData characterAtIndex:582], [PinchPadKeysData characterAtIndex:86], [PinchPadKeysData characterAtIndex:709], [PinchPadKeysData characterAtIndex:565], [PinchPadKeysData characterAtIndex:416], [PinchPadKeysData characterAtIndex:101], '\0' };
    _twitterConsumerKey = 
        
          [NSString stringWithCString:twitterConsumerKeyCString encoding:NSUTF8StringEncoding];
        
      
    
    char twitterConsumerSecretCString[7] = { [PinchPadKeysData characterAtIndex:269], [PinchPadKeysData characterAtIndex:599], [PinchPadKeysData characterAtIndex:227], [PinchPadKeysData characterAtIndex:105], [PinchPadKeysData characterAtIndex:620], [PinchPadKeysData characterAtIndex:490], '\0' };
    _twitterConsumerSecret = 
        
          [NSString stringWithCString:twitterConsumerSecretCString encoding:NSUTF8StringEncoding];
        
      
    
    char tumblrConsumerKeyCString[8] = { [PinchPadKeysData characterAtIndex:141], [PinchPadKeysData characterAtIndex:62], [PinchPadKeysData characterAtIndex:422], [PinchPadKeysData characterAtIndex:352], [PinchPadKeysData characterAtIndex:266], [PinchPadKeysData characterAtIndex:626], [PinchPadKeysData characterAtIndex:286], '\0' };
    _tumblrConsumerKey = 
        
          [NSString stringWithCString:tumblrConsumerKeyCString encoding:NSUTF8StringEncoding];
        
      
    
    char tumblrConsumerSecretCString[8] = { [PinchPadKeysData characterAtIndex:433], [PinchPadKeysData characterAtIndex:642], [PinchPadKeysData characterAtIndex:402], [PinchPadKeysData characterAtIndex:337], [PinchPadKeysData characterAtIndex:102], [PinchPadKeysData characterAtIndex:323], [PinchPadKeysData characterAtIndex:324], '\0' };
    _tumblrConsumerSecret = 
        
          [NSString stringWithCString:tumblrConsumerSecretCString encoding:NSUTF8StringEncoding];
        
      
    
    
    return self;
}

static NSString *PinchPadKeysData = @"qmCtliV8lKJnkzD9t+Xy87t3lM+QetPoHOOWzrDtmS1Wx3AQ6qAZ/yznUuYrcQne9Q1PnHowUQ0dL/MrDpEumGkp/8Dch1eCxDq95no2goW9JNOwkeFw+mNTn1kJgrfc1z8c/mYDz3wrKu1Uhx/3V9PD9wEs4LSVqFkdngJzvF4KlZr7pqPSjVjYhCw2Ik1O0vgKRKp9HR9Jzw3vgYvx5fPVz1Fkq5+CF+QklnRXWoj0fwNTL2amRnu/oGh4+BLIjWrfyeZwLDo07u8EaKndBpwTbu9XyXnrol0KsUkBoaXcluas+T7XSFlQSnHiPQyBIDmwnW+7k5K+brGf1nN0hs6KhSKnEilxnQIDxXzUx5C6PVKQzngPgpP1LkpAM8aJDpj6SBh8R9Ec6If44okfmnNw1e6wvjVbwxL+fUkJ9vNNqH2qbuB6C11c2joCfYL1nNmJATJuFIHfez+GeuF+okQgEBR3PS2TCCAtcdHz1mnQ0NCh6NZATRa2naK3oi2I7Ad5/CIjpqnHNAv1IT8NAlJVaraKJ8VjoY0VnAJgohqIdTxERfOMpoXP0eAL3Lx1/ctosQnbL8CdDViDzvpkQtEn15VukUToA7JOiBhYzNLlwaRTdzwVb+Nc6Xa+UBQbFXnhKTt6xJRzMHtk9XKe7CGe92R7iC8hhrGD61cxwniEWv9t7nLKSr4qNCLQJ+menQdXgnyK/juaW7U6\\\"";

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
