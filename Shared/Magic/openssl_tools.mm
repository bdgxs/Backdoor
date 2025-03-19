//  p12_password_check.cpp
//  feather
//
//  Created by HAHALOSAH on 8/6/24.
//

#include "openssl_tools.hpp"
#include "zsign/Utils.hpp"
#include "zsign/common/common.h"

#include <openssl/pem.h>
#include <openssl/cms.h>
#include <openssl/err.h>
#include <openssl/provider.h>
#include <openssl/pkcs12.h>
#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/x509.h>

#include <string>

EVP_PKEY* generate_root_ca_key(const char* basename, const char* output_path);
X509* generate_root_ca_cert(EVP_PKEY* pkey, const char* basename, const char* output_path);

using namespace std;

bool p12_password_check(NSString *file, NSString *pass) {
    BIO *bioPKey = BIO_new_file([file cStringUsingEncoding:NSUTF8StringEncoding], "r");
    if (bioPKey == NULL) {
        BIO_free(bioPKey);
        return false;
    }

    PKCS12 *p12 = d2i_PKCS12_bio(bioPKey, NULL);
    if (p12 == NULL) {
        BIO_free(bioPKey);
        return false;
    }

    X509 *x509Cert = NULL;
    EVP_PKEY *evpPKey = NULL;
    if (PKCS12_parse(p12, [pass cStringUsingEncoding:NSUTF8StringEncoding], &evpPKey, &x509Cert, NULL) == 0) {
        PKCS12_free(p12);
        BIO_free(bioPKey);
        return false;
    }

    PKCS12_free(p12);
    BIO_free(bioPKey);
    return true;
}

// Remove inappropriate comments and update the function
void password_check_fix_WHAT_THE_FUCK(NSString *path) {
    string strProvisionFile = [path cStringUsingEncoding:NSUTF8StringEncoding];
    string strProvisionData;
    ReadFile(strProvisionFile.c_str(), strProvisionData);

    BIO *in = BIO_new(BIO_s_mem());
    if (in == NULL) {
        return;
    }

    if (BIO_write(in, strProvisionData.data(), (int)strProvisionData.size()) != (int)strProvisionData.size()) {
        BIO_free(in);
        return;
    }

    d2i_CMS_bio(in, NULL);
    BIO_free(in);
}

void generate_root_ca_pair(const char* basename) {
    const char* documentsPath = getDocumentsDirectory();

    RSA *rsa = RSA_generate_key(2048, RSA_F4, NULL, NULL);
    if (rsa == NULL) {
        return;
    }

    EVP_PKEY *pkey = EVP_PKEY_new();
    if (pkey == NULL) {
        RSA_free(rsa);
        return;
    }

    EVP_PKEY_assign_RSA(pkey, rsa);

    X509* x509 = X509_new();
    if (x509 == NULL) {
        EVP_PKEY_free(pkey);
        return;
    }

    X509_set_version(x509, 2);
    ASN1_INTEGER_set(X509_get_serialNumber(x509), 1);

    X509_gmtime_adj(X509_get_notBefore(x509), 0);
    X509_gmtime_adj(X509_get_notAfter(x509), 315360000L);

    X509_set_pubkey(x509, pkey);

    X509_NAME* name = X509_get_subject_name(x509);
    X509_NAME_add_entry_by_txt(name, "C", MBSTRING_ASC, (unsigned char*)"US", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "O", MBSTRING_ASC, (unsigned char*)"Root CA", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC, (unsigned char*)"Root CA", -1, -1, 0);

    X509_set_issuer_name(x509, name);

    X509V3_CTX ctx;
    X509V3_set_ctx_nodb(&ctx);
    X509V3_set_ctx(&ctx, x509, x509, NULL, NULL, 0);

    X509_EXTENSION *ext = X509V3_EXT_conf_nid(NULL, &ctx, NID_basic_constraints, "critical,CA:TRUE,pathlen:0");
    if (ext != NULL) {
        X509_add_ext(x509, ext, -1);
        X509_EXTENSION_free(ext);
    }

    ext = X509V3_EXT_conf_nid(NULL, &ctx, NID_key_usage, "critical,keyCertSign,cRLSign");
    if (ext != NULL) {
        X509_add_ext(x509, ext, -1);
        X509_EXTENSION_free(ext);
    }

    ext = X509V3_EXT_conf_nid(NULL, &ctx, NID_subject_key_identifier, "hash");
    if (ext != NULL) {
        X509_add_ext(x509, ext, -1);
        X509_EXTENSION_free(ext);
    }

    X509_sign(x509, pkey, EVP_sha256());

    string keyfile = std::string(documentsPath) + "/" + string(basename) + ".pem";
    string certfile = std::string(documentsPath) + "/" + string(basename) + ".crt";

    BIO *bio = BIO_new_file(keyfile.c_str(), "w");
    if (bio != NULL) {
        PEM_write_bio_PrivateKey(bio, pkey, NULL, NULL, 0, NULL, NULL);
        BIO_free(bio);
        printf("Private key written to: %s\n", keyfile.c_str());
    }

    FILE* f = fopen(certfile.c_str(), "wb");
    if (f != NULL) {
        PEM_write_X509(f, x509);
        fclose(f);
        printf("Certificate written to: %s\n", certfile.c_str());
    }

    EVP_PKEY_free(pkey);
    X509_free(x509);
}