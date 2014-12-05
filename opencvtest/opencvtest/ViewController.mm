//
//  ViewController.m
//  opencvtest
//
//  Created by hxx on 11/10/14.
//  Copyright (c) 2014 hxx. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/highgui/cap_ios.h>
#import "DetectRectView.h"
#import "ImageBrowser.h"
#import "UIImage+OpenCV.h"

using namespace cv;
@interface ViewController ()<CvVideoCameraDelegate>
{
    AVCaptureStillImageOutput *_stillImageOutput;
    BOOL flag;
}
@property (nonatomic, strong)UIImage *catched;
@property (nonatomic, strong)UIImageView *imageView;
@property (nonatomic, strong)UIButton *button;
@property (nonatomic, retain)CvVideoCamera *videoCamera;
@property (nonatomic, retain)UIImageView *crop1;
@property (nonatomic, retain)UIImageView *crop2;
@property (nonatomic, retain)UIImageView *crop3;
@property (nonatomic, retain)UIImageView *crop4;
@property (nonatomic, retain)DetectRectView *rect;
@property (nonatomic, retain)NSMutableArray *crops;
@property (nonatomic, retain)NSDate *just;
@property (nonatomic, assign)BOOL saveImg;
@property (nonatomic, retain)UIButton *sysButton;
@property (nonatomic, assign)UIButton *curButton;
@property (nonatomic, retain)UISlider *slider;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

//    self.view.backgroundColor = [UIColor redColor];
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
//    self.imageView.backgroundColor = [UIColor blueColor];
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.button setTitle:@"opencv" forState:UIControlStateNormal];
    [self.button setBackgroundColor:[UIColor greenColor]];
    [self.button sizeToFit];
    self.button.center = CGPointMake(self.view.bounds.size.width / 3.0, self.view.bounds.size.height - 30);
    self.button.layer.cornerRadius = 7.0;
    [self.button addTarget:self action:@selector(actionStart:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.imageView];
    
    self.sysButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sysButton setTitle:@"system" forState:UIControlStateNormal];
    [self.sysButton setBackgroundColor:[UIColor greenColor]];
    [self.sysButton sizeToFit];
    self.sysButton.center = CGPointMake(self.view.bounds.size.width / 3.0 * 2, self.view.bounds.size.height - 30);
    self.sysButton.layer.cornerRadius = 7.0;
    [self.sysButton addTarget:self action:@selector(actionStart:) forControlEvents:UIControlEventTouchUpInside];
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.useAVCaptureVideoPreviewLayer = YES;
    self.videoCamera.rotateVideo = YES;
    
    self.crop1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropTag.png"]];
    self.crop2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropTag.png"]];
    self.crop3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropTag.png"]];
    self.crop4 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropTag.png"]];
    
//    [self.view addSubview:self.crop1];
//    [self.view addSubview:self.crop2];
//    [self.view addSubview:self.crop3];
//    [self.view addSubview:self.crop4];
    self.rect = [[DetectRectView alloc] initWithFrame:self.view.bounds];
    self.rect.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.rect];
    [self.view addSubview:self.button];
    [self.view addSubview:self.sysButton];
    self.crops = [[NSMutableArray alloc] init];
    
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [_stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObjectsAndKeys:
                                          AVVideoCodecJPEG,  //JPEG图片格式
                                          AVVideoCodecKey,
                                          nil]];
    flag = NO;
    self.just = [NSDate date];
    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height - 80, 280, 30)];
    self.slider.maximumValue = 2;
    self.slider.minimumValue = 0.5;
    [self.view addSubview:self.slider];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (BOOL)shouldAutorotate{
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
- (void)viewWillLayoutSubviews{
    self.imageView.frame = self.view.bounds;
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    self.imageView.frame = self.view.bounds;
    self.button.center = CGPointMake(self.view.bounds.size.width / 3.0, self.view.bounds.size.height - 30);
    self.sysButton.center = CGPointMake(self.view.bounds.size.width / 3.0 * 2, self.view.bounds.size.height - 30);
//    NSLog(@"%@",NSStringFromCGRect(self.view.bounds));
//    [self.videoCamera adjustLayoutToInterfaceOrientation:toInterfaceOrientation];
    AVCaptureConnection *stillImageConnection = nil;
    for (AVCaptureConnection *connection in _stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                stillImageConnection = connection;
                break;
            }
        }
        if (stillImageConnection)
            break;
    }
    
    
    AVCaptureVideoPreviewLayer *layer = nil;
    for (CALayer *l in [self.imageView.layer sublayers]){
        if ([l isKindOfClass:[AVCaptureVideoPreviewLayer class]])
        {
            layer = (AVCaptureVideoPreviewLayer *)l;
            break;
        }
    }
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:{
            if ([layer isOrientationSupported]) {
                [layer setOrientation:AVCaptureVideoOrientationPortrait];
            }
            
            break;
        }
        case UIInterfaceOrientationPortraitUpsideDown:{
            if ([layer isOrientationSupported]) {
                [layer setOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
            }
            
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:{
            if ([layer isOrientationSupported]) {
                [layer setOrientation:AVCaptureVideoOrientationLandscapeLeft];
            }
            
            break;
        }
        case UIInterfaceOrientationLandscapeRight:{
            if ([layer isOrientationSupported]) {
                [layer setOrientation:AVCaptureVideoOrientationLandscapeRight];
            }
            
            break;
        }   
        default:
            break;
    }
    if ([stillImageConnection isVideoOrientationSupported])
        [stillImageConnection setVideoOrientation:layer.orientation];
    [self.videoCamera.videoCaptureConnection setVideoOrientation:layer.orientation];
    [self.videoCamera updateOrientation];
    CGRect bounds = self.view.bounds;
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.bounds = bounds;
    layer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
//    layer.frame = self.view.bounds;
    self.rect.frame = self.view.bounds;
}

- (void)actionStart:(id)sender{
    if (![self.curButton isEqual:sender])
    {
        self.curButton = sender;
        [self.videoCamera start];
        if ([self.videoCamera.captureSession canAddOutput:_stillImageOutput]) {
            [self.videoCamera.captureSession addOutput:_stillImageOutput];
        }
    }
    else
    {
//        self.saveImg = YES;
        AVCaptureConnection *stillImageConnection = nil;
        for (AVCaptureConnection *connection in _stillImageOutput.connections) {
            for (AVCaptureInputPort *port in [connection inputPorts]) {
                if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                    stillImageConnection = connection;
                    break;
                }
            }
            if (stillImageConnection)
                break;
        }
        if ([stillImageConnection isVideoOrientationSupported])
        {
            [stillImageConnection setVideoOrientation:[self adjustOrientation]];
        }
        
        
        [_stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
            if (imageDataSampleBuffer) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                __block UIImage *image = [[UIImage alloc] initWithData:imageData] ;
                dispatch_async(dispatch_get_main_queue(), ^{
//                    ImageBrowser *vc = [[ImageBrowser alloc] init];
//                    [vc setImage:image];
//                    [self presentViewController:vc animated:YES completion:^{
//                        
//                    }];
                    UIImage *tImg = [self fixOrientationOfImage:image];
                    tImg = [tImg imageByScalingToSize:CGSizeMake(320, 568)];//self.view.bounds.size];
                    UIImageView *imgv = [[UIImageView alloc] initWithImage:[self getQuadrangleFromUIImage:tImg]];
                    imgv.contentMode = UIViewContentModeScaleAspectFit;
                    imgv.frame = self.view.bounds;
//                    [self.view addSubview:imgv];
                    ImageBrowser *vc = [[ImageBrowser alloc] init];
                    vc.imageView = imgv;
                    cv::Mat mat =[tImg CVMat];
                    Mat tMat;
                    resize(mat, tMat, cv::Size(320 ,568 ));//cv::Size((int)self.view.bounds.size.width,(int)self.view.bounds.size.height));
                    vc.points = [self drawArr:tMat];
                    [self presentViewController:vc animated:YES completion:^{


                    }];
                });
                
            }
        }];
    }
}
- (AVCaptureVideoOrientation)adjustOrientation{
    switch ([[UIApplication sharedApplication] statusBarOrientation]){
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            return AVCaptureVideoOrientationPortrait;
            break;
    }
}
#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    // Do some OpenCV stuff with the image
//    vector<vector<cv::Point> > v =  vector<vector<cv::Point> >();
//    findSquaresDemo(image, v);
//    for (int i=0;i<v.size();i++)
//        for (int j=0;j<v[i].size();j++)
//            NSLog(@"%d %d",v[i][j].x,v[i][j].y);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.crops enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
//            UIImageView *img = (UIImageView *)obj;
//            [img removeFromSuperview];
//        }];
//        [self.crops removeAllObjects];
//        for (int i=0;i<v.size();i++)
//            for (int j=0;j<v[i].size();j++)
//            {
//                UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cropTag.png"]];
//                img.center = CGPointMake(v[i][j].x /1280.0 * 568.0, v[i][j].y / 720.0 * 320.0);
//                [self.view addSubview:img];
//                [self.crops addObject:img];
//            }
//        NSLog(@"%@",self.crops);
//    });
    

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.button setTitle:[NSString stringWithFormat:@"%.2f", self.slider.value] forState:UIControlStateNormal];
    });
    if (fabs([self.just timeIntervalSinceNow])<self.slider.value)
        return;
    self.just = [NSDate date];
    NSInteger w = (NSInteger)MIN(self.view.bounds.size.width, self.view.bounds.size.height) / 2;
    NSInteger h = w * 1280 / 720 ;
//    resize(image, image, cv::Size(w,h));
    Mat rImg;
    resize(image, rImg, cv::Size((int)w,(int)h));
    
    
   /* vector<vector<cv::Point> > square;
    findSquaresDemo(rImg, square);
    NSMutableArray *arr = [[[NSMutableArray alloc] init] autorelease];
    for (int i=0;i<4;i++){
        if (square[0].size()>0)
        {
            CGPoint p = CGPointMake(square[0][i].x, square[0][i].y);
            [arr addObject:[NSValue valueWithCGPoint:p]];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([arr count]>0)
            [self.rect displayRect:arr orientation:[[UIApplication sharedApplication] statusBarOrientation]];
    });
    return;*/
    if ([self.curButton isEqual:self.button])
        [self drawArr:rImg];
    else
        [self drawiOS8:rImg];
    
}

- (NSArray *)drawiOS8:(Mat &)image{
    UIImage *uImage = [UIImage imageWithCVMat:image];
    uImage = [self fixOrientationOfImage:uImage];
    uImage = [uImage imageByScalingToSize:self.view.bounds.size];
    CIImage* cimage = [CIImage imageWithCGImage:[uImage CGImage]];
    static CIDetector *detector = nil;

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:CIDetectorAccuracyHigh, CIDetectorAccuracy, nil];
    detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:options];
    
    NSArray *faceArray = [detector featuresInImage:cimage];
    if ([faceArray count]<1){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rect clear];
        });
        
        return nil;
    }

    for (CIRectangleFeature *rectFeature in faceArray )
    {
        CGPoint tTopLeft = rectFeature.bottomLeft;
        CGPoint tTopRight = rectFeature.bottomRight;
        CGPoint tDownLeft = rectFeature.topLeft;
        CGPoint tDownRight = rectFeature.topRight;
        NSArray *a = @[[NSValue valueWithCGPoint:tTopLeft],[NSValue valueWithCGPoint:tTopRight],[NSValue valueWithCGPoint:tDownRight],[NSValue valueWithCGPoint:tDownLeft]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rect displayRect:a inCIImage:cimage];
        });
        return a;
        break;
    }
    return nil;
}

void AdaptiveFindThreshold(cv::Mat image, double *low, double *high, int aperture_size=3)
{
    cv::Mat src = image;//cv::cvarrToMat(image);
    const int cn = src.channels();
    cv::Mat dx(src.rows, src.cols, CV_16SC(cn));
    cv::Mat dy(src.rows, src.cols, CV_16SC(cn));
    
    cv::Sobel(src, dx, CV_16S, 1, 0, aperture_size, 1, 0, IPL_BORDER_REPLICATE);
    cv::Sobel(src, dy, CV_16S, 0, 1, aperture_size, 1, 0, IPL_BORDER_REPLICATE);
    
    CvMat _dx = dx, _dy = dy;
    _AdaptiveFindThreshold(&_dx, &_dy, low, high);
    
}

// 仿照matlab，自适应求高低两个门限
void _AdaptiveFindThreshold(CvMat *dx, CvMat *dy, double *low, double *high)
{
    CvSize size;
    IplImage *imge=0;
    int i,j;
    CvHistogram *hist;
    int hist_size = 255;
    float range_0[]={0,256};
    float* ranges[] = { range_0 };
    double PercentOfPixelsNotEdges = 0.7;
    size = cvGetSize(dx);
    imge = cvCreateImage(size, IPL_DEPTH_32F, 1);
    // 计算边缘的强度, 并存于图像中
    float maxv = 0;
    for(i = 0; i < size.height; i++ )
    {
        const short* _dx = (short*)(dx->data.ptr + dx->step*i);
        const short* _dy = (short*)(dy->data.ptr + dy->step*i);
        float* _image = (float *)(imge->imageData + imge->widthStep*i);
        for(j = 0; j < size.width; j++)
        {
            _image[j] = (float)(abs(_dx[j]) + abs(_dy[j]));
            maxv = maxv < _image[j] ? _image[j]: maxv;
            
        }
    }
    if(maxv == 0){
        *high = 0;
        *low = 0;
        cvReleaseImage( &imge );
        return;
    }
    
    // 计算直方图
    range_0[1] = maxv;
    hist_size = (int)(hist_size > maxv ? maxv:hist_size);
    hist = cvCreateHist(1, &hist_size, CV_HIST_ARRAY, ranges, 1);
    cvCalcHist( &imge, hist, 0, NULL );
    int total = (int)(size.height * size.width * PercentOfPixelsNotEdges);
    float sum=0;
    int icount = hist->mat.dim[0].size;
    
    float *h = (float*)cvPtr1D( hist->bins, 0 );
    for(i = 0; i < icount; i++)
    {
        sum += h[i];
        if( sum > total )
            break;
    }
    // 计算高低门限
    *high = (i+1) * maxv / hist_size ;
    *low = *high * 0.4;
    cvReleaseImage( &imge );
    cvReleaseHist(&hist);
}

int cvThresholdOtsu(IplImage* src)
{
    int height=src->height;
    int width=src->width;
    
    //histogram
    float histogram[256]={0};
    for(int i=0;i<height;i++) {
        unsigned char* p=(unsigned char*)src->imageData+src->widthStep*i;
        for(int j=0;j<width;j++) {
            histogram[*p++]++;
        }
    }
    //normalize histogram
    int size=height*width;
    for(int i=0;i<256;i++) {
        histogram[i]=histogram[i]/size;
    }
    
    //average pixel value
    float avgValue=0;
    for(int i=0;i<256;i++) {
        avgValue+=i*histogram[i];
    }
    
    int threshold = 0;
    float maxVariance=0;
    float w=0,u=0;
    for(int i=0;i<256;i++) {
        w+=histogram[i];
        u+=i*histogram[i];
        
        float t=avgValue*w-u;
        float variance=t*t/(w*(1-w));
        if(variance>maxVariance) {
            maxVariance=variance;
            threshold=i;
        }
    }
    
    return threshold;
}

double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}
static void findSquares( const Mat& image, vector<vector<cv::Point> >& squares )
{
    // blur will enhance edge detection
    Mat blurred(image);
    medianBlur(image, blurred, 9);
    
    Mat gray0(blurred.size(), CV_8U), gray;
    vector<vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++)
    {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++)
        {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0)
            {
                Canny(gray0, gray, 10, 20, 3); //
                
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray, Mat(), cv::Point(-1,-1));
            }
            else
            {
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
            
            // Test contours
            vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++)
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
                
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 &&
                    fabs(contourArea(Mat(approx))) > 1000 &&
                    isContourConvex(Mat(approx)))
                {
                    double maxCosine = 0;
                    
                    for (int j = 2; j < 5; j++)
                    {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if (maxCosine < 0.3)
                        squares.push_back(approx);
                }
            }
        }
    }
}

static void findSquaresDemo( const Mat& image, vector<vector<cv::Point> >& squares )
{
    int thresh = 50, N = 11;
    squares.clear();
    
    Mat pyr, timg, gray0(image.size(), CV_8U), gray;
    
    // down-scale and upscale the image to filter out the noise
    pyrDown(image, pyr, cv::Size(image.cols/2, image.rows/2));
    pyrUp(pyr, timg, image.size());
    vector<vector<cv::Point> > contours;
    vector<cv::Point> maxApprox;
    double area = 0.0;
    // find squares in every color plane of the image
    for( int c = 0; c < 3; c++ )
    {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        for( int l = 0; l < N; l++ )
        {
            // hack: use Canny instead of zero threshold level.
            // Canny helps to catch squares with gradient shading
            if( l == 0 )
            {
                // apply Canny. Take the upper threshold from slider
                // and set the lower to 0 (which forces edges merging)
                Canny(gray0, gray, 0, thresh, 5);
                // dilate canny output to remove potential
                // holes between edge segments
                dilate(gray, gray, Mat(), cv::Point(-1,-1));
            }
            else
            {
                // apply threshold if l!=0:
                //     tgray(x,y) = gray(x,y) < (l+1)*255/N ? 255 : 0
                gray = gray0 >= (l+1)*255/N;
            }
            
            // find contours and store them all as a list
            findContours(gray, contours, CV_RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
            
            vector<cv::Point> approx;
            
            // test each contour
            for( size_t i = 0; i < contours.size(); i++ )
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
                
                // square contours should have 4 vertices after approximation
                // relatively large area (to filter out noisy contours)
                // and be convex.
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if( approx.size() == 4 &&
                   fabs(contourArea(Mat(approx))) > 1000 &&
                   isContourConvex(Mat(approx)) )
                {
                    double maxCosine = 0;
                    
                    for( int j = 2; j < 5; j++ )
                    {
                        // find the maximum cosine of the angle between joint edges
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    // if cosines of all angles are small
                    // (all angles are ~90 degree) then write quandrange
                    // vertices to resultant sequence
                    if(( maxCosine < 0.3 )&&(area< fabs(contourArea(Mat(approx)))))
                    {
                        area = fabs(contourArea(Mat(approx)));
//                        squares.push_back(approx);
                        maxApprox = approx;
                    }
                }
            }
            
        }
    }
    squares.push_back(maxApprox);
}




#endif

- (UIImage *)getQuadrangleFromUIImage:(UIImage *)pSrcImage;
{
    
    int tImageWidth = pSrcImage.size.width;
    int tImageHeight = pSrcImage.size.height;
    
    cv::Mat occludedSquare = [pSrcImage CVMat];
    cv::Mat tOldImage = [pSrcImage CVMat];
    
    Mat pyr;
    
    // down-scale and upscale the image to filter out the noise
    cv::pyrDown(occludedSquare, pyr, cv::Size((occludedSquare.cols+1)/2, (occludedSquare.rows+1)/2));
    cv::pyrUp(pyr, occludedSquare, cv::Size(pyr.cols*2, pyr.rows*2));
    //    cv::pyrUp(pyr, occludedSquare, occludedSquare.size());
    
    //    medianBlur(occludedSquare, occludedSquare, 9);
    //    GaussianBlur(occludedSquare, occludedSquare, cv::Size(5, 5), 1.0, 2.0);
    
    Mat occludedSquare8u;
    cvtColor(occludedSquare, occludedSquare8u, CV_BGR2GRAY);
    
    IplImage tImage = occludedSquare8u;
    int tThreshOtsuValue = cvThresholdOtsu(&tImage);
    
    cv::Mat thresh;
    cv::threshold(occludedSquare8u, thresh, tThreshOtsuValue, 255, THRESH_BINARY);
    
    cv::Mat edges;
    cv::Canny(thresh, edges, 10, 20, 3);
    
    // dilate canny output to remove potential
    // holes between edge segments
    cv::dilate(edges, edges, cv::Mat(), cv::Point(-1, -1));
    
    cv::erode(edges, edges,  cv::Mat());
    
    vector<vector<cv::Point> > contours;
    // find contours and store them all as a list
    //    findContours(edges, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    
    // 只获取最大的轮廓
    cv::findContours(edges, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    
    vector<cv::Point> approx;
    
    double tMaxContourArea = 0.0;
    vector<cv::Point> tMaxApprox;
    
    // test each contour
    for( size_t i = 0; i < contours.size(); i++ )
    {
        // approximate contour with accuracy proportional
        // to the contour perimeter
        approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
        
        // square contours should have 4 vertices after approximation
        // relatively large area (to filter out noisy contours)
        // and be convex.
        // Note: absolute value of an area is used because
        // area may be positive or negative - in accordance with the
        // contour orientation
        //        if( approx.size() == 4 &&
        //           fabs(contourArea(Mat(approx))) > 100 &&
        //           isContourConvex(Mat(approx)) )
        
        double tContourArea = fabs(contourArea(Mat(approx)));
        if( tContourArea > 100 )
        {
            if (tMaxContourArea < tContourArea) {
                tMaxContourArea = tContourArea;
                
                tMaxApprox = approx;
            }
        }
    }
    
    NSMutableArray *tCornerArray = [[NSMutableArray alloc] init];;
    bool tFindContour = false;
    
    // 没有找到合适的连通轮廓， 则使用全图大小范围
    if (tMaxContourArea < 0.0001) {
        CGPoint tTopLeft = CGPointMake(0, 0);
        CGPoint tTopRight = CGPointMake(pSrcImage.size.width, 0);
        CGPoint tDownLeft = CGPointMake(0, pSrcImage.size.height);
        CGPoint tDownRight = CGPointMake(pSrcImage.size.width, pSrcImage.size.height);
        
        [tCornerArray addObject:[NSValue valueWithCGPoint:tTopLeft]];
        [tCornerArray addObject:[NSValue valueWithCGPoint:tTopRight]];
        [tCornerArray addObject:[NSValue valueWithCGPoint:tDownRight]];
        [tCornerArray addObject:[NSValue valueWithCGPoint:tDownLeft]];
        
        tFindContour = true;
    }
    else {
        
        // 四边形，凸多边形，夹角问题
        if (tMaxApprox.size() == 4 && isContourConvex(Mat(tMaxApprox))) {
            
            double maxCosine = 0;
            
            for( int j = 2; j < 5; j++ )
            {
                // find the maximum cosine of the angle between joint edges
                double cosine = fabs(angle(tMaxApprox[j%4], tMaxApprox[j-2], tMaxApprox[j-1]));
                maxCosine = MAX(maxCosine, cosine);
            }
            
            // if cosines of all angles are small
            // (all angles are ~90 degree) then write quandrange vertices to resultant sequence
            if( maxCosine < 0.3 )
            {
                int tPosX, tPosY;
                for( size_t i = 0; i < tMaxApprox.size(); i++ )
                {
                    const cv::Point* p = &tMaxApprox.at(i);
                    
                    // 防止查找到的矩形越界
                    tPosX = MIN(tImageWidth, MAX(0, p->x));
                    tPosY = MIN(tImageHeight, MAX(0, p->y));
                    CGPoint tPoint = CGPointMake(tPosX, tPosY);
                    
                    [tCornerArray addObject:[NSValue valueWithCGPoint:tPoint]];
                }
                
                
                vector<vector<cv::Point> > squares;
                squares.push_back(tMaxApprox);
                for( size_t i = 0; i < squares.size(); i++ )
                {
                    const cv::Point* p = &squares[i][0];
                    int n = (int)squares[i].size();
                    polylines(tOldImage, &p, &n, 1, true, Scalar(0,255,0), 3, CV_AA);
                }
                
                
                tFindContour = true;
            }
        }
        
        // 找到的连通图不符合要求，则取出包含连通区域的最小矩形
        if (!tFindContour) {
            cv::RotatedRect box = cv::minAreaRect(cv::Mat(tMaxApprox));
            
            cv::Point2f vertices[4];
            box.points(vertices);
            
            int tPosX, tPosY;
            for(int i = 0; i < 4; ++i)
            {
                // 防止查找到的矩形越界
                tPosX = MIN(tImageWidth, MAX(0, (int)vertices[i].x));
                tPosY = MIN(tImageHeight, MAX(0, (int)vertices[i].y));
                [tCornerArray addObject:[NSValue valueWithCGPoint:CGPointMake(tPosX, tPosY)]];
            }
            
            tFindContour = true;
            
            for(int i = 0; i < 4; ++i)
            {
                printf("Test Data:\t%d, %d\n", (int)vertices[i].x, (int)vertices[i].y);
                
                //                circle(tOldImage, vertices[i], 1, Scalar(0, 255, 0), 3);
                cv::line(tOldImage, vertices[i], vertices[(i + 1) % 4], cv::Scalar(0, 255, 0), 3, CV_AA);
            }
        }
        
    }
    
    NSLog(@"getQuadrangleFromUIImage :\t%@", tCornerArray);
    return [UIImage imageWithCVMat:tOldImage];
}
- (NSArray *)drawArr:(Mat &)image{
//    NSAutoreleasePool *tPool = [[NSAutoreleasePool alloc] init];
//    Mat image_copy;
//    cvtColor(image, image_copy, CV_BGRA2BGR);
//    Mat image_copy(image,cv::Rect(0,0,image.rows/2,image.cols / 2));
//    bitwise_not(image_copy,image_copy);
//    cvtColor(image_copy, image, CV_BGR2BGRA);
    @autoreleasepool {
        
    
    int tImageWidth = image.cols;
    int tImageHeight = image.rows;
    
    NSMutableArray *tCornerArray = [[NSMutableArray alloc] init];;
    bool tFindContour = false;
    
    CGPoint tTopLeft = CGPointMake(0, 0);
    CGPoint tTopRight = CGPointMake(image.cols, 0);
    CGPoint tDownLeft = CGPointMake(0, image.rows);
    CGPoint tDownRight = CGPointMake(image.cols, image.rows);
    
    [tCornerArray addObject:[NSValue valueWithCGPoint:tTopLeft]];
    [tCornerArray addObject:[NSValue valueWithCGPoint:tTopRight]];
    [tCornerArray addObject:[NSValue valueWithCGPoint:tDownRight]];
    [tCornerArray addObject:[NSValue valueWithCGPoint:tDownLeft]];
    @try {
        cv::Mat occludedSquare = image;
        
        Mat pyr;
        
        // down-scale and upscale the image to filter out the noise
        cv::pyrDown(occludedSquare, pyr, cv::Size((occludedSquare.cols+1)/2, (occludedSquare.rows+1)/2));
        
        cv::pyrUp(pyr, occludedSquare, cv::Size(pyr.cols*2, pyr.rows*2));
        
        //    cv::pyrUp(pyr, occludedSquare, occludedSquare.size());
        
        //    medianBlur(occludedSquare, occludedSquare, 9);
        //    GaussianBlur(occludedSquare, occludedSquare, cv::Size(5, 5), 1.0, 2.0);
        
        Mat occludedSquare8u;
        cvtColor(occludedSquare, occludedSquare8u, CV_BGR2GRAY);
        IplImage tImage = occludedSquare8u;
        
//        int tThreshOtsuValue = cvThresholdOtsu(&tImage);
        
        cv::Mat thresh = occludedSquare8u;
//        cv::threshold(occludedSquare8u, thresh, self.slider.value, 255, THRESH_BINARY);
//        image = thresh;
//        return nil;
        cv::Mat edges;
        
        cv::Canny(thresh, edges, 10, 20, 3);
//        double low = 0.0,high = 0.0;
//        AdaptiveFindThreshold(thresh, &low, &high);
//        cv::Canny(thresh, edges, low, high);
 
        
        // dilate canny output to remove potential
        // holes between edge segments
        cv::dilate(edges, edges, cv::Mat(), cv::Point(-1, -1));
        
        cv::erode(edges, edges,  cv::Mat());
        
        vector<vector<cv::Point> > contours;
        // find contours and store them all as a list
        //    findContours(edges, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
        
        // 只获取最大的轮廓
        
        cv::findContours(edges, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
        
        vector<cv::Point> approx;
        
        double tMaxContourArea = 0.0;
        vector<cv::Point> tMaxApprox;
        
        // test each contour
        for( size_t i = 0; i < contours.size(); i++ )
        {
            // approximate contour with accuracy proportional
            // to the contour perimeter
            approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
            
            // square contours should have 4 vertices after approximation
            // relatively large area (to filter out noisy contours)
            // and be convex.
            // Note: absolute value of an area is used because
            // area may be positive or negative - in accordance with the
            // contour orientation
            //        if( approx.size() == 4 &&
            //           fabs(contourArea(Mat(approx))) > 100 &&
            //           isContourConvex(Mat(approx)) )
            
            double tContourArea = fabs(contourArea(Mat(approx)));
            if( tContourArea > 100 )
            {
                if (tMaxContourArea < tContourArea) {
                    tMaxContourArea = tContourArea;
                    
                    tMaxApprox = approx;
                }
            }
        }
        
        // 没有找到合适的连通轮廓， 则使用全图大小范围
        if (tMaxContourArea < 0.0001) {
            tFindContour = true;
        }
        else {
            
            [tCornerArray removeAllObjects];
            
            // 四边形，凸多边形，夹角问题
            if (tMaxApprox.size() == 4 && isContourConvex(Mat(tMaxApprox))) {
                
                double maxCosine = 0;
                
                for( int j = 2; j < 5; j++ )
                {
                    // find the maximum cosine of the angle between joint edges
                    double cosine = fabs(angle(tMaxApprox[j%4], tMaxApprox[j-2], tMaxApprox[j-1]));
                    maxCosine = MAX(maxCosine, cosine);
                }
                
                // if cosines of all angles are small
                // (all angles are ~90 degree) then write quandrange vertices to resultant sequence
                if( maxCosine < 0.3 )
                {
                    int tPosX, tPosY;
                    for( size_t i = 0; i < tMaxApprox.size(); i++ )
                    {
                        const cv::Point* p = &tMaxApprox.at(i);
                        
                        // 防止查找到的矩形越界
                        tPosX = MIN(tImageWidth, MAX(0, p->x));
                        tPosY = MIN(tImageHeight, MAX(0, p->y));
                        CGPoint tPoint = CGPointMake(tPosX, tPosY);
                        
                        [tCornerArray addObject:[NSValue valueWithCGPoint:tPoint]];
                    }
//                    NSLog(@"Find");
                    tFindContour = true;
                }
            }
            
            // 找到的连通图不符合要求，则取出包含连通区域的最小矩形
            if (!tFindContour) {
                cv::RotatedRect box = cv::minAreaRect(cv::Mat(tMaxApprox));
                
                cv::Point2f vertices[4];
                box.points(vertices);
                
                int tPosX, tPosY;
                for(int i = 0; i < 4; ++i)
                {
                    // 防止查找到的矩形越界
                    tPosX = MIN(tImageWidth, MAX(0, (int)vertices[i].x));
                    tPosY = MIN(tImageHeight, MAX(0, (int)vertices[i].y));
                    [tCornerArray addObject:[NSValue valueWithCGPoint:CGPointMake(tPosX, tPosY)]];
                }
                
                tFindContour = true;
//                NSLog(@"Check");
            }
            
        }
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }

//    [tPool release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        /*for (int i=0;i<4;i++){
            CGPoint p = [tCornerArray[i] CGPointValue];
            if (0==i)
                self.crop1.center = CGPointMake(p.x / 1280.0 * 568, p.y / 720.0 *320);
            if (1==i)
                self.crop2.center = CGPointMake(p.x / 1280.0 * 568, p.y / 720.0 *320);
            if (2==i)
                self.crop3.center = CGPointMake(p.x / 1280.0 * 568, p.y / 720.0 *320);
            if (3==i)
                self.crop4.center = CGPointMake(p.x / 1280.0 * 568, p.y / 720.0 *320);
        }*/
//        if (-[self.just timeIntervalSinceNow] > 3)
//        {
//            self.rect.alpha = 1.0;
//            [self.rect displayRect:tCornerArray];
//            self.just = [NSDate date];
//        }
//        else{
//            [UIView animateWithDuration:1.0 animations:^{
//                self.rect.alpha = 0.;
//            }];
//        }
        if (self.saveImg){
            UIImage *img = [UIImage imageWithCVMat:image];
            UIImageView *imgv = [[UIImageView alloc] initWithImage:img];
            imgv.contentMode = UIViewContentModeScaleAspectFit;
            imgv.frame = self.view.bounds;
            [self.view addSubview:imgv];
            
            
        }
        [UIView animateWithDuration:0.3 animations:^{
            [self.rect displayRect:tCornerArray orientation:[[UIApplication sharedApplication] statusBarOrientation]];
        }];
    });
    return [tCornerArray autorelease];
    }
}


- (UIImage *)fixOrientationOfImage:(UIImage *)image {
    
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
@end
