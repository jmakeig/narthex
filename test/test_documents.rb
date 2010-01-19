require 'rubygems'
require 'rest_client'
require 'test/unit'
require 'xml/libxml'

class TestDocument < Test::Unit::TestCase
	def setup
		host = 'http://localhost:6667'
		creds = { :user => 'admin', :password => 'admin' }
		@resource = RestClient::Resource.new(host, creds) 
  end

  def teardown
    begin
      #delete_helper
    rescue RestClient::ResourceNotFound
      # okay to ignore
    end
  end
	
	def test_post_xquery_text
		headers = {:content_type => "application/xquery+xml", :accept => "text/plain"}
		response = @resource["/documents"].post("'Hello, world!'", headers)
		# Get back the right answer
		assert_equal "Hello, world!", response
		# Of the right type
		assert_equal "text/plain", response.headers[:content_type]
	end
	
	def test_post_xquery_xml
		headers = {:content_type => "application/xquery+xml", :accept => "application/xml"}
		response = @resource["/documents"].post("element asdf {}", headers)
		# Get back the right answer
		assert_match_path "/asdf", XML::Document.string(response)
		# Of the right type
		assert_equal "application/xml", response.headers[:content_type]
	end
	
	def test_get_search
		headers = {:accept => "text/html"}
		response = @resource["/documents?q=stuff"].get(headers)
	end
	
	
	def assert_match_path(xpath, doc, ns = {})
		assert_block "Couldn't match" + xpath + " in " + doc.to_s() do
			doc.find(xpath, ns).size > 0
		end
	end
	
	# Creates a random document and returns its URI
	def create_doc
		headers = {:content_type => 'application/xml'}
		uri = "/" + rand(2).to_s() + "/" + rand(10).to_s() + "/" + rand(1000000).to_s() + ".xml"
		response = @resource["/document.xqy?uri=" + uri].put('<stuff xmlns="stuff">' + uri + '</stuff>', headers)
		return uri
	end
end