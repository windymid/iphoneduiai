//
//  AddWeiyuViewController.m
//  iphoneduiai
//
//  Created by Cloud Dai on 12-10-3.
//  Copyright (c) 2012年 duiai.com. All rights reserved.
//

#import "AddWeiyuViewController.h"
#import "LocationController.h"
#import <RestKit/RestKit.h>
#import <RestKit/JSONKit.h>
#import "Utils.h"
#import "CustomBarButtonItem.h"
#import <QuartzCore/QuartzCore.h>
#import "PageSmileDataSource.h"
#import "PageSmileView.h"
#import "SVProgressHUD.h"

@interface AddWeiyuViewController () <PageSmileDataSource>

@property (strong, nonatomic) NSArray *emontions;
@property (strong, nonatomic) NSData *imageData;
@property (assign, nonatomic) NSRange lastRange;
@property (nonatomic) CLLocationCoordinate2D curLocaiton;
@property (strong, nonatomic) NSString *curAddress, *photoId;

@end

@implementation AddWeiyuViewController

-(void)loadView
{
    [super loadView];
    
    avatarImageView = [[[AsyncImageView alloc] initWithFrame:CGRectMake(10, 21, 35, 35)] autorelease];
    [self.view addSubview:avatarImageView];
    
    UIImageView *iconImgView = [[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"weiyu_headbox.png"]]autorelease];
    iconImgView.frame = CGRectMake(10, 20, 36, 37);
    [self.view addSubview:iconImgView];
    
    contentView = [[[UIView alloc]initWithFrame:CGRectMake(55, 20, 255, 140)]autorelease];
    contentView.backgroundColor = [UIColor whiteColor];
    
    // 圆角
    contentView.layer.cornerRadius = 4.0f;
    contentView.layer.masksToBounds = YES;
    contentView.layer.borderWidth = 1.0f;
    contentView.layer.borderColor = [RGBCOLOR(217, 217, 217) CGColor];

    contentTextView = [[[UITextView alloc]initWithFrame:CGRectMake(2, 0, 255, 100)]autorelease];
    contentTextView.backgroundColor = [UIColor clearColor];
    contentTextView.font = [UIFont systemFontOfSize:14];
    contentTextView.delegate = self;
    [contentTextView becomeFirstResponder];

    toolView = [[[UIView alloc]initWithFrame:CGRectMake(0, 100, 255, 40)]autorelease];
    toolView.backgroundColor = RGBCOLOR(246, 246, 246);
    
    UILabel *lable1 = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 255, 1)] autorelease];
    lable1.backgroundColor = RGBCOLOR(224, 224, 244);
    UILabel *lable2 = [[[UILabel alloc] initWithFrame:CGRectMake(0, 1, 255, 1)] autorelease];
    lable2.backgroundColor = RGBCOLOR(255, 255, 255);
    [toolView addSubview:lable1];
    [toolView addSubview:lable2];
    [contentView addSubview:contentTextView];
    [contentView addSubview:toolView];
    
    UIButton *picButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [picButton setImage:[UIImage imageNamed:@"messages_toolbar_photobutton_background.png"] forState:UIControlStateNormal];
    [picButton setImage:[UIImage imageNamed:@"messages_toolbar_photobutton_background_highlighted"] forState:UIControlStateHighlighted ];
     picButton.frame = CGRectMake(20, 12, 24, 20);
    [picButton addTarget:self action:@selector(picSelect:)forControlEvents:UIControlEventTouchUpInside];
    [toolView addSubview:picButton];
    
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cameraButton setImage:[UIImage imageNamed:@"messages_toolbar_camerabutton_background"] forState:UIControlStateNormal];
    [cameraButton setImage:[UIImage imageNamed:@"messages_toolbar_camerabutton_background_highlighted"] forState:UIControlStateHighlighted ];
    cameraButton.frame = CGRectMake(85, 12, 26, 21);
    [cameraButton addTarget:self action:@selector(cameraSelect:)forControlEvents:UIControlEventTouchUpInside];
    [toolView addSubview:cameraButton];
    
    faceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [faceButton setImage:[UIImage imageNamed:@"messages_toolbar_emoticonbutton_background"] forState:UIControlStateNormal];
    [faceButton setImage:[UIImage imageNamed:@"messages_toolbar_emoticonbutton_background_highlighted"] forState:UIControlStateHighlighted ];
    faceButton.frame = CGRectMake(150, 12, 24, 24);
    [faceButton addTarget:self action:@selector(faceSelect:)forControlEvents:UIControlEventTouchUpInside];
    [toolView addSubview:faceButton];
    
    UIButton *locButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [locButton setImage:[UIImage imageNamed:@"messages_toolbar_locationbutton_background"] forState:UIControlStateNormal];
    [locButton setImage:[UIImage imageNamed:@"messages_toolbar_locationbutton_background_highlighted"] forState:UIControlStateHighlighted ];
    locButton.frame = CGRectMake(220, 12, 18, 24);
    [locButton addTarget:self action:@selector(locSelect:)forControlEvents:UIControlEventTouchUpInside];
    [toolView addSubview:locButton];
    
    contentLabel = [[[UILabel alloc] initWithFrame:CGRectMake(13, 5, 244, 50)]autorelease];
    contentLabel.textColor = RGBCOLOR(172, 172, 172);
    contentLabel.backgroundColor = [UIColor clearColor];
    contentLabel.font=[UIFont systemFontOfSize:16];
    contentLabel.text=@"晒晒现在的心情,发布一张自己的美图,用语音表达一下自己的心声.";
    contentLabel.lineBreakMode = UILineBreakModeWordWrap;
    contentLabel.numberOfLines = 0;
    
    [contentLabel sizeToFit];
    [contentTextView addSubview:contentLabel];
    
    [self.view addSubview:contentView];
    state = YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_emontions release];
    [_imageData release];
    [_curAddress release];
    [super dealloc];
}

- (void)setCurAddress:(NSString *)curAddress
{
    if (![_curAddress isEqualToString:curAddress]) {
        _curAddress = [curAddress retain];
        
        UIFont *font = [UIFont systemFontOfSize:12.0f];
        CGSize size = [curAddress sizeWithFont:font];
        
        UILabel *lbl = (UILabel*)[contentTextView viewWithTag:99];
        if (lbl == nil) {
            lbl = [[[UILabel alloc] initWithFrame:CGRectMake(5, contentTextView.frame.size.height - 16, MIN(size.width, 245), 16)] autorelease];
            lbl.backgroundColor = [UIColor lightGrayColor];
            lbl.font = font;
            lbl.tag = 99;
             [contentTextView addSubview:lbl];
        }
  
        lbl.text = curAddress;
//        [lbl sizeToFit];
        
    }
}

- (NSArray *)emontions
{
    if (_emontions == nil) {
        // Custom initialization
        NSString *myFile = [[NSBundle mainBundle] pathForResource:@"em" ofType:@"plist"];
        _emontions = [[NSArray alloc] initWithContentsOfFile:myFile];
        
    }
    
    return _emontions;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
    self.navigationItem.title = @"发表新微语";
    self.navigationItem.leftBarButtonItem = [[[CustomBarButtonItem alloc] initBackBarButtonWithTitle:@"返回"
                                                                                              target:self
                                                                                              action:@selector(backAction)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[CustomBarButtonItem alloc] initRightBarButtonWithTitle:@"发表"
                                                                                                target:self
                                                                                                action:@selector(sendAction)] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    PageSmileView *pageSmileView = [[PageSmileView alloc] initWithFrame: CGRectMake(0, 200, 320, 216)
                                                         withDataSource: self];

//    pageSmileView.backgroundColor = [UIColor redColor];
    [self.view addSubview:pageSmileView];
    [pageSmileView release];
    
}

- (void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)sendAction
{
    NSLog(@"sending...");
    [self sendWeiyuRequest];
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

#pragma mark - personal method

- (IBAction)picSelect:(id)sender {
    UIImagePickerController* picker = [[UIImagePickerController alloc]init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing=YES;
    picker.delegate =self;
    
    [self presentModalViewController:picker animated: YES];
    [picker release];
}

-(IBAction)cameraSelect:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController* picker = [[UIImagePickerController alloc]init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.delegate =self;
        
        [self presentModalViewController:picker animated: YES];
        [picker release];
    }

}

-(IBAction)faceSelect:(id)sender
{
    
    if (state) {
        [contentTextView resignFirstResponder];
        [faceButton setImage:[UIImage  imageNamed:@"messages_toolbar_keyboardbutton_background.png"] forState:UIControlStateNormal];
        [faceButton setImage:[UIImage imageNamed:@"messages_toolbar_keyboardbutton_background_highlighted.png"] forState:UIControlStateHighlighted ];
        state = NO;
    }else
    {
        [contentTextView becomeFirstResponder];
        [faceButton setImage:[UIImage  imageNamed:@"messages_toolbar_emoticonbutton_background"] forState:UIControlStateNormal];
        state = YES;

    }
}

-(IBAction)locSelect:(id)sender
{
    if ([LocationController sharedInstance].allow) {
        [SVProgressHUD show];
        [[[LocationController sharedInstance] locationManager] startUpdatingLocation];
        int64_t delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.curLocaiton = [LocationController sharedInstance].location.coordinate;
            [[[LocationController sharedInstance] locationManager] stopUpdatingLocation];
            
            NSDictionary *p = @{@"latlng": [NSString stringWithFormat:@"%f,%f", self.curLocaiton.latitude, self.curLocaiton.longitude],
            @"sensor": @"true", @"language":@"zh-CN"};
            
            [[RKClient sharedClient] get:[@"http://maps.googleapis.com/maps/api/geocode/json" stringByAppendingQueryParameters:p]
                              usingBlock:^(RKRequest *request){
                                  [request setOnDidFailLoadWithError:^(NSError *error){
                                      NSLog(@"get address %@", [error description]);
                                      [SVProgressHUD dismiss];
                                  }];
                                  
                                  [request setOnDidLoadResponse:^(RKResponse *response){
                                      if (response.isOK && response.isJSON) {
                                          NSDictionary *geo = [[response bodyAsString] objectFromJSONString];
//                                          NSLog(@"geo: %@", geo);
                                          [SVProgressHUD dismiss];
                                          for (NSDictionary *g in geo[@"results"]) {
                                              if ([g[@"types"] containsObject:@"street_address"]) {
                                                   NSLog(@"name: %@", g[@"formatted_address"]);
                                                  self.curAddress = g[@"formatted_address"];
                                                  break;
                                              }
                                          }
                                      }
                                  }];
                              }];
            
        });
    } else{
        [SVProgressHUD showErrorWithStatus:@"定位未开启"];
    }
}

#pragma mark –  Camera View Delegate Methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    /*添加处理选中图像代码*/
    NSData *data = UIImagePNGRepresentation([info objectForKey:UIImagePickerControllerEditedImage]);
    
    [Utils uploadImage:data type:@"vphoto" block:^(NSDictionary *info){
        if (info) {
            NSLog(@"photo info: %@", info);
        }
    }];
    [picker dismissModalViewControllerAnimated:YES];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
   [picker dismissModalViewControllerAnimated:YES];
}

#define UITextFieldDelegate
-(void)textViewDidChange:(UITextView *)textView
{
    if (contentTextView.text.length > 0)
        contentLabel.hidden = YES;
    else
        contentLabel.hidden = NO;
}

#pragma mark - key board notice
-(void)keyboardWillShow:(NSNotification*)note
{
    [UIView animateWithDuration:0.3 animations:^(void)
     {
         CGRect r = CGRectZero;
         [[note.userInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"] getValue:&r];
         CGRect rect = contentView.frame;
         rect.size.height = 460 -70-r.size.height;
         CGRect rect2 = toolView.frame;
         rect2.origin.y = rect.size.height-40;
         CGRect rect3 = contentTextView.frame;
         rect3.size.height = 460 -114-r.size.height;
         contentView.frame = rect;
         toolView.frame = rect2;
         contentTextView.frame = rect3;
         
         UILabel *lbl = (UILabel*)[contentTextView viewWithTag:99];
         if (lbl) {
             CGRect rect4 = lbl.frame;
             rect4.origin.y = rect3.size.height - lbl.frame.size.height;
             lbl.frame = rect4;
         }

        }];
    
}

-(void)keyboardWillHide:(NSNotification*)note
{
    [UIView animateWithDuration:0.3 animations:^(void)
     {
//         CGRect r = CGRectZero;
//         [[note.userInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"] getValue:&r];
         CGRect rect = contentView.frame;
         rect.size.height = 174;
         CGRect rect2 = toolView.frame;
         rect2.origin.y = rect.size.height-40;
         CGRect rect3 = contentTextView.frame;
         rect3.size.height = 135;
         contentView.frame = rect;
         toolView.frame = rect2;
         contentTextView.frame = rect3;
         
         UILabel *lbl = (UILabel*)[contentTextView viewWithTag:99];
         if (lbl) {
             CGRect rect4 = lbl.frame;
             rect4.origin.y = rect3.size.height - lbl.frame.size.height;
             lbl.frame = rect4;
         }
         
     }];
    
}

- (void)sendWeiyuRequest
{
    NSMutableDictionary *dParams = [Utils queryParams];
    [[RKClient sharedClient] post:[@"/v/send.api" stringByAppendingQueryParameters:dParams] usingBlock:^(RKRequest *request){
        
        NSMutableDictionary *pd = [NSMutableDictionary dictionary];
        [pd setObject:[[UIDevice currentDevice] model] forKey:@"vfrom"];
        [pd setObject:@"true" forKey:@"submitupdate"];
        [pd setObject:contentTextView.text forKey:@"content"];
        
        if (self.curAddress) {
            [pd setObject:self.curAddress forKey:@"address"];
        }
        
        if (abs(self.curLocaiton.latitude - 0.0) > 0.001) {
            [pd setObject:[NSNumber numberWithDouble:self.curLocaiton.latitude] forKey:@"wei"];
            [pd setObject:[NSNumber numberWithDouble:self.curLocaiton.longitude] forKey:@"jin"];
        }
        
        if (self.photoId) {
            [pd setObject:self.photoId forKey:@"photoid"];
        }
        
        request.params = [RKParams paramsWithDictionary:pd];
        
        [request setOnDidFailLoadWithError:^(NSError *error){
            NSLog(@"send weiyu: %@", [error description]);
        }];
        
        [request setOnDidLoadResponse:^(RKResponse *response){
            NSLog(@"send weiyu: %@", [response bodyAsString]);
            if (response.isOK && response.isJSON) {
                NSDictionary *data = [[response bodyAsString] objectFromJSONString];
                NSLog(@"weiyu data: %@", data);
            }
        }];
        
    }];
}

#pragma mark - emontions

- (int)numberOfPages
{
	return (self.emontions.count / 28) + (self.emontions.count % 28 > 0 ? 1 : 0);
}

- (UIView *)viewAtIndex:(int)index
{
    
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)] autorelease];
    for (int i=index*28; i < MIN(index*28+28, self.emontions.count); i++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        
        NSInteger column = i%7;
        NSInteger row = (i%28)/7;
        
        btn.frame = CGRectMake(16 + 13 * column + 30*column, 16*(row+1) + 30*row, 30, 30);
        
        [btn setImage:[UIImage imageNamed:[[self.emontions objectAtIndex:i] objectForKey:@"gif"]]
             forState:UIControlStateNormal];
        btn.tag = i;
        [btn addTarget:self action:@selector(emontionAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [view addSubview:btn];
        
    }
    
    return view;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    self.lastRange = textView.selectedRange;
    return YES;
}

# pragma mark actions
-(void)emontionAction:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSDictionary *emontion = [self.emontions objectAtIndex:btn.tag];
    NSMutableString *content = [NSMutableString stringWithString:contentTextView.text];
    NSRange oldOne = self.lastRange;
    if (self.lastRange.location >= content.length) {
        
        self.lastRange = NSMakeRange(content.length, 0);
    }
    [content replaceCharactersInRange:self.lastRange withString:[emontion objectForKey:@"chs"]];
    contentTextView.text = content;
    contentTextView.selectedRange = NSMakeRange(oldOne.location + [[emontion objectForKey:@"chs"] length], 0);
    self.lastRange = NSMakeRange(oldOne.location + [[emontion objectForKey:@"chs"] length], 0);
    [self textViewDidChange:contentTextView];
}

@end