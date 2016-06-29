# UploadHeadImage
上传头像

博客地址：http://blog.csdn.net/CodingFire/article/details/51781194

上传头像这一步几乎在所有的应用中都会用到，但是博主发现即使是那些工作一年甚至两年的开发者依然会问这个问题，更别提那些初学者了，虽然网上能找到好多种上传的方法，但是都存在不同程度的误差，要么是不够详细，要么是运行出错，所以博主今天就把自己常用的一种方法拿出来给大家分享一下。 
这里写图片描述

![image](https://github.com/codeliu6572/UploadHeadImage/blob/master/UploadHeadImage/1.gif)

首先说明下：博主上传采用的是AF3.0，因为博主去掉了项目中的接口，所以，这个Demo中是不能上传成功的，但是效果会有，看官们只需要把自己的url放进去就可以实现上传了。具体的跟着博主慢慢往下看：

第一步：触发操作


        //根据警告知道这个对象在iOS8.3被废弃了,只是依然可以用，在下篇博客中，会针对废弃后的提供的新方法做介绍和使用
          UIActionSheet * actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take photos", @"Select picture in phone album",nil];
          actionSheet.delegate=self;
          actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
          [actionSheet showInView:self.view];


第二步：选择相册或直接拍照


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


第三步：选择一张图片后


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
    
注释比较详细，应该都能看懂吧。在这一步直接就上传成功了。


第四步：矫正图片方向，这一步和第三步息息相关，在第三部中调用


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
图片矫正位置，虽然大家不熟悉上面的代码，但是看代码也能看看明白是在做什么，目前是为了实现功能，不必深究，想了解的请自行查找资料。


第五步：点击取消后，返回原来的界面

#pragma mark - 取消图片选择


      - (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
      {
      
          NSLog(@"您取消了选择图片");
          [picker dismissViewControllerAnimated:YES completion:nil];
      
      }

以上五步就完成了头像的上传。


这里再说一个小知识，也是博主早前在把图片变为圆时发现的，layer.cornerRadius，怎么设置这个值才能让图片为圆呢？
一般很多人都会一个个试，直到无限接近圆，这里博主告诉大家一个小方法，一般来说头像的图片都是正方形，即使是矩形也要截取的
，这里以正方形为例，只需要设置cornerRadius为正方形长的一半，就好像内切圆的半径一样，矩形的话类似，设置短边的一半即可。


