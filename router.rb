require 'net/http'
require 'time'


class Router
  def initialize(host, port, name, pass, options = {})
    @http = Net::HTTP.new(host, port)
    @name = name
    @pass = pass
    @internet = false

    @know_macs = load_know_mac
    @my_macs = load_my_mac
  end

  def reboot
    req = new_request "/userRpm/SysRebootRpm.htm?Reboot=%D6%D8%C6%F4%C2%B7%D3%C9%C6%F7"
    req['Referer'] = "http://192.168.1.1/userRpm/SysRebootRpm.htm"

    @http.request req
  end

  def status
    req = new_request "/userRpm/StatusRpm.htm"
    req['Referer'] = 'http://192.168.1.1/'
    res = @http.request req
    status = scan_js_array res.body

    @internet = true if internet_connected?(status[3])

    s = status[0][4] % 60
    m = status[0][4] % 3600 / 60
    h = status[0][4] / 3600
    puts "软件版本  #{status[0][5]}"
    puts "硬件版本  #{status[0][6]}"
    puts "SSID号：  #{status[2][1]}"
    puts "MAC地址： #{status[3][1]}"
    puts "IP地址：  #{status[3][2]}"
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
      if @my_macs.include? s[0]
        puts "#{s[0]} 正在使用的设备"
      elsif x = @know_macs.find {|h| h[:value] == s[0]}
        puts "#{s[0]} #{x[:name]}"
      else
        puts s[0]
      end
    end
  end

  def wlan_security_status
    req = new_request '/userRpm/WlanSecurityRpm.htm'
    req['Referer'] = 'http://192.168.1.1/userRpm/MenuRpm.htm'
    res = @http.request req
    status = scan_js_array res.body

    puts "WiFi密码：" + status[0][9]
  end

  def internet?
    @internet
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

    def internet_connected?(s)
      ((Time.parse s[12]) > (Time.parse "00:00:00")) || s[2][0] != "0"
    end

    def load_know_mac
      File.foreach("macs.txt").map do |line|
        a = line.force_encoding("UTF-8").split
        {:name => a[1], :value => a[0]}
      end
    end

    def load_my_mac
      str = `getmac /v`
      str = str.encode(Encoding.find("UTF-8"),Encoding.find("GBK"))
      str.scan(/无线.+((?:\w\w-){5}\w\w)/).map{ $1 }
    end

end



router = Router.new("192.168.1.1", 80, 'admin', 'admin')
router.status
router.wlan_status
router.wlan_security_status

puts "\n#{router.internet? ? "Fly on Internet!" : "NO Internet!"}"



if not router.internet?
  puts "\n....REBOOTING...."
  router.reboot
  20.times do
    print "."
    sleep(0.3)
  end
else
  print "\n回车键退出..."
  gets
end

