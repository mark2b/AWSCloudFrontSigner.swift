import Foundation

extension CookiesSigner {

    public func makeCookies() throws -> [HTTPCookie] {
        
        let cookieCloudFrontPolicy = try self.makeCloudFrontPolicyCookie()
        let cookieCloudFrontSignature = try self.makeCloudFrontSignatureCookie()
        let cookieCloudFrontKeyPairId = try self.makeCloudFrontKeyPairIdCookie()

        return [cookieCloudFrontPolicy, cookieCloudFrontSignature, cookieCloudFrontKeyPairId]
    }
    
    func makeCloudFrontPolicyCookie() throws -> HTTPCookie {

        guard let domain = self.domain ?? resourceUrl.host else {
            throw "Missing cookie domain".error
        }

        guard let cookie = HTTPCookie(properties: [
            .name : "CloudFront-Policy",
            .value : try self.encode(try self.normalizedPolicyData()),
            .domain : domain,
            .path : self.path,
            .secure : true,
            HTTPCookiePropertyKey("HttpOnly") : true,
        ]) else {
            throw "Cookie [CloudFront-Policy] creation failed.".error
        }
        return cookie
    }

    func makeCloudFrontSignatureCookie() throws -> HTTPCookie {
        guard let domain = self.domain ?? resourceUrl.host else {
            throw "Missing cookie domain".error
        }

        guard let cookie = HTTPCookie(properties: [
            .name : "CloudFront-Signature",
            .value : try self.encode(try self.signRSAwithSHA1(self.normalizedPolicyData())),
            .domain : domain,
            .path : self.path,
            .secure : true,
            HTTPCookiePropertyKey("HttpOnly") : true,
        ]) else {
            throw "Cookie [CloudFront-Signature] creation failed.".error
        }
        return cookie
    }
    
    func makeCloudFrontKeyPairIdCookie() throws -> HTTPCookie {
        guard let domain = self.domain ?? resourceUrl.host else {
            throw "Missing cookie domain".error
        }
        
        guard let cookie = HTTPCookie(properties: [
            .name : "CloudFront-Key-Pair-Id",
            .value : self.keyPairId,
            .domain : domain,
            .path : self.path,
            .secure : true,
            HTTPCookiePropertyKey("HttpOnly") : true,
        ]) else {
            throw "Cookie [CloudFront-Key-Pair-Id] creation failed.".error
        }

        return cookie
    }
}
