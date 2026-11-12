Pod::Spec.new do |s|
  s.name             = 'ZHHCarouselView'
  s.version          = '1.1.0'
  s.summary          = '纯 Swift 轮播视图，支持无限循环、自动播放、多种布局与页间滚动进度。'

  s.description      = <<-DESC
ZHHCarouselView 提供可配置的轮播分页视图：无限循环、自动滚动、普通 / 线性缩放 / 封面流布局，
配套 ZHHPageControl 分页指示器，以及页间连续滚动进度（from / to / progress）回调。
通过 DataSource / Delegate 驱动 Cell 与布局参数。
                       DESC

  s.homepage         = 'https://github.com/yue5yueliang/ZHHCarouselView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '桃色三岁' => '136769890@qq.com' }
  s.source           = { :git => 'https://github.com/yue5yueliang/ZHHCarouselView.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_versions = ['5.5']
  s.frameworks = 'UIKit'

  # 隐私清单：不采集、不追踪、无 Required Reason API；resource_bundles 避免覆盖宿主 App 清单
  s.resource_bundles = {
    'ZHHCarouselView' => ['ZHHCarouselView/PrivacyInfo.xcprivacy']
  }

  # 默认 Source subspec：Development Pods 里单独一组源码树
  s.default_subspec = 'Source'

  s.subspec 'Source' do |ss|
    ss.source_files = 'ZHHCarouselView/Classes/**/*'
  end
end
