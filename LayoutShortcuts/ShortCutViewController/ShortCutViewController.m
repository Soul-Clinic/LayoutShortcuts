//
//  ShortCutViewController.m
//  LayoutShortcuts
//
//  Created by Can EriK Lu on 3/29/14.
//  Copyright (c) 2014 Can EriK Lu. All rights reserved.
//

#import "ShortCutViewController.h"
#import "Common.h"
#import <AudioToolbox/AudioToolbox.h>

#define kShakeAnimationKey		@"shaking"
#define kScaleAnimationKey		@"scale"
#define kPressAlpha				0.9
#define kShakeAngle				(10.0 / 180.0 * M_PI)
#define kShakeTimeframe			0.1
#define kStandDuration			1.0
#define kMoveDuration			0.7
#define kPressScaleFactor		1.3
#define kLocationScrollBorder	20

#define kQuietTimeTotal					0.5
#define kQuietTimeIntervalBetween		0.1
#define kMaxDistanceForQuiet			20.0

#define TESTING

enum LocationClass
{
	kLocationOutsideShortcuts 	= -1,
	kLocationScrollLeft			= -2,
	kLocationScrollRight		= -3,
	kLocationScrollTop			= -4,
	kLocationScrollBottom		= -5
};

@interface ShortCutViewController ()
{
	NSMutableArray* _shortcuts;
	NSMutableArray* _origins;
	UIView* _pressingView;
	float _zPosition;
	int _currentIndex, _destinationIndex, _appending, _pageIndex;
	BOOL _layoutUpdated, _scrolling, _firing;
	CGPoint _currentLocation;
}
@end

@implementation ShortCutViewController

- (void)_init
{
	_shortcuts = [NSMutableArray array];
	_origins = [NSMutableArray array];
	_currentIndex = _destinationIndex = kLocationOutsideShortcuts;
}
- (id)init
{
	self = [super init];
	if (self) {
		[self _init];
	}
	return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self _init];
	}
	return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[self _init];
	}
	return self;
}

- (void)loadView
{
	[super loadView];
    // Do any additional setup after loading the view.
	_scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
	for (UIView* subview in self.view.subviews) {
		[self.scrollView addSubview:subview];
	}
	_scrollView.backgroundColor = self.view.backgroundColor;
	_scrollView.delegate = self;
	self.view = _scrollView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_scrollView.pagingEnabled = YES;
	[self subviewsUpdated];

	NSLog(@"Width in load %f", _scrollView.width);
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	float minY = MAXFLOAT, range = 10;
	for (UIView* view in _shortcuts) {
		minY = MIN(view.y, minY);
	}
	_columns = 0;
	for (UIView* view in _shortcuts) {
		if (view.y - minY < range) {
			_columns++;
		}
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.view.superview.backgroundColor = [UIColor clearColor];

	_scrollView.contentSize = CGSizeMake(_scrollView.width * 3, _scrollView.height * 3);
	_scrollView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"flyship.jpg"]];

	UIView* aView = _shortcuts.lastObject;
	aView.x += _scrollView.width;
	aView.y += _scrollView.height;
	[self subviewsUpdated];
	NSLog(@"Width in appear %f", _scrollView.width);
}

- (void)alignShortcuts
{

}
- (void)setColumns:(int)columns
{
	if (_columns != columns) {
		_columns = columns;
		[self alignShortcuts];
	}
}
- (void)setRows:(int)rows
{
	if (_rows != rows) {
		_rows = rows;
		[self alignShortcuts];
	}
}

- (void)subviewsUpdated
{
	[_shortcuts removeAllObjects];
	[_origins removeAllObjects];
	for (UIView* aView in _scrollView.subviews) {
		if (CGSizeEqualToSize(aView.frame.size, CGSizeZero) || aView.userInteractionEnabled == NO) {
			continue;						//Get rid of the UILayoutGuid
		}

		UILongPressGestureRecognizer* lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self
																						 action:@selector(handleLongPressGesture:)];
		UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
		[aView addGestureRecognizer:lp];
		[aView addGestureRecognizer:pan];
		[_shortcuts addObject:aView];
	}
	[self _resortShortcutsIndex];
	for (int i = 0; i < _shortcuts.count; ++i) {
		UIView* aView = _shortcuts[i];
		aView.layer.zPosition = i;
		[_origins addObject:[NSValue valueWithCGPoint:aView.origin]];
	}
}
- (void)handlePan:(UIPanGestureRecognizer*)gesture
{
	NSLog(@"Velocity is %@", NSStringFromCGPoint([gesture velocityInView:gesture.view]));

}

- (int)_indexAtPosition:(CGPoint)point
{
	static float scWidth, scHeight, paddingX, paddingY;

	float currentPage, totalPages, x, y;

	if (self.vertical == NO) {
		currentPage = floorf(_scrollView.contentOffset.x / _scrollView.width);
		totalPages = _vertical ? : ceilf(_scrollView.contentSize.width / _scrollView.width),
		x = point.x - _scrollView.contentOffset.x;

		if (x < kLocationScrollBorder && currentPage > 0) {
			NSLog(@"Scroll left");
			return kLocationScrollLeft;
		}
		else if (x > _scrollView.width - kLocationScrollBorder && currentPage < totalPages - 1) {
			NSLog(@"Scroll right");
			return kLocationScrollRight;
		}
	}
	else
	{
		currentPage = floorf(_scrollView.contentOffset.y / _scrollView.height);
		totalPages = ceilf(_scrollView.contentSize.height / _scrollView.height);
		y = point.y - _scrollView.contentOffset.y;

		if (y < kLocationScrollBorder && currentPage > 0) {
			NSLog(@"Scroll top");
			return kLocationScrollTop;
		}
		else if (y > _scrollView.height - kLocationScrollBorder && currentPage < totalPages - 1) {
			NSLog(@"Scroll bottom");
			return kLocationScrollBottom;
		}
	}

	if (_origins.count == 1) {

		CGPoint pt = [_origins.firstObject CGPointValue];
		if (point.x >  pt.x - paddingX && point.x < pt.x + paddingX + _pressingView.width
			&& point.y > pt.y - paddingY && point.y< pt.y + paddingY + _pressingView.height) {
			return 0;
		}
		else {
			return kLocationOutsideShortcuts;
		}
	}

	if (!scWidth) {
		UIView* sc = _shortcuts.firstObject;
		scWidth = sc.width;
		scHeight = sc.height;
		CGPoint pt1 =  [_origins[0] CGPointValue],
		pt2 =  [_origins[1] CGPointValue],
		pt3 = [_origins[_columns] CGPointValue];
		float distanceX = pt2.x - pt1.x - scWidth, distanceY = pt3.y - pt1.y - scHeight;
		paddingX = distanceX * 0.5;
		paddingY = distanceY * 0.5;
	}
	for (int i = 0; i < _origins.count; ++i) {
		CGPoint pt = [_origins[i] CGPointValue];
		if (point.x >  pt.x - paddingX && point.x < pt.x + paddingX + scWidth
			&& point.y > pt.y - paddingY && point.y< pt.y + paddingY + scHeight) {
			return i;
		}
	}
	return kLocationOutsideShortcuts;
}
- (int)_pressingIndex
{
	return [self _indexAtPosition:_currentLocation];
}

- (void)_offsetDetection:(NSTimer *)timer
{
	static NSMutableArray* distances;
	static CGPoint lastLocation;
	static float offset;
	static int index, count;
	static BOOL firing;

	if (distances != timer.userInfo) {
		distances = timer.userInfo;
		lastLocation = _currentLocation;
		index = 0;
		count = (int)distances.count;
		firing = NO;
	}


	if (_scrolling) {
		distances[index] = [NSNumber numberWithFloat:kMaxDistanceForQuiet];
		return;
	}

	offset = sqrtf(powf(_currentLocation.x - lastLocation.x, 2) + powf(_currentLocation.y - lastLocation.y, 2));

	distances[index] = [NSNumber numberWithFloat:offset];
	index = (index + 1) % count;
	float totalDistance = 0;

	for (NSNumber* distance in distances) {
		totalDistance += distance.floatValue;
	}
	if (totalDistance < kMaxDistanceForQuiet) {
		if (!firing) {
			firing = YES;
			[self _updateLayout];
		}
	}
	else if (firing) {
		firing = NO;
	}
//	NSLog(@"Last distance %f", totalDistance);
	lastLocation = _currentLocation;
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer*)gesture
{
	static CGPoint start, beginLocation, currentOrigin;
	static NSTimer* timer;
	UIView* shortcut = gesture.view;
	CALayer* layer = shortcut.layer;

	if (_pressingView && _pressingView != shortcut) {		//Multiple touches
		return;
	}

	switch (gesture.state) {
		case UIGestureRecognizerStateBegan:
		{
			AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);			//Only work on iPhone

			start = gesture.view.origin;
			shortcut.alpha *= kPressAlpha;
			beginLocation = [gesture locationInView:_scrollView];
			_currentLocation = beginLocation;
			_zPosition = layer.zPosition;
			_currentIndex = [self _pressingIndex];
			_pressingView = shortcut;

			layer.zPosition = 100;

			[layer addAnimation:[self _scaleAnimationFactor:kPressScaleFactor duration:0.2 * kStandDuration] forKey:kScaleAnimationKey];
			for (UIView* aView in _shortcuts) {
				if (aView != shortcut) {
					[aView.layer addAnimation:[self _shakeAnimationAngle:kShakeAngle duration:kShakeTimeframe] forKey:kShakeAnimationKey];
				}
			}
			shortcut.layer.shadowOpacity = 1;
			shortcut.layer.shadowRadius = 5;

			int count = ceilf(kQuietTimeTotal / kQuietTimeIntervalBetween);
			NSMutableArray* distances = [NSMutableArray arrayWithCapacity:count];
			for (int i = 0; i < count; ++i) {
				distances[i] = @0;
			}

			if (timer) {
				[timer invalidate];
			}
			timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_offsetDetection:) userInfo:distances repeats:YES];

			break;
		}
		case UIGestureRecognizerStateChanged:
		{
			if (_scrolling) {
				return;
			}
			_currentLocation = [gesture locationInView:_scrollView];
			currentOrigin = CGPointMake(start.x + (_currentLocation.x - beginLocation.x ), start.y + (_currentLocation.y - beginLocation.y));
			shortcut.origin = currentOrigin;

			break;
		}
		case UIGestureRecognizerStateEnded:
		{
			[timer invalidate];
			if (!_scrolling) {
				[self layBack:shortcut];
			}

			break;
		}
		default:
			break;
	}
}

- (void)layBack:(UIView*)shortcut
{
	CALayer* layer = shortcut.layer;
	layer.transform = [((CALayer*)layer.presentationLayer) transform];
	[layer removeAnimationForKey:kScaleAnimationKey];

//	_currentIndex = [self _indexAtPosition:_currentLocation];

	[self _resortShortcutsIndex];
	float duration = (_currentIndex >= 0 ? 0.2 : 0.6) * kStandDuration;
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 shortcut.alpha /= kPressAlpha;
						 layer.transform = CATransform3DIdentity;
						 if (_layoutUpdated == NO) {			// Not changed after long press begin, so lay back to the original one
							 NSUInteger index = [_shortcuts indexOfObject:shortcut];
							 shortcut.origin = [_origins[index] CGPointValue];
						 }
						 else {
							 for (int i = 0; i < _shortcuts.count; ++i) {
								 UIButton* btn = _shortcuts[i];
								 btn.origin = [_origins[i] CGPointValue];
							 }
						 }
					 }
					 completion:^(BOOL finished) {
						 layer.zPosition = _zPosition;
						 for (UIView* shortcut in _shortcuts) {
							 [shortcut.layer removeAnimationForKey:kShakeAnimationKey];
						 }
						 _currentIndex = kLocationOutsideShortcuts;
						 _pressingView = nil;
						 _appending = NO;
						 _layoutUpdated = NO;
						 [self _resortShortcutsIndex];
						 NSLog(@"Complete");
					 }];
}
- (void)_resortShortcutsIndex
{
	if (_pressingView) {
		[_shortcuts removeObject:_pressingView];
	}
	float pageWidth = _scrollView.width;

	[_shortcuts sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		UIView* view1 = obj1, *view2 = obj2;
		float vertical = view1.y - view2.y, horizontal = view1.x - view2.x;
		float pageIndex1= floorf(view1.x / pageWidth), pageIndex2 = floorf(view2.x / pageWidth);

		if (pageIndex1 != pageIndex2) {
			return pageIndex1 < pageIndex2 ? NSOrderedAscending : NSOrderedDescending;
		}

		if (vertical != 0) {
			return view1.y < view2.y ? NSOrderedAscending : NSOrderedDescending;
		}
		else if (horizontal != 0) {
			return view1.x < view2.x ? NSOrderedAscending : NSOrderedDescending;
		}
		return NSOrderedSame;
	}];

	if (_pressingView) {
		if (_currentIndex >= 0) {				//Outside means the last one
			[_shortcuts insertObject:_pressingView atIndex:_currentIndex];
		}
		else {
			[_shortcuts addObject:_pressingView];
		}
	}
}

- (CABasicAnimation*)_scaleAnimationFactor:(float)factor duration:(float)duration
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
- (CABasicAnimation*)_shakeAnimationAngle:(float)angle duration:(float)duration
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

- (void)_updateLayout
{
//	_currentLocation
	_destinationIndex = [self _pressingIndex];

	if (_destinationIndex < 0) {
		CGPoint offset = _scrollView.contentOffset;
		switch (_destinationIndex) {
			case kLocationScrollBottom:
				offset.y += _scrollView.height;
				break;
			case kLocationScrollTop:
				offset.y -= _scrollView.height;
				break;
			case kLocationScrollLeft:
				offset.x -= _scrollView.width;
				break;
			case kLocationScrollRight:
				offset.x += _scrollView.width;
				break;
			default:
				break;
		}

		if (!CGPointEqualToPoint(offset, _scrollView.contentOffset)) {
			_scrollView.superview.clipsToBounds = YES;
			[_scrollView.superview addSubview:_pressingView];
			_pressingView.x -= _scrollView.contentOffset.x;
			_pressingView.y -= _scrollView.contentOffset.y;
			_scrolling = YES;
			[_scrollView setContentOffset:offset animated:YES];
		}
	}
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	[_scrollView addSubview:_pressingView];
	_pressingView.x += _scrollView.contentOffset.x;
	_pressingView.y += _scrollView.contentOffset.y;
	_scrolling = NO;
	NSLog(@"End scrolling");
}























@end
