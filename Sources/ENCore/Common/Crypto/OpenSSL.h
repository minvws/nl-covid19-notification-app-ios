/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SignatureValidationResult) {
    SIGNATUREVALIDATIONRESULT_SUCCESS = 1,
    SIGNATUREVALIDATIONRESULT_GENERICERROR = 2,
    SIGNATUREVALIDATIONRESULT_INCORRECTCOMMONNAME = 3,
    SIGNATUREVALIDATIONRESULT_VERIFICATIONFAILED = 4,
    SIGNATUREVALIDATIONRESULT_INCORRECTAUTHORITYKEYIDENTIFIER = 5
};

@interface OpenSSL : NSObject

- (BOOL)validateSerialNumber:(uint64_t)serialNumber forCertificateData:(NSData *)certificateData;
- (BOOL)validateSubjectKeyIdentifier:(NSData *)subjectKeyIdentifier forCertificateData:(NSData *)certificateData;

- (SignatureValidationResult)validatePKCS7Signature:(NSData *)signatureData
                   contentData:(NSData *)contentData
               certificateData:(NSData *)certificateData
        authorityKeyIdentifier:(NSData *)expectedAuthorityKeyIdentifierData
     requiredCommonNameContent:(NSString *)requiredCommonNameContent
      requiredCommonNameSuffix:(NSString *)requiredCommonNameSuffix;

@end

NS_ASSUME_NONNULL_END
