xquery version "1.0-ml";
module namespace http-util="http://marklogic.com/util/http";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace http="xdmp:http";


declare function http-util:parse-request() as item()+ {
	(<request xmlns="xdmp:http">
		<url>{xdmp:get-request-url()}</url>
		<path>{xdmp:get-request-path()}</path>
		<method>{xdmp:get-request-method()}</method>
		<username>{xdmp:get-request-username()}</username>
		<address>{xdmp:get-request-client-address()}</address>
		<headers>{
			for $h in xdmp:get-request-header-names()
			return element {xs:QName($h)} {
				xdmp:get-request-header($h)
			}
		}</headers>
		<fields>{
			for $f in xdmp:get-request-field-names()
			return element {QName("xdmp:http", $f)} {
				xdmp:get-request-field($f)
			}
		}</fields>
	</request>,
	xdmp:get-request-body())
};


(:~
 : Parses an Accept HTTP header into something like:
	<accept xmlns="http://marklogic.com/http">
		<variant order="1">
			<media-type><!-- required -->
				<type>text</type><!-- defaults to '*' -->
				<sub-type>plain</sub-type><!-- defaults to '*' -->
				<charset>utf-8</charset><!-- optional -->
			</media-type>
			<quality>0.7</quality><!-- defaults to 1.0 -->
			<param name="foo">bar</param><!-- 0 to many -->
		</variant>
		<variant>
			
		</variant>
	</accept>
 :
 : @param $
 : @return
 :)
declare function http-util:parse-accept-header($header as xs:string) as element(http:variants) {
	<http:variants>{
		for $t1 at $i in tokenize($header, '\s*,\s*')
		return <http:variant order={$i}>{
			for $t2 at $j in tokenize($t1, '\s*;\s*')
			return 
				if($j eq 1) then
					<http:media-type>{
						let $media-type := tokenize($t2,'/')
						return (
							<http:type>{$media-type[1]}</http:type>,
							<http:sub-type>{$media-type[2]}</http:sub-type>
						)
					}</http:media-type>
				else 
					let $t3 := tokenize($t2, '\s*=\s*')
					return
						if($t3[1] eq 'q') then <http:quality>{functx:trim($t3[2])}</http:quality> 
						else <http:param name={$t3[1]}>{functx:trim($t3[2])}</http:param>
		}</http:variant>
	}</http:variants>
};

declare function http-util:preferred-variant($accept as element(http:variants), $variants as element(http:variant)+) as element(http:variant)* {
	(:let $_ := xdmp:log($accept/http:variant[http:media-type/http:type eq "application" and http:media-type/http:sub-type eq "xml"]):)
	(:let $_ := xdmp:log($accept):)
	let $matches := 
		for $v in $variants
		(: TODO: Implement wildcard matching and ordering :)
		let $candidates := $accept/http:variant
			[
				(http:media-type/http:type eq data($v/http:media-type/http:type) or 
				"*" eq data(http:media-type/http:type)) 
				and 
				(http:media-type/http:sub-type eq data($v/http:media-type/http:sub-type) or
				 "*" eq data(http:media-type/http:sub-type))
			]
		return
			for $c in $candidates 
			return <match score="{(data($c/http:quality), 1.0)[1]}" is-wildcard="{count($c/http:media-type/(http:type|http:sub-type)[. eq "*"])}">{
				$v
			}</match>
	let $preferred := (
		for $m in $matches 
		order by xs:float($m/@score) descending, 
			xs:int($m/@is-wildcard) ascending,
			xs:int($m/http:variant/@order) ascending
		return $m
	)[1]/http:variant
	return $preferred
};

declare function http-util:variant-to-string($variant as element(http:variant)*) as xs:string? {
	for $v at $i in $variant
	return 
		concat($v/http:media-type/http:type,'/',$v/http:media-type/http:sub-type)
};

declare function http-util:string-to-variant($string as xs:string*) as element(http:variant)* {
    for $variant in $string
    let $media-params := tokenize($variant, "\s*;\s*")
    let $types := tokenize($media-params[1], "/")
    return <http:variant>
			<http:media-type>
				<http:type>{$types[1]}</http:type>
				<http:sub-type>{$types[2]}</http:sub-type>
			</http:media-type>{
				for $param in subsequence($media-params, 2)
				let $equal := tokenize($param, "\s*=\s*")
				return <http:param name="{$equal[1]}">{$equal[2]}</http:param>
			}
		</http:variant> 
};




declare function http-util:prepare-response($response as item()+, $advice as xdmp:function) as item() {
	http-util:prepare-response(xdmp:apply($advice, $response))
};


(:
(
<response xmlns="xdmp:http">
  <code>200</code>
  <message>OK</message>
  <headers>
    <date>Wed, 20 Jan 2010 07:21:56 GMT</date>
    <server>Apache</server>
    <accept-ranges>bytes</accept-ranges>
    <cache-control>max-age=60, private, private</cache-control>
    <expires>Wed, 20 Jan 2010 07:22:52 GMT</expires>
    <content-type>text/html</content-type>
    <vary>User-Agent,Accept-Encoding</vary>
    <content-length>108906</content-length>
    <connection>close</connection>
  </headers>
</response>,
...body...
)
:)
declare function http-util:prepare-response($response as item()+) as item() {
	let $meta as element(http:response) := $response[1]/http:response
	let $body as item()? := $response[2]
	return (
		xdmp:set-response-code(xs:int($meta/http:code), data($meta/http:message)),
		for $h in $response/http:headers/http:*
		return xdmp:add-response-header(local-name($h), data($h)),
		$response[2]
	)
};
