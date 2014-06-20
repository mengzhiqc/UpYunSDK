//
//  ViewController.m
//  Example
//
//  Created by nickcheng on 14-6-20.
//  Copyright (c) 2014年 nxmix.com. All rights reserved.
//

#import "ViewController.h"
#import "UpYun.h"

@interface ViewController ()

@end

@implementation ViewController {
  UpYun *_logUploader;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
	//
  _logUploader = [[UpYun alloc] initWithBucket:@"bucket" andPassCode:@"passcode"]; // Replace bucket and passcode with yourself's
  
  //
  UIImage *image = [UIImage imageNamed:@"jpeg.jpg"];
  NSData *data = UIImageJPEGRepresentation(image, .9f);
  [_logUploader uploadFileWithData:data
                        useSaveKey:@"/test.jpg"
                        completion:^(BOOL success, NSDictionary *result, NSError *error) {
                          if (success)
                            NSLog(@"Upload successful. %@", result);
                          else
                            NSLog(@"Upload failed. Error: %@", error);
                        }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
