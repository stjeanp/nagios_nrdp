require 'net/http'
require 'uri'
require 'nokogiri'

module Nagios
  class Nrdp
    attr_accessor :url
    attr_accessor :token

    def initialize(args = {})
      @url = args[:url] || nil
      @token = args[:token] || nil

      if !@url || @url.empty?
        raise ArgumentError, "The URL supplied is invalid!"
      else
        begin
          the_uri = URI.parse(url)
          if !the_uri.kind_of? URI::HTTP
            raise ArgumentError, "The URL supplied is invalid!"
          end
        rescue URI::InvalidURIError
          raise ArgumentError, "The URL supplied is invalid!"
        end
      end
      if !@token || @token.empty?
        raise ArgumentError, "The token supplied is invalid!"
      end
    end

    def submit_check(*args)
      if args[0].is_a? Hash
        the_checks = [args[0]]
      else
        the_checks = args[0]
      end
      the_checks.each do |the_check|
        validate_check(the_check)
      end

      payload = build_xml(the_checks)

      the_uri = URI.parse(@url)
      http = Net::HTTP.new(the_uri.host, the_uri.port)
      if the_uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      request = Net::HTTP::Post.new(the_uri.request_uri + "/")
      request.set_form_data( { "token" => token, "cmd" => "submitcheck", "XMLDATA" => payload } )
      request['Accept'] = 'text/*'
      request['User-Agent'] = 'NrdpClient/1.0'
      response = http.request(request)

      if response.code != "200"
        raise RuntimeError, "Didn't get a 200 (" + response.code.to_s + ")"
      end

      doc = Nokogiri::XML(response.body)

      status = doc.xpath("//status").first.content.to_i
      message = doc.xpath("//message").first.content

      if status != 0
        raise RuntimeError, "Status isn't 0 (" + message + ")"
      end

      count_agrees = false
      doc.xpath("//output").each do |output|
        if output.content == "#{the_checks.count.to_s} checks processed."
          count_agrees = true
        end
      end
      if !count_agrees
        raise RuntimeError, "Not all notifications were processed!"
      end
      true
    end
    alias_method :submit_checks, :submit_check

    def submit_command(the_command = "")
      if !the_command || !the_command.is_a?(String) || the_command.empty?
        raise ArgumentError, "Invalid command supplied!"
      end

      the_uri = URI.parse(@url)
      http = Net::HTTP.new(the_uri.host, the_uri.port)
      if the_uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      query = "?token=#{token}&cmd=submitcmd&command=#{the_command}"
      request = Net::HTTP::Get.new(the_uri.request_uri + "/" + query)
      request['Accept'] = 'text/*'
      request['User-Agent'] = 'NrdpClient/1.0'
      response = http.request(request)

      if response.code != "200"
        raise RuntimeError, "Didn't get a 200 (" + response.code.to_s + ")"
      end

      doc = Nokogiri::XML(response.body)

      status = doc.xpath("//status").first.content.to_i
      message = doc.xpath("//message").first.content

      if status != 0
        raise RuntimeError, "Status isn't 0 (" + message + ")"
      end
      true
    end

    private

    def validate_check(the_check = {})
      if !the_check.keys.all? { |key| [:hostname, :servicename, :state, :output].include? key }
        raise ArgumentError, "Unknown parameters in check!"
      end
      if [:hostname, :state, :output].any? { |key| !the_check.has_key?(key) }
        raise ArgumentError, "You must provide all check details!"
      end
      if !the_check[:state].kind_of? Integer
        raise ArgumentError, "Check's state must be an integer!"
      end
    end

    def build_xml(the_checks = [])
      if the_checks.count < 1
        raise ArgumentError, "You must send at least one check!"
      end

      the_xml = "<?xml version='1.0'?>\n"
      the_xml += "<checkresults>\n"
      the_checks.each do |check|
        the_xml += "  <checkresult type='"
        the_xml += check[:servicename] ? 'service' : 'host'
        the_xml += "'>\n"
        the_xml += "    <hostname>" + check[:hostname] + "</hostname>\n"
        if check[:servicename]
          the_xml += "    <servicename>" + check[:servicename] + "</servicename>\n"
        end
        the_xml += "    <state>" + check[:state].to_s + "</state>\n"
        the_xml += "    <output>" + check[:output] + "</output>\n"
        the_xml += "  </checkresult>\n"
      end
      the_xml += "</checkresults>\n"
    end
  end
end
