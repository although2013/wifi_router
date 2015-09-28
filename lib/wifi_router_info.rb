require 'net/http'
require 'time'

class Router
  def initialize params
    @http = Net::HTTP.new(params[:host], params[:port])
    @name = params[:name]
    @pass = params[:pass]
    @internet = false

    @know_macs = load_know_mac
    @my_macs = load_my_mac
  end

  def reboot
    req = new_request "/userRpm/SysRebootRpm.htm?Reboot=%D6%D8%C6%F4%C2%B7%D3%C9%C6%F7"
    req['Referer'] = "http://#{@http.address}/userRpm/SysRebootRpm.htm"

    @http.request req
  end

  def status
    status = get_status "/userRpm/StatusRpm.htm"
    @internet = true if internet_connected?(status[3])
    status
  end

  def wlan_status
    get_status "/userRpm/WlanStationRpm.htm"
  end

  def wlan_security_status
    get_status "/userRpm/WlanSecurityRpm.htm"
  end

  def system_statistic
    get_status "/userRpm/SystemStatisticRpm.htm"
  end

  def status_print
    status   = status()
    w_status = wlan_status()
    s_status = wlan_security_status()
    sys_s    = system_statistic()


    s = status[0][4] % 60
    m = status[0][4] % 3600 / 60
    h = status[0][4] / 3600
    #puts "软件版本  #{status[0][5]}"
    puts "硬件版本  #{status[0][6]}"
    puts "SSID号：  #{status[2][1]}"
    puts "MAC地址： #{status[3][1]}"
    puts "IP地址：  #{status[3][2]}"
    puts "上网时间：#{status[3][12]}"
    puts "运行时间：#{h}小时#{m}分#{s}秒"


    puts "当前所连接的主机: "
    puts "MAC地址            下载    上传    下载速度  上传速度\n"
    w_status[1][0..-3].each_slice(7) do |s|
      print s[0]

      sys_s[0].each_with_index do |e, i|
        if e == s[0]
          print "  "
          printf("%-8s", size_of_bits(sys_s[0][i+1], ""))
          printf("%-8s", size_of_bits(sys_s[0][i+2], ""))
          printf("%-10s", size_of_bits(sys_s[0][i+3], "/s"))
          printf("%-10s", size_of_bits(sys_s[0][i+4], "/s"))
          break
        end
      end

      if @my_macs.include? s[0]
        print "正在使用的设备"
      elsif x = @know_macs.find {|h| h[:value] == s[0]}
        print "#{x[:name]}"
      end

      print "\n"
    end

    puts "WiFi密码：" + s_status[0][9]
  end


  def internet?
    @internet
  end


  private
    def new_request path
      req = Net::HTTP::Get.new path
      req.basic_auth @name, @pass
      req
    end

    def scan_js_array html
      html = html.gsub("\n", "").gsub("</script>", "\n")
      status = html.scan(/var\s+\w+\s*=new\s+Array.+\);/).map do |e|
        s = e.gsub("new Array(", "[").gsub(");", "]").gsub("var ", "").gsub("\\\"", "\"")
        eval s
      end
    end

    def internet_connected? s
      ((Time.parse s[12]) > (Time.parse "00:00:00")) || s[2][0] != "0"
    end

    def load_know_mac
      File.foreach("macs.txt").map do |line|
        a = line.force_encoding("UTF-8").split
        {:name => a[1], :value => a[0]}
      end
    end

    def load_my_mac
      #OS windows or *nix
      if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
        str = `getmac /v`
        str = str.encode("UTF-8", "GBK")
        str.scan(/(?:\w\w-){5}\w\w/)
      else
        str = `ifconfig`
        str.scan(/(?:\w\w:){5}\w\w/).map {|mac| mac.gsub(":", "-").upcase }
      end
    end

    def get_status path
      req = new_request path
      req['Referer'] = "http://#{@http.address}#{path}"
      res = @http.request req
      scan_js_array res.body
    end

    def size_of_bits(bits, per_second)
      bits = bits.to_f
      case bits
      when 0...1024
        bits.round(0).to_s             + "B"  + per_second
      when 1024...(1024**2)
        (bits/1024).round(0).to_s      + "KB" + per_second
      when (1024**2)...(1024**3)
        (bits/(1024**2)).round(1).to_s + "MB" + per_second
      else
        (bits/(1024**3)).round(2).to_s + "GB" + per_second
      end
    end

end
