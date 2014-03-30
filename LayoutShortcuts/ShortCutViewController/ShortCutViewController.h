//
//  ShortCutViewController.h
//  LayoutShortcuts
//
//  Created by Can EriK Lu on 3/29/14.
//  Copyright (c) 2014 Can EriK Lu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShortCutViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView* scrollView;
@property (assign, nonatomic) int columns;
@property (assign, nonatomic) int rows;
@property (assign, nonatomic) BOOL vertical;
@property (assign, nonatomic) UIEdgeInsets margins;
@property (strong, nonatomic) NSArray* staticViews;
@property (assign, nonatomic) BOOL alignStaticViews;

- (void)updateSubviews;
- (void)alignShortcuts;
@end
