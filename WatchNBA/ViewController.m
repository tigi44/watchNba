//
//  ViewController.m
//  WatchNBA
//
//  Created by tigi on 2018. 2. 20..
//  Copyright © 2018년 tigi. All rights reserved.
//

#import "ViewController.h"
#import "NBAGameViewController.h"
#import "NBAApiUrl.h"
#import <AFNetworking/AFNetworking.h>
#import <PromiseKit/PromiseKit.h>
#import "NBAVOGame.h"

@interface ViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property(nonatomic, strong) UIPageViewController *pageViewController;
@property(nonatomic, assign) NSInteger numGames;
@property(nonatomic, strong) NSArray<NSDictionary *> *games;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setup];
    
    [AnyPromise promiseWithResolverBlock:^(PMKResolver resolver) {
        [self setupTodayApiPromiseResolver:resolver];
    }].catch(^(NSError *error){
        NBADebugLog(@"Error: %@", error);
        NSString *todayScoreboardApiURLString = NBA_TODAY_UTC_SCOREBOARD_API_PATH;
        return [AnyPromise promiseWithValue:[NSDictionary dictionaryWithObject:todayScoreboardApiURLString forKey:@"todayScoreboard"]];
    }).then(^(id object) {
        NSString *todayScoreboardApiURLString = [object objectForKey:@"todayScoreboard"];
        todayScoreboardApiURLString = [NBA_DOMAIN stringByAppendingString:todayScoreboardApiURLString];
        return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolver) {
            [self setupGamesByURLString:todayScoreboardApiURLString promiseResolver:resolver];
        }];
    }).catch(^(NSError *error){
        NBADebugLog(@"Error: %@", error);
    }).ensure(^{
        [self setupPageViewController];
    });
}

#pragma mark -

- (void)setup {
    _numGames = 0;
    _games = [NSArray array];
}

- (void)setupTodayApiPromiseResolver:(PMKResolver)aResolver {
    NSString *sTodayApiURLString = NBA_TODAY_API;
    AFHTTPSessionManager *sManager = [AFHTTPSessionManager manager];
    [sManager GET:sTodayApiURLString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *sDic = (NSDictionary *)responseObject;
        NSDictionary *sLinks = [sDic objectForKey:@"links"];
        aResolver(sLinks);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        aResolver(error);
    }];
}

- (void)setupGamesByURLString:(NSString *)aURLString promiseResolver:(PMKResolver)aResolver {
    AFHTTPSessionManager *sManager = [AFHTTPSessionManager manager];
    [sManager GET:aURLString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *sDic = (NSDictionary *)responseObject;
        NSInteger sNumGame = [[sDic objectForKey:@"numGames"] integerValue];
        NSArray<NSDictionary *> *sGames = [sDic objectForKey:@"games"];
        
        _numGames += sNumGame;
        _games = [_games arrayByAddingObjectsFromArray:sGames];
        
        aResolver(sGames);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        aResolver(error);
    }];
}

- (void)setupPageViewController {
    [self setPageViewController:[[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil]];
    [_pageViewController setDataSource:self];
    [_pageViewController setDelegate:self];
    [[_pageViewController view] setFrame:[[self view] bounds]];
    
    NSArray *sViewControllers = [NSArray arrayWithObject:[self viewControllerAtIndex:0]];
    [_pageViewController setViewControllers:sViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    [self addChildViewController:_pageViewController];
    [[self view] addSubview:[_pageViewController view]];
    [_pageViewController didMoveToParentViewController:self];
}

- (NBAGameViewController *)viewControllerAtIndex:(NSUInteger)aIndex {
    if (_games && [_games count] > aIndex)
    {
        return [[NBAGameViewController alloc] initWithGameData:_games[aIndex] index:aIndex];
    }
    else
    {
        return [[NBAGameViewController alloc] initWithGameData:nil index:0];
    }
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)aPageViewController viewControllerAfterViewController:(UIViewController *)aViewController {
    NSUInteger sIndex = [(NBAGameViewController *)aViewController index];
    if (_numGames == 0 || sIndex == (_numGames - 1))
    {
        return nil;
    }
    
    return [self viewControllerAtIndex:++sIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)aPageViewController viewControllerBeforeViewController:(UIViewController *)aViewController {
    NSUInteger sIndex = [(NBAGameViewController *)aViewController index];
    if (sIndex == 0)
    {
        return nil;
    }
    
    return [self viewControllerAtIndex:--sIndex];
}

@end
