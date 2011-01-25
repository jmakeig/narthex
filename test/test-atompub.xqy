xquery version "1.0-ml";
module namespace my="my";
declare default function namespace "http://www.w3.org/2005/xpath-functions";
import module namespace ut="http://marklogic.com/test/unit" at "lib/unit-test.xqy";
declare namespace http="xdmp:http";
declare namespace error="http://marklogic.com/xdmp/error";

declare namespace atom = "http://www.w3.org/2005/Atom";

declare variable $my:HOST as xs:string := "http://localhost:6666";
declare variable $my:AUTH as element(http:authentication) := <authentication xmlns="xdmp:http">
			<username>admin</username>
			<password>admin</password>
		</authentication>;

declare function my:get-tests() as xs:QName* {
	for $test in (
		"test-post-entry",
		"test-get-entry",
		"test-get-missing"
		) return QName("my", $test)
};

declare private function my:create-entry() as xs:string {
	(: Need to do this in a separate transaction :)
	xdmp:eval('
		let $uri as xs:string := concat("/test/", xs:string(xdmp:random()), ".xml")
		return ($uri, xdmp:document-insert($uri, <test>This is a test of {$uri}</test>))
		', 
		(), 
		<options xmlns="xdmp:eval">
			<isolation>different-transaction</isolation>
			<prevent-deadlocks>true</prevent-deadlocks>
		</options>
	) 
};

declare function my:test-post-entry() as element(ut:assertion)* {
	let $uri as xs:string := concat("/test/", xs:string(xdmp:random()), ".xml")
	let $url as xs:string := concat($my:HOST, "/documents/")
	let $entry as element(atom:entry) := 
    <entry xmlns="http://www.w3.org/2005/Atom">
      <title>Atom-Powered Robots Run Amok</title>
      <id>{$uri}</id>
      <updated>2003-12-13T18:30:02Z</updated>
      <author><name>John Doe</name></author>
      <content>
      	<stuff xmlns="">Stuff should be in the empty namespace</stuff>
      </content>
    </entry>
	let $options := <options xmlns="xdmp:http">
		<headers>
			<content-type>application/atom+xml;type=entry</content-type>
			<slug>{$uri}</slug>
		</headers>
		{$my:AUTH}
		<data>{xdmp:quote($entry)}</data>
	</options>
	let $response := xdmp:http-post($url, $options)
	let $_ := xdmp:log(xdmp:node-kind($response[2]/node()))
	let $entry as element(atom:entry) := $response[2]/node()
	let $url as xs:string := concat($my:HOST, "/documents/", encode-for-uri($uri))
	return (
		ut:assert-equals(201, xs:int($response[1]/http:code)),
		ut:assert-equals($uri, data($entry/atom:id)),
		ut:assert-equals($response[1]/http:headers/http:location, $url)
	)
};

declare function my:test-get-entry() as element(ut:assertion)* {
	let $uri as xs:string := my:create-entry()
	let $url as xs:string := concat($my:HOST, "/documents/", encode-for-uri($uri))
	let $options := <options xmlns="xdmp:http">
		<headers>
			<accept>application/atom+xml;type=entry</accept>
		</headers>
		{$my:AUTH}
		<format xmlns="xdmp:document-get">xml</format>
	</options>
	let $response := xdmp:http-get($url, $options)
	let $_ := xdmp:log($response)
	let $entry as element(atom:entry) := $response[2]/atom:entry
	return (
		ut:assert-equals(200, xs:int($response[1]/http:code)),
		ut:assert-equals($uri, data($entry/atom:id))
	)
};

declare function my:test-get-missing() as element(ut:assertion)* {
	let $uri as xs:string := "somthing-that-does-not-exist"
	let $url as xs:string := concat($my:HOST, "/documents/", encode-for-uri($uri))
	let $options := <options xmlns="xdmp:http">
		<headers>
			<accept>application/atom+xml;type=entry</accept>
		</headers>
		{$my:AUTH}
		<format xmlns="xdmp:document-get">xml</format>
	</options>
	let $response := xdmp:http-get($url, $options)
	return (
		ut:assert-equals(404, xs:int($response[1]/http:code))
	)
};
