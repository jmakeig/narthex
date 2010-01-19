xquery version "1.0-ml";
import module namespace fx="http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace http="http://marklogic.com/function/http" at "lib/http.xqy";
import module namespace atompub="http://www.marklogic.com/modules/atompub" at "lib/atompub.xqy";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace sec="http://marklogic.com/xdmp/security";
declare namespace prop="http://marklogic.com/xdmp/property";
declare namespace ml="ml";
declare namespace my="local";

(: TODO: Probably some crazy security issues going on here. :)
declare function my:role-names($role-ids as xs:unsignedLong*) as xs:string* {
	xdmp:eval(
		concat(
			'import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";sec:get-role-names((', 
			string-join(for $ri in $role-ids return xs:string($ri), ","), 
			"))"
		),
	  (),
	  <options xmlns="xdmp:eval">
	    <database>{xdmp:security-database()}</database>
	  </options>
	)
};

(:
 : Centralized place to create URLs
 : 
 : @param $doc-uri The database URI of a document
 : @param root-relative Whether to start from the root of the server as opposed to an absolute URL begining with a http[s]
 : @return The server-specific URL 
 :)
declare function my:document-url($doc-uri as xs:string, $root-relative as xs:boolean) as xs:string {
	let $protocol := xdmp:get-request-protocol()
	let $host := xdmp:get-request-header("Host")
	let $root := if($root-relative) then "" else concat($protocol, "://", $host)
	return concat($root, "/documents/", encode-for-uri($doc-uri))
};
declare function my:document-url($doc-uri as xs:string) as xs:string {
	my:document-url($doc-uri, false())
};

declare function my:collection-url($coll-uri as xs:string+) as xs:string {
	my:collection-url($coll-uri, false())
};
declare function my:collection-url($coll-uris as xs:string+, $root-relative as xs:boolean) as xs:string {
	let $protocol := xdmp:get-request-protocol()
	let $host := xdmp:get-request-header("Host")
	let $root := if($root-relative) then "" else concat($protocol, "://", $host)
	let $colls := for $c in $coll-uris return encode-for-uri($c)
	return concat($root, "/collections/", string-join($colls, "+"))
};


declare function my:render-xhtml($doc as node()?) as item()+ {
	my:render-xhtml($doc, false())
};

declare function my:render-xhtml($doc as node()?, $is-new as xs:boolean) as item()+ {
	my:render-xhtml($doc, $is-new, ())
};

declare function my:render-xhtml($doc as node()?, $is-new as xs:boolean, $variants as element(http:variant)*) as item()+ {
  let $uri := if($doc) then xdmp:node-uri($doc) else xdmp:get-request-field("uri")
  return (
  	xdmp:add-response-header("Content-Type", "text/html;charset=utf-8"),
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
    <html xmlns="http://www.w3.org/1999/xhtml">
	  <head>
	  	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	  	<link type="text/css" rel="stylesheet" href="/assets/base.css"/>
	    <link type="text/css" rel="stylesheet" href="/assets/document.css"/>
	    <script type="text/javascript" src="/assets/yui-min.js">//</script>
	    <script type="text/javascript" src="/assets/cm/js/codemirror.js">//</script>
	    <script type="text/javascript" src="/assets/document.js">//</script>
	    <title>{$uri}</title>{
	    for $v in $variants
	       return 
	           <link rel="self" href="{my:document-url($uri, false())}" type="{http:variant-to-string($v)}"/>
	    }
	  </head>
	  <body>
			<h1>{if($is-new) then <span class="callout">New</span> else ()} <a href="/documents/{encode-for-uri($uri)}">{$uri}</a></h1>
			<form id="Document">
      <div>
      	<ul id="document-actions" class="actions">
      		<!--<li><button class="savemeta-action">Meta</button></li>-->
	        <li><button class="save-action">Save</button></li>
	        <li><button class="delete-action">Remove</button></li>
        </ul>
      </div>
      <div>
      	<ul id="DocumentNav">
      		<li id="document-nav"><a href="#document">Document</a></li>
      		<li id="properties-nav"><a href="#properties">Properties <span class="badge">{count(xdmp:document-properties($uri)/prop:properties/element())}</span></a></li>
      		<li id="metadata-nav"><a href="#metadata">Metadata</a></li>
      	</ul>
      </div>
			<div id="document">
				<textarea id="DocumentXML">{if($doc) then fx:trim(xdmp:quote($doc)) else ""}</textarea>
			</div>
			<div id="properties">
				<textarea id="PropertiesXML">{xdmp:document-properties($uri)}</textarea>
			</div>
			<div id="metadata">
				<div class="control">
					<div class="label">
						<label for="">Collections</label>
					</div>
					<div class="input">
						<ul id="collections">{
							for $c in xdmp:document-get-collections($uri)
							order by $c
							return 
								<li class="collection">
									<a href="/collections/{encode-for-uri($c)}">{$c}</a>
									<input type="hidden" name="collections" value="{$c}"/>
									<button class="delete-action" title="Remove collection"></button>
								</li>
						}</ul>
						<div>
							<input type="text" class="add-collection-name"/>
							<button class="add-collection-action">Add</button>
						</div>	
					</div>
				</div>
				<div class="control">
					<div class="label">
						<label for="">Permissions</label>
					</div>
					<div class="input">
						<table id="permissions">
							<tbody>
								{for $p in xdmp:document-get-permissions($uri)
								order by $p/sec:role-id, $p/sec:capability
								return
								<tr class="permission">
									<td>
									<span>{my:role-names((data($p/sec:role-id)))}</span>
									<input type="hidden" name="permission-role-id" value="{data($p/sec:role-id)}"/>
									</td>
									<td>
									<select name="permission-capability">{
										for $i in ("read", "update", "insert", "execute")
										return <option value="{$i}">
											{if(data($p/sec:capability) eq $i) then attribute selected {"selected"} else ()}
											{$i}
											</option>
									}</select>
									</td>
								</tr>}
							</tbody>
						</table>
						<div>
							<button class="add-action">Add</button>
						</div>
					</div>
				</div>
				<div class="control">
					<div class="label">
						<label for="Quality">Quality</label>
					</div>
					<div class="input">
						<input id="Quality" name="quality" type="text" value="{xdmp:document-get-quality($uri)}" class="numeric"/>
					</div>
				</div>
				<div class="control">
					<div class="label">
						<label for="">Forest</label>
					</div>
					<div class="input">
						<select name="forest">{
							(: TODO: This stuff shouldn't be in the view :)
							for $i in xdmp:database-forests((xdmp:get-request-field("database"), xdmp:database())[1])
							return <option value="{$i}">
								{if(xdmp:document-forest($uri) eq $i) then attribute selected {"selected"} else ()}
								{xdmp:forest-name($i)}
							</option>
						}</select>
					</div>
				</div>
				<!--<ul class="actions">
					<li><button class="save-action">Save Metadata</button></li>
				</ul>-->
			</div>
			<div id="Nav">{
			let $q := xdmp:get-request-field("q")
			return <form method="get" action="/documents">
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
			</form>
      <div id="Notification"></div>
	  </body>
	</html>
    )
};

let $method := xdmp:get-request-method()
let $uri := xdmp:get-request-field("uri")
let $db := (xdmp:get-request-field("database"), xdmp:database())[1]
let $accept := xdmp:get-request-header("Accept")
let $content-type := xdmp:get-request-header("Content-Type")
let $variants := http:string-to-variant(("application/xml", "text/html", "application/xhtml+xml", "application/atom+xml;type=entry"))

return
  if ("PUT" eq $method) then
  	(: TODO: Real content negotiation :)
    if (starts-with($content-type, "application/xml")) then
    	let $code as xs:integer := if(doc-available($uri)) then 200 else 201
    	return
      	(
      		xdmp:document-insert(
      			$uri, 
      			xdmp:get-request-body("xml"), 
      			xdmp:document-get-permissions($uri), 
      			xdmp:document-get-collections($uri), 
      			xdmp:document-get-quality($uri)
      		),
      		xdmp:set-response-code($code, ""),
      		xdmp:add-response-header("Location", my:document-url($uri)),
      		xdmp:add-response-header("Content-Type", "application/xml"),
      		xdmp:get-request-body("xml")
      	)
    (: TODO: Implement Atom entry :)
    (: TODO: Do real content negotiation. e.g. Firefox sends application/atom+xml;charset=UTF-8;type=entry:)
    else if (contains($content-type, "application/atom+xml") and contains($content-type, "type=entry")) then
      let $envelope := xdmp:get-request-body("xml")/atom:entry
      let $body as element() := $envelope/atom:content/element()
      let $permissions as element(sec:permission)* := $envelope/ml:metadata/sec:permission
      let $collections as xs:string* := $envelope/ml:collection/text()
      let $forest-ids as xs:unsignedLong* := $envelope/ml:forest/text()
      let $quality as xs:int? := $envelope/ml:quality/text()
      let $properties as element()* := $envelope/prop:properties/element()
      return
        (xdmp:document-insert(
                    $uri, 
                    $body,
                    $permissions,
                    $collections,
                    $quality,
                    $forest-ids
         ),
         xdmp:document-set-properties($uri, $properties),
         (: TODO: If it's new we should send a 201 :)
         xdmp:set-response-code(200, "OK"),
         xdmp:add-response-header(
           "Content-Type",
           "application/atom+xml;type=entry"),
         atompub:render-entry($uri))
    (: DEPRECATED :)
    else if ("application/vnd.marklogic.document-envelope" eq $content-type) then
      let $envelope := xdmp:get-request-body("xml")/ml:envelope
      let $body as element() := $envelope/ml:document/element()
      let $permissions as element(sec:permission)* := $envelope/ml:metadata/sec:permission
      let $collections as xs:string* := $envelope/ml:metadata/ml:collection/text()
      let $forest-ids as xs:unsignedLong* := $envelope/ml:metadata/ml:forest/text()
      let $quality as xs:int? := $envelope/ml:metadata/ml:quality/text()
      let $properties as element()* := $envelope/ml:metadata/prop:properties/element()
      return
        (xdmp:document-insert(
					$uri, 
					$body,
					$permissions,
					$collections,
					$quality,
					$forest-ids
         ),
         xdmp:document-set-properties($uri, $properties),
         (: TODO: If it's new we should send a 201 :)
         xdmp:set-response-code(200, "OK"),
         xdmp:add-response-header(
           "Content-Type",
           "application/vnd.marklogic.document-envelope"),
         $body)
    else
      xdmp:set-response-code(400, concat("I don’t know what to do with ", $content-type))
  else if ("GET" eq $method) then
  	(: TODO: The 404 error here cuts across accepted media types. Handle this more flexibly. :)
  	let $is-new as xs:boolean := if(doc-available($uri)) then false() else (xdmp:set-response-code(404, "Not found"), true())
    let $doc as node()? := doc($uri)
    return
      if ("application/xml" eq $accept) then
        (xdmp:add-response-header("Content-Type", "application/xml"), $doc)
      else if ("application/atom+xml;type=entry" eq $accept) then 
      	if($is-new) then
      		"" (: TODO: What, if any, body should be returned on a 404 entry request?:)
      	else (
      		atompub:render-entry($uri),
      		xdmp:add-response-header("Content-Type", "application/atom+xml;type=entry")
      	)
      (: DEPRECATED :)
      else if("application/vnd.marklogic.document-envelope" eq $accept) then
      	(xdmp:add-response-header("Content-Type", "application/vnd.marklogic.document-envelope"),
      		<ml:envelope>
      			<ml:metadata href="/documents/{$uri}/metadata">
      				{xdmp:document-get-permissions($uri)}
      				{for $c in xdmp:document-get-collections($uri) return <ml:collection href="/collections/{$c}">{$c}</ml:collection>}
      				{xdmp:document-properties($uri)}
      				<ml:forest>{xdmp:document-forest($uri)}</ml:forest>
      				<ml:quality>{xdmp:document-get-quality($uri)}</ml:quality>
      			</ml:metadata>
      			<ml:document>{doc($uri)}</ml:document>
      		</ml:envelope>
      	)
      else if (contains($accept, "text/html")) then
        (xdmp:add-response-header("Content-Type", "text/html"), my:render-xhtml($doc, $is-new, $variants))
      else
        (xdmp:set-response-code(406, "Not Acceptable"), "")
  else if ("DELETE" eq $method) then
  	if (not(doc-available($uri))) then 
			(xdmp:set-response-code(404, "Not found"), xdmp:add-response-header("Content-Type", "text/plain"), "Not found")
		else
    	(xdmp:document-delete($uri), xdmp:set-response-code(204, ""))
  else
    (xdmp:set-response-code(405, "Method Not Allowed"))