//
//  ViewController.m
//  BasicGaoDeMap
//
//  Created by zhaoxu on 15/3/24.
//  Copyright (c) 2015年 赵旭. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import "CustomAnnotationView.h"

#define APIKey @"ec040d3991e935572088eeedee87361d"

@interface ViewController () <MAMapViewDelegate, AMapSearchDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
{
    MAMapView *_mapView;
    AMapSearchAPI *_search;
    
    CLLocation *_currentLocation;
    UIButton *_locationButton;
    
    UITableView *_tableView;
    NSArray *_pois;
    
    NSMutableArray *_annotations;
    
//    声明一个长按手势
    UILongPressGestureRecognizer *_longPressGesture;
    
    MAPointAnnotation *_destinationPoint;
    
    NSArray *_pathPolylines;
}

@end

@implementation ViewController

#pragma mark --tableView
- (void)initTableView
{
    CGFloat halfHeight = CGRectGetHeight(self.view.bounds) * 0.5;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, halfHeight, CGRectGetWidth(self.view.bounds), halfHeight) style:UITableViewStylePlain];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self.view addSubview:_tableView];
}

#pragma mark --tableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _pois.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    AMapPOI *poi = _pois[indexPath.row];
    
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    为点击的poi点添加标注
    AMapPOI *poi = _pois[indexPath.row];
    
    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    annotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
    annotation.title = poi.name;
    annotation.subtitle = poi.address;
    
    [_annotations addObject:annotation];
    [_mapView addAnnotation:annotation];
    
}

- (void)initAttributes
{
    _annotations = [NSMutableArray array];
    _pois = nil;
    
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    _longPressGesture.delegate = self;
    [_mapView addGestureRecognizer:_longPressGesture];
}

#pragma mark --action方法
- (void)reGeoAction
{
    if (_currentLocation) {
        AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc] init];
        
        request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
        
        [_search AMapReGoecodeSearch:request];
    }
}

//添加searchAction
- (void)searchAction
{
    if (_currentLocation == nil || _search == nil) {
        NSLog(@"search failed");
        return;
    }
    
    AMapPlaceSearchRequest *request = [[AMapPlaceSearchRequest alloc] init];
    request.searchType = AMapSearchType_PlaceAround;
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    
    request.keywords = @"餐饮";
    
    [_search AMapPlaceSearch:request];
}

- (void)locateAction
{
    if (_mapView.userTrackingMode != MAUserTrackingModeFollow) {
        [_mapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CLLocationCoordinate2D coordinate = [_mapView convertPoint:[gesture locationInView:_mapView] toCoordinateFromView:_mapView];
        
//        添加标注
        if (_destinationPoint != nil) {
//            清理
            [_mapView removeAnnotation:_destinationPoint];
            _destinationPoint = nil;
        }
        
        _destinationPoint = [[MAPointAnnotation alloc] init];
        _destinationPoint.coordinate = coordinate;
        _destinationPoint.title = @"Destination";
        
        [_mapView addAnnotation:_destinationPoint];
    }
}

- (CLLocationCoordinate2D *)coordinatesForString:(NSString *)string coordinateCount:(NSInteger *)coordinateCount parseToken:(NSString *)token
{
    if (string == nil) {
        return NULL;
    }
    
    if (token == nil) {
        token = @",";
    }
    
    NSString *str = @"";
    if (![token isEqualToString:@","]) {
        str = [string stringByReplacingOccurrencesOfString:token withString:@","];
    } else {
        str = [NSString stringWithString:string];
    }
    
    NSArray *components = [str componentsSeparatedByString:@","];
    NSUInteger count = [components count] / 2;
    if (coordinateCount != NULL) {
        *coordinateCount = count;
    }
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(count * sizeof(CLLocationCoordinate2D));
    
    for (int i = 0; i < count; i++) {
        coordinates[i].longitude = [[components objectAtIndex:2 * i]    doubleValue];
        coordinates[i].latitude = [[components objectAtIndex:2 * i + 1] doubleValue];
    }
    
    return coordinates;
}

//导航搜索请求发起部分
- (void)pathAction
{
    if (_destinationPoint == nil || _currentLocation == nil || _search == nil) {
        NSLog(@"path search failed");
        return;
    }
    
    AMapNavigationSearchRequest *request = [[AMapNavigationSearchRequest alloc] init];
//    设置为步行路径规划
    request.searchType = AMapSearchType_NaviWalking;
    
    request.origin = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    request.destination = [AMapGeoPoint locationWithLatitude:_destinationPoint.coordinate.latitude longitude:_destinationPoint.coordinate.longitude];
    
    [_search AMapNavigationSearch:request];
}

- (NSArray *)polylinesForPath:(AMapPath *)path
{
    if (path == nil || path.steps.count == 0) {
        return nil;
    }
    
    NSMutableArray *polylines = [NSMutableArray array];
    
    [path.steps enumerateObjectsUsingBlock:^(AMapStep *step, NSUInteger idx, BOOL *stop) {
        NSInteger count = 0;
        CLLocationCoordinate2D *coordinates = [self coordinatesForString:step.polyline coordinateCount:&count parseToken:@";"];
        
        MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:count];
        [polylines addObject:polyline];
        
        free(coordinates), coordinates = NULL;
    }];
    
    return polylines;
}

#pragma mark --search初始化
- (void)initSearch
{
    _search = [[AMapSearchAPI alloc] initWithSearchKey:APIKey Delegate:self];
}

#pragma mark --searchDelegate

- (void)searchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"request :%@, error :%@", request, error);
}

- (void)onNavigationSearchDone:(AMapNavigationSearchRequest *)request response:(AMapNavigationSearchResponse *)response
{
    if (response.count > 0) {
        [_mapView removeOverlays:_pathPolylines];
        _pathPolylines = nil;
        
//        只显示第一条
        _pathPolylines = [self polylinesForPath:response.route.paths[0]];
        [_mapView addOverlays:_pathPolylines];
        
        [_mapView showAnnotations:@[_destinationPoint, _mapView.userLocation] animated:YES];
    }
}

- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    NSLog(@"response :%@", response);
    
    NSString * title = response.regeocode.addressComponent.city;
    if (title.length == 0) {
        title = response.regeocode.addressComponent.province;
    }
    
    _mapView.userLocation.title = title;
    _mapView.userLocation.subtitle = response.regeocode.formattedAddress;
}

//搜索回调
- (void)onPlaceSearchDone:(AMapPlaceSearchRequest *)request response:(AMapPlaceSearchResponse *)response
{
    NSLog(@"request: %@", request);
    NSLog(@"response: %@", response);
    
    if (response.pois.count > 0) {
        _pois = response.pois;
        
        [_tableView reloadData];
        
//        清空标注
        [_mapView removeAnnotations:_annotations];
        [_annotations removeAllObjects];
    }
}

#pragma mark --按钮的添加和初始化
- (void)initControls
{
    _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _locationButton.frame = CGRectMake(20, CGRectGetHeight(_mapView.bounds) - 80, 40, 40);
    _locationButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _locationButton.backgroundColor = [UIColor whiteColor];
    _locationButton.layer.cornerRadius = 5;
    
    [_locationButton addTarget:self action:@selector(locateAction) forControlEvents:UIControlEventTouchUpInside];
    
    [_locationButton setImage:[UIImage imageNamed:@"location_no"] forState:UIControlStateNormal];
    
    [_mapView addSubview:_locationButton];
    
    
//    添加搜索按钮
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    searchButton.frame = CGRectMake(80, CGRectGetHeight(_mapView.bounds) - 80, 40, 40);
    searchButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    searchButton.backgroundColor = [UIColor whiteColor];
    [searchButton setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    
    [searchButton addTarget:self action:@selector(searchAction) forControlEvents:UIControlEventTouchUpInside];
    
    [_mapView addSubview:searchButton];
    
    UIButton *pathButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    pathButton.frame = CGRectMake(140, CGRectGetHeight(_mapView.bounds) - 60, 40, 40);
    pathButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    pathButton.backgroundColor = [UIColor whiteColor];
    [pathButton setImage:[UIImage imageNamed:@"path"] forState:UIControlStateNormal];
    
    [pathButton addTarget:self action:@selector(pathAction) forControlEvents:UIControlEventTouchUpInside];
    
    [_mapView addSubview:pathButton];
}

#pragma mark --mapViewDelegate

- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]]) {
        MAPolylineView *polylineView = [[MAPolylineView alloc] initWithPolyline:overlay];
        
        polylineView.lineWidth = 4;
        polylineView.strokeColor = [UIColor magentaColor];
        
        return polylineView;
    }
    
    return nil;
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if (annotation == _destinationPoint) {
        static NSString * reuseIndetifier = @"startAnnotationReuseIndetifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil) {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        
        return annotationView;
        
    }
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
        CustomAnnotationView *annotationView = (CustomAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil) {
            annotationView = [[CustomAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        
        annotationView.image = [UIImage imageNamed:@"restaurant"];
        
        annotationView.canShowCallout = YES;
        
//        设置中心点偏移，使得标注底部中间点成为经纬度对应点
        annotationView.centerOffset = CGPointMake(0, -18);
        
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated
{
//    修改定位状态按钮
    if (mode == MAUserTrackingModeNone) {
        [_locationButton setImage:[UIImage imageNamed:@"location_no"] forState:UIControlStateNormal];
    } else {
        [_locationButton setImage:[UIImage imageNamed:@"location_yes"] forState:UIControlStateNormal];
    }
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    NSLog(@"userLocation:%@", userLocation.location);
    _currentLocation = [userLocation.location copy];
}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view
{
    //    选中定位annotation的时候进行逆地理编码查询
    if ([view.annotation isKindOfClass:[MAUserLocation class]]) {
        [self reGeoAction];
    }
}

#pragma mark --mapView初始化
- (void)initMapView
{
//    设置APIKey
    [MAMapServices sharedServices].apiKey = APIKey;
    
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) * 0.5)];
    
    _mapView.delegate = self;
    _mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, 22);
    _mapView.scaleOrigin = CGPointMake(_mapView.scaleOrigin.x, 22);
    
    [self.view addSubview:_mapView];
    
    
//    打开定位  打开定位需要在plist文件中添加这个 NSLocationWhenInUseUsageDescription 字段
//    NSLocationWhenInUseUsageDescription意思是仅在页面首时定位
//    NSLocationAlwaysUsageDescription意思是总是定位，费电
    _mapView.showsUserLocation = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initMapView];
    
    [self initControls];
    
    [self initSearch];
    
    [self initTableView];
    
    [self initAttributes];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
