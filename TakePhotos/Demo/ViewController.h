//
//  ViewController.h
//  Demo
//
//  Created by CaoWentao on 14-8-20.
//  Copyright (c) 2014年 YCQY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/ios.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import <CoreMotion/CoreMotion.h>



@interface ViewController : UIViewController<CvPhotoCameraDelegate,CLLocationManagerDelegate>

@property (nonatomic,strong) CvPhotoCamera* photoCamera;
@property (nonatomic,strong) CLLocationManager* locationManager;
@property (nonatomic,strong) CMMotionManager* motionManager;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *takePhotoButton;

- (IBAction)takePhotoPressed:(id)sender;

@end
