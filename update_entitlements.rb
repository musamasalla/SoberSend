require 'xcodeproj'

project_path = 'SoberSend.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. Main App
app_target = project.targets.find { |t| t.name == 'SoberSend' }
if app_target
  app_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'SoberSend/SoberSend.entitlements'
  end
end

# 2. Widget
widget_target = project.targets.find { |t| t.name == 'SoberSendWidgetExtension' }
if widget_target
  widget_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'SoberSendWidget/SoberSendWidget.entitlements'
  end
end

# 3. Shield Config
shield_config = project.targets.find { |t| t.name == 'SoberSendShieldConfig' }
if shield_config
  shield_config.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'SoberSendShieldConfig/SoberSendShieldConfig.entitlements'
  end
end

# 4. Shield Action
shield_action = project.targets.find { |t| t.name == 'SoberSendShieldAction' }
if shield_action
  shield_action.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'SoberSendShieldAction/SoberSendShieldAction.entitlements'
  end
end

project.save
puts "Successfully updated Entitlements settings in SoberSend.xcodeproj for all targets"
