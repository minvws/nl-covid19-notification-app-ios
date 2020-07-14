//
//  SignatureValidator.m
//  OpenSSLTest
//
//  Created by Robin van Dijke on 10/07/2020.
//  Copyright © 2020 Robin van Dijke. All rights reserved.
//

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
        return false;
    }
    
    X509 *certificate = PEM_read_bio_X509(certificateBlob, NULL, 0, NULL);
    BIO_free(certificateBlob); certificateBlob = NULL;
    
    if (certificate == NULL) {
        return false;
    }
    
    ASN1_INTEGER *expectedSerial = ASN1_INTEGER_new();
    
    if (expectedSerial == NULL) {
        return false;
    }
    
    ASN1_INTEGER_set_uint64(expectedSerial, serialNumber);
    ASN1_INTEGER *certificateSerial = X509_get_serialNumber(certificate);
    
    if (certificateSerial == NULL) {
        return false;
    }
    
    BOOL isMatch = ASN1_INTEGER_cmp(certificateSerial, expectedSerial) == 0;
    
    ASN1_INTEGER_free(expectedSerial); expectedSerial = NULL;
    
    return isMatch;
}

- (BOOL)validateSubjectKeyIdentifier:(NSData *)subjectKeyIdentifier forCertificateData:(NSData *)certificateData {
    BIO *certificateBlob = BIO_new_mem_buf(certificateData.bytes, (int)certificateData.length);
    
    if (certificateBlob == NULL) {
        return false;
    }
    
    X509 *certificate = PEM_read_bio_X509(certificateBlob, NULL, 0, NULL);
    BIO_free(certificateBlob); certificateBlob = NULL;
    
    if (certificate == NULL) {
        return false;
    }
    
    const unsigned char *bytes = subjectKeyIdentifier.bytes;
    ASN1_OCTET_STRING *expectedSubjectKeyIdentifier = d2i_ASN1_OCTET_STRING(NULL, &bytes, (int)subjectKeyIdentifier.length);
    
    if (expectedSubjectKeyIdentifier == NULL) {
        return false;
    }
    
    const ASN1_OCTET_STRING *certificateSubjectKeyIdentifier = X509_get0_subject_key_id(certificate);
    if (certificateSubjectKeyIdentifier == NULL) {
        return false;
    }
    
    BOOL isMatch = ASN1_OCTET_STRING_cmp(expectedSubjectKeyIdentifier, certificateSubjectKeyIdentifier) == 0;
    
    X509_free(certificate); certificate = NULL;
    ASN1_OCTET_STRING_free(expectedSubjectKeyIdentifier); expectedSubjectKeyIdentifier = NULL;
    
    return isMatch;
}

- (BOOL)validatePKCS7Signature:(NSData *)signatureData
                   contentData:(NSData *)contentData
               certificateData:(NSData *)certificateData {
    BIO *signatureBlob = BIO_new_mem_buf(signatureData.bytes, (int)signatureData.length);
    BIO *contentBlob = BIO_new_mem_buf(contentData.bytes, (int)contentData.length);
    BIO *certificateBlob = BIO_new_mem_buf(certificateData.bytes, (int)certificateData.length);
    
    PKCS7 *p7 = d2i_PKCS7_bio(signatureBlob, NULL);
    X509 *cert = PEM_read_bio_X509(certificateBlob, NULL, 0, NULL);
    
    BIO_free(signatureBlob); signatureBlob = NULL;
    BIO_free(certificateBlob); certificateBlob = NULL;
        
    X509_STORE *store = X509_STORE_new();
    X509_STORE_add_cert(store, cert);
    
    X509_VERIFY_PARAM *verifyParameters = X509_VERIFY_PARAM_new();
    X509_VERIFY_PARAM_set_flags(verifyParameters, X509_V_FLAG_CRL_CHECK_ALL | X509_V_FLAG_POLICY_CHECK);
    X509_VERIFY_PARAM_set_purpose(verifyParameters, X509_PURPOSE_ANY);

    X509_STORE_set1_param(store, verifyParameters);
    X509_VERIFY_PARAM_free(verifyParameters);
    verifyParameters = NULL;
    
    int result = PKCS7_verify(p7, NULL, store, contentBlob, NULL, PKCS7_BINARY);
    
    BIO_free(contentBlob); contentBlob = NULL;
    X509_STORE_free(store); store = NULL;
    OPENSSL_free(cert); cert = NULL;
    OPENSSL_free(p7); p7 = NULL;
    
    return result == 1;
}

@end
