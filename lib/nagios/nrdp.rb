require 'net/http'
require 'uri'
require 'nokogiri'

# The parent, trying to keep the class tree clean
module Nagios
  # Implements an interface to Nagios NRDP to facilitate submitting check
  # results and commands
  #
  # @see https://assets.nagios.com/downloads/nrdp/docs/NRDP_Overview.pdf
  class Nrdp
    # @!attribute [rw] url
    #   The URL of the NRDP endpoint
    #   @return [String] the URL of the NRDP endpoint
    attr_accessor :url
    # @!attribute [rw] token
    #   The authentication token
    #   @return [String] the authentication token
    attr_accessor :token

    # Create a new instance of Nagios::Nrdp and set the URL and token
    #
    # @param [Hash] args parameters for this instance
    # @option args [String] :url the URL of the NRDP endpoint
    # @option args [String] :token the authentication token
    #
    # @raise [ArgumentError] when the args fail validation
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

    # @overload submit_check(the_check)
    #   Submit a single passive check result
    #   @param [Hash] the_check the passive check result data
    #   @option the_check [String] :hostname The hostname for this passive check
    #   @option the_check [String] :servicename The optional service name for this passive check
    #   @option the_check [Integer] :state The state of this passive check
    #   @option the_check [String] :output The output of this passive check
    #   @raise [RuntimeError] when the submission fails
    # @overload submit_check(the_checks)
    #   @param [Array<Hash>] the_checks an array of passive check results
    #   @raise [RuntimeError] when the submission fails
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

    # Submit a Nagios command
    #
    # @param [String] the_command the command to be submitted
    #
    # @raise [ArgumentError] when the args fail validation
    # @raise [RuntimeError] when the submission fails
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

    # Validate the supplied check's data
    #
    # @api private
    #
    # @param [Hash] the_check the passive check result data
    # @option the_check [String] :hostname The hostname for this passive check
    # @option the_check [String] :servicename The optional service name for this passive check
    # @option the_check [Integer] :state The state of this passive check
    # @option the_check [String] :output The output of this passive check
    #
    # @raise [ArgumentError] when validation fails
    def validate_check(the_check = {})
      fail ArgumentError, 'Unknown parameters in check!' unless the_check.keys.all? { |key| [:hostname, :servicename, :state, :output].include? key }
      if [:hostname, :state, :output].any? { |key| !the_check.key?(key) }
        fail ArgumentError, 'You must provide all check details!'
      end
      fail ArgumentError, "Check's state must be an integer!" unless the_check[:state].is_a? Integer
    end

    # Create the XML document containing the passive check results
    #
    # @param [Array<Hash>] the_checks the array of passive check results
    #
    # @return [String] the XML document to be submitted
    #
    # @raise [ArgumentError] when the checks aren't valid
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
