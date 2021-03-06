//
//  FRPGalleryViewController.m
//  FRP
//
//  Created by Chinsyo on 16/5/16.
//  Copyright © 2016年 Chinsyo. All rights reserved.
//

// ViewControllers
#import "FRPGalleryViewController.h"
#import "FRPFullSizePhotoViewController.h"
#import "FRPLoginViewController.h"

// View Models
#import "FRPGalleryViewModel.h"
#import "FRPFullSizePhotoViewModel.h"

// Views
#import "FRPCell.h"

// Utilities
#import "FRPGalleryFlowLayout.h"

static NSString *const reuseIdentifier = @"Cell";

@interface FRPGalleryViewController ()

// Private Properties
@property (nonatomic, strong) FRPGalleryViewModel *viewModel;

@end

@implementation FRPGalleryViewController

- (instancetype)init {
    FRPGalleryFlowLayout *flowLayout = [[FRPGalleryFlowLayout alloc] init];
    self = [self initWithCollectionViewLayout:flowLayout];
    if (!self) return nil;
    
    self.viewModel = [[FRPGalleryViewModel alloc] init];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Popular on 500px";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log in" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [self.collectionView registerClass:[FRPCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    @weakify(self);
    [RACObserve(self.viewModel, model) subscribeNext:^(id x) {
        @strongify(self);
        [self.collectionView reloadData];
    }];
    
    [[self rac_signalForSelector:@selector(userDidScroll:toPhotoAtIndex:) fromProtocol:@protocol(FRPFullSizePhotoViewControllerDelegate)] subscribeNext:^(RACTuple *value) {
        @strongify(self);
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[value.second integerValue] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }];
    
    [[self rac_signalForSelector:@selector(collectionView:didSelectItemAtIndexPath:) fromProtocol:@protocol(UICollectionViewDelegate)] subscribeNext:^(RACTuple *arguments) {
        @strongify(self);
        
        NSIndexPath *indexPath = arguments.second;
        FRPFullSizePhotoViewModel *viewModel = [[FRPFullSizePhotoViewModel alloc] initWithPhotoArray:self.viewModel.model initialPhotoIndex:indexPath.item];
        
        FRPFullSizePhotoViewController *viewController = [[FRPFullSizePhotoViewController alloc] init];
        viewController.viewModel = viewModel;
        viewController.delegate = (id<FRPFullSizePhotoViewControllerDelegate>)self;
        [self.navigationController pushViewController:viewController animated:YES];
    }];
    
    self.navigationItem.rightBarButtonItem.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            @strongify(self);
            FRPLoginViewController *viewController = [[FRPLoginViewController alloc] initWithNibName:@"FRPLoginViewController" bundle:nil];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            
            [self presentViewController:navigationController animated:YES completion:^{
                [subscriber sendCompleted];
            }];
            
            return nil;
        }];
    }];
    
    // Need to "reset" the cached values of respondsToSelector: of UIKit
    self.collectionView.delegate = nil;
    self.collectionView.delegate = self;
    
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.viewModel.model.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FRPCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [cell setPhotoModel:self.viewModel.model[indexPath.row]];
    return cell;
}
@end
