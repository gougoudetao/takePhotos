//
//  ViewController.m
//  Demo
//
//  Created by CaoWentao on 14-8-14.
//  Copyright (c) 2014年 YCQY. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/nonfree/nonfree.hpp>
#import "UIImage_Extension.h"

@interface ViewController ()
{
    NSTimer* timer;
    cv::Mat pauseImage;//相机暂停时那帧图像
#pragma 需要传输的原始数据
    CLLocation* currLocation;
    CMAttitude* currAttitude;
    float currTrueHeading;
    NSDictionary* writeToFileDictory;
    
    UIImageView* resultView;
}

@end


@implementation ViewController

@synthesize toolbar,takePhotoButton,imageView;
@synthesize photoCamera,locationManager,motionManager;

static const double FPS=10.0;
static const NSTimeInterval interval=1.0/FPS;

#pragma 位置服务
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    currLocation=[locations lastObject];
    NSLog(@"Location: %f,%f,%f",currLocation.coordinate.latitude,currLocation.coordinate.longitude,currLocation.altitude);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"error: %@",error);
}

#pragma 朝向服务
-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    UIDevice *device=[UIDevice currentDevice];
    if(newHeading.headingAccuracy>0){
        currTrueHeading=[self trueHeading:newHeading.trueHeading fromeOrientation:device.orientation];
        //NSLog(@"True Heading: %.5f",currTrueHeading);
    }
}

-(float)trueHeading:(float)heading fromeOrientation:(UIDeviceOrientation)orientation{
    float realHeading=heading;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            realHeading=realHeading+180.0f;
            break;
        case UIDeviceOrientationLandscapeLeft:
            realHeading=realHeading+90.0f;
            break;
        case UIDeviceOrientationLandscapeRight:
            realHeading=realHeading-90.0f;
            break;
        default:
            break;
    }
    while(realHeading>360.0f){
        realHeading=realHeading-360;
    }
    while(realHeading<0.0f){
        realHeading=realHeading+360;
    }
    return realHeading;
}

#pragma 姿态服务
-(void)updateAttitude:(NSTimer*)timer
{
    CMDeviceMotion *motionData=motionManager.deviceMotion;
    currAttitude=motionData.attitude;
}

#pragma 视图
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [locationManager startUpdatingLocation];
    [locationManager startUpdatingHeading];
    
    [photoCamera start];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [locationManager startUpdatingLocation];
    [locationManager startUpdatingHeading];
    
    [photoCamera stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Init camera
    photoCamera=[[CvPhotoCamera alloc]initWithParentView:imageView];
    photoCamera.delegate=self;
    photoCamera.defaultAVCaptureDevicePosition=AVCaptureDevicePositionBack;
    photoCamera.defaultAVCaptureSessionPreset=AVCaptureSessionPreset640x480;
    photoCamera.defaultAVCaptureVideoOrientation=AVCaptureVideoOrientationPortrait;
    
    [photoCamera start];
    [self.view addSubview:imageView];
    
    //Init locationManager
    locationManager=[[CLLocationManager alloc]init];
    locationManager.delegate=self;
    if([CLLocationManager locationServicesEnabled]&&[CLLocationManager headingAvailable]){
        locationManager.headingFilter=1;
        locationManager.desiredAccuracy=kCLLocationAccuracyBest;
        locationManager.distanceFilter=kCLDistanceFilterNone;
    }else{
        NSLog(@"Can't report heading");
    }
    
    //Init motionManager
    motionManager=[[CMMotionManager alloc]init];
    [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
    if(motionManager.deviceMotionAvailable){
        timer=[NSTimer scheduledTimerWithTimeInterval:interval
                                               target:self
                                             selector:@selector(updateAttitude:)
                                             userInfo:nil
                                              repeats:YES];
    }else{
        NSLog(@"Motion device is not available.");
        [motionManager stopDeviceMotionUpdates];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    photoCamera.delegate=nil;
}

#pragma 响应函数


-(void)photoCamera:(CvPhotoCamera *)photoCamera capturedImage:(UIImage *)image
{
    cv::Mat frame=[self cvMatFromUIImage:image];
    
    UIImage* rotatedImage=[self UIImageFromCVMat:frame];
    
    //UIImage* rotatedImage=[self leftPixelRotation:image];
    //UIImage* rotatedImage=[image rotation:UIImageOrientationLeft];
    
    
    NSLog(@"image width:%f height:%f",rotatedImage.size.width,rotatedImage.size.height);
    
    
    [photoCamera stop];
    
    //[takePhotoButton setEnabled:NO];
    
    //UIImageWriteToSavedPhotosAlbum(image, self, nil, dataPtr);
    
//    UIAlertView *alert = [UIAlertView alloc];
//    alert = [alert initWithTitle:@"保存图片"
//                         message:@"已经保存"
//                        delegate:nil
//               cancelButtonTitle:@"继续"
//               otherButtonTitles:nil];
//    [alert show];
//    
//    NSString* documentPath=[self applicationDocumentsDirectoryPath];
//    NSString* timeString=[self getCurrentTimeString];
//    NSString* rotateFilename=[[documentPath stringByAppendingPathComponent:[timeString stringByAppendingString:@"rotated"]]stringByAppendingPathExtension:@"jpg"];
//    NSString* imageFilename=[documentPath stringByAppendingPathComponent:[timeString stringByAppendingPathExtension:@"jpg"]];
//    NSString* textFilename=[documentPath stringByAppendingPathComponent:[timeString stringByAppendingPathExtension:@"xml"]];
//    NSLog(@"%@",imageFilename);
//    NSLog(@"%@",textFilename);
//    
//    [UIImageJPEGRepresentation(rotatedImage, 1.0)writeToFile:rotateFilename atomically:YES];
//    [UIImageJPEGRepresentation(image, 1.0)writeToFile:imageFilename atomically:YES];
//    [writeToFileDictory writeToFile:textFilename atomically:YES];
    
//    [photoCamera start];
//    [takePhotoButton setEnabled:YES];
}

-(NSString *)getCurrentTimeString
{
    NSDate *now=[NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *dateComponent = [calendar components:unitFlags fromDate:now];
    
    int year = [dateComponent year];
    int month = [dateComponent month];
    NSString *monthStr=month<10?[NSString stringWithFormat:@"0%d",month]:[NSString stringWithFormat:@"%d",month];
    int day = [dateComponent day];
    NSString *dayStr=day<10?[NSString stringWithFormat:@"0%d",day]:[NSString stringWithFormat:@"%d",day];
    int hour = [dateComponent hour];
    NSString *hourStr=hour<10?[NSString stringWithFormat:@"0%d",hour]:[NSString stringWithFormat:@"%d",hour];
    int minute = [dateComponent minute];
    NSString *minuteStr=minute<10?[NSString stringWithFormat:@"0%d",minute]:[NSString stringWithFormat:@"%d",minute];
    int second = [dateComponent second];
    NSString *secondStr=second<10?[NSString stringWithFormat:@"0%d",second]:[NSString stringWithFormat:@"%d",second];
    
    return [NSString stringWithFormat:@"%d%@%@%@%@%@",year,monthStr,dayStr,hourStr,minuteStr,secondStr];
}

-(void)photoCameraCancel:(CvPhotoCamera *)photoCamera
{
    
}

-(NSString *)applicationDocumentsDirectoryPath{
    NSString *documentDirectory=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    
    return documentDirectory;
}

- (IBAction)takePhotoPressed:(id)sender
{
    NSString* documentPath=[self applicationDocumentsDirectoryPath];
    NSString* filename=@"20140829142148.jpg";
    NSString* imageFilename=[documentPath stringByAppendingPathComponent:filename];
    
    cv::Mat image=cv::imread([imageFilename UTF8String]);
    NSLog(@"%d,%d",image.cols,image.rows);
    cv::Mat resultImage(image.cols,image.rows,CV_8UC3);
    
    NSLog(@"%d,%d",resultImage.cols,resultImage.rows);
    
    
    
    int height=image.rows;
    int width=image.cols;
    
    for(int j=0;j<height;++j){
        for(int i=0;i<width;++i){
            resultImage.at<cv::Vec4b>(width-1-i,j)[0]=image.at<cv::Vec4b>(j,i)[0];
            resultImage.at<cv::Vec4b>(width-1-i,j)[1]=image.at<cv::Vec4b>(j,i)[1];
            resultImage.at<cv::Vec4b>(width-1-i,j)[2]=image.at<cv::Vec4b>(j,i)[2];
        }
    }
    
    NSString* saveFilename=[documentPath stringByAppendingPathComponent:@"test.jpg"];
    cv::imwrite([saveFilename UTF8String], resultImage);
    

    UIImage* rotatedImage=[self UIImageFromCVMat:image];
    resultView=[[UIImageView alloc]initWithFrame:imageView.bounds];
    [resultView setImage:rotatedImage];
    [self.view addSubview:resultView];
    
    
    float* dataPtr=new float[11];
    
    dataPtr[0]=currLocation.coordinate.latitude;
    dataPtr[1]=currLocation.coordinate.longitude;
    dataPtr[2]=currLocation.altitude;
    dataPtr[3]=currAttitude.yaw;
    dataPtr[4]=currAttitude.pitch;
    dataPtr[5]=currAttitude.roll;
    dataPtr[6]=currTrueHeading;
    dataPtr[7]=4.28/4.54*640;
    dataPtr[8]=320;
    dataPtr[9]=4.28/3.42*480;
    dataPtr[10]=240;
    
    NSMutableDictionary *dictionary=[[NSMutableDictionary alloc]init];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[0]] forKey:@"latitude"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[1]] forKey:@"longitude"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[2]] forKey:@"altitude"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[3]] forKey:@"yaw"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[4]] forKey:@"pitch"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[5]] forKey:@"roll"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[6]] forKey:@"heading"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[7]] forKey:@"fx"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[8]] forKey:@"cx"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[9]] forKey:@"fy"];
    [dictionary setValue:[NSNumber numberWithFloat:dataPtr[10]] forKey:@"cy"];
    
//    NSMutableArray* array=[[NSMutableArray alloc]init];
//    for(uint i=0;i<11;++i){
//        array[i]=[NSNumber numberWithFloat:dataPtr[i]];
//    }
    
    writeToFileDictory=[dictionary copy];
    
    [photoCamera takePicture];
}

-(UIImage *)leftPixelRotation:(UIImage *)src
{
    cv::Mat frame;
    UIImageToMat(src, frame ,YES);
    
    cv::Mat resultImage(frame.cols,frame.rows,frame.type());
    
    NSLog(@"type: %d",frame.type());
    
    int height=frame.rows;
    int width=frame.cols;
    
    for(int j=0;j<height;++j){
        for(int i=0;i<width;++i){
            resultImage.at<cv::Vec3b>(width-1-i,j)=frame.at<cv::Vec3b>(j,i);
        }
    }
    
    UIImage* result=MatToUIImage(frame);
    return result;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
