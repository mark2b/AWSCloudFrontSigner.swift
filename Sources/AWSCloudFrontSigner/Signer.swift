import Foundation
import Security
import CommonCrypto

public struct CookiesSigner : CookiesSignerAPI {

    var resourceUrl:URL
    var policyResource:String
    var dateLessThan:Date
    var dateGreaterThan:Date?
    var ipAddress:String?
    var domain:String?
    var path:String = "/"
    var policy:String?
    var keyPairId:String
    var privateKey:String?
    var privateKeyFile:String?
    var secKey:SecKey?

    /**
        CookiesSigner
        Parameters:
        - resourceUrl: Primary resource you need access to.
        - policyResource: Resource name will be set to policy. Optional. In case of missing resourceUrl will be used.
        - dateLessThan: DateLessThan parameter of custom policy. Optional. In case of missing current date + one minute will be used.
        - dateGreaterThan: DateGreaterThan parameter of custom policy. Optional
        - ipAddress: IpAddress parameter of custom policy. Optional
        - domain: Domain parameter of cookie. Optional. In case of missing resourceUrl.host will be used.
        - path: Path parameter of cookie. Optional. In case of missing "/" will be used.
        - policy: User provided policy as string. Optional. This parameter overrides automatically build policy based on parameters: policyResource, dateLessThan, dateGreaterThan, ipAddress.
        - keyPairId: Public key ID registered in the CloudFront console
        - privateKey: Private key in format base64 without header and footer. Optional. In case of missing, parameters privateKeyFile or secKey will be used
        - privateKeyFile: Path to the file containing Private key in format base64 with header and footer. Optional. In case of missing, parameters privateKey or secKey will be used
        - secKey: Instance of SecKey object. This parameter overrides parameters privateKey and privateKeyFile
     */
    public init(resourceUrl:URL, policyResource:String? = nil, dateLessThan:Date? = nil, dateGreaterThan:Date? = nil, ipAddress:String? = nil, domain:String? = nil, path:String = "/", policy:String? = nil, keyPairId:String, privateKey:String? = nil, privateKeyFile:String? = nil, secKey:SecKey? = nil) {
        self.resourceUrl = resourceUrl
        self.policyResource = policyResource ?? resourceUrl.absoluteString
        self.dateLessThan = dateLessThan ?? Date().addingTimeInterval(60)
        self.dateGreaterThan = dateGreaterThan
        self.ipAddress = ipAddress
        self.domain = domain
        self.path = path
        self.policy = policy
        self.keyPairId = keyPairId
        self.privateKey = privateKey
        self.privateKeyFile = privateKeyFile
        self.secKey = secKey
    }

    public func makeURLRequest() throws -> URLRequest {
        var request = URLRequest(url: self.resourceUrl)
        request.httpMethod = "GET"

        let cookies = try self.makeCookies()
        let cookiesHeaders = HTTPCookie.requestHeaderFields(with: cookies)
        for cookiesHeader in cookiesHeaders {
            request.addValue(cookiesHeader.value, forHTTPHeaderField: cookiesHeader.key)
        }

        return request
    }

    func normalizedPolicyData() throws -> Data {
        if let policy = policy {
            let nospacesPolicy = policy.components(separatedBy: .whitespacesAndNewlines).joined(separator: "")
            guard let policyData = nospacesPolicy.data(using: .utf8) else {
                throw "Failed to convert policy text to Data.".error
            }
            return policyData
        }
        else {
            let policy = self.makePolicy()
            let encoder = JSONEncoder()
            if #available(iOS 13.0, *) {
                encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
            }
            let policyData = try encoder.encode(policy)
            return policyData
        }
    }

    func signRSAwithSHA1(_ data: Data) throws -> Data {

        let secKey = try self.makeSecKey()

        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }

        var signedDataLength = SecKeyGetBlockSize(secKey)
        let signedData = UnsafeMutablePointer<UInt8>.allocate(capacity: signedDataLength)

        let err = SecKeyRawSign(secKey,
            .PKCS1SHA1,
            digest,
            digest.count,
            signedData,
            &signedDataLength)

        guard err == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(err), userInfo: nil)
        }

        return Data(bytes: signedData, count: signedDataLength)
    }
    
    func makeSecKey() throws -> SecKey {
        if let secKey = self.secKey {
            return secKey
        }

        var tmpPrivateKey = self.privateKey

        if let privateKeyFile = self.privateKeyFile {
            let privateKeyFilePayload = try String(contentsOfFile: privateKeyFile)
            tmpPrivateKey = privateKeyFilePayload.components(separatedBy: .newlines).filter{!$0.hasPrefix("-----")}.joined(separator: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }


        guard let privateKey = tmpPrivateKey else {
            throw "Missing private key.".error
        }

        guard let keyData =  Data(base64Encoded: privateKey, options: .ignoreUnknownCharacters) else {
            throw "Decoding private key failed.".error
        }
        
        var secKeyCreateWithDataError: Unmanaged<CFError>?
        
        let secKeyAttributes:Dictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate] as [CFString : Any]
            
        guard let secKey = SecKeyCreateWithData(keyData as CFData, secKeyAttributes as CFDictionary, &secKeyCreateWithDataError) else {
            throw "Creation SecKey from PrivateKey failed.".error
        }
        return secKey
    }

    func encode(_ input: Data) throws -> String {
        var output = input.base64EncodedData()
        let illegalChars = "+=/".utf8.map {UInt8($0)}
        let legalChars = "-_~".utf8.map {UInt8($0)}

        output.withUnsafeMutableBytes {
            for i in 0 ..< $0.count {
                for j in 0 ..< illegalChars.count {
                    if $0[i] == illegalChars[j] {
                        $0[i] = legalChars[j]
                    }
                }
            }
        }
        guard let outputAsString = String(data: output, encoding: .utf8) else {
            throw "convert encoded policy to string failed".error
        }
        
        return outputAsString
    }
}

extension String {
    var error : NSError {
        return NSError(domain: self, code: 0, userInfo: nil)
    }
}
