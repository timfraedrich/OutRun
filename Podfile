project 'OutRun.xcodeproj'
platform :ios, '13.0'

def ui_pods
  pod 'SnapKit'
  pod 'Charts'
  # pod 'JTAppleCalendar'
end

def data_pods
  pod 'Cache'
  pod 'CombineExt'
  pod 'CoreStore'
  pod 'CoreGPX'
end

target 'OutRun' do
  use_frameworks!

  ui_pods
  data_pods

  target 'UnitTests' do
    inherit! :search_paths
  end

end