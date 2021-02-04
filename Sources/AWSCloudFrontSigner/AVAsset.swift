import Foundation
import AVKit

extension CookiesSigner {

    public func makeAVAsset() throws -> AVURLAsset {
        let cookies = try self.makeCookies()
        let options:[String:Any] = [AVURLAssetHTTPCookiesKey:cookies]
        return AVURLAsset(url: self.resourceUrl, options: options)
    }
}
