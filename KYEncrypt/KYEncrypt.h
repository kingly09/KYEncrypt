//
//  KYEncrypt.h
//  KYEncryptDemo
//
//  Created by kingly on 2017/12/26.
//  Copyright © 2017年 KYEncrypt Software (https://github.com/kingly09/KYEncrypt ) by kingly inc.

//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KYEncrypt : NSObject

@property (nonatomic,copy) NSString *sKey; //16位的字符串
@property (nonatomic,copy) NSString *sIv;  //16位的字符串
/**
 * @breif 获取实例
 */
+ (KYEncrypt *) sharedInstance;

/**
 Base64 加密字符串

 @param inputString 需要加密的字符串
 @return 返回Base64 加密字符串
 */
- (NSString *)encodeBase64String:(NSString *)inputString;

/**
 Base64 解密字符串
 
 @param inputString Base64加密过的字符串
 @return 解密Base64 加密过的字符串
 */
- (NSString *)decodeBase64String:(NSString *)inputString;

/*＊
 *  AES128 + CBC + No Padding
 *
 *  @param data 要加密的原始数据
 *
 *  @return  加密后数据
 */
- (NSData*) encryptData:(NSData *)data;
/*＊
 *  AES128 + CBC + No Padding
 *
 *  @param data 要解密的原始数据
 *
 *  @return  解密后数据
 */
- (NSData*) decryptData:(NSData *)data;

/*＊
 *  AES128 + ECB + PKCS7
 *
 *  @param data 要加密的原始数据
 *
 *  @return  加密后数据
 */
- (NSData*)encryptECBData:(NSData*)data;

/*＊
 *  AES128 + ECB + PKCS7
 *
 *  @param data 要解密的原始数据
 *
 *  @return  解密后数据
 */
- (NSData*)decryptECBData:(NSData*)data;
/*＊
 *  AES256 + ECB + PKCS7
 *
 *  @param data 要加密的原始数据
 *
 *  @return  加密后数据
 */
- (NSData *)AES256EncryptWithData:(NSData* )data;
/*＊
 *  AES256 + ECB + PKCS7
 *
 *  @param data 要解密的原始数据
 *
 *  @return  解密后数据
 */
- (NSData *)AES256DecryptWithData:(NSData* )data;

/**
 使用 AES256 + ECB + PKCS7加密字符串
 
 @param str 需要加密的字符串
 @param key 密钥
 @return 返回加密的字符串
 */
- (NSString *)AES256EncryptWithString:(NSString *)str withKey:(NSString *)key;

/**
 使用 AES256 + ECB + PKCS7 解密字符串
 
 @param str 需要加密的字符串
 @param key 密钥
 @return 返回加密的字符串
 */
- (NSString *)AES256DecryptWithString:(NSString *)str withKey:(NSString *)key;

@end
