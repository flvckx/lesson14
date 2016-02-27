//
//  ViewController.m
//  itune
//
//  Created by Anton Lookin on 2/22/16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "ViewController.h"

@interface ViewController () <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSArray *itunesEntries;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end

@implementation ViewController

-(void) viewDidLoad {
	[super viewDidLoad];
	
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	configuration.HTTPMaximumConnectionsPerHost = 3;
	self.session = [NSURLSession sessionWithConfiguration:configuration
												 delegate:self
											delegateQueue:[NSOperationQueue mainQueue]];
	
	NSURLSessionDataTask *task = [self.session dataTaskWithURL:[NSURL URLWithString:@"https://itunes.apple.com/search?term=rock&country=US&entity=song"]
											 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
												 NSError *jsonError = nil;
												 NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data
																												 options:0ul
																												   error:&jsonError];
												 self.itunesEntries = jsonData[@"results"];
												 NSLog(@"%@", self.itunesEntries);
												 NSString *previewUrl = [self.itunesEntries lastObject][@"previewUrl"];
												 NSLog(@"%@", [previewUrl lastPathComponent]);
												 [self downloadItunesAudioPreview:previewUrl];
											 }];
	[task resume];
	
	NSString *applicationSupportPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportPath]) {
		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:&error];
	}
}

-(void) downloadItunesAudioPreview:(NSString *)previewUrl {
	NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:[NSURL URLWithString:previewUrl]];
	[task resume];
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
	NSLog(@"%@ of %@", [formatter stringFromByteCount:totalBytesWritten], [formatter stringFromByteCount:totalBytesExpectedToWrite]);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	NSString *destinationUrl = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
	destinationUrl = [destinationUrl stringByAppendingPathComponent:@"2.m4a"];
	
	if (![fileManager fileExistsAtPath:destinationUrl]) {
		[fileManager moveItemAtURL:location
							 toURL:[NSURL fileURLWithPath:destinationUrl]
							 error:&error];
	} else {
		[fileManager replaceItemAtURL:[NSURL fileURLWithPath:destinationUrl]
						withItemAtURL:location
					   backupItemName:@"ololo"
							  options:0ul
					 resultingItemURL:NULL
								error:&error];
	}
	NSLog(@"%@", error);
	
	AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] initWithNibName:nil bundle:nil];
	AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:destinationUrl]];
	playerViewController.player = player;
//	[self presentViewController:playerViewController
//					   animated:YES
//					 completion:NULL];
	
}

- (IBAction)playTheSong:(id)sender {
    NSString *destinationUrl = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
    destinationUrl = [destinationUrl stringByAppendingPathComponent:@"2.m4a"];
    
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] initWithNibName:nil bundle:nil];
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:destinationUrl]];
    playerViewController.player = player;
    	[self presentViewController:playerViewController
    					   animated:YES
    					 completion:NULL];
}

- (IBAction)downloadTheSong:(id)sender {
    
}

#pragma mark Table View data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;// [self.itunesEntries count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *artistName = [self.itunesEntries objectAtIndex:indexPath.row][@"artistName"];
    NSString *songInfo = [[artistName stringByAppendingFormat:@" – "] stringByAppendingString:[self.itunesEntries objectAtIndex:indexPath.row][@"trackName"]];
    CGSize textSize = [songInfo sizeWithFont:[UIFont systemFontOfSize: 14.0] forWidth:[tableView frame].size.width - 40.0 lineBreakMode:NSLineBreakByWordWrapping];
    return textSize.height < 44.0 ? 44.0 : textSize.height;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:
(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //NSLog(@"Section:%d Row:%d selected and its data is %@",
      //    indexPath.section,indexPath.row,cell.textLabel.text);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    //CDBasket *basket = self.fetchedResultsController.fetchedObjects[indexPath.row];
    NSString *artistName = [self.itunesEntries objectAtIndex:indexPath.row][@"artistName"];
    NSString *songInfo = [[artistName stringByAppendingFormat:@" – "] stringByAppendingString:[self.itunesEntries objectAtIndex:indexPath.row][@"trackName"]];
    [[cell textLabel] setNumberOfLines:0];
    [[cell textLabel] setLineBreakMode:NSLineBreakByWordWrapping];
    [[cell textLabel] setFont:[UIFont systemFontOfSize: 14.0]];
    cell.textLabel.text = songInfo;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (IBAction)playSong:(id)sender {
}
@end
