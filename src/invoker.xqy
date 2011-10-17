xquery version "1.0-ml";
declare namespace local="local";

declare function local:get-cookie-value($name as xs:string) as xs:string* {
	let $cookie := xdmp:get-request-header("Cookie")
	let $tokens := tokenize($cookie, "\s*;\s*")
	let $k-vs := tokenize($tokens[1], "\s*=\s*")
	return if($k-vs[1] eq $name) then $k-vs[2] else ()
};
let $_ := xdmp:log(local:get-cookie-value("db"))
let $db := xdmp:get-request-field("db", string(xdmp:database((local:get-cookie-value("db"), xdmp:database-name(xdmp:database()))[1])))
return ( 
	if(xdmp:get-request-field("db")) then xdmp:add-response-header("Set-Cookie", concat("db=", xdmp:database-name(xs:unsignedLong($db)), "; expires=Wednesday, 01-Aug-2040 08:00:00 GMT; path=/; domain=", xdmp:host-name(xdmp:host()))) else (),
	xdmp:invoke(
	  xdmp:get-request-field("_path"),
	  (),
	  <options xmlns="xdmp:eval">
	    <database>{$db}</database>
	  </options>
	)
)
