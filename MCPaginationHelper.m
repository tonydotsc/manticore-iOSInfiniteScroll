//
//  MCPaginationHelper.m
//  Manticore Utilities
//
//  Created by Richard Fung on 3/11/13.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import "MCPaginationHelper.h"
#import <AFNetworking-TastyPie/AFNetworking+ApiKeyAuthentication.h>
#import <SVPullToRefresh/UIScrollView+SVInfiniteScrolling.h>
#import <RestKit/RestKit.h>
#import <Manticore-iOSViewFactory/ManticoreViewFactory.h>

@interface MCPaginationHelper(Extension)

-(void)setMeta:(MCMeta*)newMeta;
-(void)setObjects:(NSMutableArray*)array;

@end

@implementation MCPaginationHelper

@synthesize meta = _meta;
@synthesize objects = _objects;

+(MCPaginationHelper*)helper{
  MCPaginationHelper* obj = [MCPaginationHelper new];
  obj.meta = [MCMeta new];
  obj.objects = [NSMutableArray array];
  
  obj->m_username = nil;
  obj->m_apikey = nil;
  obj->m_urlPrefix = nil;
  
  return obj;
}

+(MCPaginationHelper*)helperWithRestKit:(RKMappingResult*)mappingResult {
  MCPaginationHelper* obj = [MCPaginationHelper new];
  obj.meta = [MCMeta new];
  obj.objects = [NSMutableArray array];
  
  obj->m_username = nil;
  obj->m_apikey = nil;
  obj->m_urlPrefix = nil;
  
  [obj loadRestKitArray:mappingResult.array andTableView:nil infiniteScroll:NO];
  
  return obj;
}

+(MCPaginationHelper*)helperWithUsername:(NSString*)username apikey:(NSString*)apiKey urlPrefix:(NSString*)urlPrefix {
  MCPaginationHelper* obj = [MCPaginationHelper new];
  obj.meta = [MCMeta new];
  obj.objects = [NSMutableArray array];
  
  obj->m_username = username;
  obj->m_apikey = apiKey;
  obj->m_urlPrefix = urlPrefix;
  
  return obj;
}

+(MCPaginationHelper*)helperWithUsername:(NSString*)username apikey:(NSString*)apiKey urlPrefix:(NSString*)urlPrefix restKitArray:(NSArray*)array   {
  MCPaginationHelper* obj = [MCPaginationHelper helperWithUsername:username apikey:apiKey urlPrefix:urlPrefix];
  [obj loadRestKitArray:array andTableView:nil infiniteScroll:NO];
  return obj;
}


+(MCPaginationHelper*)helperWithUsername:(NSString*)username apikey:(NSString*)apiKey urlPrefix:(NSString*)urlPrefix restKitArray:(NSArray*)array andTableView:(UITableView*)tableView infiniteScroll:(BOOL)infiniteScroll {
  MCPaginationHelper* obj = [MCPaginationHelper helperWithUsername:username apikey:apiKey urlPrefix:urlPrefix];
  [obj loadRestKitArray:array andTableView:tableView infiniteScroll:infiniteScroll];
  return obj;
}

-(void)setMeta:(MCMeta *)newMeta{
  _meta = newMeta;
}

-(void)setObjects:(NSMutableArray *)array{
  _objects = array;
}

-(void)loadRestKitArray:(NSArray*)array andTableView:(UITableView*)scrollView infiniteScroll:(BOOL)infiniteScroll {
  
  isLoading = NO;
  // process data from RestKit
  // extract the Meta object from the rest of the objects
  
  newArray = [NSMutableArray arrayWithCapacity:array.count];
  for (int i = 0; i < array.count; i++){
    NSObject* sample = [array objectAtIndex:i];
    
    if (sample == nil){
      // remove null
    }else if ([sample isKindOfClass:[MCMeta class]]){
      _meta = (MCMeta*) sample;
    }else{
      [newArray addObject:sample];
    }
  }
  
  _objects = newArray;
  
  
  // determine if scroll down is needed
  
  if (scrollView && infiniteScroll) {
    if (_meta && _meta.next){
      scrollView.showsInfiniteScrolling = YES;
      __weak UITableView* weakScrollView = scrollView;
      [scrollView addInfiniteScrollingWithActionHandler:^{
        
        [self loadMoreData:weakScrollView];
      }];
      
    }else{
      scrollView.showsInfiniteScrolling = NO;
    }
    
    [scrollView reloadData];
  }
  else{
    scrollView.showsInfiniteScrolling = NO;
  }
}

-(void)loadMoreData{
  [self loadMoreData:nil];
}

-(void)loadMoreData:(UITableView*)tableView{
  // guard against multiple reloads
  if (isLoading)
    return;
  
  // nothing to scroll to next, do nothing
  if (!_meta || !_meta.next)
    return;
  
  // verify that keys are assigned
  if (!m_username || !m_apikey || !m_urlPrefix){
    NSAssert(!m_username || !m_apikey || !m_urlPrefix, @"Infinite scroll requires a constructor with username, apikey, and url prefix");
  }
  
  // set up RestKit 0.20
  RKObjectManager* sharedMgr = [ RKObjectManager sharedManager];
  [sharedMgr.HTTPClient setAuthorizationHeaderWithTastyPieUsername:m_username andToken:m_apikey];
  
  // this line should remove the api/ prefix from the URLs returned from the server
  NSAssert([[_meta.next substringToIndex:m_urlPrefix.length] isEqualToString:m_urlPrefix], @"All URLs returned from the server should be prefixed by API_URL");
  NSString* modURL = [_meta.next substringFromIndex:m_urlPrefix.length];
  if ([modURL characterAtIndex:0] == '/'){ // auto remove the path prefix (/)
    modURL = [modURL substringFromIndex:1];
  }
  
//  NSLog(@"Infinite scroll is hitting %@", modURL);
  
  isLoading = YES;
  
  [sharedMgr getObjectsAtPath:modURL parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
    isLoading = NO;
    
    // erase the old meta object, we will load another one
    self.meta = nil;
    
    // filter out the Meta object from the result list and add to the meta property
    for (int i = 0; i < mappingResult.array.count; i++){
      NSObject* sample = [mappingResult.array objectAtIndex:i];
      if (sample && ![sample isKindOfClass:[MCMeta class]]){
        [newArray addObject:sample];
      }else if ([sample isKindOfClass:[MCMeta class]]){
        self.meta = (MCMeta*)sample;
//          NSLog(@"Infinite scroll found a new limit %@ and offset %@ and next page `%@`", self.meta.limit, self.meta.offset, self.meta.next);
      }
    }
    
    // assumption: infinite scrolling is already turned on
    if (tableView){
//      NSLog(@"Infinite scroll stop table animation");
      [tableView.infiniteScrollingView stopAnimating];
      
      dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"Infinite scroll reload data");
        [tableView reloadData];
      
        if (!self.meta || !self.meta.next){
//          NSLog(@"Infinite scroll no more scrolling");
          tableView.showsInfiniteScrolling = NO;
        }
        else{
//          NSLog(@"Infinite scroll can scroll again");
          tableView.showsInfiniteScrolling = YES;
        }
      });
    }
   
  } failure:^(RKObjectRequestOperation *operation, NSError *error) {
    isLoading = NO;
    [[MCViewModel sharedModel] setErrorTitle:@"Infinite Scroll" andDescription:error.localizedDescription];
    
    if (tableView){
      tableView.showsInfiniteScrolling = NO;
      [tableView.infiniteScrollingView stopAnimating];
    }
  }];
  
}


@end
