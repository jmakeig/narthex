xquery version "1.0-ml";
module namespace util="http://marklogic.com/util/sequence";
declare default function namespace "http://www.w3.org/2005/xpath-functions";
(:
 : Apply a function to each item in a sequence to produce a new
 : sequence of the same length.
 :
 : @param $seq The original sequence
 : @param $f as function($item as item()?) as item() A function to create a new sequence value of type 
 : @return A sequence of the same length as the input 
 :)
declare function util:map($seq as item()*, $f as xdmp:function) as item()* {
	for $s at $i in $seq
	return xdmp:apply($f, ($s))
};

(:
 : Fold a sequence into a single value by evaluating each of the items.
 :
 : @param $seq The sequence to fold
 : @param $f as function($accumulator, $current-item) as item() The function to apply to the accumlated value and the current item, 
 :)
declare function util:reduce($seq as item()*, $accumulator as item()*, $f as xdmp:function (: ($accumulator as item()*, $item as item()) as xs:item()* :)) as item()? {
	if(empty($seq)) then ()
	else if(count($seq) eq 1) then xdmp:apply($f, $seq[1], $accumulator)
	else util:reduce(subsequence($seq, 2), xdmp:apply($f, $seq[1], $accumulator), $f)
};