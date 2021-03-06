//
//  KYEncrypt.m
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

#import "KYEncrypt.h"
#import "GTMBase64.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#define FBENCRYPT_ALGORITHM     kCCAlgorithmAES128
#define FBENCRYPT_BLOCK_SIZE    kCCBlockSizeAES128
#define FBENCRYPT_KEY_SIZE      kCCKeySizeAES128


@implementation KYEncrypt

static KYEncrypt *sharedObj = nil; //第一步：静态实例，并初始化。
/**
 * @brief 返回实例
 */
+ (KYEncrypt *) sharedInstance  //第二步：实例构造检查静态实例是否为nil
{
    @synchronized (self)
    {
        if (sharedObj == nil)
        {
            sharedObj = [[self alloc] init];
        }
    }
    return sharedObj;
}
+ (id) allocWithZone:(NSZone *)zone //第三步：重写allocWithZone方法
{
    @synchronized (self) {
        if (sharedObj == nil) {
            sharedObj = [super allocWithZone:zone];
            return sharedObj;
        }
    }
    return nil;
}
- (id) copyWithZone:(NSZone *)zone //第四步
{
    return self;
}


/**
 Base64 加密字符串
 
 @param inputString 需要加密的字符串
 @return 返回Base64 加密字符串
 */
- (NSString *)encodeBase64String:(NSString *)inputString {
    
    NSData *data = [inputString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    data = [GTMBase64 encodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return base64String;
}

/**
 Base64 解密字符串
 
 @param inputString Base64加密过的字符串
 @return 解密Base64 加密过的字符串
 */
- (NSString *)decodeBase64String:(NSString *)inputString {
    
    NSData *data = [inputString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    data = [GTMBase64 decodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return base64String;
}

/*＊
 *  AES128 + CBC + No Padding
 *
 *  @param data 要加密的原始数据
 *
 *  @return  加密后数据
 */
- (NSData*) encryptData:(NSData *)data{
    
    if (![self checkInfo]) {
        return data;
    }
    char keyPtr[kCCKeySizeAES128+1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [_sKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128+1];
    memset(ivPtr, 0, sizeof(ivPtr));
    [_sIv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    NSUInteger diff = kCCKeySizeAES128 - (dataLength % kCCKeySizeAES128);
    NSUInteger newSize = 0;
    
    if(diff > 0)
    {
        newSize = dataLength + diff;
    }
    
    char dataPtr[newSize];
    memcpy(dataPtr, [data bytes], [data length]);
    for(NSUInteger i = 0; i < diff; i++)
    {
        dataPtr[i + dataLength] = 0x00;
    }
    
    size_t bufferSize = newSize + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    memset(buffer, 0, bufferSize);
    
    size_t numBytesCrypted = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          0x0000,               //No padding
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          ivPtr,
                                          dataPtr,
                                          sizeof(dataPtr),
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
        return resultData;
    }
    free(buffer);
    return nil;
    
}
/*＊
 *  AES128 + CBC + No Padding
 *
 *  @param data 要解密的原始数据
 *
 *  @return  解密后数据
 */
- (NSData*) decryptData:(NSData *)data{
    
    if (![self checkInfo]) {
        return data;
    }
    
    char keyPtr[kCCKeySizeAES128 + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [_sKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128 + 1];
    memset(ivPtr, 0, sizeof(ivPtr));
    [_sIv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          0x0000,       //No padding
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          ivPtr,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
        return resultData;
    }
    free(buffer);
    return nil;
    
}

/**
 * 检查加密合法性
 */
-(BOOL) checkInfo{
    
    if (![self checkKey]) {
        return NO;
    }
    
    if (![self checkivKey]) {
        return NO;
    }
    return YES;
}
/**
 * 密钥长度是否合法
 */
-(BOOL) checkKey{
    
    BOOL succ = YES;
    NSData* keyData = [_sKey dataUsingEncoding:NSUTF8StringEncoding];
    if (keyData.length != 16) {
        NSLog(@"密钥长度不是16字节，请重新设置!");
        succ = NO;
    }
    return succ;
}

/**
 * 检查初始向量是否合法
 */
-(BOOL) checkivKey{
    
    BOOL succ = YES;
    NSData* ivData = [_sIv dataUsingEncoding:NSUTF8StringEncoding];
    if (ivData.length != 16) {
        NSLog(@"iv向量不是16字节，请重新设置!");
        succ = NO;
    }
    return succ;
}

/*＊
 *  AES128 + ECB + PKCS7
 *
 *  @param data 要加密的原始数据
 *
 *  @return  加密后数据
 */
- (NSData*)encryptECBData:(NSData* )data{
    
    if (![self checkKey]) {
        return data;
    }
    
    NSData* result = nil;
    NSData *key = [_sKey dataUsingEncoding:NSASCIIStringEncoding];
    // setup key
    unsigned char cKey[FBENCRYPT_KEY_SIZE];
    bzero(cKey, sizeof(cKey));
    [key getBytes:cKey length:FBENCRYPT_KEY_SIZE];
    
    // setup output buffer
    size_t bufferSize = [data length] + FBENCRYPT_BLOCK_SIZE;
    void *buffer = malloc(bufferSize);
    
    // do encrypt
    size_t encryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          FBENCRYPT_ALGORITHM,
                                          kCCOptionECBMode|kCCOptionPKCS7Padding,
                                          cKey,
                                          FBENCRYPT_KEY_SIZE,
                                          nil,
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
                                          &encryptedSize);
    if (cryptStatus == kCCSuccess) {
        result = [NSData dataWithBytesNoCopy:buffer length:encryptedSize];
    } else {
        free(buffer);
        NSLog(@"[ERROR] failed to encrypt|CCCryptoStatus: %d", cryptStatus);
    }
    
    return result;
    
    
}

/*＊
 *  AES128 + ECB + PKCS7
 *
 *  @param data 要解密的原始数据
 *
 *  @return  解密后数据
 */
- (NSData*)decryptECBData:(NSData* )data{
    if (![self checkKey]) {
        return data;
    }
    NSData* result = nil;
    NSData *key = [_sKey dataUsingEncoding:NSASCIIStringEncoding];
    // setup key
    unsigned char cKey[FBENCRYPT_KEY_SIZE];
    bzero(cKey, sizeof(cKey));
    [key getBytes:cKey length:FBENCRYPT_KEY_SIZE];
    
    // setup output buffer
    size_t bufferSize = [data length] + FBENCRYPT_BLOCK_SIZE;
    void *buffer = malloc(bufferSize);
    
    // do decrypt
    size_t decryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          FBENCRYPT_ALGORITHM,
                                          kCCOptionECBMode|kCCOptionPKCS7Padding,
                                          cKey,
                                          FBENCRYPT_KEY_SIZE,
                                          nil,
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
                                          &decryptedSize);
    
    if (cryptStatus == kCCSuccess) {
        result = [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
    } else {
        free(buffer);
        NSLog(@"[ERROR] failed to decrypt| CCCryptoStatus: %d", cryptStatus);
    }
    
    return result;
}
/*＊
 *  AES256 + ECB + PKCS7
 *
 *  @param data 要加密的原始数据
 *
 *  @return  加密后数据
 */
- (NSData *)AES256EncryptWithData:(NSData* )data {
    // 'key' 必须是32字节 AES256,不足的用零补充
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr)); // 用零填充（填充）
    // fetch key data
    [_sKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    //块加密，输出的大小总是小于或等于输入大小加一块大小。
    //我们需要在这里添加一个块大小的原因
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //返回的NSData以缓冲区并将它释放自由
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //释放缓冲区;
    return nil;
}
/*＊
 *  AES256 + ECB + PKCS7
 *
 *  @param data 要解密的原始数据
 *
 *  @return  解密后数据
 */
- (NSData *)AES256DecryptWithData:(NSData* )data  {
    
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    
    // fetch key data
    [_sKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data  length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}


/**
 使用 AES256 + ECB + PKCS7加密字符串
 
 @param str 需要加密的字符串
 @param key 密钥
 @return 返回加密的字符串
 */
- (NSString *)AES256EncryptWithString:(NSString *)str withKey:(NSString *)key {
    
    _sKey = key;
    NSData *requData = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSData *enAES256Data = [self AES256EncryptWithData:requData];
    //最终结果再base64转码
    NSString *resultStr = [GTMBase64 stringByEncodingData:enAES256Data];
    return resultStr;
}

/**
 使用 AES256 + ECB + PKCS7 解密字符串
 
 @param str 需要加密的字符串
 @param key 密钥
 @return 返回加密的字符串
 */
- (NSString *)AES256DecryptWithString:(NSString *)str withKey:(NSString *)key {
  
    _sKey = key;
  
    NSData *AES256Data  = [GTMBase64 decodeString:str];
    NSData *deAES256BData = [self AES256DecryptWithData:AES256Data];
    NSString *deAES256text = [[NSString alloc] initWithData:deAES256BData encoding:NSUTF8StringEncoding];
    return deAES256text;
}

/**
 * @brief MD5 返回大写加密
 * @param inputString 需要加密的字符串
 */
- (NSString *)md5_uppercase:(NSString *)inputString {
    NSString *xMd5 = [self md5_str:inputString];
    return  [xMd5 uppercaseString];
}
/**
 * @brief MD5加密
 * @param inputString 需要加密的字符串
 */
- (NSString *)md5_str:(NSString *)inputString {
    
    const char *cStr = [inputString UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result );
    
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
