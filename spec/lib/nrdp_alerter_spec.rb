require 'nagios/nrdp'
require 'webmock/rspec'

describe Nagios::Nrdp do
  it "#initialize should raise an error without no args" do
    expect { nrdp = Nagios::Nrdp.new }.to raise_error(ArgumentError)
  end

  it "#initialize should raise an error without a token" do
    expect { nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp") }.to raise_error(ArgumentError)
  end

  it "#initialize should raise an error without a URL" do
    expect { nrdp = Nagios::Nrdp.new(:token => "foobar") }.to raise_error(ArgumentError)
  end

  it "#initialize should raise an error with an invalid URL" do
    expect { nrdp = Nagios::Nrdp.new(:url => "httq::\\/localhost/nrdp", :token => "foobar") }.to raise_error(ArgumentError)
  end

  it "#initialize should raise an error with an invalid token" do
    expect { nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "") }.to raise_error(ArgumentError)
  end

  it "#initialize" do
    expect(Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")).to be_an_instance_of Nagios::Nrdp
  end

  it "#submit_check should alert on missing hostname parameter" do
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { nrdp.submit_check(:state => 0, :output => "UP") }.to raise_error(ArgumentError)
  end

  it "#submit_check should alert on missing state parameter" do
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { nrdp.submit_check(:hostname => "foobar", :output => "UP") }.to raise_error(ArgumentError)
  end

  it "#submit_check should alert on missing output parameter" do
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { nrdp.submit_check(:hostname => "foobar", :state => 0) }.to raise_error(ArgumentError)
  end

  it "#submit_check should alert on unknown parameter" do
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { nrdp.submit_check(:hostname => "foobar", :state => 0, :output => "UP", :blarg => "blop") }.to raise_error(ArgumentError)
  end

  it "#submit_check, single, host, successful" do
    body = <<-EOXML
<result>
  <status>0</status>
  <message>OK</message>
    <meta>
       <output>1 checks processed.</output>
    </meta>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    nrdp.submit_check(:hostname => "foobar", :state => 0, :output => "UP")
    WebMock.reset!
  end

  it "#submit_check, single, service, successful" do
    body = <<-EOXML
<result>
  <status>0</status>
  <message>OK</message>
    <meta>
       <output>1 checks processed.</output>
    </meta>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    nrdp.submit_check(:hostname => "foobar", :servicename => "something", :state => 0, :output => "UP")
    WebMock.reset!
  end

  it "#submit_check, single, host, failed" do
    body = <<-EOXML
<result>
  <status>-1</status>
  <message>NO DATA</message>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { nrdp.submit_check(:hostname => "foobar", :state => 0, :output => "UP") }.to raise_error(RuntimeError)
    WebMock.reset!
  end

  it "#submit_check, single, service, failed" do
    body = <<-EOXML
<result>
  <status>-1</status>
  <message>NO DATA</message>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { nrdp.submit_check(:hostname => "foobar", :servicename => "blarg", :state => 0, :output => "UP") }.to raise_error(RuntimeError)
    WebMock.reset!
  end

  it "#submit_check, single, wrong count" do
    body = <<-EOXML
<result>
  <status>0</status>
  <message>OK</message>
    <meta>
       <output>2 checks processed.</output>
    </meta>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { nrdp.submit_check(:hostname => "foobar", :state => 0, :output => "UP") }.to raise_error(RuntimeError)
    WebMock.reset!
  end

  it "#submit_check, multiple, all host, successful" do
    body = <<-EOXML
<result>
  <status>0</status>
  <message>OK</message>
    <meta>
       <output>2 checks processed.</output>
    </meta>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    checks = [ { :hostname => "foobar", :state => 1, :output => "testing" },
               { :hostname => "foobarbaz", :state => 0, :output => "moar testing" } ]
    nrdp.submit_check(checks)
    WebMock.reset!
  end

  it "#submit_check, multiple, all service, successful" do
    body = <<-EOXML
<result>
  <status>0</status>
  <message>OK</message>
    <meta>
       <output>2 checks processed.</output>
    </meta>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    checks = [ { :hostname => "foobar", :servicename => "the_service", :state => 1, :output => "testing" },
               { :hostname => "foobarbaz", :servicename => "another_service", :state => 0, :output => "moar testing" } ]
    nrdp.submit_check(checks)
    WebMock.reset!
  end

  it "#submit_check, multiple, mixed host/service, successful" do
    body = <<-EOXML
<result>
  <status>0</status>
  <message>OK</message>
    <meta>
       <output>2 checks processed.</output>
    </meta>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    checks = [ { :hostname => "foobar", :servicename => "the_service", :state => 1, :output => "testing" },
               { :hostname => "foobarbaz", :state => 0, :output => "moar testing" } ]
    nrdp.submit_check(checks)
    WebMock.reset!
  end

  it "#submit_check, multiple, failed" do
    body = <<-EOXML
<result>
  <status>-1</status>
  <message>BAD XML</message>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    checks = [ { :hostname => "foobar", :servicename => "the_service", :state => 1, :output => "testing" },
               { :hostname => "foobarbaz", :state => 0, :output => "moar testing" } ]
    expect { nrdp.submit_check(checks) }.to raise_error(RuntimeError)
    WebMock.reset!
  end

  it "#submit_check, multiple, wrong count" do
    body = <<-EOXML
<result>
  <status>0</status>
  <message>OK</message>
    <meta>
       <output>3 checks processed.</output>
    </meta>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    checks = [ { :hostname => "foobar", :servicename => "the_service", :state => 1, :output => "testing" },
               { :hostname => "foobarbaz", :state => 0, :output => "moar testing" } ]
    expect { nrdp.submit_check(checks) }.to raise_error(RuntimeError)
    WebMock.reset!
  end

  it "#submit_command should alert on missing command" do
    nrdp = Nagios::Nrdp.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { nrdp.submit_command }.to raise_error(ArgumentError)
  end
end
