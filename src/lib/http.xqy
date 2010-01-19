xquery version "0.9-ml"
module "http://marklogic.com/function/http"
(:~
 :
 : 
 :
 : @author Justin Makeig <a href="mailto:justin.makeig@marklogic.com">justin.makeig@marklogic.com</a>
 :)
default function namespace = "http://www.w3.org/2003/05/xpath-functions"
declare namespace http = "http://marklogic.com/function/http"

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
define function http:parse-accept-header($header as xs:string) as element(http:accept) {
	<http:accept>{
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
						if($t3[1] eq 'q') then <http:quality>{$t3[2]}</http:quality> 
						else <http:param name={$t3[1]}>{$t3[2]}</http:param>
		}</http:variant>
	}</http:accept>
}

define function http:preferred-variant($variants as element(http:variant)+) as element(http:variant)* {
	let $accept := http:parse-accept-header(xdmp:get-request-header('Accept','text/plain'))
	let $format := xdmp:get-request-field('format')
	let $acceptable-variant := $accept/http:variant[1]
	for $variant in $variants
	return
		(: First test the format query parameter :)
		if($format eq $variant/@name) then
			$variant
		(: Then check the Accept header (Outlook, for example, sends */*) :)
		else if($variant/http:media-type/http:type eq $acceptable-variant/http:media-type/http:type 
			and $variant/http:media-type/http:sub-type eq $acceptable-variant/http:media-type/http:sub-type) then $variant
		else ()
}

define function http:variant-to-string($variant as element(http:variant)*) as xs:string? {
	for $v at $i in $variant
	return 
		concat($v/http:media-type/http:type,'/',$v/http:media-type/http:sub-type)
}

define function http:string-to-variant($string as xs:string*) as element(http:variant)* {
    for $variant in $string
    let $types := tokenize($variant, "/")
    return <http:variant>
        <http:media-type>
            <http:type>{$types[1]}</http:type>
            <http:sub-type>{$types[2]}</http:sub-type>
        </http:media-type>
    </http:variant> 
}
