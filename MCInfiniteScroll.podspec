Pod::Spec.new do |s|
  s.name         = "MCInfiniteScroll"
  s.version      = "0.0.10"
  s.summary      = "manticore-iOSInfiniteScroll provides infinite scrolling for UITableView and supports TastyPie pagnination coupled with RestKit."
  s.description  = <<-DESC
          Manticore-iOSInfiniteScroll provides infinite scrolling for UITableView and supports TastyPie pagnination coupled with RestKit.
          DESC
  s.homepage     = "https://github.com/tonyscherba/manticore-iOSInfiniteScroll"
  s.license      = 'MIT'
  s.author       = { "Richard Fung" => "richard@yetihq.com", "Anthony Scherba" => "tony@yetihq.com" }
  s.source       = { :git => "https://github.com/tonyscherba/manticore-iOSInfiniteScroll.git", :tag => "0.0.10" }
  s.platform     = :ios
  s.source_files = '*.{h,m}'
  s.requires_arc = true
  s.dependency 'RestKit', '~> 0.20'
  s.dependency 'AFNetworking-TastyPie', '~> 0.0.2'
  s.dependency 'SVPullToRefresh', '~> 0.4.1'
end
