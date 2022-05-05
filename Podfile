project 'OutRun.xcodeproj'
platform :ios, '13.0'

def app_pods
  pod 'Cache'
end

def ui_pods
  pod 'SnapKit'
  pod 'Charts'
  # pod 'JTAppleCalendar'
end

def data_pods
  pod 'CoreStore'
  pod 'CoreGPX'
end

def rx_pods
  pod 'RxSwift'
  pod 'RxCocoa'
end

target 'OutRun' do
  use_frameworks!

  app_pods
  ui_pods
  rx_pods
  data_pods

  target 'UnitTests' do
    inherit! :search_paths
  end

end