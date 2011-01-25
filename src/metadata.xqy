xquery version "1.0-ml";

(:import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";:)
import module "http://marklogic.com/util/http" at "lib/http.xqy";
declare namespace http="http://marklogic.com/util/http";
declare namespace ml="ml";
declare namespace my="local";
declare namespace error="http://marklogic.com/xdmp/error";

declare option xdmp:mapping "false";

let $method := xdmp:get-request-method()
let $uri := xdmp:get-request-field("uri")
let $db := (xdmp:get-request-field("database"), xdmp:database())[1]
let $accept := xdmp:get-request-header("Accept")
let $content-type := xdmp:get-request-header("Content-Type")
let $variants := http:string-to-variant(("application/xml", "text/hmtl", "application/xhtml+xml"))

return
	if("GET" eq $method) then
		xdmp:set-response-code(405, "Not yet implemented")
  else if("PUT" eq $method) then
  	(: TODO: Real content negotiation :)
    if ("application/vnd.marklogic.document-metadata" eq $content-type) then
      let $envelope := xdmp:get-request-body("xml")
      let $permissions as element(sec:permission)* := $envelope/ml:metadata/sec:permission
      let $collections as xs:string* := $envelope/ml:metadata/ml:collection/text()
      (: Need to delete and re-insert for this to change. Groan! :)
      let $forest-ids as xs:unsignedLong* := $envelope/ml:metadata/ml:forest/text()
      let $quality as xs:int? := $envelope/ml:metadata/ml:quality/text()
      let $properties as element()* := $envelope/ml:metadata/prop:properties/element()
      return (
      	xdmp:document-set-permissions($uri, $permissions),
				xdmp:document-set-properties($uri, $properties),
				xdmp:document-set-collections($uri, $collections),
				xdmp:set-response-code(200, "OK"),
				xdmp:add-response-header(
					"Content-Type",
					"application/vnd.marklogic.document-metadata"),
         $envelope)
    else
      xdmp:set-response-code(400, concat("I don’t know what to do with ", $content-type))
	else 
		xdmp:set-response-code(405, "Method Not Allowed")