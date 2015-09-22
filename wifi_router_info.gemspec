Gem::Specification.new do |s|
  s.name        = 'wifi_router_info'
  s.version     = '0.1.0'
  s.date        = '2015-09-22'
  s.summary     = "Get WiFi Router Information!"
  s.description = "A gem for get WiFi-Router info"
  s.authors     = ["Ge Hao"]
  s.email       = 'althoughghgh@gmail.com'
  s.files       = ["lib/wifi_router_info.rb",
                    "config.txt",
                    "macs.txt"]
  s.homepage    = 'http://although2013.com'
  s.license     = 'MIT'
  s.executables << 'rou'
end