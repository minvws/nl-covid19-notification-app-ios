/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

#import "OpenSSL.h"
#import <openssl/err.h>
#import <openssl/pem.h>
#import <openssl/pkcs7.h>
#import <openssl/safestack.h>
#import <openssl/x509.h>
#import <openssl/x509v3.h>
#import <openssl/x509_vfy.h>
#import <Security/Security.h>

@implementation OpenSSL

- (BOOL)validateSerialNumber:(uint64_t)serialNumber forCertificateData:(NSData *)certificateData {
    BIO *certificateBlob = BIO_new_mem_buf(certificateData.bytes, (int)certificateData.length);
    
    if (certificateBlob == NULL) {
        return NO;
    }
    
    X509 *certificate = PEM_read_bio_X509(certificateBlob, NULL, 0, NULL);
    BIO_free(certificateBlob); certificateBlob = NULL;
    
    if (certificate == NULL) {
        return NO;
    }
    
    ASN1_INTEGER *expectedSerial = ASN1_INTEGER_new();
    
    if (expectedSerial == NULL) {
        return NO;
    }
    
    if (ASN1_INTEGER_set_uint64(expectedSerial, serialNumber) != 1) {
        ASN1_INTEGER_free(expectedSerial); expectedSerial = NULL;
        
        return NO;
    }
    
    ASN1_INTEGER *certificateSerial = X509_get_serialNumber(certificate);
    if (certificateSerial == NULL) {
        return NO;
    }
    
    BOOL isMatch = ASN1_INTEGER_cmp(certificateSerial, expectedSerial) == 0;
    
    ASN1_INTEGER_free(expectedSerial); expectedSerial = NULL;
    
    return isMatch;
}

- (BOOL)validateSubjectKeyIdentifier:(NSData *)subjectKeyIdentifier forCertificateData:(NSData *)certificateData {
    BIO *certificateBlob = BIO_new_mem_buf(certificateData.bytes, (int)certificateData.length);
    
    if (certificateBlob == NULL) {
        return NO;
    }
    
    X509 *certificate = PEM_read_bio_X509(certificateBlob, NULL, 0, NULL);
    BIO_free(certificateBlob); certificateBlob = NULL;
    
    if (certificate == NULL) {
        return NO;
    }
    
    const unsigned char *bytes = subjectKeyIdentifier.bytes;
    ASN1_OCTET_STRING *expectedSubjectKeyIdentifier = d2i_ASN1_OCTET_STRING(NULL, &bytes, (int)subjectKeyIdentifier.length);
    
    if (expectedSubjectKeyIdentifier == NULL) {
        return NO;
    }
    
    const ASN1_OCTET_STRING *certificateSubjectKeyIdentifier = X509_get0_subject_key_id(certificate);
    if (certificateSubjectKeyIdentifier == NULL) {
        return NO;
    }

    BOOL isMatch = ASN1_OCTET_STRING_cmp(expectedSubjectKeyIdentifier, certificateSubjectKeyIdentifier) == 0;
    
    X509_free(certificate); certificate = NULL;
    ASN1_OCTET_STRING_free(expectedSubjectKeyIdentifier); expectedSubjectKeyIdentifier = NULL;
    
    return isMatch;
}

- (BOOL)validateCommonNameForCertificate:(X509 *)certificate
                         requiredContent:(NSString *)requiredContent
                         requiredSuffix:(NSString *)requiredSuffix {
    
    // Get subject from certificate
    X509_NAME *certificateSubjectName = X509_get_subject_name(certificate);
    
    // Get Common Name from certificate subject
    char certificateCommonName[256];
    X509_NAME_get_text_by_NID(certificateSubjectName, NID_commonName, certificateCommonName, 256);
    NSString *cnString = [NSString stringWithUTF8String:certificateCommonName];
    
    // Compare Common Name to required content and required suffix
    BOOL containsRequiredContent = [cnString rangeOfString:requiredContent options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL hasCorrectSuffix = [cnString hasSuffix:requiredSuffix];    
    
    X509_NAME_free(certificateSubjectName);
    certificateSubjectName = NULL;
    
    return hasCorrectSuffix && containsRequiredContent;
}
    
- (BOOL)validatePKCS7Signature:(NSData *)signatureData
                   contentData:(NSData *)contentData
               certificateData:(NSData *)certificateData
        authorityKeyIdentifier:(NSData *)expectedAuthorityKeyIdentifierData
     requiredCommonNameContent:(NSString *)requiredCommonNameContent
      requiredCommonNameSuffix:(NSString *)requiredCommonNameSuffix {
    
    BIO *signatureBlob = BIO_new_mem_buf(signatureData.bytes, (int)signatureData.length);
    if (signatureBlob == NULL) {
        return NO;
    }
    
    BIO *contentBlob = BIO_new_mem_buf(contentData.bytes, (int)contentData.length);
    if (contentBlob == NULL) {
        BIO_free(signatureBlob); signatureBlob = NULL;
        
        return NO;
    }
    
    BIO *certificateBlob = BIO_new_mem_buf(certificateData.bytes, (int)certificateData.length);
    if (certificateBlob == NULL) {
        BIO_free(signatureBlob); signatureBlob = NULL;
        BIO_free(contentBlob); contentBlob = NULL;
        
        return NO;
    }
    
    PKCS7 *p7 = d2i_PKCS7_bio(signatureBlob, NULL);
    if (p7 == NULL) {
        BIO_free(signatureBlob); signatureBlob = NULL;
        BIO_free(contentBlob); contentBlob = NULL;
        BIO_free(certificateBlob); certificateBlob = NULL;
        
        return NO;
    }
    
    STACK_OF(X509) *signers = PKCS7_get0_signers(p7, NULL, 0);
    
    if (signers == NULL || sk_X509_num(signers) == 0) {
        BIO_free(signatureBlob); signatureBlob = NULL;
        BIO_free(contentBlob); contentBlob = NULL;
        BIO_free(certificateBlob); certificateBlob = NULL;
        return NO;
    }
    
    X509 *signingCert = sk_X509_value(signers, 0);
    
    BOOL isAuthorityKeyIdentifierValid = [self validateAuthorityKeyIdentifierData:expectedAuthorityKeyIdentifierData signingCertificate:signingCert];
    BOOL isCommonNameValid = [self validateCommonNameForCertificate:signingCert
                                                    requiredContent:requiredCommonNameContent
                                                     requiredSuffix:requiredCommonNameSuffix];
    
    if (!isAuthorityKeyIdentifierValid || !isCommonNameValid) {
        BIO_free(signatureBlob); signatureBlob = NULL;
        BIO_free(contentBlob); contentBlob = NULL;
        BIO_free(certificateBlob); certificateBlob = NULL;
        return NO;
    }
    
    X509 *cert = PEM_read_bio_X509(certificateBlob, NULL, 0, NULL);
    if (cert == NULL) {
        BIO_free(signatureBlob); signatureBlob = NULL;
        BIO_free(contentBlob); contentBlob = NULL;
        BIO_free(certificateBlob); certificateBlob = NULL;
        
        return NO;
    }
    
    BIO_free(signatureBlob); signatureBlob = NULL;
    BIO_free(certificateBlob); certificateBlob = NULL;
        
    X509_STORE *store = X509_STORE_new();
    if (store == NULL) {
        BIO_free(contentBlob); contentBlob = NULL;
        
        return NO;
    }
    
    if (X509_STORE_add_cert(store, cert) != 1) {
        X509_STORE_free(store); store = NULL;
        
        return NO;
    }
    
    X509_VERIFY_PARAM *verifyParameters = X509_VERIFY_PARAM_new();
    if (verifyParameters == NULL) {
        X509_STORE_free(store); store = NULL;
        
        return NO;
    }
    
    if (X509_VERIFY_PARAM_set_flags(verifyParameters, X509_V_FLAG_CRL_CHECK_ALL | X509_V_FLAG_POLICY_CHECK) != 1
        || X509_VERIFY_PARAM_set_purpose(verifyParameters, X509_PURPOSE_ANY) != 1) {
        X509_STORE_free(store); store = NULL;
        X509_VERIFY_PARAM_free(verifyParameters); verifyParameters = NULL;
        
        return NO;
    }

    if (X509_STORE_set1_param(store, verifyParameters) != 1) {
        X509_STORE_free(store); store = NULL;
        X509_VERIFY_PARAM_free(verifyParameters); verifyParameters = NULL;
        
        return NO;
    }
    
    X509_VERIFY_PARAM_free(verifyParameters); verifyParameters = NULL;
    
    int result = PKCS7_verify(p7, NULL, store, contentBlob, NULL, PKCS7_BINARY);
    
    BIO_free(contentBlob); contentBlob = NULL;
    X509_STORE_free(store); store = NULL;
    OPENSSL_free(cert); cert = NULL;
    OPENSSL_free(p7); p7 = NULL;
    
    return result == 1;
}

- (BOOL)validateAuthorityKeyIdentifierData:(NSData *)expectedAuthorityKeyIdentifierData
                        signingCertificate:(X509 *)signingCert {
    
    if (expectedAuthorityKeyIdentifierData == NULL) {
        return NO;
    }
    
    const unsigned char * bytes = expectedAuthorityKeyIdentifierData.bytes;
    ASN1_OCTET_STRING *expectedAuthorityKeyIdentifier = d2i_ASN1_OCTET_STRING(NULL,
                                                                              &bytes,
                                                                              (int)expectedAuthorityKeyIdentifierData.length);

    if (expectedAuthorityKeyIdentifier == NULL) {
        return NO;
    }
    
    const ASN1_OCTET_STRING * authorityKeyIdentifier = X509_get0_authority_key_id(signingCert);
    
    if (authorityKeyIdentifier == NULL) {
        ASN1_OCTET_STRING_free(expectedAuthorityKeyIdentifier); expectedAuthorityKeyIdentifier = NULL;
        return NO;
    }

    BOOL isMatch = ASN1_OCTET_STRING_cmp(authorityKeyIdentifier, expectedAuthorityKeyIdentifier) == 0;
    ASN1_OCTET_STRING_free(expectedAuthorityKeyIdentifier); expectedAuthorityKeyIdentifier = NULL;
            
    return isMatch;
}
@end
