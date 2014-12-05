//
//  DetectRectView.h
//  opencvtest
//
//  Created by hxx on 11/13/14.
//  Copyright (c) 2014 hxx. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetectRectView : UIView
- (void)displayRect:(NSArray *)points orientation:(UIInterfaceOrientation)orientation;
- (void)displayRect:(NSArray *)points inCIImage:(CIImage *)image;
- (void)clear;
@end
