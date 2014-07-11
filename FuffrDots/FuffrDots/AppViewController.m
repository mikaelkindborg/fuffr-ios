//
//  AppViewController.m
//  FuffrDots
//
//  Created by Fuffr on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "AppViewController.h"
#import <CoreText/CTLine.h>
#import <CoreText/CTFont.h>
#import <CoreText/CTStringAttributes.h>

@implementation AppViewController

dispatch_semaphore_t frameRenderingSemaphore;
dispatch_queue_t openGLESContextQueue;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Add custom initialization if needed.
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Create a GL view for drawing.
	self.glView = [[EAGLView alloc] initWithFrame:self.view.bounds];
	self.glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.glView.userInteractionEnabled = YES;
	
	[self.view addSubview:self.glView];

	frameRenderingSemaphore = dispatch_semaphore_create(1);
	openGLESContextQueue = dispatch_get_main_queue();

	// Create view that displays messages.
	[self createMessageView];

	// Create button and popup menu for settings.
	[self createSettingsButtonAndPopUp];

	// Active touches.
	self.touches = [NSMutableSet new];

	// When paintmode is on touches are painted on the screen.
	// When off dots are displayed.
	self.paintModeOn = NO;

	// Create colors for the dots.
	[self createColors];
}

-(void) addColorAtIndex: (int)index
	red: (CGFloat)red
	green: (CGFloat)green
	blue: (CGFloat)blue
{
	DotColor* color = [DotColor new];
	color.red = red;
	color.green = green;
	color.blue = blue;
	[self.dotColors
		setObject: color
		forKey: [NSNumber numberWithInt: index]
	];
}

-(void) createMessageView
{
	self.messageView = [[UILabel alloc] initWithFrame: CGRectMake(10, 25, 300, 300)];
    self.messageView.textColor = [UIColor blackColor];
    self.messageView.backgroundColor = [UIColor clearColor];
    self.messageView.userInteractionEnabled = NO;
	//self.messageView.autoresizingMask = UIViewAutoresizingNone;
	self.messageView.lineBreakMode = NSLineBreakByWordWrapping;
	self.messageView.numberOfLines = 0;
    self.messageView.text = @"";
    [self.view addSubview: self.messageView];
}

-(void) createSettingsButtonAndPopUp
{
	// Create settings button.
	CGRect bounds = CGRectMake(self.view.bounds.size.width - 90, 22, 90, 25);
	self.buttonSettings = [UIButton buttonWithType: UIButtonTypeSystem];
    [self.buttonSettings setFrame: bounds];
	[self.buttonSettings setTitle: @"Settings" forState: UIControlStateNormal];
	[self.buttonSettings
		addTarget: self
		action: @selector(onButtonSettings:)
		forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: self.buttonSettings];

	// Create popup menu.
	self.actionSheet =
		[[UIActionSheet alloc]
			initWithTitle: nil
			delegate: self
			cancelButtonTitle:@"Cancel"
			destructiveButtonTitle:nil
			otherButtonTitles: @"Dots", @"Paint", nil];
}

- (void) createColors
{
	// Set up colors for touches. Max touch id should
	// be 20 in the current case implementation (5 touches,
	// 4 sides, touch ids starting at 1).
	self.dotColors = [NSMutableDictionary new];

	[self addColorAtIndex: 1  red: 1.0 green: 0.0 blue: 0.0];
	[self addColorAtIndex: 2  red: 0.8 green: 0.0 blue: 0.0];
	[self addColorAtIndex: 3  red: 0.6 green: 0.0 blue: 0.0];
	[self addColorAtIndex: 4  red: 0.4 green: 0.0 blue: 0.0];
	[self addColorAtIndex: 5  red: 0.2 green: 0.0 blue: 0.0];

	[self addColorAtIndex: 6  red: 0.0 green: 1.0 blue: 0.0];
	[self addColorAtIndex: 7  red: 0.0 green: 0.8 blue: 0.0];
	[self addColorAtIndex: 8  red: 0.0 green: 0.6 blue: 0.0];
	[self addColorAtIndex: 9  red: 0.0 green: 0.4 blue: 0.0];
	[self addColorAtIndex: 10 red: 0.0 green: 0.2 blue: 0.0];

	[self addColorAtIndex: 11 red: 0.0 green: 0.0 blue: 1.0];
	[self addColorAtIndex: 12 red: 0.0 green: 0.0 blue: 0.8];
	[self addColorAtIndex: 13 red: 0.0 green: 0.0 blue: 0.6];
	[self addColorAtIndex: 14 red: 0.0 green: 0.0 blue: 0.4];
	[self addColorAtIndex: 15 red: 0.0 green: 0.0 blue: 0.2];

	[self addColorAtIndex: 16 red: 1.0 green: 1.0 blue: 0.0];
	[self addColorAtIndex: 17 red: 0.8 green: 0.8 blue: 0.0];
	[self addColorAtIndex: 18 red: 0.6 green: 0.6 blue: 0.0];
	[self addColorAtIndex: 19 red: 0.4 green: 0.4 blue: 0.0];
	[self addColorAtIndex: 20 red: 0.2 green: 0.2 blue: 0.0];
}

-(void) showMessage:(NSString*)message
{
	self.messageView.text = message;
	self.messageView.frame = CGRectMake(10, 25, 300, 300);
	[self.messageView sizeToFit];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];

	// Connect to Fuffr and setup touch events.
	[self setupFuffr];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) onButtonSettings: (id)sender
{
	[self.actionSheet
		showFromRect: self.buttonSettings.frame
		inView: self.view
		animated: YES];
}

- (void) actionSheet: (UIActionSheet *)actionSheet
	clickedButtonAtIndex: (NSInteger)buttonIndex
{
	if (1 == buttonIndex) { self.paintModeOn = YES; }
	else { self.paintModeOn = NO; }
}

- (void) setupFuffr
{
	[self showMessage: @"Scanning for Fuffr..."];

	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	[manager
		onFuffrConnected:
		^{
			NSLog(@"Fuffr Connected");
			[self showMessage: @"Fuffr Connected"];
			[manager useSensorService:
			^{
				// Sensor is available, set active sides.
				[[FFRTouchManager sharedManager]
					enableSides: FFRSideLeft | FFRSideRight | FFRSideTop | FFRSideBottom
					touchesPerSide: @5];
			}];
		}
		onFuffrDisconnected:
		^{
			NSLog(@"Fuffr Disconnected");
			[self showMessage: @"Fuffr Disconnected"];
		}];

	// Register methods for touch events. Here the side constants are
	// bit-or:ed to capture touches on all four sides.
	[manager
		addTouchObserver: self
		touchBegan: @selector(touchesBegan:)
		touchMoved: @selector(touchesMoved:)
		touchEnded: @selector(touchesEnded:)
		sides: FFRSideLeft | FFRSideRight | FFRSideTop | FFRSideBottom];
}

- (void) fuffrConnected
{
	NSLog(@"fuffrConnected");
}

- (void) touchesBegan: (NSSet*)touches
{
	for (FFRTouch* touch in touches)
	{
		[self.touches addObject: touch];
	}

	[self redrawView];
}

- (void) touchesMoved: (NSSet*)touches
{
	[self redrawView];
}

- (void) touchesEnded: (NSSet*)touches
{
	for (FFRTouch* touch in touches)
	{
		[self.touches removeObject: touch];
	}

	[self redrawView];
}

- (void) redrawView
{
	// render asynchronously, only one frame at a time.
	if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
	{
		return;
	}
	
	dispatch_async(openGLESContextQueue, ^{
		[self drawImageView];
		dispatch_semaphore_signal(frameRenderingSemaphore);
	});
	
}

- (void)drawImageView
{
	if (self.paintModeOn)
	{
		self.glView.clearsContextBeforeDrawing = NO;
	}
	
	[self.glView drawViewWithTouches:self.touches paintMode:self.paintModeOn dotColors:self.dotColors];

	NSString* message = [NSString stringWithFormat: @"Number of touches: %i", self.touches.count];
	[self showMessage: message];
}

@end
