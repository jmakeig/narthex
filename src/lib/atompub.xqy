xquery version "1.0-ml";
module namespace atompub = "http://www.marklogic.com/modules/atompub";
declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace ml="ml";

declare function atompub:render-entry($uri as xs:string, $by-ref as xs:boolean) as element(atom:entry) {
    <atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
    	<atom:id>{$uri}</atom:id>
    	<atom:tite>{$uri}</atom:tite>
    	<atom:updated>{(data(xdmp:document-properties($uri)//prop:last-modified[last()]), current-dateTime())[1]}</atom:updated>
    	{xdmp:document-get-permissions($uri)}
    	{for $c in xdmp:document-get-collections($uri) return <ml:collection href="/collections/{$c}">{$c}</ml:collection>}
    	{xdmp:document-properties($uri)}
    	<ml:forest>{xdmp:document-forest($uri)}</ml:forest>
  		<ml:quality>{xdmp:document-get-quality($uri)}</ml:quality>{
  			if($by-ref) then
					<atom:content type="application/xml" src="{"asdf"}"/>
	  		else
	  			<atom:content type="application/xml">{doc($uri)}</atom:content>
	  	}
    </atom:entry>
};

declare function atompub:render-entry($uri as xs:string) as element(atom:entry) {
	atompub:render-entry($uri, false())
};

declare function atompub:render-feed($uris as xs:string*) as element(atom:feed)? {

};
