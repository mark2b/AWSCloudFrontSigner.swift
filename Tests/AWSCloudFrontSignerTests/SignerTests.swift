import class Foundation.Bundle
import XCTest
@testable import AWSCloudFrontSigner

final class AWSCloudFrontSignerTests: XCTestCase {

    func testPrivateKeyFile() {
        do {
            let dateFormatter = ISO8601DateFormatter()
            let dateLessThan = dateFormatter.date(from: "2023-01-01T00:00:00Z")!
            let privateKeyFile = Bundle.module.path(forResource: "private", ofType: "pem")!
            let signer = CookiesSigner(resourceUrl: URL(string: "https://host/path")!, dateLessThan: dateLessThan, keyPairId: "", privateKeyFile: privateKeyFile)
            _ = try signer.makeSecKey()
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPrivateKey() {
        do {
            let dateFormatter = ISO8601DateFormatter()
            let dateLessThan = dateFormatter.date(from: "2023-01-01T00:00:00Z")!
            let signer = CookiesSigner(resourceUrl: URL(string: "https://host/path")!, dateLessThan: dateLessThan, keyPairId: "", privateKey: pk)
            _ = try signer.makeSecKey()
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPolicy() {
        let dateFormatter = ISO8601DateFormatter()
        let dateLessThan = dateFormatter.date(from: "2023-01-01T00:00:00Z")!
        let dateGreaterThan = dateFormatter.date(from: "2022-01-01T00:00:00Z")!
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    
        let signer1 = CookiesSigner(resourceUrl: URL(string: "https://host/path")!, dateLessThan: dateLessThan, keyPairId: "", privateKey: nil)

        let policy1 = signer1.makePolicy()
    
        let actualPolicy1 = String(data: (try? encoder.encode(policy1))!, encoding: .utf8)!
        let expectedPolicy1 = """
        {
          "Statement" : [
            {
              "Condition" : {
                "DateLessThan" : {
                  "AWS:EpochTime" : 1672531200
                }
              },
              "Resource" : "https://host/path"
            }
          ]
        }
        """
        XCTAssertEqual(actualPolicy1, expectedPolicy1)

        let signer2 = CookiesSigner(resourceUrl: URL(string: "https://host/path")!, dateLessThan: dateLessThan, dateGreaterThan: dateGreaterThan, ipAddress: "1.1.1.1/24", keyPairId: "", privateKey: nil)

        let policy2 = signer2.makePolicy()
    
        let actualPolicy2 = String(data: (try? encoder.encode(policy2))!, encoding: .utf8)!
        let expectedPolicy2 = """
        {
          "Statement" : [
            {
              "Condition" : {
                "DateGreaterThan" : {
                  "AWS:EpochTime" : 1640995200
                },
                "DateLessThan" : {
                  "AWS:EpochTime" : 1672531200
                },
                "IpAddress" : {
                  "AWS:SourceIp" : "1.1.1.1/24"
                }
              },
              "Resource" : "https://host/path"
            }
          ]
        }
        """
        XCTAssertEqual(actualPolicy2, expectedPolicy2)
    }


    func testCloudFrontPolicyCookie() {
        do {
            let resourceUrl = URL(string: "https://d1234567890123.cloudfront.net/*")!

            let signer = CookiesSigner(resourceUrl: resourceUrl, dateLessThan: Date.distantFuture, keyPairId: "K1234567890120")
            
            let cookie = try signer.makeCloudFrontPolicyCookie()
            XCTAssertEqual(cookie.value, "eyJTdGF0ZW1lbnQiOlt7IkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6NjQwOTIyMTEyMDB9fSwiUmVzb3VyY2UiOiJodHRwczovL2QxMjM0NTY3ODkwMTIzLmNsb3VkZnJvbnQubmV0LyoifV19")
        }
        catch {
            XCTFail(error.localizedDescription)
        }

    }

    func testCloudFrontPolicyCookieWithCustomPolicyPayload() {
        do {
            let resourceUrl = URL(string: "https://d1234567890123.cloudfront.net/*")!
            let policy = """
            {
                "Statement": [
                    {
                        "Resource": "\(resourceUrl.absoluteString)",
                        "Condition": {
                            "DateLessThan": {
                                "AWS:EpochTime": 1738264886
                            }
                        }
                    }
                ]
            }
            """

            let signer = CookiesSigner(resourceUrl: resourceUrl, dateLessThan: Date.distantFuture, policy: policy, keyPairId: "K1234567890120", privateKey: nil)
            
            let cookie = try signer.makeCloudFrontPolicyCookie()
            XCTAssertEqual(cookie.value, "eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9kMTIzNDU2Nzg5MDEyMy5jbG91ZGZyb250Lm5ldC8qIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoxNzM4MjY0ODg2fX19XX0_")
        }
        catch {
            XCTFail(error.localizedDescription)
        }

    }

    func testCloudFrontSignatureCookie() {
        do {
            let resourceUrl = URL(string: "https://d1234567890123.cloudfront.net/*")!

            let signer = CookiesSigner(resourceUrl: resourceUrl, dateLessThan: Date.distantFuture, keyPairId: "K1234567890120", privateKey: pk)
            
            let cookie = try signer.makeCloudFrontSignatureCookie()
            XCTAssertEqual(cookie.value, "KQUIn0wn5PeU9CqqAJc7LqTFW4hyWdNuqkYhxZxZQHl-TbvjWE5EmUlbPy2s37T9EH3QOFVQOvQ9gz14-q1ELmI~8yjvzLUxoAeNc7rNZHVANhxDrkkMeCsd7SzU36DXkh2Fac5SBI2bGefI1kdD8F8ndiuuzdG0M4dZz8ht5RntcGVilsVXXlYl32tfzVCKiNjrAe0X~I5NrB5ihyj8s8-tXb-ezCL~m~PtBpXKVdYZcS4bR2l1629wGwBenlERZvVqeKh0EE~PKzB0TqkeslHXd8iuELKUDkmBo7QgIiP-cWJXvWcm2p00hjDpFh9Gqoc1pamvqOyIOgds5ecKlA__")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCloudFrontSignatureCookieWithCustomPolicyPayload() {
        do {
            let resourceUrl = URL(string: "https://d1234567890123.cloudfront.net/*")!

            let policy = """
            {
                "Statement": [
                    {
                        "Resource": "\(resourceUrl.absoluteString)",
                        "Condition": {
                            "DateLessThan": {
                                "AWS:EpochTime": 1738264886
                            }
                        }
                    }
                ]
            }
            """

            let signer = CookiesSigner(resourceUrl: resourceUrl, dateLessThan: Date.distantFuture, policy: policy, keyPairId: "K1234567890120", privateKey: pk)
            
            let cookie = try signer.makeCloudFrontSignatureCookie()
            XCTAssertEqual(cookie.value, "uglPRCnXDqqe94bYwUqkLMi0I~Dp4G4GGPxVczoTcLvKdK620FIkAbj3zrBoJ80gyRBnHeFde-gtDSVC19P7y69YUEnRYoXpmhFoGYsbRqWgiekD0hya0nZtcUBdatJ2DhMu8c5r-O~H83KX~QJbEBc6U1dL~hkK4C3TZZvthnMrGUWFJk~logdpsrckVJ8v-XP-tewmyS0v4T26hkeAnJ4ev6ovhwoGkSyTY7KeyUw84adIiyPv1wkNJavPyUpsZ1~s844wdmAjmm0ri2lSh0HtPod1EpR2rsk7HElixvHWFN1ftZCw1LLXLj23Xr0eOiWGZmVRI2hef~aYhsSH3g__")
        }
        catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    static var allTests = [
        ("testPolicy", testPolicy),
        ("testPrivateKey", testPrivateKey),
        ("testPrivateKeyFile", testPrivateKeyFile),
        ("testCloudFrontPolicyCookie", testCloudFrontPolicyCookie),
        ("testCloudFrontPolicyCookieWithCustomPolicyPayload", testCloudFrontPolicyCookieWithCustomPolicyPayload),
        ("testCloudFrontSignatureCookie", testCloudFrontSignatureCookie),
        ("testCloudFrontSignatureCookieWithCustomPolicyPayload", testCloudFrontSignatureCookieWithCustomPolicyPayload),
    ]
}

let pk = /* it is only testing private key */ """
MIIEpAIBAAKCAQEAzlMSjFyTUjYFi2GAn7w0pXC8P+8QKW7EwopZ3Y/u+tyxP0TC
TRHRg+S8eARF2uF0v5HsmboUki6iDPHh4eJN+cPMSbHZ6B29qxKy21KkBEAdwbmi
kUaPtSjwNYFcYnw6KcDjcE8wiLTb4u9RjAt5b7CPDfKkPvREyaETQS/mc1j3Q1eg
ihC+hn+q59Ikj0Smduve71NJsDSf2SrhrMwP++StM8OntoJK+I42tU/qP5pbPejm
t6a9KYpQsfinMylI38ZNFi4Kfc2ke2XjFG0Hv0z+ozTiVG69dKs/E/DHVSFH4pb9
NifAi/1MQVFtu0u1RUSebKSipBbxbxH3LXqpgQIDAQABAoIBAGghXRciEehIA3xY
9UWpAxkMULYjvZBrqzpUAQ7lecN6Zqp71WR4PbnHU6du4KKbbwTQbQ0Y8RDmIDtQ
SKRsRtZrj0sSS9vuRq90fHhcuRK8GUiQnA+eASF5S+J1K185O1GfXCpujRwxy1g5
WHrJv7wy68AqWeK7/YuVk9YuiqxjrYL94MT47sBv6nJCDgMd7kTJ9JEt5ISPG4nm
tzh3brvn2TzWca7r3JVlU8Zn5BQ4mzCmHAhEBtDGGWNht5ZRBRgb3iwNL0VO2Vk9
zeVZOBOaGDMGoxmrbKn4VtEgatowdhSrAa9/mP3+1ooXvsm6QipoigKrKqxOOfQ6
/2T/a8ECgYEA+YCjy8yBfxMX5sbkrr2lJpZyZHErght8HB6kbNnd1jZUMpKS2vpA
JZ1fXSfvt1ISS6rjMmOHVvVgQcntQ4fg24eKcnN8ib62rFjRHPSXHCQHkin6YQJI
2ZHNXBytupOqdUM422c4PK3nBjJTv6HRmKjqsY3zo8SoFCDCzbvV+b0CgYEA07KT
2irM+3RIUgcihZlPHoVMbDJJaz4B6ug79dYhOKmOtJxNM1qaCth1lQLWOfRmKlAr
9uctbkcilJNwwdCtO/TRJtOFTHfmCJLYVUkMhV+gmXqxTzIl11ZGLm69FyNE2lKU
ubxZq3OmuWeT8sFUIDpQauj92z44+nNEVEKgMRUCgYBIsRgHyn94HIH8NLpvxsUV
JwQRC3/XmlZggvT42cjuHkoNqfKrZfnGe8FLDNWknX7DGPi0t5a42SjAQiqkYDQ9
AZJuogMIxs3GDOJwAzr7cevaw+w000uSSA6C5cAf+eHR5FHuanZSB4Clp4gK7wR3
687lCCyR7DvkEV9wPWesKQKBgQCxp404au62nrEKVX59C1lATbECo3jFjLXjQpz/
A4HBoVlm7DxFOmVHcLvMHyNUY2tRWxJqEzsm7n9wnALmQ479X8gdgyi8MWpUC5eM
is79JnEKG9KsmXL0MSyYTspUnn5rkR3KeOvvXBCwSuH3uJI2sXlHHtvan28FjrHq
3Da+uQKBgQDNBEyZ7CTs2odo6tnQ17T9Y/MJF5cEwWLRNJuQcOBqoQ/m/+AAISxA
OzUNys6lulFesh0fNnzs4o63mPfifcKE2zVZCVcZiCv50Tj3knSh5Cae+UIdAEAb
+pv8qWJOR31tIRDBY9Km7rN/nOLcWZ4UsUFnRIglvmnCJTmK19vpqw==
"""
