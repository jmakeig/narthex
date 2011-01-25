(: Copyright 2002-2009 Mark Logic Corporation.  :)

xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module "http://marklogic.com/util/http" at "lib/http.xqy";
import module namespace util="http://marklogic.com/narthex/util" at "lib/util.xqy";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace http="http://marklogic.com/util/http";
declare namespace ml="ml";
declare namespace my="local";
declare namespace error="http://marklogic.com/xdmp/error";

declare option xdmp:mapping "false";

(: This should be replaced with fn:format-number :)
declare function my:format-number($value, $picture as xs:string) as xs:string {
	try {
		format-number($value, $picture)
	} catch($err) {
		string($value)
	}
};

declare function my:documents-url($coll-ids as xs:string*, $root-relative as xs:boolean) as xs:string {
    let $protocol := xdmp:get-request-protocol()
    let $host := xdmp:get-request-header("Host")
    let $root := if($root-relative) then "" else concat($protocol, "://", $host)
    let $coll := if($coll-ids) then concat("/collections/", string-join(for $c in $coll-ids return encode-for-uri($c), "+")) else "/documents/"
    return concat($root, $coll)
};

declare function my:documents-url($coll-ids as xs:string*) as xs:string {
    my:documents-url($coll-ids, false())
};

declare function my:documents-url() as xs:string {
    my:documents-url((),false())
};

declare function my:node-to-rgb($name as xs:QName+) as xs:string {
	for $n in $name
	return substring(
		xdmp:md5(
			concat("asdf", (: Shift color "space" :)
				namespace-uri-from-QName($n), 
				local-name-from-QName($n)
			)
		),
		1, 6)
};

declare function my:node-stack($domain as node()*) as element()* {
<div style="width: 100%; overflow: hidden;" xmlns="http://www.w3.org/1999/xhtml">{
let $names := $domain//*/node-name(.)
let $uniq := distinct-values($names)
let $groups := 
	for $u in $uniq 
	return element {$u} { 
		attribute count {
			sum(for $n in $names return if($n eq $u) then 1 else 0)
		}
	}
let $total := sum($groups/@count) (: Change to sum for stacked bars :)
for $g in $groups 
(: Leave out the elements that every document has :)
(: where xs:int($g/@count) != count($domain) :)
order by $g/local-name()
return <div title="{$g/name()} { 
(:
	string-join(
		for $d in ($domain//*[name() eq $g/name()])[1 to 10] 
		return substring($d, 1, 50),
		" | "
	)
:)}" 
	style="float: left; width: {$g/@count div $total * 100}%; background-color: #{my:node-to-rgb(node-name($g))};" >&#160;</div>
}</div>
};

declare function my:render-xhtml($docs as node()*, $start as xs:integer, $end as xs:integer, $total as xs:integer, $page-size as xs:integer) as item()+ {
	let $r := xdmp:get-request-field("_resource")
	let $q := xdmp:get-request-field("q")
	let $colls := xdmp:get-request-field("coll")
	
	let $nav := <div xmlns="http://www.w3.org/1999/xhtml">
		« 
    {if($start > 1) then 
    	<a href="{$r}?{if($q) then concat("q=", $q, "&amp;") else ""}start={max((1, $start - $page-size))}&amp;end={$start - 1}">Previous</a>
    	else "Previous"} | 
    {if($total > $end) then
    	<a href="{$r}?{if($q) then concat("q=", $q, "&amp;") else ""}start={$end + 1}&amp;end={min(($total, $end + $page-size))}">Next</a>
    else "Next"
    } »
  </div>
	return
    (
    xdmp:add-response-header("Content-Type", "text/html;charset=utf-8"),
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
        	<meta http-equiv="content-type" content="text/html; charset=utf-8" /> 
            <title>Documents</title>
            <link type="text/css" rel="stylesheet" href="/assets/base.css"/>
            <link type="text/css" rel="stylesheet" href="/assets/documents.css"/>
            <script type="text/javascript" src="/assets/yui-min.js">//</script>
            <script type="text/javascript" src="/assets/documents.js">//</script>
            <link rel="alternate" type="application/atom+xml" href="{my:documents-url()}" />
           
        </head>
        <body>
        		<div class="database">Database <strong>{xdmp:database-name(xdmp:database())}</strong></div>
            <h1>{if(starts-with($r, "/documents")) then "Documents" else concat("Collection ", string-join($colls, ", "))}</h1>
            <div>
	          	{(my:format-number($total, "#,###"), " documents ", if($q) then (" matching ", <strong>{$q}</strong>) else "")}
	          </div>
            {$nav}
            <table>
            	<col width="40em"/>
            	<col width="4em"/>
            	<col/>
            	<col width="80em"/>
            	<col width="80em"/>
            	<col width="80em"/>
            	<col width="80em"/>
            		<thead>
                <tr><th></th><th>Document</th><th>Names</th><th>Kind</th><th>Root</th><th>Size</th><th></th></tr>
                </thead>
                <tbody>
            {
                if($docs) then
	                for $doc in $docs
	                let $uri := xdmp:node-uri($doc)
	                let $url := concat("/documents/", encode-for-uri($uri))
                        let $root
                          := if (count($doc/node()) > 1)
                             then
                               if ($doc/*)
                               then
                                 $doc/*
                               else
                                 $doc/node()[1]
                             else
                               $doc/node()
	                return <tr>
	                	<td class="action"><a href="{$url}"><img src="/assets/pencil.png" alt="Edit"/></a></td>
	                	<td class="uri"><a href="{$url}">{$uri}</a></td>
	                	<td>{my:node-stack($doc)}</td>
	                	<td>{xdmp:node-kind($root)}</td>
	                	<td><span class="local-name">{local-name($root)}</span> {{<span class="namespace">{namespace-uri($root)}</span>}}</td>
	                	{ (: This is probably prohibitively expensive for large documents :) }
	                	<td class="numeric">{if(xdmp:node-kind($root)="element") then my:format-number(string-length(xdmp:quote($doc)) div 1024, "###,### KB") else ""}</td>
	                	<td class="action"><button class="delete-action" data-url="{$url}" data-uri="{$uri}" title="Remove {$uri}…"></button></td>
	                </tr>
	               else <tr><td colspan="6" class="message">I can’t find anything matching <strong>{$q}</strong></td></tr>
            }
            	</tbody>
            </table>
            {$nav}
            {(: TODO: Extract this out into a shared library :)}
            <div id="Nav">{
		        	let $q := xdmp:get-request-field("q")
		        	let $rsc := xdmp:get-request-field("_resource")
			      	return <form method="get" action="{$rsc}">
			      		<div class="search">
				      		<input type="search" name="q" value="{$q}" placeholder="Search…"/><button class="search-action">Search</button> 
								</div>
								<div>
									<ul>
										<li><a href="/documents">Documents</a></li>
										<li><a href="/collections">Collections</a></li>
									</ul>
								</div>
			      	</form>
		      }</div>
		      <div id="Notification"></div>
        </body>
    </html>
    )
};

let $method := (xdmp:get-request-field("x-method-override"), xdmp:get-request-method())[1]
let $uri := xdmp:get-request-field("uri")
let $resource := xdmp:get-request-field("_resource")
let $db := (xdmp:get-request-field("database"), xdmp:database())[1]

let $DEFAULT_PAGE_SIZE := 50

let $accept := xdmp:get-request-header("Accept")
let $content-type := xdmp:get-request-header("Content-Type")
let $start := xs:integer((xdmp:get-request-field("start"), 1)[1])
let $end := xs:integer((xdmp:get-request-field("end"), $DEFAULT_PAGE_SIZE)[1])

return 
	if("GET" eq $method) then
		let $q as xs:string? := xdmp:get-request-field("q")
		let $colls as xs:string* := xdmp:get-request-field("coll")
		let $options := <options xmlns="http://marklogic.com/appservices/search">
				<search-option>unfiltered</search-option>
				{if($colls) then <additional-query>{cts:collection-query($colls)}</additional-query> else ()}
			</options>
		let $docs := if($q) then
			search:resolve-nodes(search:parse($q, $options), $options, $start, $end - $start + 1)
			else if($colls) then collection($colls)[$start to $end]
			else collection()[$start to $end]
		let $total := if($q or $colls) then 
			xdmp:estimate(
				cts:search(
					if($colls) then collection($colls) else collection(), 
					cts:query(search:parse(($q,"")[1], $options)), "unfiltered")
			)
			else xdmp:estimate(collection())
		return 
			(: TODO: This is ugly and wrong :)
			if(contains($accept, "application/atom+xml")) then (
				xdmp:set-response-code(200, "OK"), 
				xdmp:add-response-header("Content-Type", "application/atom+xml"),
					<atom:feed xmlns:atom="http://www.w3.org/2005/Atom">
						<atom:id>{$uri}</atom:id>
						<atom:title>{$uri}</atom:title>
						<atom:updated>{current-dateTime()}</atom:updated>
						<atom:link rel="next" href=""/>
						<atom:link rel="previous" href=""/>
						<ml:count>{count($docs)}</ml:count>
						<ml:total>{$total}</ml:total>{
						for $doc in $docs
						return 
							<atom:entry>
								<atom:id>{xdmp:node-uri($doc)}</atom:id>
								<atom:title>{xdmp:node-uri($doc)}</atom:title>
								<atom:updated>{current-dateTime()}</atom:updated>
								<atom:content type="{xdmp:node-kind($doc)}">{$doc}</atom:content>
							</atom:entry>
						}		
					</atom:feed>
       )
		else if(contains($accept, "text/html")) then
			(
	      xdmp:set-response-code(200, "OK"), 
	      my:render-xhtml($docs, $start, $end, $total, $DEFAULT_PAGE_SIZE)
       )
		else
			xdmp:set-response-code(406, "Not acceptable")
	else if("POST" eq $method) then
		if("application/atom+xml;type=entry" eq $content-type) then
			let $uri as xs:string := xdmp:get-request-header("Slug") (: TODO Generalize this to support other schemes for mapping a slug to a URI :)
			(: This requires that application/atom+xml is registered with MarkLogic as an XML MIME-type. :)
			let $entry as element(atom:entry) := xdmp:get-request-body("xml")/node()
			return
      	(
      		xdmp:document-insert(
      			$uri, 
      			$entry, 
      			xdmp:document-get-permissions($uri), 
      			xdmp:document-get-collections($uri), 
      			xdmp:document-get-quality($uri)
      		),
      		xdmp:set-response-code(201, "Created"),
      		xdmp:add-response-header("Location", util:document-url($uri)),
      		xdmp:add-response-header("Content-Type", "application/atom+xml;type=entry"),
      		$entry
      	)
		(: Evaluate a query. This is a sharp tool. Consider how one might disable this. Perhaps in the dispatcher. :)
		else if("application/xquery+xml" eq $content-type) then
			let $query as xs:string? := xdmp:get-request-body("text")
			return (xdmp:add-response-header("Content-Type", $accept), 
				try {
					xdmp:eval($query)
				} catch($e) {
					(: TODO: Better error handling here. Are there 400 errors we could catch, such as syntax? What about security? :)
					(xdmp:log($e), xdmp:set-response-code(400, "Eval issue"), xdmp:add-response-header("Content-Type", "application/xml"), $e)
				})
		(: else if => should be allowed to add a document using a system-wide URI policy :)
		else
			xdmp:set-response-code(400, concat("No can do: ", $content-type))	
	else 
		xdmp:set-response-code(405, "Method not allowed")