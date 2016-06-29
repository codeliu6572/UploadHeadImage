//
//  ViewController.m
//  UploadHeadImage
//
//  Created by 刘浩浩 on 16/6/29.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
@interface ViewController ()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    UIImageView *headImageView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    headImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
    headImageView.center = self.view.center;
    UIImage *headImage = [UIImage imageNamed:@"fire.jpg"];
    headImageView.image = headImage;
    headImageView.userInteractionEnabled = YES;
    headImageView.layer.cornerRadius = 100;
    headImageView.layer.masksToBounds = YES;
    [self.view addSubview:headImageView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction)];
    [headImageView addGestureRecognizer:tap];
    
}
- (void)tapAction
{
    //根据警告知道这个对象在iOS8.3被废弃了,只是依然可以用，在下篇博客中，会针对废弃后的提供的新方法做介绍和使用
    UIActionSheet * actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take photos", @"Select picture in phone album",nil];
    actionSheet.delegate=self;
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];

}

#pragma mark - 选择手机拍照上传或者手机相册上传
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==1) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        //设置选择后的图片可被编辑
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    }
    if (buttonIndex==0) {
        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
        {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            //设置拍照后的图片可被编辑
            picker.allowsEditing = YES;
            picker.sourceType = sourceType;
            [self presentViewController:picker animated:YES completion:nil];
            
        }else
        {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"警告" message:@"请使用真机进行测试" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
            NSLog(@"模拟其中无法打开照相机,请在真机中使用");
        }
    }
}
#pragma mark - 当在相册选择一张图片后进入这里
-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info

{
    
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    
    //当选择的类型是图片
    if ([type isEqualToString:@"public.image"])
    {

        //先把图片转成NSData
        UIImage* image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        //调整图片方向，防止上传后图片方向不对
        [self fixOrientation:image];
        //压缩图片
        NSData *data = UIImageJPEGRepresentation(image, 0.5);
        
        //图片保存的路径
        //这里将图片放在沙盒的documents文件夹中
        NSString * DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSLog(@"图片储存路径：%@",DocumentsPath);
        //文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        //把刚刚图片转换的data对象拷贝至沙盒中 并保存为image.png
        [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:@"/image.png"] contents:data attributes:nil];
        
        //得到选择后沙盒中图片的完整路径
        NSString *filePath = [[NSString alloc]initWithFormat:@"%@%@",DocumentsPath,@"/image.png"];
        NSLog(@"................%@",filePath);

        
        
        //表单请求，上传文件
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];//请求
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];//响应
        manager.requestSerializer.timeoutInterval = 8;
        /*
         *这里需要特别注意一下，因为没有放具体的上传地址，所以这个上传方式是不成功的，但是方法是没错的，需要替换成正确的上传地址
         */
        [manager POST:[NSString stringWithFormat:@"url"] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            //将图片以表单形式上传
            NSData *data1=[NSData dataWithContentsOfFile:filePath];
            [formData appendPartWithFileData:data1 name:@"headPicFile" fileName:@"headPicFile" mimeType:@"image/png"];
            
            //关闭相册界面
            [picker dismissViewControllerAnimated:YES completion:nil];
        }progress:^(NSProgress *uploadProgress){
            
            
        }success:^(NSURLSessionDataTask *task, id responseObject) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"dic:%@",dic);
            //成功后替换新头像
            NSData *data1=[NSData dataWithContentsOfFile:filePath];
            headImageView.image = [UIImage imageWithData:data1];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"%@",[error description]);
            NSLog(@"%@",error);
            //因为没有有效地址，所以肯定是上传失败的，为了表现出效果，此处也替换为新头像
            NSData *data1=[NSData dataWithContentsOfFile:filePath];
            headImageView.image = [UIImage imageWithData:data1];
        }];
        
    }
    
    
}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#pragma mark - 取消图片选择
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
    NSLog(@"您取消了选择图片");
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
