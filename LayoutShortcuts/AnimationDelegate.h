//
//  AnimationDelegate.h
//  LayoutShortcuts
//
//  Created by Can EriK Lu on 3/27/14.
//  Copyright (c) 2014 Can EriK Lu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnimationDelegate : NSObject
- (id)initWithView:(UIView*)aView;
@property (weak, nonatomic) UIView* theView;
@end
