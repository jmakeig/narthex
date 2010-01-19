(: Copyright 2009 Mark Logic Corporation.  All Rights  Reserved. :)
xquery version "1.0-ml";
import module namespace fx="http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

let $url := xdmp:get-request-url()
let $tokens := tokenize($url, "\?") (: relies on correct URL encoding :)
let $path := $tokens[1] (: less the query params :)
let $search := $tokens[2] (: only the query params :)
let $accept := xdmp:get-request-header("Accept")
let $content-type := xdmp:get-request-header("Content-Type")

let $new-url := (
	(:xdmp:log($accept),:)
	(:xdmp:log(xdmp:get-request-path()),:)
	if (matches($url, "^/echo.xqy")) then "echo.xqy"
	(: favicon :)
	(:else if (matches($url, "/favicon.ico")) then "echo.xqy":)
	(: assets :)
	else if (matches($path, "^/assets/")) then $url
	(: documents :)
	else if (matches($path, "^/documents/([^/]+)/metadata/?")) then 
		string-join(
			(replace($path, "^/documents/([^/]+)/metadata/?", "document.xqy?scope=meta&amp;uri=$1"), $search), 
			"&amp;"
		)
	else if (matches($path, "^/documents/([^/]+)/?")) then 
		concat(replace($path, "^/documents/([^/\?]+)", "document.xqy?uri=$1"), 
			if (empty($search)) then ()
			else concat("&amp;", $search)
		)
	else if (matches($path, "^/documents/?$")) then concat("documents.xqy", "?", $search)
	else if (matches($path, "^/collections/([^/]+)")) then
		let $colls := tokenize(replace($path, "^/collections/([^/]+)", "$1"), "\+")
		let $qs := for $c in $colls return concat("coll=", $c)
		return concat(
			"documents.xqy",
			if($colls or $search) then "?" else (),
			if($colls) then string-join($qs, "&amp;") else (), 
			if($search) then concat("&amp;", $search) else () 
		)
	else if (matches($path, "^/collections/?")) then "collections.xqy"
	else if (matches($path, "^/$")) then "home.xqy"
	(: Anything else :)
	(: TODO: Should be a 404, not an error :)
	else "error.xqy"
)

(: This is UGLY: The dispatched module has no way of knowing the "orginal" request URI. Need to pass it as a param. :)
return if(contains($new-url, "?")) then
	concat($new-url, "&amp;_resource=", encode-for-uri($path))
else concat($new-url, "?", "&amp;_resource=", encode-for-uri($path))