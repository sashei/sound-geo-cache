//
//  MainViewController.h
//  soundgeocache
//
//  Created by Sasha Heinen on 4/11/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MainViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@property MKMapView *map;
@property CLLocationManager *locationManager;

@property UIButton *record;
@property UIButton *play;

@end
