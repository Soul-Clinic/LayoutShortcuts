//
//  AnimationDelegate.m
//  LayoutShortcuts
//
//  Created by Can EriK Lu on 3/27/14.
//  Copyright (c) 2014 Can EriK Lu. All rights reserved.
//

#import "AnimationDelegate.h"

@implementation AnimationDelegate
- (id)initWithView:(UIView*)aView
{
	self = [super init];
	if (self) {
		_theView = aView;
	}
	return self;
}
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	CABasicAnimation* anim = (CABasicAnimation*)theAnimation;
	CALayer* layer = _theView.layer;
	CALayer* presentation = _theView.layer.presentationLayer;
	[layer removeAllAnimations];
	layer.position = presentation.position;

	if ([anim.keyPath rangeOfString:@"position"].length > 0) {

	}
}

@end
