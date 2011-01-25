xquery version "1.0-ml";
module namespace util="http://marklogic.com/narthex/util";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

(:
 : Centralized place to create URLs
 : 
 : @param $doc-uri The database URI of a document
 : @param root-relative Whether to start from the root of the server as opposed to an absolute URL begining with a http[s]
 : @return The server-specific URL 
 :)
declare function util:document-url($doc-uri as xs:string, $root-relative as xs:boolean) as xs:string {
	let $protocol := xdmp:get-request-protocol()
	let $host := xdmp:get-request-header("Host")
	let $root := if($root-relative) then "" else concat($protocol, "://", $host)
	return concat($root, "/documents/", encode-for-uri($doc-uri))
};
declare function util:document-url($doc-uri as xs:string) as xs:string {
	util:document-url($doc-uri, false())
};

declare function util:collection-url($coll-uri as xs:string+) as xs:string {
	util:collection-url($coll-uri, false())
};
declare function util:collection-url($coll-uris as xs:string+, $root-relative as xs:boolean) as xs:string {
	let $protocol := xdmp:get-request-protocol()
	let $host := xdmp:get-request-header("Host")
	let $root := if($root-relative) then "" else concat($protocol, "://", $host)
	let $colls := for $c in $coll-uris return encode-for-uri($c)
	return concat($root, "/collections/", string-join($colls, "+"))
};
