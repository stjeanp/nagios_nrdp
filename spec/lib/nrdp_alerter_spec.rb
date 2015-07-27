require 'nagios/nrdp_alerter'
require 'webmock/rspec'

describe Nagios::NrdpAlerter do
  it "should raise an error without no args" do
    expect { @alerter = Nagios::NrdpAlerter.new }.to raise_error(ArgumentError)
  end

  it "should raise an error without a token" do
    expect { @alerter = Nagios::NrdpAlerter.new(:url => "http://localhost/nrdp") }.to raise_error(ArgumentError)
  end

  it "should raise an error without a URL" do
    expect { @alerter = Nagios::NrdpAlerter.new(:token => "foobar") }.to raise_error(ArgumentError)
  end

  it "should raise an error with an invalid URL" do
    expect { @alerter = Nagios::NrdpAlerter.new(:url => "httq::\\/localhost/nrdp", :token => "foobar") }.to raise_error(ArgumentError)
  end

  it "should raise an error with an invalid token" do
    expect { @alerter = Nagios::NrdpAlerter.new(:url => "http://localhost/nrdp", :token => "") }.to raise_error(ArgumentError)
  end

  it "#initialize" do
    expect(Nagios::NrdpAlerter.new(:url => "http://localhost/nrdp", :token => "foobar")).to be_an_instance_of Nagios::NrdpAlerter
  end

  it "#send_alert, single, successful" do
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
    alerter = Nagios::NrdpAlerter.new(:url => "http://localhost/nrdp", :token => "foobar")
    alerter.send_alert(:hostname => "foobar", :state => 0, :output => "UP")
  end

  it "#send_alert, single, failed" do
    body = <<-EOXML
<result>
  <status>-1</status>
  <message>NO DATA</message>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    alerter = Nagios::NrdpAlerter.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { alerter.send_alert(:hostname => "foobar", :state => 0, :output => "UP") }.to raise_error(RuntimeError)
  end

  it "#send_alert, single, wrong count" do
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
    alerter = Nagios::NrdpAlerter.new(:url => "http://localhost/nrdp", :token => "foobar")
    expect { alerter.send_alert(:hostname => "foobar", :state => 0, :output => "UP") }.to raise_error(RuntimeError)
  end

  it "#send_alert, multiple, successful" do
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
    alerter = Nagios::NrdpAlerter.new(:url => "http://localhost/nrdp", :token => "foobar")
    alerts = [ { :hostname => "foobar", :servicename => "the_service", :state => 1, :output => "testing" },
               { :hostname => "foobarbaz", :state => 0, :output => "moar testing" } ]
    alerter.send_alerts(alerts)
  end

  it "#send_alert, multiple, failed" do
    body = <<-EOXML
<result>
  <status>-1</status>
  <message>BAD XML</message>
</result>
EOXML
    stub_request(:post, "http://localhost/nrdp/").to_return(:body => body, :status => 200)
    alerter = Nagios::NrdpAlerter.new(:url => "http://localhost/nrdp", :token => "foobar")
    alerts = [ { :hostname => "foobar", :servicename => "the_service", :state => 1, :output => "testing" },
               { :hostname => "foobarbaz", :state => 0, :output => "moar testing" } ]
    expect { alerter.send_alert(alerts) }.to raise_error(RuntimeError)
  end

  it "#send_alert, multiple, wrong count" do
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
    alerter = Nagios::NrdpAlerter.new(:url => "http://localhost/nrdp", :token => "foobar")
    alerts = [ { :hostname => "foobar", :servicename => "the_service", :state => 1, :output => "testing" },
               { :hostname => "foobarbaz", :state => 0, :output => "moar testing" } ]
    expect { alerter.send_alert(alerts) }.to raise_error(RuntimeError)
  end
end
