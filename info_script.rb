require 'xcodeproj'
project_path = "FriendlyPix.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# Add a file to the project in the main group
file_name = 'GoogleService-Info.plist'
file = project.new_file(file_name)

# Add the file to the all targets
project.targets.each do |target|
  target.add_file_references([file])
end

#save project
project.save()
