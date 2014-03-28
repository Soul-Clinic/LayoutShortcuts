//
//  ViewController.m
//  OrginIssue
//
//  Created by Can EriK Lu on 3/27/14.
//  Copyright (c) 2014 Can EriK Lu. All rights reserved.
//

#import "ViewController.h"
#import "Common.h"


//TODO: Write a ShortCutsViewController

#define kShakeAnimationKey		@"shaking"
#define kOutside				-1
#define kPanningAlpha			0.9
#define kShakeAngle				(10.0 / 180.0 * M_PI)
#define kShakeTimeframe			0.1
#define kStandDuration			1.0
#define kMoveDuration			0.7
#define kPanScaleFactor			1.3
#define kQuietTimeBeforeMove	0.4


@interface ViewController ()
{
	NSMutableArray* _buttons;
	NSMutableArray* _origins;
	UIButton* _panningButton;
	float _zPosition;
	int _columns, _current, _destination, _appending;
	BOOL _layoutUpdated;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
	_current = _destination = kOutside;
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
	[self resortButtonIndexs];
	_columns = 3;

	for (int i = 0; i < _buttons.count; ++i) {
		UIButton* btn = _buttons[i];
		btn.layer.zPosition = i;
		[_origins addObject:[NSValue valueWithCGPoint:btn.origin]];
	}
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sunset_tree.jpg"]];

	UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	doubleTap.numberOfTouchesRequired = 2;
	[self.view addGestureRecognizer:tap];
	[self.view addGestureRecognizer:doubleTap];
}

- (IBAction)handleTap:(UITapGestureRecognizer*)sender
{
	if (sender.numberOfTouches == 1) {
//		[self moveButtonsRangFrom:2 to:7 directionForward:NO];
	}
	else {
		[self resetButtonPositions];
	}
}

- (void)resetButtonPositions
{
	[self resortButtonIndexs];
	[UIView animateWithDuration:.6 * kStandDuration animations:^{
		for (int i = 0; i < _buttons.count; ++i) {
			UIButton* btn = _buttons[i];
			btn.origin = [_origins[i] CGPointValue];
		}
	}];
}
- (IBAction)handleLongPressGesture:(UILongPressGestureRecognizer *)longPress
{

	static CGPoint start, orgin;
	CGPoint currentLocation, newOrigin;
	CALayer* layer = longPress.view.layer;
	switch (longPress.state) {
		case UIGestureRecognizerStateBegan:
			NSLog(@"Start long pressed");
			start = longPress.view.origin;
			orgin = [longPress locationInView:self.view];
			longPress.view.alpha *= 0.8;
			[layer addAnimation:[self scaleAnimationFactor:kPanningAlpha duration:0.2 * kStandDuration] forKey:@"scale"];
			_zPosition = layer.zPosition;
			layer.zPosition = 100;

			break;
		case UIGestureRecognizerStateChanged:
			currentLocation = [longPress locationInView:self.view];
			newOrigin = CGPointMake(start.x + (currentLocation.x - orgin.x ), start.y + (currentLocation.y - orgin.y));
			longPress.view.origin = newOrigin;
			break;
		case UIGestureRecognizerStateEnded:
		{
			longPress.view.alpha /= 0.7;
			[longPress.view.layer removeAnimationForKey:@"scale"];
			layer.transform = [((CALayer*)layer.presentationLayer) transform];
			[UIView animateWithDuration:.2 * kStandDuration animations:^{
				layer.transform = CATransform3DIdentity;
			} completion:^(BOOL finished) {
				layer.zPosition = _zPosition;
			}];
			break;
		}
		default:
			break;
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
	rotate.beginTime = CACurrentMediaTime() + duration * (rand() % 100) / 100;
	rotate.autoreverses = YES;
	rotate.delegate = self;
	rotate.repeatCount = HUGE_VALF;
	return rotate;
}

- (int)indexAtPosition:(CGPoint)point
{
	static float btnWidth, btnHeight, paddingX, paddingY;
	if (!btnWidth) {
		UIButton* btn = _buttons[0];
		btnWidth = btn.width;
		btnHeight = btn.height;
		CGPoint pt1 =  [_origins[0] CGPointValue],
		pt2 =  [_origins[1] CGPointValue],
		pt3 = [_origins[_columns] CGPointValue];
		float distanceX = pt2.x - pt1.x - btnWidth, distanceY = pt3.y - pt1.y - btnHeight;
		paddingX = distanceX * 0.5;
		paddingY = distanceY * 0.5;
	}
	for (int i = 0; i < _origins.count; ++i) {
		CGPoint pt = [_origins[i] CGPointValue];
		if (point.x >  pt.x - paddingX && point.x < pt.x + paddingX + btnWidth
			&& point.y > pt.y - paddingY && point.y< pt.y + paddingY + btnHeight) {
			return i;
		}
	}
	return kOutside;
}



- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)pan
{

    static CGPoint start, position, translation, newOrigin;
	static BOOL trigger;

	UIButton* btn = (UIButton*)pan.view;
	CALayer* layer = btn.layer;



	switch (pan.state) {
		case UIGestureRecognizerStateBegan:
		{
			start = pan.view.origin;
			_current = [self indexAtPosition:start];
			pan.view.alpha *= kPanningAlpha;
			_zPosition = layer.zPosition;
			layer.zPosition = 100;
			_panningButton = btn;
			[layer addAnimation:[self scaleAnimationFactor:kPanScaleFactor duration:0.2 * kStandDuration] forKey:@"scale"];
			for (UIButton* aButton in _buttons) {
				if (aButton != btn) {
					[aButton.layer addAnimation:[self shakeAnimationAngle:kShakeAngle duration:kShakeTimeframe] forKey:kShakeAnimationKey];
				}
			}
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLayout) object:nil];
			NSLog(@"Cancel in the begin");
			trigger = NO;
			break;
		}
		case UIGestureRecognizerStateChanged:
		{
			translation = [pan translationInView:self.view];
			newOrigin = CGPointMake(start.x + translation.x, start.y + translation.y);
			btn.origin = newOrigin;
			position = [pan locationOfTouch:0 inView:btn.superview];
			_destination = [self indexAtPosition:position];
			CGPoint velocity = [pan velocityInView:self.view];
			float linearVelocity = sqrtf(powf(velocity.x, 2) + powf(velocity.y, 2));

			if (_destination != _current && linearVelocity < 40.f) {
				NSLog(@"Speed is %f", linearVelocity);
				if (trigger == NO) {
					[self performSelector:@selector(updateLayout) withObject:pan afterDelay:kQuietTimeBeforeMove];
					trigger = YES;
				}
			} else {
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLayout) object:pan];
				NSLog(@"Cancel in the move: %f", linearVelocity);
				trigger = NO;
			}
			break;
		}
		case UIGestureRecognizerStateEnded:
		{
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLayout) object:pan];
			NSLog(@"Cancel in the end");
			trigger = NO;
			[self layBack:btn inPoint:position];
			break;
		}
		default:
			break;
	}
}


- (void)updateLayout
{
	int lastOne = (int)_buttons.count -1;

	if (_current == kOutside) {				//Drag in
		[self moveButtonsRangFrom:_destination to:lastOne - 1 directionForward:YES];
	}
	else if (_destination == kOutside) {	//Drag out
		[self moveButtonsRangFrom:_current + 1 to:lastOne directionForward:NO];
	}
	else if (_current < _destination) {
		[self moveButtonsRangFrom:_current + 1 to:_destination directionForward:NO];
	}
	else if (_current > _destination) {
		[self moveButtonsRangFrom:_destination to:_current - 1 directionForward:YES];
	}
}


- (void)layBack:(UIButton*)aButton inPoint:(CGPoint)position
{
	CALayer* layer = aButton.layer;
	layer.transform = [((CALayer*)layer.presentationLayer) transform];
	[layer removeAnimationForKey:@"scale"];

	_current = [self indexAtPosition:position];
	int index = (int)[_buttons indexOfObject:aButton];
	[self resortButtonIndexs];
	float duration = (_current == kOutside ? 0.6 : 0.2) * kStandDuration;
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 aButton.alpha /= kPanningAlpha;
						 layer.transform = CATransform3DIdentity;
						 if (_layoutUpdated == NO) {
							 aButton.origin = [_origins[index] CGPointValue];
						 }
						 else {
							 for (int i = 0; i < _buttons.count; ++i) {
								 UIButton* btn = _buttons[i];
								 btn.origin = [_origins[i] CGPointValue];
							 }
						 }
					 }
					 completion:^(BOOL finished) {
						 layer.zPosition = _zPosition;
						 for (UIButton* btn in _buttons) {
							 [btn.layer removeAnimationForKey:kShakeAnimationKey];
						 }
						 _current = kOutside;
						 _panningButton = nil;
						 _appending = NO;
						 _layoutUpdated = NO;
						 [self resortButtonIndexs];
						 NSLog(@"Complete");
					 }];
}

- (void)moveButtonsRangFrom:(int)first to:(int)last directionForward:(BOOL)forward
{
	static BOOL moving;
	_layoutUpdated = YES;

	if (moving) {
		_appending = YES;
		return;
	}
	_current = _destination;
	static float duration = kMoveDuration;
	int row = 0;
	for (int i = first; i <= last; ++i) {
		int column = i % _columns;
		if (!column && i) {
			row++;
		}
		NSLog(@"Row is %i", row);
		moving = YES;
		UIButton* btn = _buttons[i];
		[UIView animateWithDuration:duration
							  delay:(row * 0.2 + column * 0.15) * duration
							options:UIViewAnimationOptionBeginFromCurrentState
						 animations:^{
							 btn.origin =[_origins[forward ? i + 1 : i - 1] CGPointValue];
						 }
						 completion:^(BOOL finished) {
							 NSLog(@"Finish %@", finished ? @"YES" : @"NO");
							 moving = NO;
							 [self resortButtonIndexs];
							 if (_appending && _current != _destination) {
								 [self updateLayout];
								 _appending = NO;
							 }
						 }];
	}}

- (void)resortButtonIndexs
{
	if (_panningButton) {
		[_buttons removeObject:_panningButton];
	}

	[_buttons sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		UIButton* btn1 = obj1, *btn2 = obj2;
		float vertical = fabsf(btn1.y - btn2.y), horizontal = fabsf(btn1.x - btn2.x);
		if (vertical > 0) {
			return btn1.y < btn2.y ? NSOrderedAscending : NSOrderedDescending;
		}
		else if (horizontal > 0) {
			return btn1.x < btn2.x ? NSOrderedAscending : NSOrderedDescending;
		}
		return NSOrderedSame;
	}];
	if (_panningButton) {
		if (_current != kOutside) {				//Outside means the last one
			[_buttons insertObject:_panningButton atIndex:_current];
		}
		else {
			[_buttons addObject:_panningButton];
		}
	}
}

@end
