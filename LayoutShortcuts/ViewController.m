//
//  ViewController.m
//  OrginIssue
//
//  Created by Can EriK Lu on 3/27/14.
//  Copyright (c) 2014 Can EriK Lu. All rights reserved.
//

#import "ViewController.h"
#import "Common.h"
#import "AnimationDelegate.h"

@interface ViewController ()
{
	NSMutableArray* _buttons;
	NSMutableArray* _origins;
	int columns;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	self.wrapper.layer.cornerRadius = 10;
	_buttons = [NSMutableArray array];
	_origins = [NSMutableArray array];
	for (UIButton* aButton in self.wrapper.subviews) {
		if ([aButton isKindOfClass:[UIButton class]]) {
			UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
			UILongPressGestureRecognizer* lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
			[aButton addGestureRecognizer:pan];
			[aButton addGestureRecognizer:lp];
			[_buttons addObject:aButton];
		}
	}
	[_buttons sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		UIButton* btn1 = obj1, *btn2 = obj2;
		float vertical = fabsf(btn1.y - btn2.y), horizontal = fabsf(btn1.x - btn2.x);
		if (vertical > btn1.height * 0.7) {
			return btn1.y < btn2.y ? NSOrderedAscending : NSOrderedDescending;
		}
		else if (horizontal > btn1.height * 0.7) {
			return btn1.x < btn2.x ? NSOrderedAscending : NSOrderedDescending;
		}
		return NSOrderedSame;
	}];
	columns = 3;

	for (int i = 0; i < _buttons.count; ++i) {
		UIButton* btn = _buttons[i];
		btn.layer.zPosition = i;
		[_origins addObject:[NSValue valueWithCGPoint:btn.origin]];
	}

	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sunset_tree.jpg"]];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self moveButtonsFrom:0 To:8 direction:NO];
	return;
}

- (IBAction)handleLongPressGesture:(UILongPressGestureRecognizer *)longPress
{

	static CGPoint start, orgin;
	static float zPosition;
	CGPoint current, newOrigin;
	CALayer* layer = longPress.view.layer;
	switch (longPress.state) {
		case UIGestureRecognizerStateBegan:
			NSLog(@"Start long pressed");
			start = longPress.view.origin;
			orgin = [longPress locationInView:self.view];
			longPress.view.alpha *= 0.8;
			[layer addAnimation:[self scaleAnimationFactor:1.3 duration:0.2] forKey:@"scale"];
			zPosition = layer.zPosition;
			layer.zPosition = 100;

			break;
		case UIGestureRecognizerStateChanged:
			current = [longPress locationInView:self.view];
			newOrigin = CGPointMake(start.x + (current.x - orgin.x ), start.y + (current.y - orgin.y));
			longPress.view.origin = newOrigin;
			break;
		case UIGestureRecognizerStateEnded:
		{
			longPress.view.alpha /= 0.7;
			[longPress.view.layer removeAnimationForKey:@"scale"];
			layer.transform = [((CALayer*)layer.presentationLayer) transform];
			[UIView animateWithDuration:.2 animations:^{
				layer.transform = CATransform3DIdentity;
			} completion:^(BOOL finished) {
				layer.zPosition = zPosition;
			}];
			break;
		}
		default:
			break;
	}

}

- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)pan
{

	UIButton* button = (UIButton*)pan.view;

    static CGPoint start;
	static float zPosition;
	CGPoint translation, newOrigin;
	CALayer* layer = button.layer;
	switch (pan.state) {
		case UIGestureRecognizerStateBegan:
		{
			start = pan.view.origin;
			pan.view.alpha *= 0.9;
			zPosition = layer.zPosition;
			layer.zPosition = 100;
			NSLog(@"z = %f ", layer.zPosition);
			[layer addAnimation:[self scaleAnimationFactor:1.3 duration:0.2] forKey:@"scale"];
			for (UIButton* btn in _buttons) {
				if (btn != button) {
					[btn.layer addAnimation:[self shakeAnimationAngle:0.07 duration:0.1] forKey:nil];
				}
			}

			break;
		}
		case UIGestureRecognizerStateChanged:
		{
			translation = [pan translationInView:self.view];
			newOrigin = CGPointMake(start.x + translation.x, start.y + translation.y);
			button.origin = newOrigin;
			break;
		}
		case UIGestureRecognizerStateEnded:
		{
			[layer removeAnimationForKey:@"scale"];
			layer.transform = [((CALayer*)layer.presentationLayer) transform];
			[UIView animateWithDuration:.3 animations:^{
				pan.view.alpha /= 0.9;
				layer.transform = CATransform3DIdentity;
				button.origin = start;
			} completion:^(BOOL finished) {
				layer.zPosition = zPosition;
				for (UIButton* btn in _buttons) {
					if (btn != button) {
						[btn.layer removeAllAnimations];
					}
				}
			}];
			break;
		}
		default:
			break;
	}
}

- (void)moveButtonsFrom:(int)first To:(int)last direction:(BOOL)forward
{
	static float duration = 1;
	for (int i = first; i <= last; ++i) {
		//Increment one
		UIButton* btn = _buttons[i];

		NSValue* p1 = _origins[i];
		NSValue* p2 = _origins[(i + 1) % _buttons.count];
		if (!forward) {
			p2 = i ? _origins[i-1] : _origins[_buttons.count - 1];
		}

		float horizon =  p2.CGPointValue.x - p1.CGPointValue.x,
		vertical =  p2.CGPointValue.y - p1.CGPointValue.y;
		CABasicAnimation* aX = [CABasicAnimation animationWithKeyPath:@"position.x"];
		aX.byValue = [NSNumber numberWithFloat:horizon];
		aX.duration = duration;
		aX.removedOnCompletion = NO;
		aX.fillMode = kCAFillModeForwards;
		aX.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		aX.delegate = [[AnimationDelegate alloc] initWithView:btn];
		[btn.layer addAnimation:aX forKey:@"translateX"];
		if ( (forward && i % columns == columns - 1) || (!forward && i % columns == 0) ) {
			CABasicAnimation* aY = [CABasicAnimation animationWithKeyPath:@"position.y"];
			aY.byValue = [NSNumber numberWithFloat:vertical];
			aY.duration = duration;
			aY.removedOnCompletion = aX.removedOnCompletion;
			aY.fillMode = aX.fillMode;
			aY.timingFunction = aX.timingFunction;
			aY.delegate = aX.delegate;
			[btn.layer addAnimation:aY forKey:@"translateY"];
		}
	}
}

- (CABasicAnimation*)scaleAnimationFactor:(float)factor duration:(float)duration
{
	CABasicAnimation* scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];

	scale.toValue = [NSNumber numberWithFloat:factor];
	scale.duration = duration;
	scale.delegate = self;
	scale.removedOnCompletion = NO;
	scale.fillMode = kCAFillModeForwards;
	scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	return scale;
}
- (CABasicAnimation*)shakeAnimationAngle:(float)angle duration:(float)duration
{
	CABasicAnimation* rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
	rotate.fromValue = [NSNumber numberWithFloat:angle];
	rotate.toValue = [NSNumber numberWithFloat:-angle];
	rotate.duration = duration;
	rotate.autoreverses = YES;
	rotate.delegate = self;
	rotate.repeatCount = HUGE_VALF;
	return rotate;
}
@end
