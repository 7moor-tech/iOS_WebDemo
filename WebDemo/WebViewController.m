 //
//  WebViewController.m
//  WebDemo
//
//  Created by ZCZ on 2021/12/6.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>
#import "Masonry.h"
#import <Photos/Photos.h>
#import <CoreServices/CoreServices.h>

#define QM_kStatusBarHeight  [UIApplication sharedApplication].statusBarFrame.size.height
#define kStatusBarAndNavHeight (QM_kStatusBarHeight + 44.0)
#define QM_kScreenWidth  [[UIScreen mainScreen] bounds].size.width
#define QM_kScreenHeight  [[UIScreen mainScreen] bounds].size.height
@interface WebViewController () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) WKWebView *rootWeb;


@end

@implementation WebViewController

- (void)dealloc {
    [self.rootWeb removeObserver:self forKeyPath:@"title"];
    [self.rootWeb.configuration.userContentController removeScriptMessageHandlerForName:@"moorJsCallBack"];
    NSLog(@"注销了");

}

- (void)viewDidLoad {
    [super viewDidLoad];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];

    /**注册 js 回调 样例*/ //功能未上线待定
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:@"moorJsCallBack"];
//    [userContentController addScriptMessageHandler:self name:@"其他名称"];
    /**/

    config.userContentController = userContentController;

    WKWebView *wbview = [[WKWebView alloc] initWithFrame:CGRectMake(0, kStatusBarAndNavHeight, QM_kScreenWidth, QM_kScreenHeight-kStatusBarAndNavHeight) configuration:config];
    wbview.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    wbview.navigationDelegate = self;
    wbview.UIDelegate = self;
    [wbview addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.view addSubview:wbview];
//    [wbview mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(self.view);
//    }];

    NSString *urlStr = [self.urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:urlStr];

    NSLog(@"url = %@",url);

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [wbview loadRequest:request];
    self.rootWeb = wbview;
    
    typedef void(^Myblock)(NSString *);
    
    __weak typeof(self)weakSelf = self;
    Myblock block = ^ (NSString * string){
        __strong typeof(weakSelf)sSelf = weakSelf;
        NSLog(@"_____%@",sSelf);
        [sSelf pring];
    };
            
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        block(@"1234");
    });
}

- (void)pring {
    NSLog(@"打印了");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.navigationController setNavigationBarHidden:YES animated:true];
//    [self.rootWeb.configuration.userContentController addScriptMessageHandler:self name:@"moorJsCallBack"];

}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {

}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"title"]) {
        NSString *title = change[NSKeyValueChangeNewKey] ? : @"";
        self.navigationItem.title = title;
    }
}

//WKScriptMessageHandler协议方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    // message.body 即为JS向OC传的值
    id data = message.body;
    NSLog(@"=== %@", data);
    
    
    NSString *body = @"";
    if ([data isKindOfClass:NSDictionary.class]) {
        body = [(NSDictionary *)data valueForKey:@"body"];
    }
    
    if ([message.name isEqualToString:@"moorJsCallBack"]) {
        if ([body isEqualToString:@"onCloseEvent"]) {
            // 功能 可能未上线
            NSLog(@"js-事件 = %@",body);
        } else if ([body hasPrefix:@"checkPermission"]) {
            // js 调用检查访问图片权限
            NSString *type = [(NSDictionary *)data valueForKey:@"type"];
            [self checkPermission:type];
        } else if ([body hasPrefix:@"onDownloadVideo"]) {
            // 视频下载
            NSString *videoUrl = [(NSDictionary *)data valueForKey:@"url"];
            NSLog(@"videoUrl%@",videoUrl);
            [self showMessage:videoUrl showTime:3];
        }
    }

    if ([message.name isEqualToString:@"其他shili名称"]) {
    }
}

/**
 H5 上传图片检查访问权限
 type参数为js回调参数  image图片访问权 file 文件上传
 */
- (void)checkPermission:(NSString *)type {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            switch (status) {
                    
                case PHAuthorizationStatusLimited:
                case PHAuthorizationStatusAuthorized: {
                    NSString *js = [NSString stringWithFormat:@"initAllUpload('%@')", type];
                    [self.rootWeb evaluateJavaScript:js completionHandler:^(id _Nullable dict, NSError * _Nullable error) {
                        NSLog(@"ssssss");
                    }];
                }
                    break;
                default:
                {
                    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"提醒" message: @"请在iPhone的“隐私-设置”选项中，允许app访问您的相册" preferredStyle: UIAlertControllerStyleAlert];
                    
                    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if (UIApplicationOpenSettingsURLString != NULL) {
                            NSURL *appURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                            [UIApplication.sharedApplication openURL:appURL options:@{} completionHandler:nil];
                        }
                    }];
                    
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:action];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                }
                    
                    break;
            }
        });
    }];

}

//
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
        
        //跳转浏览器
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:nil];
    }
        
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:true completion:nil];
}

- (void)showMessage:(NSString *)message showTime:(NSInteger)time {
    __block NSInteger times = time;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIWindow * window = [UIApplication sharedApplication].keyWindow;
        UIView *showview =  [[UIView alloc]init];
        showview.backgroundColor = [UIColor blackColor];
        showview.alpha = 0.8;
        showview.frame = CGRectMake(1, 1, 1, 1);
        showview.alpha = 1.0f;
        showview.layer.cornerRadius = 5.0f;
        showview.layer.masksToBounds = YES;
        [window addSubview:showview];
        
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectZero;
        label.textColor = [UIColor whiteColor];
        label.textAlignment = 1;
        label.numberOfLines = 0;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:14];
        [showview addSubview:label];
        label.text = message;
        CGSize LabelSize = [self calculateText:message fontSize:14 maxWidth:QM_kScreenWidth - 100 maxHeight:0];
        label.frame = CGRectMake(10, 5, LabelSize.width, LabelSize.height);
        showview.frame = CGRectMake((QM_kScreenWidth - LabelSize.width - 20)/2, QM_kScreenHeight - label.frame.size.height - 180, LabelSize.width + 20, LabelSize.height + 10);
        times = times <= 0 ? 3 : times;
        [UIView animateWithDuration:times animations:^{
            showview.alpha = 0;
        } completion:^(BOOL finished) {
            [showview removeFromSuperview];
        }];
    });
}

- (CGSize)calculateText:(NSString *)text fontSize:(NSInteger)fontSize maxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight {
    NSDictionary *attribute = @{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]};
    CGSize maxSize = CGSizeMake(maxWidth, maxHeight);
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGRect labelRect = [text boundingRectWithSize:maxSize options: options attributes:attribute context:nil];
    return labelRect.size;
}


//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
//    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
//    if([mediaType isEqualToString:(NSString *)kUTTypeImage]){
//        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
//        NSString *imageName = [[info objectForKey:UIImagePickerControllerImageURL] lastPathComponent];
//        if (!imageName) {
//            imageName = [NSUUID.new.UUIDString stringByAppendingString:@".jpeg"];
//        }
////        NSString *locolPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
////
////        NSString *locolFile = [locolPath stringByAppendingPathComponent:@"QMPict"];
////        NSFileManager *mgr = [NSFileManager defaultManager];
////        if (![mgr fileExistsAtPath:locolFile]) {
////            [mgr createDirectoryAtPath:locolFile withIntermediateDirectories:true attributes:nil error:nil];
////        }
//
//        NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
//         NSString *baseString = [imageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
//        UIPasteboard.generalPasteboard.string = baseString;
//        NSLog(@"%@",baseString);
////        NSData *datass = [[NSData alloc] initWithBase64EncodedString:baseString options:NSDataBase64DecodingIgnoreUnknownCharacters];
////        UIImage *img = [[UIImage alloc] initWithData:datass];
//
//
////        NSString *byteString = [self hexStringFromString:imageData];
////        NSString *imageFilePath = [locolFile stringByAppendingPathComponent:imageName];
////        BOOL rel = [imageData writeToFile:imageFilePath atomically:true];
////        if (rel) {
////        NSString *str = [[NSString alloc] initWithData:imageData encoding:NSUTF8StringEncoding];
//            NSString *js = [NSString stringWithFormat:@"addImage('%@','%@')",baseString, imageName];
//            [self.rootWeb evaluateJavaScript:js completionHandler:^(id _Nullable dict, NSError * _Nullable error) {
//                NSLog(@"ssssss");
//            }];
//
////        }
//    }
//
//
//    [picker dismissViewControllerAnimated:YES completion:nil];
//}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
