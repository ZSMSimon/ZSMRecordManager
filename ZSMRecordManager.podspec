Pod::Spec.new do |s|
  s.name          = "ZSMRecordManager"
  s.version       = "1.0.0"
  s.summary       = "Recording function integration(录音功能集成)"
  s.description   = <<-DESC
                    iOS Recording function integration by Simon (iOS录音功能集成) 
                   DESC
  s.homepage      = "https://github.com/ZSMSimon/ZSMRecordManager"
  s.license       = { :type => "MIT", :file => "LICENSE" }
  s.author        = { "Simon" => "18320832089@163.com" }
  s.platform      = :ios, "8.0"
  s.source        = { :git => "https://github.com/ZSMSimon/ZSMRecordManager.git", :tag => s.version.to_s }
  s.requires_arc  = true
  s.source_files  = "RecordManager/*.{h,m}"
end