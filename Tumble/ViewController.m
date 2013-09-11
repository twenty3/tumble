//
//  ViewController.m
//  Tumble
//

#import "ViewController.h"

@interface TumbleAwayBehavior : UIDynamicBehavior<UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate>

@property (assign, nonatomic) NSTimeInterval firstStageDuration;
@property (assign, nonatomic) NSTimeInterval secondStageDuration;
@property (assign, nonatomic) CGRect startingFrame;
@property (assign, nonatomic) UIView* tumblingView;

@property (strong, nonatomic) UIDynamicAnimator* animator;

@property (nonatomic, strong) UIGravityBehavior* gravityBehavior;
@property (nonatomic, strong) UIAttachmentBehavior* pinAttachmentBehavior;
@property (nonatomic, strong) UICollisionBehavior* collisionBehavior;

- (void) tumbleAwayView:(UIView*)view inView:(UIView*)containerView;

@end

@implementation TumbleAwayBehavior

- (id)init
{
    self = [super init];
    if (self)
    {
        self.firstStageDuration = 0.3;
        self.secondStageDuration = 1.0;
    }
    return self;
}

#pragma mark - Tumbling Away

- (void) tumbleAwayView:(UIView*)view inView:(UIView*)containerView;
{
    self.tumblingView = view;
    self.startingFrame = view.frame;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:containerView];
    self.animator.delegate = self;
    
    // add gravity
    UIGravityBehavior* gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[view]];
    gravityBehavior.magnitude = 3.0;
    [self addChildBehavior:gravityBehavior];
    
    // pin a corner
    CGRect viewFrame = view.frame;
    UIOffset offset = {view.frame.size.width / 2.0, -view.frame.size.height / 2.0};
    CGPoint anchorPoint = {CGRectGetMaxX(viewFrame), CGRectGetMinY(viewFrame)};
    self.pinAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:view offsetFromCenter:offset attachedToAnchor:anchorPoint];
    [self addChildBehavior:self.pinAttachmentBehavior];
    
    // add collision with the reference view
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[view]];
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    self.collisionBehavior.collisionDelegate = self;
    [self addChildBehavior:self.collisionBehavior];
    
    // give the view some bounce for the collision
    UIDynamicItemBehavior* itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[view]];
    itemBehavior.elasticity = 1.3;
    [self addChildBehavior:itemBehavior];
    
    // start tumbling

    UIDynamicAnimator* animator = self.animator;
    NSTimeInterval totalDuration = self.firstStageDuration + self.secondStageDuration;

    // action block of this custom behavior will be called with each tick of the animation
    
    TumbleAwayBehavior* weakSelf = self;
    self.action = ^{
        if (weakSelf.pinAttachmentBehavior && animator.elapsedTime > weakSelf.firstStageDuration)
        {
            // remove the pinning attachment so the view can fall away
            NSLog(@"First stage of tumble complete");
            [weakSelf removeChildBehavior:weakSelf.pinAttachmentBehavior];
            weakSelf.pinAttachmentBehavior = nil;
        }
        else if ( animator.elapsedTime > totalDuration )
        {
            NSLog(@"Second stage of tumble complete, cleaning up");
            [animator removeAllBehaviors];
            weakSelf.animator = nil;
        }
    };
    
    [self.animator addBehavior:self];
}

#pragma mark - UIDynamicAnimatorDelegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator*)animator
{
    // either we came to rest or all our total time elapsed
    NSLog(@"animator did pause, reseting view");
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.tumblingView.transform = CGAffineTransformIdentity;
        self.tumblingView.frame = self.startingFrame;
    });
    
}

#pragma mark - UICollisionBehaviorDelegate
- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{
    // once we collide with anything, remove the collision behavior so the view can fall away
    [self removeChildBehavior:behavior];
    self.collisionBehavior = nil;
}


@end

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *alertView;

@property (strong, nonatomic) TumbleAwayBehavior* tumbleBehavior;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.alertView.layer.cornerRadius = 5.0;
    
    self.tumbleBehavior = [[TumbleAwayBehavior alloc] init];
}


#pragma mark - Alert View

- (IBAction)okButtonTapped:(id)sender
{
    [self dismissAlertView];
}


- (void) dismissAlertView
{
    [self.tumbleBehavior tumbleAwayView:self.alertView inView:self.view];
}



@end
