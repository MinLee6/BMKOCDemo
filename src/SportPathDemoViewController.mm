//
//  SportPathDemoViewController.m
//  IphoneMapSdkDemo
//
//  Created by wzy on 16/6/15.
//  Copyright © 2016年 Baidu. All rights reserved.
//

#import "SportPathDemoViewController.h"
#import "JSONKit.h"

// 运动结点信息类
@interface BMKSportNode : NSObject

//经纬度
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
//方向（角度）
@property (nonatomic, assign) CGFloat angle;
//距离
@property (nonatomic, assign) CGFloat distance;
//速度
@property (nonatomic, assign) CGFloat speed;

@end

@implementation BMKSportNode

@synthesize coordinate = _coordinate;
@synthesize angle = _angle;
@synthesize distance = _distance;
@synthesize speed = _speed;

@end

// 自定义BMKAnnotationView，用于显示运动者
@interface SportAnnotationView : BMKAnnotationView

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation SportAnnotationView

@synthesize imageView = _imageView;

- (id)initWithAnnotation:(id<BMKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setBounds:CGRectMake(0.f, 0.f, 22.f, 22.f)];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 22.f, 22.f)];
        _imageView.image = [UIImage imageNamed:@"sportarrow.png"];
        [self addSubview:_imageView];
    }
    return self;
}

@end


@interface SportPathDemoViewController () {
    BMKPolygon *pathPloygon;
    BMKPointAnnotation *sportAnnotation;
    SportAnnotationView *sportAnnotationView;

    NSMutableArray *sportNodes;//轨迹点
    NSInteger sportNodeNum;//轨迹点数
    NSInteger currentIndex;//当前结点
}

@end

@implementation SportPathDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //适配ios7
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0)) {
        self.navigationController.navigationBar.translucent = NO;
    }
    
    _mapView.zoomLevel = 19.4;
    _mapView.centerCoordinate = CLLocationCoordinate2DMake(40.056898, 116.307626);
    _mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放

    //初始化轨迹点
    [self initSportNodes];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_mapView viewWillAppear];
    _mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_mapView viewWillDisappear];
    _mapView.delegate = nil; // 不用时，置nil
}

- (void)dealloc {
    if (_mapView) {
        _mapView = nil;
    }
}

//初始化轨迹点
- (void)initSportNodes {
    sportNodes = [[NSMutableArray alloc] init];
    //读取数据
    NSData *jsonData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sport_path" ofType:@"json"]];
    if (jsonData) {
        NSArray *array = [jsonData objectFromJSONData];
        for (NSDictionary *dic in array) {
            BMKSportNode *sportNode = [[BMKSportNode alloc] init];
            sportNode.coordinate = CLLocationCoordinate2DMake([dic[@"lat"] doubleValue], [dic[@"lon"] doubleValue]);
            sportNode.angle = [dic[@"angle"] doubleValue];
            sportNode.distance = [dic[@"distance"] doubleValue];
            sportNode.speed = [dic[@"speed"] doubleValue];
            [sportNodes addObject:sportNode];
        }
    }
    sportNodeNum = sportNodes.count;
}

//开始
- (void)start {
    CLLocationCoordinate2D paths[sportNodeNum];
    for (NSInteger i = 0; i < sportNodeNum; i++) {
        BMKSportNode *node = sportNodes[i];
        paths[i] = node.coordinate;
    }
    
    pathPloygon = [BMKPolygon polygonWithCoordinates:paths count:sportNodeNum];
    [_mapView addOverlay:pathPloygon];
    
    sportAnnotation = [[BMKPointAnnotation alloc]init];
    sportAnnotation.coordinate = paths[0];
    sportAnnotation.title = @"test";
    [_mapView addAnnotation:sportAnnotation];
    currentIndex = 0;
}

//runing
- (void)running {
    BMKSportNode *node = [sportNodes objectAtIndex:currentIndex % sportNodeNum];
    sportAnnotationView.imageView.transform = CGAffineTransformMakeRotation(node.angle);
    [UIView animateWithDuration:node.distance/node.speed animations:^{
        currentIndex++;
        BMKSportNode *node = [sportNodes objectAtIndex:currentIndex % sportNodeNum];
        sportAnnotation.coordinate = node.coordinate;
    } completion:^(BOOL finished) {
        [self running];
    }];
}

#pragma mark - BMKMapViewDelegate

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView {
    [self start];
}

//根据overlay生成对应的View
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolygon class]])
    {
        BMKPolygonView* polygonView = [[BMKPolygonView alloc] initWithOverlay:overlay];
        polygonView.strokeColor = [[UIColor alloc] initWithRed:0.0 green:0.5 blue:0.0 alpha:0.6];
        polygonView.lineWidth = 3.0;
        return polygonView;
    }
    return nil;
}


// 根据anntation生成对应的View
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    if (sportAnnotationView == nil) {
        sportAnnotationView = [[SportAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"sportsAnnotation"];
        
        
        sportAnnotationView.draggable = NO;
        BMKSportNode *node = [sportNodes firstObject];
        sportAnnotationView.imageView.transform = CGAffineTransformMakeRotation(node.angle);
        
    }
    return sportAnnotationView;
}

- (void)mapView:(BMKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    [self running];
}

@end