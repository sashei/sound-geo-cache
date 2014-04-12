//
//  MainViewController.m
//  soundgeocache
//
//  Created by Sasha Heinen on 4/11/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        
        // location manager initialization
        _locationManager = [CLLocationManager new];
        [_locationManager setDelegate:self];
        // make location updates very granular
        [_locationManager startUpdatingLocation];
        
        // maps! well, just one.
        _map = [[MKMapView alloc] initWithFrame:self.view.bounds];
        [_map setDelegate:self];
        _map.showsUserLocation = true;
        _map.showsPointsOfInterest = false;
        _map.showsBuildings = false;
        
        // just a for setting the region when we get the CLLocationManager stuff goin' on.
        _shouldUpdateLocation = true;
        
        [self.view addSubview:_map];
        
        // record button
        int recX = self.view.bounds.size.width*.1;
        int recSizeX = self.view.bounds.size.width*.3;
        int recSizeY = recSizeX;
        int recY = self.view.bounds.size.height*.95 - recSizeX;
        CGRect recordFrame = CGRectMake(recX, recY, recSizeX, recSizeY);
        
        _recordButton = [[UIButton alloc] initWithFrame:recordFrame];
        _recordButton.contentMode = UIViewContentModeScaleAspectFit;
        //[_recordButton setBackgroundColor:[UIColor redColor]];
        //UIImage *redButton = [UIImage imageNamed:@"redbutton.png"];
        //[_recordButton setBackgroundImage:[UIImage imageNamed:@"redbutton.png"] forState:UIControlStateNormal];
        [_recordButton setImage:[UIImage imageNamed:@"redcircle.png"] forState:UIControlStateNormal];
        [self.view addSubview:_recordButton];
        
        // play / compass?
        int playSizeX = recSizeX;
        int playSizeY = playSizeX;
        int playX = self.view.bounds.size.width*.9 - playSizeX;
        int playY = recY;
        CGRect playFrame = CGRectMake(playX, playY, playSizeX, playSizeY);
        
        _playButton = [[UIButton alloc] initWithFrame:playFrame];
        _playButton.contentMode = UIViewContentModeScaleAspectFit;
        [_playButton setImage:[UIImage imageNamed:@"whitecircle.png"] forState:UIControlStateNormal];
        
    }
    return self;
}

float milesToMeters(float miles) {
    return 1609.344f * miles;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *current = [locations objectAtIndex:([locations count]-1)];
    CLLocationCoordinate2D center = current.coordinate;
    
    if (_shouldUpdateLocation) {
        [_map setRegion:(MKCoordinateRegionMakeWithDistance(center, milesToMeters(1.0f), milesToMeters(1.0f)))];
        _shouldUpdateLocation = false;
    }
    
    // send this to john's database manager, woohoo!
    NSArray *bounds = [self getBounds];
    
    // we will get something back, so fun-ness.
    
    
}

-(NSArray *)getBounds
{
    MKCoordinateRegion currentRegion = _map.region;
    double latDif = currentRegion.span.latitudeDelta/2.0;
    double longDif = currentRegion.span.longitudeDelta/2.0;
    
    double topLeftLat = currentRegion.center.latitude + latDif;
    double topLeftLong = currentRegion.center.longitude - longDif;
    
    double bottomRightLat = currentRegion.center.latitude - latDif;
    double bottomRightLong = currentRegion.center.longitude + longDif;
    
    CLLocation *topLeft = [[CLLocation alloc] initWithLatitude:topLeftLat longitude:topLeftLong];
    CLLocation *bottomRight = [[CLLocation alloc] initWithLatitude:bottomRightLat longitude:bottomRightLong];
    
    return [NSArray arrayWithObjects: topLeft, bottomRight, nil];
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    
    if ([annotation isMemberOfClass:[SCSound class]])
    {
        SCSound *p = annotation;
        NSString *identifier = p.soundURL;
        MKAnnotationView* annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if (annotationView) {
            annotationView.annotation = annotation;
        } else {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:identifier];
        }
        
        annotationView.image = [UIImage imageNamed:@"smallredcircle.png"];
        
        return annotationView;
    } else {
        return nil;
    }
    
    return nil;
}

-(void)receiveSounds:(NSMutableArray *)sounds
{
    // this is what I will get back from john:
    _closeSounds = sounds;
    
    // add the annotations
    for (SCSound *p in _closeSounds) {
        [_map addAnnotation:p];
        CLLocation *pLoc = [[CLLocation alloc] initWithLatitude:p.coordinate.latitude longitude:p.coordinate.longitude];
        
        // check close-ness of each new thing around us
        if ([self isWithinTenFeet:pLoc]) {
            [self closeEnough:p];
        }
    }
}

-(void)closeEnough:(SCSound *)sound
{
    [self.view addSubview:_playButton];
    
    MKAnnotationView *pView = [_map dequeueReusableAnnotationViewWithIdentifier:sound.soundURL];
    
    if (pView) {
        pView.annotation = sound;
    } else {
        pView = [[MKAnnotationView alloc] initWithAnnotation:sound
                                                reuseIdentifier:sound.soundURL];
    }
    
    pView.image = [UIImage imageNamed:@"smallredcircle.png"];
    
    // this is where I will retrieve the proper sounds from the database and package them to send to the
    // music player.
    
    
}

-(void)recordButtonPressed:(id)sender
{
    // todo!
}

-(void)playButtonPressed:(id)sender
{
    // send packaged stuff to rupe
    
}

-(bool)isWithinTenFeet:(CLLocation *) location
{
    return (([_locationManager.location distanceFromLocation:location]*3.28084) <= 10.0);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
