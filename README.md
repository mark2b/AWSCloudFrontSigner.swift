# AWSCloudFrontSigner

This package provides easy way to access to the AWS CloudFront protected content.

There are two ways to access  to the AWS CloudFront protected content.
    - by Signed URL
    - by Signed Cookies
  
Currently this package provides only SignedCookies access method.

https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-signed-cookies.html

1. Create private key and store it in application
    openssl genrsa -out private.pem 2048
    This key will be used to initialize CoockeSigner
2. Create public key and upload it into CloudFront console.
    openssl rsa -in private.pem -outform PEM -pubout -out public.pem
    As result of upload, you will get Public Key ID.
    This ID will be used to initialize CoockeSigner (keyPairId parameter)




# Usage
let signer = CookiesSigner(resourceUrl: resourceUrl, keyPairId: "K1234567890120", privateKey: "PRIVATE KEY")

// Creates cookies for HTTP request 
let cookies = try signer.makeCookies()
// Creates HTTP request with signed cookies.  
let request = try signer.makeURLRequest()
// Creates AVURLAsset with signed cookies.  
let asset = try signer.AVURLAsset()

```
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
```

```
    func makeURLRequest() throws -> URLRequest
    func makeCookies() throws -> [HTTPCookie]
    func makeAVAsset() throws -> AVURLAsset
```

## Installation

AWSCloudFrontSigner is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AWSCloudFrontSigner"
```

## Author

Mark Berner, mark@berner.dev

## License

l10n is available under the MIT license. See the LICENSE file for more info.
