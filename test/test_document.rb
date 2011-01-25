require 'rubygems'
require 'rest_client'
require 'test/unit'
require 'xml/libxml'
require 'cgi'

class TestDocument < Test::Unit::TestCase
	def setup
		@host = 'http://localhost:6667'
		creds = { :user => 'admin', :password => 'admin' }
		@resource = RestClient::Resource.new(@host, creds) 
  end

  def teardown
    begin
      #delete_helper
    rescue RestClient::ResourceNotFound
      # okay to ignore
    end
  end

	def test_document_notfound
		assert_raises(RestClient::ResourceNotFound) {
			response = @resource["/documents/xxxxxxxx-not-found"].get
		}
	end
	
	def test_document_notfound_atom
		assert_raises(RestClient::ResourceNotFound) {
			response = @resource["/documents/xxxxxxxx-not-found"].get({:accept => "application/atom+xml;type=entry"})
		}
	end
	
	def test_document_get_xml
		uri = create_doc
		# Test it
		response = @resource["/documents/" + uri].get
		assert_equal 200, response.code
		assert_match_path "/s:stuff", XML::Document.string(response), {:s => "stuff"}
	end
	
	def test_document_get_xhtml_default
		uri = create_doc
		# Test it
		h2 = {:accept => 'foo/bar, text/html, baz/blah'}
		response = @resource["/documents/" + uri].get(h2)
		assert_equal 200, response.code
		#assert_match_path "/s:stuff", XML::Document.string(response), {:s => "stuff"}
		assert_equal "text/html", response.headers[:content_type]
	end
	
	def test_document_get_atom_entry
		uri = create_doc
		# Test it
		h2 = {:accept => 'application/atom+xml;type=entry'}
		response = @resource["/documents/" + uri].get(h2)
		assert_equal 200, response.code
		assert_equal "application/atom+xml;type=entry", response.headers[:content_type]
		resp_xml = XML::Document.string(response)
		assert_match_path "/a:entry", resp_xml, {:a => "http://www.w3.org/2005/Atom"}
		assert_equals_path "/a:entry/a:content/@type", resp_xml, "application/xml", {:a => "http://www.w3.org/2005/Atom", :s => "stuff"}
		assert_match_path "/a:entry/a:content/s:stuff", resp_xml, {:a => "http://www.w3.org/2005/Atom", :s => "stuff"}
	end
	
	def test_document_get_notacceptable
		uri = create_doc
		# Test it
		h2 = {:accept => 'foo/bar, baz/blah'}
		e = assert_raises(RestClient::RequestFailed) {
			response = @resource["/documents/" + uri].get(h2)
		}
		# This is really fucking ugly!
		assert_equal "HTTP status code 406", e.message
		#assert_match_path "/s:stuff", XML::Document.string(response), {:s => "stuff"}
		#assert_equal "text/html", response.headers[:content_type]
	end
	
	def test_document_put_xml
		headers = {:content_type => 'application/xml'}
		response = @resource["/documents/" + CGI.escape("/a/b/c/d.xml")].put('<stuff xmlns="stuff">my stuff is here</stuff>', headers)
		assert_equal 200, response.code
	end
	
	def test_document_put_xml_charset
		headers = {:content_type => 'application/xml;charset=utf-8'}
		uri = CGI.escape("/" + rand(2).to_s() + "/" + rand(10).to_s() + "/" + rand(1000000).to_s() + ".xml")
		response = @resource["/documents/" + uri].put('<stuff xmlns="stuff">my stuff is here</stuff>', headers)
		assert_equal 201, response.code
	end
	
	def test_document_put_xml_new
		headers = {:content_type => 'application/xml'}
		uri = CGI.escape("/" + rand(2).to_s() + "/" + rand(10).to_s() + "/" + rand(1000000).to_s() + ".xml")
		response = @resource["/documents/" + uri].put('<stuff xmlns="stuff">' + uri + '</stuff>', headers)
		assert_equal 201, response.code
		assert_equal @host + "/documents/" + uri, response.headers[:location]
		assert_equal "application/xml", response.headers[:content_type]
		response = @resource["/documents/" + uri].put('<stuff xmlns="stuff">' + uri + '</stuff>', headers)
		assert_equal 200, response.code
		assert_equal "application/xml", response.headers[:content_type]
	end
	
	def _test_document_put_envelope
		uri = "envelope.xml"
		headers = {:content_type => 'application/vnd.marklogic.document-envelope'}
		envelope = IO.read("test/envelope.xml")
		response = @resource["/documents/" + uri].put(envelope, headers)
		assert_equal 200, response.code
		assert_equal "application/vnd.marklogic.document-envelope", response.headers[:content_type]
		
		
		h2 = {:accept => "application/vnd.marklogic.document-envelope"}
		r2 = @resource["/documents/" + uri].get(h2)
		#print r2.to_s
		assert_match_path "/ml:envelope/ml:document/nitf", XML::Document.string(r2), {:ml => "ml"}
		# Collections
		# Quality
		# Forest
		# Permissions
	end
	
	def test_document_methodnotallowed
		uri = create_doc
		# Test it
		h2 = {:accept => 'application/xml'}
		e = assert_raises(RestClient::RequestFailed) {
			response = @resource["/documents/" + uri].post("")
		}
		assert_equal "HTTP status code 405", e.message
	end
	
	#def test_document_put_unknown_content_type
	#	
	#end
	
	def test_document_delete
		uri = create_doc
		# Test it
		@resource["/documents/" + uri].delete
		# How the hell do you test the response to a DELETE? The response looks be nil
		#assert_equal 204, response.code
		
		# Make sure it's not there. (Probably not the most comprehensive test.)
		e = assert_raises(RestClient::ResourceNotFound) {
			response = @resource["/documents/" + uri].get
		}
	end
	
	def test_document_delete_404
		uri = "Im_like_so_not_there"
		e = assert_raises(RestClient::ResourceNotFound) {
			response = @resource["/documents/" + uri].delete
		}
	end
	
	def _test_metadata_put
		uri = "meta.xml"
		@resource["/documents/" + uri].put('<stuff xmlns="stuff">' + uri + '</stuff>', {:content_type => 'application/xml'})
		# print uri
		headers = {:content_type => 'application/vnd.marklogic.document-metadata'}
		envelope = IO.read("test/metadata.xml")
		response = @resource["/documents/" + uri + "/metadata"].put(envelope, headers)
		assert_equal 200, response.code
		assert_equal "application/vnd.marklogic.document-metadata", response.headers[:content_type]
	end
####################################################################################################
	def assert_match_path(xpath, doc, ns = {})
		assert_block "Couldn't match" + xpath + " in " + doc.to_s() do
			doc.find(xpath, ns).size > 0
		end
	end
	
	def assert_equals_path(xpath, doc, value, ns = {})
		assert_block "Couldn't match " + value + " to " + xpath + " in " + doc.to_s() do
			#print doc.find(xpath, ns).first.to_s
			# TODO: I think value only applies to attributes
			doc.find(xpath, ns).first.value == value
		end
	end
	
	# Creates a random document and returns its URI
	def create_doc
		headers = {:content_type => 'application/xml'}
		uri = CGI.escape("/" + rand(2).to_s() + "/" + rand(10).to_s() + "/" + rand(1000000).to_s() + ".xml")
		response = @resource["/documents/" + uri].put('<stuff xmlns="stuff">' + uri + '</stuff>', headers)
		return uri
	end
end