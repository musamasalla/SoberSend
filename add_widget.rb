require 'xcodeproj'

project_path = '/Users/musamasalla/Library/Mobile Documents/com~apple~CloudDocs/Cursor/New Projects/SoberSend/iOS/SoberSend/SoberSend.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if target already exists
if project.targets.find { |t| t.name == 'SoberSendWidget' }
  puts "SoberSendWidget target already exists."
  exit
end

# Find the main app target
app_target = project.targets.find { |t| t.name == 'SoberSend' }
if app_target.nil?
  puts "Could not find SoberSend target"
  exit
end

# Creating a new App Extension target from scratch is very complex via xcodeproj.
# Let's print the instructions for the user instead to do it correctly via Xcode UI.
puts "Widget configuration is safer via UI"
