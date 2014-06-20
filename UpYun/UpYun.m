//
//  UpYun.m
//
//  Created by nickcheng on 14-6-20.
//  Copyright (c) 2014年 nickcheng.com. All rights reserved.
//

#import "UpYun.h"
#import "NSString+SAMAdditions.h"
#import "AFNetworking.h"

@implementation UpYun {
  NSString *_bucket;
  NSTimeInterval _expiresIn;
  NSMutableDictionary *_params;
  NSString *_passcode;
  UpYunUploadProgressBlock _progressBlock;
}

@synthesize bucket = _bucket;
@synthesize expiresIn = _expiresIn;
@synthesize params = _params;
@synthesize passcode = _passcode;
@synthesize progressBlock = _progressBlock;

#pragma mark -
#pragma mark Init

- (id)initWithBucket:(NSString *)bucket andPassCode:(NSString *)passcode {
  //
	if((self = [super init]) == nil) return nil;
  
  // Custom initialization
  _bucket = bucket;
  _passcode = passcode;
  
  _expiresIn = 100;
  _params = [NSMutableDictionary dictionary];
  _progressBlock = nil;
  
  return self;
}

#pragma mark -
#pragma mark Public Methods

- (void)uploadFileWithPath:(NSString *)path completion:(UpYunCompletionBlock)completionBlock {
  NSRange range = [path rangeOfString:@"/" options:NSBackwardsSearch];
  if (range.location == NSNotFound) {
    NSError *error = [[NSError alloc] initWithDomain:UPYUN_ERROR_DOMAIN code:400 userInfo:nil];
    completionBlock(NO, nil, error);
    return;
  }
  NSString *saveKey = [path substringFromIndex:range.location];
  
  [self uploadFileWithPath:path useSaveKey:saveKey completion:completionBlock];
}

- (void)uploadFileWithPath:(NSString *)path useSaveKey:(NSString *)saveKey completion:(UpYunCompletionBlock)completionBlock {
  NSString *policy = [self policyWithSaveKey:saveKey andBucket:self.bucket];
  NSString *str = [NSString stringWithFormat:@"%@&%@", policy, self.passcode];
  NSString *signature = str.sam_MD5Digest.sam_stringByEscapingForURLQuery.lowercaseString;
  NSDictionary *dic = @{
                        @"policy": policy,
                        @"signature": signature,
                        @"file": path
                        };
  [self upload:dic completion:completionBlock];
}

- (void)uploadFileWithData:(NSData *)data useSaveKey:(NSString *)saveKey completion:(UpYunCompletionBlock)completionBlock {
  NSString *policy = [self policyWithSaveKey:saveKey andBucket:self.bucket];
  NSString *str = [NSString stringWithFormat:@"%@&%@", policy, self.passcode];
  NSString *signature = str.sam_MD5Digest.sam_stringByEscapingForURLQuery.lowercaseString;
  NSDictionary *dic = @{
                        @"policy": policy,
                        @"signature": signature,
                        @"file": data
                        };
  [self upload:dic completion:completionBlock];
}

#pragma mark -
#pragma mark Private Methods

- (NSString *)policyWithSaveKey:(NSString *)saveKey andBucket:(NSString *)bucket {
  NSMutableDictionary *dic = [NSMutableDictionary dictionary];
  dic[@"bucket"] = bucket;
  dic[@"expiration"] = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970] + self.expiresIn];
  dic[@"save-key"] = saveKey;
  for (NSString *key in self.params.keyEnumerator) {
    dic[key] = self.params[key];
  }
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
  NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//  NSLog(@"%@", json);
  return json.sam_base64EncodedString;
}

- (void)upload:(NSDictionary *)dic completion:(UpYunCompletionBlock)completionBlock {
  NSString *policy = dic[@"policy"];
  NSString *signature = dic[@"signature"];
  id file = dic[@"file"];
  
  NSMutableData *post = [NSMutableData data];
  NSURL *myWebserverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", UPYUN_API_DOMAIN, self.bucket]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myWebserverURL];
  
	[request setTimeoutInterval: 60.0];
	[request setCachePolicy: NSURLRequestUseProtocolCachePolicy];
  [request setHTTPMethod:@"POST"];
  
	// Set your own boundary string only if really obsessive.
  // We don't bother to check if post data contains the boundary, since it's pretty unlikely that it does.
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
  NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
	
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, stringBoundary]
    forHTTPHeaderField:@"Content-Type"];
	
	[post appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSASCIIStringEncoding]];
	
	// Adds post data
	NSString *endItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary];
  [post appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",@"policy"]
                      dataUsingEncoding:NSASCIIStringEncoding]];
  [post appendData:[policy dataUsingEncoding:NSUTF8StringEncoding]];
  [post appendData:[endItemBoundary dataUsingEncoding:NSASCIIStringEncoding]];
  [post appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",@"signature"]
                      dataUsingEncoding:NSASCIIStringEncoding]];
  [post appendData:[signature dataUsingEncoding:NSUTF8StringEncoding]];
  [post appendData:[endItemBoundary dataUsingEncoding:NSASCIIStringEncoding]];
  
  // Adds files to upload
  if (file) {
    [post appendData:[endItemBoundary dataUsingEncoding:NSASCIIStringEncoding]];
    [post appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"file", @"pic"]
                        dataUsingEncoding:NSASCIIStringEncoding]];
    [post appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"application/octet-stream"] dataUsingEncoding:NSASCIIStringEncoding]];

    if ([file isKindOfClass:[NSString class]])
      [post appendData:[NSData dataWithContentsOfFile:file]];
    else
      [post appendData:file];
  }
  
  // Only add the boundary if this is not the last item in the post body
	[post appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSASCIIStringEncoding]];
  
  NSString *postLength = [NSString stringWithFormat:@"%d", post.length];
  [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  [request setHTTPBody:post];
  
  //
  AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
  [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:operation.responseData options:NSJSONReadingMutableContainers error:nil];
    NSString *message = dic[@"message"];
    if ([@"ok" isEqualToString:message]) {
      if (self.progressBlock)
        self.progressBlock(0, post.length, post.length);
      if (completionBlock)
        completionBlock(YES, dic, nil);
    } else {
      if (completionBlock) {
        NSError *err = [NSError errorWithDomain:UPYUN_ERROR_DOMAIN code:[dic[@"code"] intValue] userInfo:dic];
        completionBlock(NO, nil, err);
      }
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    if (completionBlock)
      completionBlock(NO, nil, error);
  }];
  [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    if (self.progressBlock)
      self.progressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
  }];
  [operation start];
}

@end
