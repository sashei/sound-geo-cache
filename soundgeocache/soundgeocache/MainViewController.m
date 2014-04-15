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
        _isGettingSounds = NO;
        
        // init soundstosend
        _soundsToSend = [NSMutableArray new];
        
        // location manager initialization
        _locationManager = [CLLocationManager new];
        [_locationManager setDelegate:self];
        // make location updates very granular
        [_locationManager startUpdatingLocation];
        
        
        // the main view that contains the app
        _mainView = [[UIView alloc] initWithFrame:self.view.frame];
        [self.view addSubview:_mainView];
        
        // maps! well, just one.
        _map = [[MKMapView alloc] initWithFrame:self.view.bounds];
        [_map setDelegate:self];
        _map.showsUserLocation = true;
        _map.showsPointsOfInterest = false;
        _map.showsBuildings = false;
        
        // just for setting the region when we get the CLLocationManager stuff goin' on.
        _shouldUpdateLocation = true;
        
        _significantLocation = nil;
        
        [_mainView addSubview:_map];
        
        // record button
        int recX = self.view.bounds.size.width*.05;
        int recSizeX = self.view.bounds.size.width*.2;
        int recSizeY = recSizeX;
        int recY = self.view.bounds.size.height - (recSizeX + recX);
        CGRect recordFrame = CGRectMake(recX, recY, recSizeX, recSizeY);
        
        _recordButton = [[UIButton alloc] initWithFrame:recordFrame];
        _recordButton.contentMode = UIViewContentModeScaleAspectFit;
        //[_recordButton setBackgroundColor:[UIColor redColor]];
        //UIImage *redButton = [UIImage imageNamed:@"redbutton.png"];
        //[_recordButton setBackgroundImage:[UIImage imageNamed:@"redbutton.png"] forState:UIControlStateNormal];
        [_recordButton setImage:[UIImage imageNamed:@"MIC-3.png"] forState:UIControlStateNormal];
        [_recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_recordButton setAlpha:0.0];
        [_recordButton setHidden:YES];
        [_mainView addSubview:_recordButton];
        _shouldShowRecordButton = NO;
        _isUploadingData = NO;
        
        _recordActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_recordActivityIndicator setCenter:_recordButton.center];
        [_recordActivityIndicator setHidesWhenStopped:YES];
        [_recordActivityIndicator setColor:[UIColor darkGrayColor]];
        [_mainView addSubview:_recordActivityIndicator];
        
        
        // play / compass?
        int playSizeX = recSizeX;
        int playSizeY = playSizeX;
        int playX = self.view.bounds.size.width*.95 - playSizeX;
        int playY = recY;
        CGRect playFrame = CGRectMake(playX, playY, playSizeX, playSizeY);
        
        _playButton = [[UIButton alloc] initWithFrame:playFrame];
        _playButton.contentMode = UIViewContentModeScaleAspectFit;
        [_playButton setImage:[UIImage imageNamed:@"ear.png"] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        //_playButton.alpha = 0.0f;
        [_mainView addSubview:_playButton];
        
        // mainview is hidden until sounds are loaded
        //[_mainView setHidden:YES];
        [_mainView setAlpha:0.3];
        [_mainView setUserInteractionEnabled:NO];
        
        
        // Add the loading label and activity indicator to self.view
        
        _annotationsActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_annotationsActivityIndicator setCenter:self.view.center];
        [_annotationsActivityIndicator setHidesWhenStopped:YES];
        [_annotationsActivityIndicator setColor:[UIColor darkGrayColor]];
        [self.view addSubview:_annotationsActivityIndicator];
        
        _loadingAnnotationsLabel = [[UILabel alloc] init];
        [_loadingAnnotationsLabel setFont:[UIFont systemFontOfSize:15.0]];
        [_loadingAnnotationsLabel setText:@"Loading nearby sounds"];
        [_loadingAnnotationsLabel sizeToFit];
        CGPoint labelCenter = [_annotationsActivityIndicator center];
        labelCenter.y += _annotationsActivityIndicator.frame.size.height;
        [_loadingAnnotationsLabel setCenter:labelCenter];
        [self.view addSubview:_loadingAnnotationsLabel];
        
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
        //NSLog(@"Audio path is: %@", _tempAudioPath);
        
        NSURL *soundFileURL = [NSURL fileURLWithPath:_tempAudioPath];
        NSError *error = nil;
        _recorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
        
        // set up table view controller for sound detail views
        _soundsView = [SCSoundsViewController new];
        
        _closeSounds = nil;
        
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    if (!_closeSounds) {
        [_annotationsActivityIndicator startAnimating];
    }
}

#pragma mark - location & map delegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *current = [locations objectAtIndex:([locations count]-1)];
    CLLocationCoordinate2D center = current.coordinate;
    
    // for the first update, get our first significant location
    if (!_significantLocation) {
        //NSLog(@"Setting significant location");
        _significantLocation = current;
        _isGettingSounds = YES;
        [_database requestSoundsNear:center];
    }
    
    // hack for a significant location change (> 10km) to call the database
    if ([_significantLocation distanceFromLocation:current] > 10000) {
        _significantLocation = current;
        _isGettingSounds = YES;
        [_database requestSoundsNear:center];
    }
    
    if (_shouldUpdateLocation) {
        [_map setRegion:(MKCoordinateRegionMakeWithDistance(center, milesToMeters(1.0f), milesToMeters(1.0f)))];
        _shouldUpdateLocation = false;
    }
    
    // cleanup our soundstosend object as we move:
    NSMutableArray *toRemove = [NSMutableArray new];
    
    if (!_isGettingSounds) {
        for (SCSound *s in _soundsToSend) {
            CLLocation *loc = [[CLLocation alloc] initWithLatitude:s.coordinate.latitude longitude:s.coordinate.longitude];
            
            if (![self isWithinTenFeet:loc])
                [toRemove addObject:s];
        }
        
        for (SCSound *p in _closeSounds) {
            CLLocation *pLoc = [[CLLocation alloc] initWithLatitude:p.coordinate.latitude longitude:p.coordinate.longitude];
            if (![_soundsToSend containsObject:p]) {
                if ([self isWithinTenFeet:pLoc]) {
                    [_soundsToSend addObject:p];
                }
            }
            else {
                if (![self isWithinTenFeet:pLoc]) {
                    [_soundsToSend removeObject:p];
                }
            }
        }
    }
    
    [self updatePlayButton];
    [self updateRecordButton];
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
        
        annotationView.image = [UIImage imageNamed:@"orangesound.png"];
        
        return annotationView;
        
    } else {
        return nil;
    }
}

# pragma mark - database delegate methods & logic

-(void)receiveSounds:(NSMutableArray *)sounds
{
    _isGettingSounds = NO;
    if (!_closeSounds) {
        [_annotationsActivityIndicator stopAnimating];
        [_loadingAnnotationsLabel setHidden:YES];
        //[_mainView setHidden:NO];
        [UIView animateWithDuration:0.5 animations:^{
            [_mainView setAlpha:1.0];
        }];
        [_mainView setUserInteractionEnabled:YES];
    }
    
    // the sounds array will be coming from john's database
    //NSLog(@"Num annotations: %lu", (unsigned long)[_map.annotations count]);
    
    _closeSounds = sounds;
    //NSLog(@"Num close sounds: %lu", (unsigned long)[_closeSounds count]);

    [_soundsToSend removeAllObjects];
    
    for (SCSound *p in _closeSounds) {
        if (![self soundAlreadyAnnotated:p])
            [_map addAnnotation:p];
        
        CLLocation *pLoc = [[CLLocation alloc] initWithLatitude:p.coordinate.latitude longitude:p.coordinate.longitude];
        if (![_soundsToSend containsObject:p]) {
            if ([self isWithinTenFeet:pLoc]) {
                [_soundsToSend addObject:p];
            }
        }
        else {
            if (![self isWithinTenFeet:pLoc]) {
                [_soundsToSend removeObject:p];
            }
        }
    }
    
    // useful to look at for debugging purposes!
    NSArray *annotations = _map.annotations;
    //NSLog(@"Num annotations: %lu", (unsigned long)[annotations count]);
}

- (void) uploadFinished {
    _isGettingSounds = YES;
    [_database requestSoundsNear:_locationManager.location.coordinate];
    [_recordActivityIndicator stopAnimating];
    _isUploadingData = NO;
    [_recordButton setImage:[UIImage imageNamed:@"MIC-3.png" ] forState:UIControlStateNormal];
    [self updateRecordButton];
}

-(void)closeEnough:(SCSound *)sound
{
//    [UIView beginAnimations:@"Fade" context:NULL];
//    _playButton.alpha = 1.0f;
//    [UIView commitAnimations];
    
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
        audioData = [[NSData alloc] initWithContentsOfFile:_tempAudioPath];
        //[[NSFileManager defaultManager] removeItemAtPath:_tempAudioPath error:nil];
        
        //need to do something with data to store into database!!! D:
        [_database addSound:audioData withLocation:_locationManager.location.coordinate];
        _isUploadingData = YES;
        [self updateRecordButton];
        [_recordActivityIndicator startAnimating];
    }
}

-(void)playButtonPressed:(id)sender
{
    // send packaged stuff to rupe!
    [_soundsView loadSounds:_soundsToSend];
    [self.navigationController pushViewController:_soundsView animated:YES];
}

- (void) updatePlayButton {
    if ([_playButton isHidden] && ([_soundsToSend count] > 0) && ![_recorder isRecording] && !_isUploadingData) {
        [_playButton setHidden:NO];
        [UIView animateWithDuration:0.5 animations:^{
            [_playButton setAlpha:1.0];
        }];
    }
    if (![_playButton isHidden] && (([_soundsToSend count] == 0) || [_recorder isRecording] || _isUploadingData))
        [UIView animateWithDuration:0.5 animations:^{
            [_playButton setAlpha:0.0];
        } completion:^(BOOL finished) {
            [_playButton setHidden:YES];
        }];
}

- (void) updateRecordButton {
    _shouldShowRecordButton = !_isUploadingData && (_locationManager.location.horizontalAccuracy < 50);
    
    if (!_shouldShowRecordButton && ![_recordButton isHidden]) {
        [UIView animateWithDuration:0.5 animations:^(void){
            [_recordButton setAlpha:0.0];
        } completion:^(BOOL finished) {
            [_recordButton setHidden:YES];
        }];
    }
    else if (_shouldShowRecordButton && [_recordButton isHidden]) {
        [_recordButton setHidden:NO];
        [UIView animateWithDuration:0.5 animations:^(void){
            [_recordButton setAlpha:1.0];
        }];
    }
}

#pragma mark - helper functions

float milesToMeters(float miles) {
    return 1609.344f * miles;
}

-(bool)isWithinTenFeet:(CLLocation *)loc
{
    return (([_locationManager.location distanceFromLocation:loc]*3.28084) <= 50.0);
}

-(bool)soundAlreadyAnnotated:(SCSound *)sound
{
    NSUInteger index = -1;
    index = [_map.annotations indexOfObjectPassingTest:
                        ^BOOL(id obj, NSUInteger idx, BOOL *stop){
                            return [self clCoordinatesEqual:((SCSound*)obj).coordinate and: sound.coordinate];
                        }];
    if (index == NSNotFound)
    {
        return false;
    }
    return true;
}

- (BOOL) clCoordinatesEqual:(CLLocationCoordinate2D)c1 and: (CLLocationCoordinate2D)c2 {
    return (c1.latitude == c2.latitude) && (c1.longitude == c2.longitude);
}

- (void)removeAllPinsButUserLocation
{
    id userLocation = [_map userLocation];
    [_map removeAnnotations:[_map annotations]];
    
    if ( userLocation != nil ) {
        [_map addAnnotation:userLocation]; // will cause user location pin to blink
    }
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
