xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module "http://marklogic.com/util/http" at "lib/http.xqy";
declare namespace http="http://marklogic.com/util/http";
declare namespace ml="ml";
declare namespace my="local";
declare namespace error="http://marklogic.com/xdmp/error";

let $method as xs:string := (xdmp:get-request-field("x-method-override"), xdmp:get-request-method())[1]
let $accept as xs:string := xdmp:get-request-header("Accept")
let $db := (xdmp:get-request-field("database"), xdmp:database())[1]

return if("GET" eq $method) then
	if("application/xml" eq $accept) then
		(xdmp:add-response-header("Content-Type", "application/xml"),
			<ml:collections>{
				for $coll in cts:collections()
				return <ml:link href="/collections/{$coll}"/>
			}</ml:collections>
		)
	else
		(xdmp:add-response-header("Content-Type", "text/html"),
		'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
			<html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <title>Collections</title>
            <link type="text/css" rel="stylesheet" href="/assets/base.css"/>
            <link type="text/css" rel="stylesheet" href="/assets/documents.css"/>
            <script type="text/javascript" src="/assets/yui-min.js">//</script>
        </head>
        <body>
            <h1>Collections</h1>
			<ul>{
				for $coll in cts:collections()
				return <li><a href="/collections/{encode-for-uri($coll)}">{$coll}</a></li>
			}</ul>
			</body>
			</html>
		)
else xdmp:set-response-code(405, "Method not allowed")