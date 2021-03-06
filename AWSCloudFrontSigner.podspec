Pod::Spec.new do |s|
    s.name         = 'AWSCloudFrontSigner'
    s.version      = '0.1.1'
    s.summary      = 'AWS CloudFront Signer'
    s.homepage     = 'https://github.com/mark2b/AWSCloudFrontSigner.swift'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Mark Berner' => 'mark@berner.dev' }
    s.source           = { :git => 'https://github.com/mark2b/AWSCloudFrontSigner.swift.git', :tag => s.version.to_s }
    s.platform     = :ios
    s.platform     = :ios, '13.0'
    s.swift_versions = '5.0'
    s.ios.deployment_target = '13.0'
    s.module_name     = 'AWSCloudFrontSigner'
    s.source_files = 'Sources/AWSCloudFrontSigner/**/*'
end

