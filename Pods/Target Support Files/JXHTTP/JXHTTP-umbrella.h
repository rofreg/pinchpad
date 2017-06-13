#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JXBackgroundTaskManager.h"
#import "JXHTTP.h"
#import "JXHTTPDataBody.h"
#import "JXHTTPFileBody.h"
#import "JXHTTPFormEncodedBody.h"
#import "JXHTTPJSONBody.h"
#import "JXHTTPMultipartBody.h"
#import "JXHTTPOperation+Convenience.h"
#import "JXHTTPOperation.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPOperationQueue.h"
#import "JXHTTPOperationQueueDelegate.h"
#import "JXHTTPRequestBody.h"
#import "JXNetworkActivityIndicatorManager.h"
#import "JXOperation.h"
#import "JXURLConnectionOperation.h"
#import "JXURLEncoding.h"

FOUNDATION_EXPORT double JXHTTPVersionNumber;
FOUNDATION_EXPORT const unsigned char JXHTTPVersionString[];

