//
//  DetectRectView.m
//  opencvtest
//
//  Created by hxx on 11/13/14.
//  Copyright (c) 2014 hxx. All rights reserved.
//

#import "DetectRectView.h"
@interface DetectRectView()
@property (nonatomic, assign)CGPoint a;
@property (nonatomic, assign)CGPoint b;
@property (nonatomic, assign)CGPoint x;
@property (nonatomic, assign)CGPoint y;
@property (nonatomic, retain)UIColor *color;
@property (nonatomic, retain)UIBezierPath *path;
@property (nonatomic, retain)CAShapeLayer *caShape;
@end
@implementation DetectRectView
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        self.path = [UIBezierPath bezierPath];
        self.caShape = [CAShapeLayer new];
        [self.layer addSublayer:self.caShape];
        self.caShape.fillColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.3].CGColor;
        self.caShape.strokeColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.3].CGColor;
//        self.caShape.lineWidth = 5.0;
    }
    return self;
}
- (CGPoint)convertPoint:(CGPoint)p withOrientation:(int)orientation{
//    CGFloat scaleX = MIN(self.bounds.size.height, self.bounds.size.width) / 768.0;
//    CGFloat scaleY = MAX(self.bounds.size.height, self.bounds.size.width) / 1280.0;
    CGFloat w = MIN(self.bounds.size.height, self.bounds.size.width) / 2;
    CGFloat h = w * 1280.0 / 720.0;
    CGFloat scaleX = 2.0;
    CGFloat scaleY = 2.0;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return CGPointMake(p.x * scaleX, p.y * scaleY - (h * 2 - MAX(self.bounds.size.height, self.bounds.size.width))/2);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            return CGPointMake(MAX(self.bounds.size.height, self.bounds.size.width) - (p.y * scaleY - (h * 2 - MAX(self.bounds.size.height, self.bounds.size.width))/2), p.x*scaleX);
            break;
        case UIInterfaceOrientationLandscapeRight:
            return CGPointMake(p.y * scaleY - (h * 2 - MAX(self.bounds.size.height, self.bounds.size.width))/2, MIN(self.bounds.size.width, self.bounds.size.height)-p.x*scaleX);
        default:
            break;
    }
    return CGPointMake(p.x * scaleX, p.y * scaleY);
}
- (void)clear{
    self.path = [UIBezierPath bezierPath];
    self.caShape.path = self.path.CGPath;
}
- (void)displayRect:(NSArray *)points inCIImage:(CIImage *)image{
    CGFloat h = [image extent].size.height;
    self.a = CGPointMake([points[0] CGPointValue].x, h -[points[0] CGPointValue].y);
    self.b = CGPointMake([points[1] CGPointValue].x, h -[points[1] CGPointValue].y);
    self.x = CGPointMake([points[2] CGPointValue].x, h -[points[2] CGPointValue].y);
    self.y = CGPointMake([points[3] CGPointValue].x, h -[points[3] CGPointValue].y);
    self.color = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.3];
    self.caShape.fillColor = self.color.CGColor;
    self.caShape.strokeColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.3].CGColor;
    [self drawBezierPath];
}
- (void)displayRect:(NSArray *)p orientation:(UIInterfaceOrientation)orientation{
    NSArray *points = [self sortPoints:p];
    self.a = [self convertPoint:[points[0] CGPointValue] withOrientation:orientation];//CGPointMake([points[0] CGPointValue].x * 320.0 / 720.0, [points[0] CGPointValue].y * 568.0 / 1280.0);
    self.b = [self convertPoint:[points[1] CGPointValue] withOrientation:orientation];//CGPointMake([points[1] CGPointValue].x * 320.0 / 720.0, [points[1] CGPointValue].y * 568.0 / 1280.0);
    self.x = [self convertPoint:[points[2] CGPointValue] withOrientation:orientation];//CGPointMake([points[2] CGPointValue].x * 320.0 / 720.0, [points[2] CGPointValue].y * 568.0 / 1280.0);
    self.y = [self convertPoint:[points[3] CGPointValue] withOrientation:orientation];//CGPointMake([points[3] CGPointValue].x * 320.0 / 720.0, [points[3] CGPointValue].y * 568.0 / 1280.0);
    self.color = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.3];
    self.caShape.fillColor = self.color.CGColor;
    if ([self shouldDraw:points])
        [self drawBezierPath];
    else{
        [self clear];
//        NSLog(@"no Find");
    }
}
- (BOOL)shouldDraw:(NSArray *)points{
    CGFloat minX,maxX,minY,maxY;
    minX = 99999.0;
    minY = 99999.0;
    maxX = 0.0;
    maxY = 0.0;
    for (id obj in points){
        CGPoint p = CGPointMake([obj CGPointValue].x , [obj CGPointValue].y );
        if (p.x<minX) minX = p.x;
        if (p.x>maxX) maxX = p.x;
        if (p.y<minY) minY = p.y;
        if (p.y>maxY) maxY = p.y;
    }
    int h = MIN(self.bounds.size.width, self.bounds.size.height) * 1280 / 720;
    CGFloat maxArea = (MIN(self.bounds.size.width, self.bounds.size.height) * h / 4.0) - 10.0;
    if ((maxX - minX) * (maxY - minY) < 50 ||  (maxX - minX) * (maxY - minY)> maxArea)
        return NO;
    return YES;
}
- (NSArray *)sortPoints:(NSArray *)points{
    CGFloat centerX = 0.0;
    CGFloat centerY = 0.0;
    for (id p in points){
        centerX += [p CGPointValue].x;
        centerY += [p CGPointValue].y;
    }
    centerX /=4.0;
    centerY /=4.0;
    CGPoint lt,rt,lb,rb;
    int ll=0;
    int rr=0;
    for (id p in points){
        CGPoint point = [p CGPointValue];
        if ((point.x< centerX) && (point.y < centerY))
        {
            lt = point;
            ll++;
        }
        if ((point.x< centerX) && (point.y > centerY))
        {
            lb = point;
            ll++;
        }
        if ((point.x> centerX) && (point.y < centerY))
        {
            rt = point;
            rr++;
        }
        if ((point.x> centerX) && (point.y > centerY))
        {
            rb = point;
            rr++;
        }
    }
    if ((ll!=2)||(rr!=2))
        return @[[NSValue valueWithCGPoint:CGPointZero],[NSValue valueWithCGPoint:CGPointZero],[NSValue valueWithCGPoint:CGPointZero],[NSValue valueWithCGPoint:CGPointZero]];
    NSArray *ret = @[[NSValue valueWithCGPoint:lt],[NSValue valueWithCGPoint:rt],[NSValue valueWithCGPoint:rb],[NSValue valueWithCGPoint:lb]];
    return ret;
}
- (void)drawBezierPath{
    self.path = [UIBezierPath bezierPath];
    [self.path moveToPoint:self.a];
    
    [self.path addLineToPoint:self.b];
    [self.path addLineToPoint:self.x];
    [self.path addLineToPoint:self.y];
    [self.path closePath];
    [self startAnimation];
}
- (void)startAnimation
{
//    if (self.caShape == nil)
//    {
//        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
//        
//        shapeLayer.path = self.path.CGPath;
//        shapeLayer.strokeColor = [[UIColor grayColor] CGColor];
//        shapeLayer.fillColor = nil;
//        shapeLayer.lineWidth = 1.5f;
//        shapeLayer.lineJoin = kCALineJoinBevel;
//        
//        [self.layer addSublayer:shapeLayer];
//        
//        self.caShape = shapeLayer;
//    }

    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.duration = 0.3;
    pathAnimation.fromValue = (id)self.caShape.path;
    pathAnimation.toValue = (id)self.path.CGPath;
    [self.caShape addAnimation:pathAnimation forKey:@"path"];
    self.caShape.path = self.path.CGPath;
}
- (void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetLineWidth(context, 2.0);
//    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
//    CGFloat components[] = {0.3, 0.3, 0.3, 1.0};
//    CGColorRef color=CGColorCreate(colorspace,components);
//    CGContextSetStrokeColorWithColor(context, color);
    CGContextMoveToPoint(context, self.a.x,self.a.y);
    CGContextAddLineToPoint(context, self.b.x, self.b.y);
    CGContextAddLineToPoint(context, self.x.x, self.x.y);
    CGContextAddLineToPoint(context, self.y.x, self.y.y);
    CGContextAddLineToPoint(context, self.a.x, self.a.y);
//    CGContextStrokePath(context);
    CGContextSetFillColorWithColor(context,self.color.CGColor);
    CGContextFillPath(context);

}
@end
