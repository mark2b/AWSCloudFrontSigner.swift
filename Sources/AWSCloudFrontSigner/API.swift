//
//  File.swift
//  
//
//  Created by Mark Berner on 03/02/2021.
//

import Foundation
import AVKit

protocol CookiesSignerAPI {
    func makeURLRequest() throws -> URLRequest
    func makeCookies() throws -> [HTTPCookie]
    func makeAVAsset() throws -> AVURLAsset
}
