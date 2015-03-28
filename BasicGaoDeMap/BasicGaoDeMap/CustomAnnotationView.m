//
//  CustomAnnotationView.m
//  BasicGaoDeMap
//
//  Created by zhaoxu on 15/3/25.
//  Copyright (c) 2015年 &#36213;&#26093;. All rights reserved.
//

#import "CustomAnnotationView.h"

#define kCalloutVidth 200.0
#define kCalloutHeight 70.0

@interface CustomAnnotationView ()

@property (nonatomic, strong, readwrite) CustomCalloutView *calloutView;

@end

@implementation CustomAnnotationView
@synthesize calloutView = _calloutView;

#pragma mark --Override

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.selected == selected) {
        return;
    }
    
    if (selected) {
        if (self.calloutView == nil) {
            self.calloutView = [[CustomCalloutView alloc] initWithFrame:CGRectMake(0, 0, kCalloutVidth, kCalloutHeight)];
            self.calloutView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.f + self.calloutOffset.x, -CGRectGetHeight(self.calloutView.bounds) / 2.f + self.calloutOffset.y);
        }
        
        self.calloutView.image = [UIImage imageNamed:@"building"];
        self.calloutView.title = self.annotation.title;
        self.calloutView.subtitle = self.annotation.subtitle;
        
        [self addSubview:self.calloutView];
        
    } else {
        
        [self.calloutView removeFromSuperview];
        
    }
    
    [super setSelected:selected animated:animated];
}

//重写父类的此函数，用以实现点击calloutView判断为点击该annotationView
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [super pointInside:point withEvent:event];
    
    if (!inside && self.selected) {
        inside = [self.calloutView pointInside:[self convertPoint:point toView:self.calloutView] withEvent:event];
    }
    return inside;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
