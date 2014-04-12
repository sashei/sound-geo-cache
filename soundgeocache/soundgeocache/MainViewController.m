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
        
       // database initialization
        _database = [[SCDatabase alloc] init];
        _database.delegate = self;
        
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
        
        // just for setting the region when we get the CLLocationManager stuff goin' on.
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
        [_recordButton setImage:[UIImage imageNamed:@"MIC-3.png"] forState:UIControlStateNormal];
        [_recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
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
        [_playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _playButton.hidden = true;
        [self.view addSubview:_playButton];
        
        
        // audio player stuff:
        NSDictionary *recordSettings = [NSDictionary
                                        dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:AVAudioQualityMin],
                                        AVEncoderAudioQualityKey,
                                        [NSNumber numberWithInt:16],
                                        AVEncoderBitRateKey,
                                        [NSNumber numberWithInt: 2],
                                        AVNumberOfChannelsKey,
                                        [NSNumber numberWithFloat:44100.0],
                                        AVSampleRateKey,
                                        nil];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [paths objectAtIndex:0];
        _tempAudioPath = [documentDirectory stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
        NSLog(@"Audio path is: %@", _tempAudioPath);
        
        NSURL *soundFileURL = [NSURL fileURLWithPath:_tempAudioPath];
        NSError *error = nil;
        _recorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
        
        // set up table view controller for sound detail views
        _soundsView = [SCSoundsViewController new];
        
    }
    return self;
}

#pragma mark - location & map delegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *current = [locations objectAtIndex:([locations count]-1)];
    CLLocationCoordinate2D center = current.coordinate;
    
    if (_shouldUpdateLocation) {
        [_map setRegion:(MKCoordinateRegionMakeWithDistance(center, milesToMeters(1.0f), milesToMeters(1.0f)))];
        _shouldUpdateLocation = false;
    }
    
    // cleanup our soundstosend object as we move:
    for (SCSound *s in _soundsToSend) {
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:s.coordinate.latitude longitude:s.coordinate.longitude];
        if (![self isWithinTenFeet:loc])
            [_soundsToSend removeObject:s];
    }

    [_database requestSoundsNear:center];
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[SCSound class]])
    {
        SCSound *p = annotation;
        NSString *identifier = p.soundURL.fragment;
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

# pragma mark - database delegate methods & logic

-(void)receiveSounds:(NSMutableArray *)sounds
{
    // the sounds array will be coming from john's database
    
    _closeSounds = sounds;
    NSLog(@"received sounds in range with count: %d", [_closeSounds count]);
    
    bool hasSoundInRange = false;
    
    // alter the annotations
    for (SCSound *p in _closeSounds) {
        // check to make sure this particular sound isn't already in our map
        if (![self containsURL:_map.annotations fromSound:p])
            [_map addAnnotation:p];
        
        CLLocation *pLoc = [[CLLocation alloc] initWithLatitude:p.coordinate.latitude longitude:p.coordinate.longitude];
        
        // check close-ness of each new thing around us
        if ([self isWithinTenFeet:pLoc]) {
            [self closeEnough:p];
            hasSoundInRange = true;
        }
    }
    
    if (!hasSoundInRange)
        _playButton.hidden = true;
    
    // useful to look at for debugging purposes!
    //NSArray *annotations = _map.annotations;
    
}

-(void)closeEnough:(SCSound *)sound
{
    _playButton.hidden = false;
    
    MKAnnotationView *pView = [_map dequeueReusableAnnotationViewWithIdentifier:sound.soundURL.fragment];
    
    if (pView) {
        pView.annotation = sound;
    } else {
        pView = [[MKAnnotationView alloc] initWithAnnotation:sound
                                                reuseIdentifier:sound.soundURL.fragment];
    }
    
    pView.image = [UIImage imageNamed:@"smallwhitecircle.png"];
    
    [_soundsToSend addObject:sound];
}

#pragma mark - button functionality

-(void)recordButtonPressed:(id)sender
{
    NSData *audioData;
    if (!_recorder.recording) {
        if ([_recorder prepareToRecord]) {
            [_recorder record];
            [_recordButton setImage:[UIImage imageNamed:@"Stop.png"] forState:UIControlStateNormal];
        } else {
            NSLog(@"Problem preparing AVAudioRecorder");
        }
    }
    else {
        [_recorder stop];
        [_recordButton setImage:[UIImage imageNamed:@"MIC-3.png"] forState:UIControlStateNormal];
        audioData = [[NSData alloc] initWithContentsOfFile:_tempAudioPath];
        
        //need to do something with data to store into database!!! D:
        [_database addSound:audioData withLocation:_locationManager.location.coordinate];
        
        [_database requestSoundsNear:_locationManager.location.coordinate];
    }
}

-(void)playButtonPressed:(id)sender
{
    // send packaged stuff to rupe!
    [_soundsView loadSounds:_soundsToSend];
    [self.navigationController pushViewController:_soundsView animated:YES];
}

#pragma mark - helper functions

float milesToMeters(float miles) {
    return 1609.344f * miles;
}

-(bool)isWithinTenFeet:(CLLocation *)loc
{
    return (([_locationManager.location distanceFromLocation:loc]*3.28084) <= 10.0);
}

-(bool)containsURL:(NSArray *)annotations fromSound:(SCSound *)sound
{
    for (id note in annotations) {
        if ([note isKindOfClass:[SCSound class]]) {
            SCSound *sound = note;
            if ([sound.soundURL isEqual:sound.soundURL])
                return true;
        }
    }
    return false;
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
