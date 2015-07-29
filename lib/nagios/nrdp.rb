require 'net/http'
require 'uri'
require 'nokogiri'

module Nagios
  # Implements an interface to Nagios NRDP to facilitate submitting check
  # results and commands
  class Nrdp
    attr_accessor :url
    attr_accessor :token

    def initialize(args = {})
      @url = args[:url] || nil
      @token = args[:token] || nil

      fail ArgumentError, 'The URL supplied is invalid!' unless @url && !@url.empty?
      begin
        the_uri = URI.parse(url)
        fail ArgumentError, 'The URL supplied is invalid!' unless the_uri.is_a? URI::HTTP
      rescue URI::InvalidURIError
        raise ArgumentError, 'The URL supplied is invalid!'
      end
      fail ArgumentError, 'The token supplied is invalid!' unless @token && !@token.empty?
    end

    def submit_check(*args)
      if args[0].is_a? Hash
        the_checks = [args[0]]
      else
        the_checks = args[0]
      end

      payload = build_xml(the_checks)

      the_uri = URI.parse(@url)
      http = Net::HTTP.new(the_uri.host, the_uri.port)
      if the_uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      request = Net::HTTP::Post.new(the_uri.request_uri + '/')
      request.set_form_data(token: token, cmd: 'submitcheck', XMLDATA: payload)
      request['Accept'] = 'text/*'
      request['User-Agent'] = 'NrdpClient/1.0'
      response = http.request(request)

      if response.code != '200'
        fail "Didn't get a 200 (" + response.code.to_s + ')'
      end

      doc = Nokogiri::XML(response.body)

      status = doc.xpath('//status').first.content.to_i
      message = doc.xpath('//message').first.content

      fail "Status isn't 0 (" + message + ')' unless status == 0

      count_agrees = false
      doc.xpath('//output').each do |output|
        if output.content == "#{the_checks.count} checks processed."
          count_agrees = true
        end
      end
      fail 'Not all notifications were processed!' unless count_agrees
      true
    end
    alias_method :submit_checks, :submit_check

    def submit_command(the_command = '')
      if !the_command || !the_command.is_a?(String) || the_command.empty?
        fail ArgumentError, 'Invalid command supplied!'
      end

      the_uri = URI.parse(@url)
      http = Net::HTTP.new(the_uri.host, the_uri.port)
      if the_uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      query = "?token=#{token}&cmd=submitcmd&command=#{the_command}"
      request = Net::HTTP::Get.new(the_uri.request_uri + '/' + query)
      request['Accept'] = 'text/*'
      request['User-Agent'] = 'NrdpClient/1.0'
      response = http.request(request)

      if response.code != '200'
        fail "Didn't get a 200 (" + response.code.to_s + ')'
      end

      doc = Nokogiri::XML(response.body)

      status = doc.xpath('//status').first.content.to_i
      message = doc.xpath('//message').first.content

      fail "Status isn't 0 (" + message + ')' unless status == 0
      true
    end

    private

    def validate_check(the_check = {})
      fail ArgumentError, 'Unknown parameters in check!' unless the_check.keys.all? { |key| [:hostname, :servicename, :state, :output].include? key }
      if [:hostname, :state, :output].any? { |key| !the_check.key?(key) }
        fail ArgumentError, 'You must provide all check details!'
      end
      fail ArgumentError, "Check's state must be an integer!" unless the_check[:state].is_a? Integer
    end

    def build_xml(the_checks = [])
      if the_checks.nil? || the_checks.count < 1
        fail ArgumentError, 'You must send at least one check!'
      end

      the_xml = "<?xml version='1.0'?>\n"
      the_xml += "<checkresults>\n"
      the_checks.each do |check|
        validate_check(check)
        the_xml += "  <checkresult type='"
        the_xml += check[:servicename] ? 'service' : 'host'
        the_xml += "'>\n"
        the_xml += '    <hostname>' + check[:hostname] + "</hostname>\n"
        if check[:servicename]
          the_xml += '    <servicename>' + check[:servicename] + "</servicename>\n"
        end
        the_xml += '    <state>' + check[:state].to_s + "</state>\n"
        the_xml += '    <output>' + check[:output] + "</output>\n"
        the_xml += "  </checkresult>\n"
      end
      the_xml += "</checkresults>\n"
    end
  end
end
