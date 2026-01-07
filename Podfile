platform :ios, '13.0'

target 'FridgeMind' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Networking
  pod 'AFNetworking'

  # Layout
  pod 'Masonry'

  # JSON Mapping
  pod 'YYModel'
  
  # Image Loading
  pod 'SDWebImage'

end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
  end
end
