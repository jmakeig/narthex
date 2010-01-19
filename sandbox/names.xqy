xquery version "1.0-ml";
declare namespace x = "http://www.w3.org/1999/xhtml";
declare namespace local="local";
declare option xdmp:mapping "false";

(: Consistently hash QNames to RGB colors :)
declare function local:node-to-rgb($name as xs:QName+) as xs:string {
	for $n in $name
	return substring(
		xdmp:md5(
			concat(
				namespace-uri-from-QName($n), 
				"|", 
				local-name-from-QName($n)
			)
		),
		1, 6)
};

declare function local:node-stack($domain as node()*) as element() {
<x:div style="width: 100%; font-size: 18px;">{
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
order by xs:int($g/@count) descending
return <x:div title="{$g/name()}: {
	string-join(
		for $d in ($domain//*[name() eq $g/name()])[1 to 10] 
		return substring($d, 1, 50),
		" | "
	)}" 
	style="padding: 0.5em 0; float: left; width: {$g/@count div $total * 100}%; background-color: #{local:node-to-rgb(node-name($g))};" ><x:span>{(:$g/name():)}</x:span></x:div>
}</x:div>
};

let $domain := (collection())[25 to 25]
return local:node-stack($domain)