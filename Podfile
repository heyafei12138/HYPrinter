# Uncomment the next line to define a global platform for your project
 platform :ios, '16.0'

target 'HYPrinter' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for HYPrinter
  pod 'SnapKit', '~> 5.7.0'
  pod 'lottie-ios', '~> 4.6'
  pod 'QuicklySwift', :git => 'https://github.com/rztime/QuicklySwift.git'
  pod 'RZRichTextView'  
end
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
