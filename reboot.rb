require 'net/http'


class Router
  def initialize(host, port, name, pass, options = {})
    @http = Net::HTTP.new(host, port)
    @name = name
    @pass = pass
  end

  def reboot
    req = new_request "/userRpm/SysRebootRpm.htm?Reboot=%D6%D8%C6%F4%C2%B7%D3%C9%C6%F7"

    @http.request req do |res|
      File.open("192.html", "w") { |file| file.write res.body }
    end
  end

  #index is useless, so comment these lines
  #def index
  #  req = new_request '/'
  #  @http.request req do |res|
  #    File.open("192.html", "w") { |file| file.write res.body }
  #  end
  #end

  def status
    req = new_request "/userRpm/StatusRpm.htm"
    req['Referer'] = 'http://192.168.1.1/'
    res = @http.request req
    status = scan_js_array res.body

    s = status[0][4] % 60
    m = status[0][4] % 3600 / 60
    h = status[0][4] / 3600
    puts "当前软件版本 #{status[0][5]}"
    puts "当前硬件版本 #{status[0][6]}"
    puts "SSID号：  #{status[2][1]}"
    puts "MAC地址：  #{status[3][1]}"
    puts "IP地址： #{status[3][2]}"
    puts "上网时间：#{status[3][12]}"
    puts "运行时间：#{h}小时#{m}分#{s}秒"
  end

  def wlan_status
    req = new_request '/userRpm/WlanStationRpm.htm'
    req['Referer'] = 'http://192.168.1.1/userRpm/WlanStationRpm.htm'
    res = @http.request req
    status = scan_js_array res.body

    puts "当前所连接的主机: "
    status[1][0..-3].each_slice(7) do |s|
      puts "#{s}"
    end
  end

  def wlan_security_status
    req = new_request '/userRpm/WlanSecurityRpm.htm'
    req['Referer'] = 'http://192.168.1.1/userRpm/MenuRpm.htm'
    res = @http.request req
    status = scan_js_array res.body

    puts "WiFi密码：" + status[0][9]
  end


  private
    def new_request(path)
      req = Net::HTTP::Get.new path
      req.basic_auth @name, @pass
      req
    end

    def scan_js_array(html)
      html = html.gsub("\n", "").gsub("</script>", "\n")
      status = html.scan(/var\s+\w+\s*=new\s+Array.+\);/).map do |e|
        s = e.gsub("new Array(", "[").gsub(");", "]").gsub("var ", "").gsub("\\\"", "\"")
        eval s
      end
    end
end



router = Router.new("192.168.1.1", 80, 'admin', 'admin')
router.status
router.wlan_status
router.wlan_security_status


print "\n回车键退出..."
gets