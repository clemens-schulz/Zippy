Pod::Spec.new do |s|

  s.name         = "Zippy"
  s.version      = "0.1"
  s.summary      = "Framework for reading ZIP files"

  s.description  = <<-DESC
Zippy is an iOS framework for reading ZIP files. It's written in Swift 3 and uses Apple's compression framework for decompression. Files can be read using URLs or FileWrappers.
                   DESC

  s.homepage     = "https://github.com/clemens-schulz/Zippy"
  
  s.license      = "MIT"
  
  s.author             = { "Clemens Schulz" => "clemens@wetfish.de" }
  s.social_media_url   = "https://twitter.com/cl1993"

  s.platform     = :ios, "10.0"

  s.source       = { :git => "https://github.com/clemens-schulz/Zippy.git", :tag => "v#{s.version}" }


  s.source_files  = "Zippy"

end
