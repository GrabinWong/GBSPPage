//
//  SPPageController.m
//  Radio
//
//  Created by sparrow on 25/11/2016.
//  Copyright © 2016 qzone. All rights reserved.
//

#import "SPPageController.h"
#import "SPPageContentView.h"

typedef NS_ENUM(NSInteger,SPPageScrollDirection) {
    PageLeft = 0,
    PageRight = 1,
};


@interface SPPageController  () <NSCacheDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableDictionary <NSNumber *, UIViewController *> *memCacheDic;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSNumber *> *lastContentOffset;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSNumber *> *lastContentSize;

@property (nonatomic, strong) SPPageContentView *scrollView;

@property (nonatomic, assign) NSInteger lastSelectedIndex;
@property (nonatomic, assign) NSInteger guessToIndex;
@property (nonatomic, assign) CGFloat originOffset;
@property (nonatomic, assign) BOOL firstWillAppear;
@property (nonatomic, assign) BOOL firstWillLayoutSubViews;
@property (nonatomic, assign) BOOL firstDidAppear;

@property (nonatomic, assign, readwrite) NSInteger currentPageIndex;

@end

@implementation SPPageController

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.memCacheDic = [[NSMutableDictionary <NSNumber *, UIViewController *> alloc] init];
        self.lastContentOffset = [[NSMutableDictionary <NSNumber *, NSNumber *> alloc] init];
        self.lastContentSize = [[NSMutableDictionary <NSNumber *, NSNumber *> alloc] init];
    }
    return self;
}

-(void)reloadPage
{
    for (UIView *view in self.scrollView.subviews) {
        [view removeFromSuperview];
    }



    [self.lastContentOffset removeAllObjects];
    [self.lastContentSize removeAllObjects];
    [self.memCacheDic removeAllObjects];

    [self addVisibleViewContorllerWithIndex:self.currentPageIndex];
    [self updateScrollViewLayoutIfNeed];

    if ([self.delegate respondsToSelector:@selector(willChangeInit)]) {
        [self.delegate willChangeInit];
    }

    if ([self.delegate respondsToSelector:@selector(pageviewController:willLeaveFromVC:toViewController:)]) {
        [self.delegate pageviewController:self willLeaveFromVC:[self controllerAtIndex:self.lastSelectedIndex] toViewController:[self controllerAtIndex:self.currentPageIndex]];
    }

    [self showPageAtIndex:self.currentPageIndex animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.firstWillAppear = YES;
    self.firstDidAppear = YES;
    self.firstWillLayoutSubViews = YES;
    self.scrollView = [[SPPageContentView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self configScrollView:self.scrollView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.firstWillAppear) {
        if ([self.delegate respondsToSelector:@selector(pageviewController:willLeaveFromVC:toViewController:)]) {
            [self.delegate pageviewController:self willLeaveFromVC:[self controllerAtIndex:self.lastSelectedIndex] toViewController:[self controllerAtIndex:self.currentPageIndex]];
        }

        if ([self.dataSource respondsToSelector:@selector(screenEdgePanGestureRecognizer)] && self.dataSource.screenEdgePanGestureRecognizer){
            [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.dataSource.screenEdgePanGestureRecognizer];
        } else {

            if ([self __screenEdgePanGestureRecognizer]) {
                [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:[self __screenEdgePanGestureRecognizer]];
                
            }
        }

        self.firstWillAppear = NO;

        [self updateScrollViewLayoutIfNeed];
    }

    [[self controllerAtIndex:self.currentPageIndex] beginAppearanceTransition:YES animated:YES];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.firstDidAppear) {

        if ([self.delegate respondsToSelector:@selector(willChangeInit)]) {
            [self.delegate willChangeInit];
        }

        if ([self.delegate respondsToSelector:@selector(pageviewController:didLeaveFromVC:toViewController:)]) {
            [self.delegate pageviewController:self didLeaveFromVC:[self controllerAtIndex:self.lastSelectedIndex] toViewController:[self controllerAtIndex:self.currentPageIndex]];
        }

        self.firstDidAppear = NO;
    }


    [[self controllerAtIndex:self.currentPageIndex] endAppearanceTransition];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (self.firstWillLayoutSubViews) {
        [self updateScrollViewLayoutIfNeed];
        [self updateScrollViewDisplayIndexIfNeed];
        self.firstWillLayoutSubViews = NO;
    } else {
        [self updateScrollViewLayoutIfNeed];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
}

- (BOOL)needIgnoreFMStatusBarStyle
{
    return YES;
}

- (void)configScrollView:(UIScrollView *)scrollView
{
    scrollView.delegate = self;

    [self.view addSubview:scrollView];
}

- (UIScreenEdgePanGestureRecognizer *)__screenEdgePanGestureRecognizer
{
    UIScreenEdgePanGestureRecognizer *screenEdgePanGestureRecognizer = nil;
    if (self.navigationController.view.gestureRecognizers.count > 0)
    {
        for (UIGestureRecognizer *recognizer in self.navigationController.view.gestureRecognizers)
        {
            if ([recognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]])
            {
                screenEdgePanGestureRecognizer = (UIScreenEdgePanGestureRecognizer *)recognizer;
                break;
            }
        }
    }

    return screenEdgePanGestureRecognizer;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.memCacheDic removeAllObjects];
    // Dispose of any resources that can be recreated.
}


- (void)__removeFromParentViewController:(UIViewController *)controller
{
    [controller willMoveToParentViewController:nil];
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
}

- (NSInteger)pageCount
{
    return [self.dataSource numberOfControllers];
}

#pragma scrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.isDragging && scrollView == self.scrollView) {


        CGFloat offset = scrollView.contentOffset.x;
        CGFloat width = scrollView.frame.size.width;
        NSInteger lastGuestIndex=  self.guessToIndex < 0? self.currentPageIndex:self.guessToIndex;

        if (self.originOffset < offset){
            self.guessToIndex = ceil(offset/width);
        } else if (self.originOffset >= offset) {
            self.guessToIndex = floor(offset/width);
        }
        NSInteger maxCount = [self pageCount];


        if ([self isPreLoad]) {
            if  (lastGuestIndex != self.guessToIndex && self.guessToIndex != self.currentPageIndex && self.guessToIndex >=0 && self.guessToIndex < maxCount) {

                if ([self.delegate respondsToSelector:@selector(willChangeInit)]) {
                    [self.delegate willChangeInit];
                }

                UIViewController *fromVC = [self controllerAtIndex:self.currentPageIndex];
                UIViewController *toVc = [self controllerAtIndex:self.guessToIndex];

                [self.delegate pageviewController:self willTransitionFromVC:fromVC toViewController:toVc];
                [toVc beginAppearanceTransition:YES animated:YES];
                if (lastGuestIndex == self.currentPageIndex) {
                    [fromVC beginAppearanceTransition:NO animated:YES];
                }


                if (lastGuestIndex != self.currentPageIndex && lastGuestIndex >=0 && lastGuestIndex < maxCount) {
                    UIViewController *lastGuestVC = [self controllerAtIndex:lastGuestIndex];
                    [lastGuestVC beginAppearanceTransition:NO animated:YES];
                    [lastGuestVC endAppearanceTransition];
                }
                
            }
        } else {
            if ((self.guessToIndex != self.currentPageIndex && !self.scrollView.isDecelerating) || self.scrollView.isDecelerating) {
                if (lastGuestIndex != self.guessToIndex && self.guessToIndex >= 0 && self.guessToIndex <maxCount) {

                    if ([self.delegate respondsToSelector:@selector(willChangeInit)]) {
                        [self.delegate willChangeInit];
                    }

                    if ([self.delegate respondsToSelector:@selector(pageviewController:willTransitionFromVC:toViewController:)]) {
                        [self.delegate pageviewController:self willTransitionFromVC:[self.memCacheDic objectForKey:@(self.currentPageIndex)] toViewController:[self.memCacheDic objectForKey:@(self.guessToIndex)]];
                    }
                }
            }

        }

        if ([self.delegate respondsToSelector:@selector(scrollViewContentOffsetWithRatio:draging:)]) {
            [self.delegate scrollViewContentOffsetWithRatio:scrollView.contentOffset.x/scrollView.frame.size.width draging:YES];
        }

    }

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (!scrollView.isDecelerating) {
        self.originOffset = scrollView.contentOffset.x;
        self.guessToIndex = self.currentPageIndex;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updatePageViewAfterDragging:scrollView];
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if ([self.delegate respondsToSelector:@selector(scrollViewContentOffsetWithRatio: draging:)]) {
        [self.delegate scrollViewContentOffsetWithRatio:targetContentOffset->x/scrollView.frame.size.width draging:NO];
    }
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

- (void)updatePageViewAfterDragging:(UIScrollView *)scrollView
{
    NSInteger newIndex = [self.scrollView calcIndexWithOffset:scrollView.contentOffset.x width:scrollView.frame.size.width];
    NSInteger oldIndex = self.currentPageIndex;
    self.currentPageIndex = newIndex;
    
    if (newIndex == oldIndex) {
        if (self.guessToIndex >= 0 && self.guessToIndex < [self pageCount]) {
            [[self controllerAtIndex:oldIndex] beginAppearanceTransition:YES animated:YES];
            
            [[self controllerAtIndex:oldIndex] endAppearanceTransition];
            
            [[self controllerAtIndex:self.guessToIndex] beginAppearanceTransition:NO animated:YES];
            
            [[self controllerAtIndex:self.guessToIndex] endAppearanceTransition];
        }
    } else {
        if (![self isPreLoad]) {
            [[self controllerAtIndex:newIndex] beginAppearanceTransition:YES animated:YES];
            [[self controllerAtIndex:oldIndex] beginAppearanceTransition:NO animated:YES];

        }
        [[self controllerAtIndex:newIndex] endAppearanceTransition];
        [[self controllerAtIndex:oldIndex] endAppearanceTransition];

    }
    
    self.originOffset = scrollView.contentOffset.x;
    self.guessToIndex = self.currentPageIndex;
    if ([self.delegate respondsToSelector:@selector(pageviewController:didTransitionFromVC:toViewController:)]) {
        [self.delegate pageviewController:self didTransitionFromVC:[self controllerAtIndex:self.lastSelectedIndex] toViewController:[self controllerAtIndex:self.currentPageIndex]];
    }

}


- (BOOL)isPreLoad
{
    return [self.dataSource respondsToSelector:@selector(isPreLoad)] && [self.dataSource isPreLoad];
}

- (void)addVisibleViewContorllerWithIndex:(NSInteger)index
{
    if (index < 0 || index > [self pageCount]) {
        return;
    }

    UIViewController *vc = [self controllerAtIndex:index];
 
    CGRect childViewFrame = [self.scrollView calcVisibleViewControllerFrameWithIndex:index];
    [self __addChildViewController:vc frame:childViewFrame];

}

- (void)__addChildViewController:(UIViewController *)childController frame:(CGRect)frame
{
    [self __addChildViewController:childController];
    childController.view.frame = frame;
    [self.scrollView addSubview:childController.view];
}

- (void)__addChildViewController:(UIViewController *)childController
{
    if (![self.childViewControllers containsObject:childController]) {
        [self addChildViewController:childController];
        [self didMoveToParentViewController:self];
    }
    [super addChildViewController:childController];
}

- (void)updateScrollViewDisplayIndexIfNeed
{
    if (self.scrollView.frame.size.width > 0)  {
        [self addVisibleViewContorllerWithIndex:self.currentPageIndex];
        CGPoint newOffset = [self.scrollView calOffsetWithIndex:self.currentPageIndex width:self.scrollView.frame.size.width maxWidth:self.scrollView.contentSize.width];
        if (newOffset.x != self.scrollView.contentOffset.x || newOffset.y != self.scrollView.contentOffset.y) {
            self.scrollView.contentOffset = newOffset;
        }

        [self controllerAtIndex:self.currentPageIndex].view.frame = [self.scrollView calcVisibleViewControllerFrameWithIndex:self.currentPageIndex];
    }
}

- (void)updateScrollViewLayoutIfNeed
{
    if (self.scrollView.frame.size.width > 0) {
        CGFloat width = [self pageCount] * self.scrollView.frame.size.width;
        CGFloat height = self.scrollView.frame.size.height;
        [self.scrollView updateScrollViewLayoutWithSize:CGSizeMake(width, height)];
    }
}

- (void)showPageAtIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index < 0 || index>= [self pageCount]) {
        return;
    }

    if (self.scrollView.frame.size.width > 0 && self.scrollView.contentSize.width > 0) {
        NSInteger oldSelectIndex = self.lastSelectedIndex;
        self.lastSelectedIndex = self.currentPageIndex;
        self.currentPageIndex = index;

        if ([self.delegate respondsToSelector:@selector(willChangeInit)]) {
            [self.delegate willChangeInit];
        }

        if ([self.delegate respondsToSelector:@selector(pageviewController:willLeaveFromVC:toViewController:)]) {
            [self.delegate pageviewController:self willLeaveFromVC:[self controllerAtIndex:self.lastSelectedIndex] toViewController:[self controllerAtIndex:self.currentPageIndex]];
        }

        [self addVisibleViewContorllerWithIndex:index];
        [self scrollBeginAnimation:animated];
        if (animated) {
            //页面切换动画
            if (self.lastSelectedIndex != self.currentPageIndex) {
                __block CGSize pageSize = self.scrollView.frame.size;
                SPPageScrollDirection direction = (self.lastSelectedIndex < self.currentPageIndex) ? PageRight :PageLeft;
                UIView *lastView = [self controllerAtIndex:self.lastSelectedIndex].view;
                UIView *currentView = [self controllerAtIndex:self.currentPageIndex].view;
                UIView *oldSelectView = [self controllerAtIndex:oldSelectIndex].view;
                CGFloat backgroundIndex = [self.scrollView calcIndexWithOffset:self.scrollView.contentOffset.x width:self.scrollView.frame.size.width];
                UIView *backgroundView = nil;
                if (oldSelectView.layer.animationKeys.count > 0 && lastView.layer.animationKeys.count > 0) {
                    UIView *tmpView = [self controllerAtIndex:backgroundIndex].view;
                    if (tmpView != currentView && tmpView != lastView) {
                        backgroundView = tmpView;
                        backgroundView.hidden = YES;
                    }
                }
                
                [self.scrollView.layer removeAllAnimations];
                [oldSelectView.layer removeAllAnimations];
                [lastView.layer removeAllAnimations];
                [currentView.layer removeAllAnimations];
                
                [self moveBackToOriginPositionIfNeeded:oldSelectView index:oldSelectIndex];
                
                [self.scrollView bringSubviewToFront:lastView];
                
                [self.scrollView bringSubviewToFront:currentView];
                
                lastView.hidden = NO;
                currentView.hidden = NO;
                
                CGPoint lastViewStartOrigin = lastView.frame.origin;
                CGPoint currentViewStartOrigin = lastViewStartOrigin;
                CGFloat offset = direction == PageRight?self.scrollView.frame.size.width:-self.scrollView.frame.size.width;
                currentViewStartOrigin.x += offset;
                
                CGPoint lastViewAnimationOrgin = lastViewStartOrigin;
                lastViewAnimationOrgin.x -= offset;
                CGPoint currentViewAnimationOrgin = lastViewStartOrigin;
                CGPoint lastViewEndOrigin = lastViewStartOrigin;
                CGPoint currentViewEndOrgin =  currentView.frame.origin;
                
                lastView.frame = CGRectMake(lastViewStartOrigin.x, lastViewStartOrigin.y, pageSize.width, pageSize.height);
                
                currentView.frame = CGRectMake(currentViewStartOrigin.x, currentViewStartOrigin.y, pageSize.width, pageSize.height);

                CGFloat duration = 0.3;

                __weak SPPageController *wSelf = self;
                [UIView animateWithDuration:duration animations:^{
                    lastView.frame = CGRectMake(lastViewAnimationOrgin.x, lastViewAnimationOrgin.y, pageSize.width, pageSize.height);
                    currentView.frame = CGRectMake(currentViewAnimationOrgin.x, currentViewAnimationOrgin.y, pageSize.width, pageSize.height);
                }  completion:^(BOOL finished) {
                    SPPageController *bSelf = wSelf;

                     if (finished) {
                         pageSize = bSelf.scrollView.frame.size;
                            lastView.frame = CGRectMake(lastViewEndOrigin.x, lastViewEndOrigin.y, pageSize.width, pageSize.height);
                            
                            currentView.frame = CGRectMake(currentViewEndOrgin.x, currentViewEndOrgin.y, pageSize.width, pageSize.height);
                            
                            backgroundView.hidden = NO;
                            [bSelf moveBackToOriginPositionIfNeeded:currentView index:bSelf.currentPageIndex];
                            [bSelf moveBackToOriginPositionIfNeeded:lastView index:bSelf.lastSelectedIndex];
                            [bSelf scrollAnimation:animated];
                            [bSelf scrollEndAnimation:animated];
                        }
                }];
                
                
            } else {
                [self scrollAnimation:animated];
                [self scrollEndAnimation:animated];
            }
        } else {
            [self scrollAnimation:animated];
            [self scrollEndAnimation:animated];
        }
        
        
    }
    
}

- (void) moveBackToOriginPositionIfNeeded:(UIView *)view index:(NSInteger)index
{
    if (index < 0 || index >= [self pageCount] || !view) {
        return;
    }
    
    
    UIView *destView = view;
    CGPoint originPostion = [self.scrollView calOffsetWithIndex:index width:self.scrollView.frame.size.width maxWidth:self.scrollView.contentSize.width];
    if (destView.frame.origin.x != originPostion.x) {
        CGRect newFrame = destView.frame;
        newFrame.origin = originPostion;
        destView.frame = newFrame;
    }
    
}

- (UIViewController *)controllerAtIndex:(NSInteger)index
{
    if (![self.memCacheDic objectForKey:@(index)]) {
        UIViewController *controller = [self.dataSource controllerAtIndex:index];

        if (controller) {
            if ([controller conformsToProtocol:@protocol(SPPageSubControllerDataSource)]) {
                [self bindController:(UIViewController<SPPageSubControllerDataSource> *)controller index:index];
            }

            [self.memCacheDic setObject:controller forKey:@(index)];

            [self addVisibleViewContorllerWithIndex:index];
        }
    }


    return [self.memCacheDic objectForKey:@(index)];
}


-(void)dealloc
{
    self.delegate = nil;
    self.dataSource = nil;
    for (NSNumber *key in self.memCacheDic) {
        UIViewController *vc = self.memCacheDic[key];
        if ([vc conformsToProtocol:@protocol(SPPageSubControllerDataSource)]) {
            UIScrollView *scrollView = [(UIViewController<SPPageSubControllerDataSource> *)vc preferScrollView];
            [scrollView removeObserver:self forKeyPath:@"contentOffset"];
            [scrollView removeObserver:self forKeyPath:@"contentSize"];
        }
    }

    self.memCacheDic = nil;
}

- (void)bindController:(UIViewController<SPPageSubControllerDataSource> *)controller index:(NSInteger)index
{
    UIScrollView *scrollView = [controller preferScrollView];
    scrollView.scrollsToTop = NO;
    scrollView.tag = index;
    if ([self.dataSource respondsToSelector:@selector(pageTopAtIndex:)]) {
        UIEdgeInsets contentInset = scrollView.contentInset;

        scrollView.contentInset =  UIEdgeInsetsMake([self.dataSource pageTopAtIndex:index], contentInset.left, contentInset.bottom, contentInset.right);
        
#ifdef __IPHONE_11_0
        if ([UIDevice currentDevice].systemVersion.floatValue >= 11.0) {// ios11 苹果加了一个安全区域 会自动修改scrollView的contentOffset
            scrollView.contentInsetAdjustmentBehavior =  UIScrollViewContentInsetAdjustmentNever;
        }
#endif

    }
    


    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    [scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    UIScrollView *scrollView = object;
    NSInteger index = scrollView.tag;
    if ([keyPath isEqualToString:@"contentOffset"]) {
        if ([self.delegate respondsToSelector:@selector(cannotScrollWithPageOffset)] && [self.delegate cannotScrollWithPageOffset]) {
            return;
        }

        if (ceil([self.lastContentSize[@(index)] floatValue]) == ceil(scrollView.contentSize.height)) {
            self.lastContentOffset[@(index)] = @(scrollView.contentOffset.y);
        }

        [self.delegate scrollWithPageOffset:scrollView.contentOffset.y index:index];

        NSLog(@"contentInset top:%@, bottom:%@, left:%@, right:%@", @(scrollView.contentInset.top), @(scrollView.contentInset.bottom), @(scrollView.contentInset.left), @(scrollView.contentInset.right));
    } else if ([keyPath isEqualToString:@"contentSize"]) {
        if (self.lastContentSize[@(index)] && ( ceil([self.lastContentSize[@(index)] floatValue])  != ceil(scrollView.contentSize.height))) {
            self.lastContentSize[@(index)] = @(scrollView.contentSize.height);
            if ( self.lastContentOffset[@(index)]) {
                scrollView.contentOffset = CGPointMake(0, [self.lastContentOffset[@(index)] floatValue]);
            }
        } else {
            self.lastContentSize[@(index)] = @(scrollView.contentSize.height);
        }

        if (!UIAccessibilityIsVoiceOverRunning()) {//在voiceover 强行修改contentsize会出现问题
            if ([self.dataSource respondsToSelector:@selector(scrollMinHeight)]) {
                CGFloat minHeight = [self.dataSource scrollMinHeight];
                if (scrollView.contentSize.height < minHeight && [self.dataSource numberOfControllers] > 1) {
                    self.lastContentSize[@(index)] = @(minHeight);
                    scrollView.contentSize =  CGSizeMake(scrollView.contentSize.width, minHeight);
                }
            }
        }
    }
}

- (void)scrollAnimation:(BOOL)animated
{
    [self.scrollView setContentOffset:[self.scrollView calOffsetWithIndex:self.currentPageIndex width:self.scrollView.frame.size.width maxWidth:self.scrollView.contentSize.width] animated:NO];
}

- (void)scrollBeginAnimation:(BOOL)animated
{
    [[self controllerAtIndex:self.currentPageIndex] beginAppearanceTransition:YES animated:animated];
    if (self.currentPageIndex != self.lastSelectedIndex) {
        [[self controllerAtIndex:self.lastSelectedIndex] beginAppearanceTransition:NO animated:animated];
    }
}

- (void)scrollEndAnimation:(BOOL)animated
{
    [[self controllerAtIndex:self.currentPageIndex] endAppearanceTransition];
    if (self.currentPageIndex != self.lastSelectedIndex) {
        [[self controllerAtIndex:self.lastSelectedIndex] endAppearanceTransition];
    }
    if ([self.delegate respondsToSelector:@selector(pageviewController:didLeaveFromVC:toViewController:)]) {
        [self.delegate pageviewController:self didLeaveFromVC:[self controllerAtIndex:self.lastSelectedIndex] toViewController:[self controllerAtIndex:self.currentPageIndex]];
    }

}

- (void)resizePageAtIndex:(NSInteger)index offset:(CGFloat)offset isNeedChangeOffset:(BOOL)isNeedChangeOffset
{
    UIViewController *vc = [self controllerAtIndex:index];
    if (vc && [vc conformsToProtocol:@protocol(SPPageSubControllerDataSource)]) {
        UIScrollView *scrollView = [(UIViewController<SPPageSubControllerDataSource> *)vc preferScrollView];

        scrollView.contentInset = UIEdgeInsetsMake([self.dataSource pageTopAtIndex:index], scrollView.contentInset.left, scrollView.contentInset.bottom, scrollView.contentInset.right);
        if (isNeedChangeOffset) {
            scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, offset);
        }
    }
}

- (NSInteger)indexOfController:(UIViewController *)vc
{
    for (NSNumber *key in self.memCacheDic) {
        if (vc ==self.memCacheDic[key]) {
            return [key integerValue];
        }
    }

    return  -1;
}

- (void)updateCurrentIndex:(NSInteger)index
{
    self.currentPageIndex = index;
}


@end
