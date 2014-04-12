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

// view stuff
@property MKMapView *map;
@property UIButton *recordButton;
@property UIButton *playButton;

// location stuff
@property CLLocationManager *locationManager;
@property BOOL shouldUpdateLocation;

// data stuff
@property NSMutableArray *closeSounds;
@property NSMutableArray *soundsToSend;

-(NSArray *)getBounds;
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation;

//todo:
-(void)recordButtonPressed:(id)sender;
-(void)playButtonPressed:(id)sender;

@end
