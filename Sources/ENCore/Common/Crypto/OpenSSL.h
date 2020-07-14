//
//  SignatureValidator.h
//  OpenSSLTest
//
//  Created by Robin van Dijke on 10/07/2020.
//  Copyright © 2020 Robin van Dijke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenSSL : NSObject

- (BOOL)validateSerialNumber:(uint64_t)serialNumber forCertificateData:(NSData *)certificateData;
- (BOOL)validateSubjectKeyIdentifier:(NSData *)subjectKeyIdentifier forCertificateData:(NSData *)certificateData;

- (BOOL)validatePKCS7Signature:(NSData *)signatureData contentData:(NSData *)contentData certificateData:(NSData *)certificateData;

@end

NS_ASSUME_NONNULL_END
