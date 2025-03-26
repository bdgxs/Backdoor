import Foundation

struct CertData {
    var certificate: SecCertificate
    var identity: SecIdentity

    init(certificate: SecCertificate, identity: SecIdentity) {
        self.certificate = certificate
        self.identity = identity
    }

    func getCertificateData() -> Data? {
        return SecCertificateCopyData(certificate) as Data
    }

    static func loadCertificate(from url: URL) throws -> SecCertificate {
        guard let certificateData = try? Data(contentsOf: url) else {
            throw NSError(domain: "CertData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to load certificate data from URL."])
        }
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            throw NSError(domain: "CertData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create certificate from data."])
        }
        return certificate
    }

    static func loadIdentity(from url: URL, password: String) throws -> SecIdentity {
        let options = [kSecImportExportPassphrase as String: password]
        var items: CFArray?

        let status = SecPKCS12Import(try Data(contentsOf: url) as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess else {
            throw NSError(domain: "CertData", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Unable to import identity from PKCS12 data."])
        }
        guard let item = (items as? [[String: Any]])?.first,
              let identity = item[kSecImportItemIdentity as String] as? SecIdentity else {
            throw NSError(domain: "CertData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve identity from imported items."])
        }
        return identity
    }
}