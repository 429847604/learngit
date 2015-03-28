//
//  CustomAnnotationView.h
//  BasicGaoDeMap
//
//  Created by zhaoxu on 15/3/25.
//  Copyright (c) 2015年 &#36213;&#26093;. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import "CustomCalloutView.h"

@interface CustomAnnotationView : MAAnnotationView

@property (nonatomic, readonly) CustomCalloutView *calloutView;

@end
