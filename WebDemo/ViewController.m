//
//  ViewController.m
//  WebDemo
//
//  Created by ZCZ on 2021/11/2.
//

#import "ViewController.h"
#import "Masonry.h"
#import "WebViewController.h"

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UILabel *tipLab = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, 60)];
    tipLab.text = @"请输入地址:";
    if (@available(iOS 13.0, *)) {
        tipLab.textColor = [UIColor labelColor];
    } else {
        // Fallback on earlier versions
    }
    [self.view addSubview:tipLab];
    [tipLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(10);
        make.top.mas_equalTo(70);
        make.height.mas_equalTo(20);
    }];

    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, 200, 60)];
    textView.tag = 200;
    textView.text = @"";
    
    textView.layer.borderWidth = 1;
    textView.layer.cornerRadius = 6;
    [self.view addSubview:textView];
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(10);
        make.right.equalTo(self.view).offset(-10);
        make.top.mas_equalTo(100);
        make.height.mas_equalTo(80);
    }];
    
//    NSString *url = [NSUserDefaults.standardUserDefaults stringForKey:@"qm_web_last_url"];
//    if (url.length > 0) {
//        textView.text = url;
//    }
   
    UIButton *sureButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [sureButton setTitle:@"确 定" forState:UIControlStateNormal];
    [sureButton addTarget:self action:@selector(pushWebAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sureButton];
    
    [sureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(textView.mas_bottom).offset(20);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(80);
    }];
}

- (void)pushWebAction {
    UITextView *textView = [(UITextView *)self.view viewWithTag:200];
    NSString *string = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    WebViewController *webVC = [WebViewController new];
    webVC.urlString = string;
    [NSUserDefaults.standardUserDefaults setValue:string forKey:@"qm_web_last_url"];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    [self.navigationController pushViewController:webVC animated:true];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.navigationController setNavigationBarHidden:YES animated:true];
}


@end
