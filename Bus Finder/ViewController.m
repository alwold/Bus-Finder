//
//  ViewController.m
//  Bus Finder
//
//  Created by Al Wold on 12/6/14.
//  Copyright (c) 2014 Al Wold. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;
@property (nonatomic) dispatch_source_t source;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableData *data;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CLAuthorizationStatus status =[CLLocationManager authorizationStatus];
    NSLog(@"Status: %d", status);
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if (status == kCLAuthorizationStatusNotDetermined) {
        NSLog(@"requestin gaccess");
        [self.locationManager requestWhenInUseAuthorization];
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
    } else {
        NSLog(@"can't use location");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (self.location == nil) {
        self.location = locations[0];
        // TODO start updates
        NSLog(@"starting updates");
        self.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(self.source, DISPATCH_TIME_NOW, 90*NSEC_PER_SEC, NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.source, ^{
            NSLog(@"updatE");
            [self updateBuses];
        });
        dispatch_resume(self.source);
    } else {
        self.location = locations[0];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
    }
}

- (void)updateBuses
{
    NSLog(@"updateBuses");
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://transitdata.phoenix.gov/api/vehiclepositions?format=json"]];
    self.connection = [NSURLConnection connectionWithRequest:req delegate:self];
    NSLog(@"starting connection");
    self.data = [[NSMutableData alloc] init];
    [self.connection start];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"connection did fail");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"receive data");
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error;
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&error];
    NSLog(@"did finish loading: %@", jsonData);
    NSArray *array = jsonData[@"entity"];
    [self.mapView removeAnnotations:self.mapView.annotations];
    for (NSDictionary *dictionary in array) {
        NSDictionary *vehicle = dictionary[@"vehicle"];
        NSDictionary *position = vehicle[@"position"];
        NSString *latitude = position[@"latitude"];
        NSString *longitude = position[@"longitude"];
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
        [self.mapView addAnnotation:annotation];
        NSLog(@"position: %@", position);
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"received response");
}

@end
