require 'net/http'
require 'uri'
require 'nokogiri'

module Nagios
  class NrdpAlerter
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

    def send_alert(*args)
      if args[0].is_a? Hash
        the_alerts = [args[0]]
      else
        the_alerts = args[0]
      end
      the_alerts.each do |the_alert|
        validate_alert(the_alert)
      end

      payload = build_xml(the_alerts)

      the_uri = URI.parse(@url)
      http = Net::HTTP.new(the_uri.host, the_uri.port)
      if the_uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      request = Net::HTTP::Post.new(the_uri.request_uri + "/")
      request.set_form_data( { "token" => token, "cmd" => "submitcheck", "XMLDATA" => payload } )
      request['Accept'] = 'text/*'
      request['User-Agent'] = 'NrdpAlerter/1.0'
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
        if output.content == "#{the_alerts.count.to_s} checks processed."
          count_agrees = true
        end
      end
      if !count_agrees
        raise RuntimeError, "Not all notifications were processed!"
      end
      true
    end
    alias_method :send_alerts, :send_alert

    private

    def validate_alert(the_alert = {})
      if [:hostname, :state, :output].any? { |key| !the_alert.has_key?(key) }
        raise ArgumentError, "You must provide all alert details!"
      end
      if !the_alert[:state].kind_of? Integer
        raise ArgumentError, "Alert state must be an integer!"
      end
    end

    def build_xml(the_alerts = [])
      if the_alerts.count < 1
        raise ArgumentError, "You must send at least one alert!"
      end

      the_xml = "<?xml version='1.0'?>\n"
      the_xml += "<checkresults>\n"
      the_alerts.each do |alert|
        the_xml += "  <checkresult type='"
        the_xml += alert[:servicename] ? 'service' : 'host'
        the_xml += "'>\n"
        the_xml += "    <hostname>" + alert[:hostname] + "</hostname>\n"
        if alert[:servicename]
          the_xml += "    <servicename>" + alert[:servicename] + "</servicename>\n"
        end
        the_xml += "    <state>" + alert[:state].to_s + "</state>\n"
        the_xml += "    <output>" + alert[:output] + "</output>\n"
        the_xml += "  </checkresult>\n"
      end
      the_xml += "</checkresults>\n"
    end
  end
end
