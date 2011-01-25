xquery version "1.0-ml";
module namespace ut="http://marklogic.com/test/unit";
declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare namespace error="http://marklogic.com/xdmp/error";

declare variable $ut:TEST-HOME as xs:string := "../";

(:
 : Assert that two parameters are equal (using the eq operator).
 : For sequences, perform the eq comparison on each corresponding item.
 :
 : @param $a Left side comparison
 : @param $b Right side comparison
 : @param $context Optional context to send to the test output
 : @return ()
 : @throws ut:AssertionError
 :)
declare function ut:assert-equals($a, $b, $context as item()*) as element(ut:assertion) {
	(
	if(count($a) ne count($b)) then 
		error(xs:QName("ut:AssertionError"), concat("[",$a,"] is length ",count($a)," and [",$b,"] is length ",count($b)), $context)
	else 
		for $item at $i in $a
		return if($item eq $b[$i]) then ()
		else error(xs:QName("ut:AssertionError"), concat("[", $a, "] is not equal to [", $b, "]"), $context)
	,<ut:assertion/>)
};

(:
 : Assert that two parameters are equal (using the eq operator).
 : @see ut:assert-equals($a, $b, $context as item()*)
 :)
declare function ut:assert-equals($a, $b) as element(ut:assertion) {
		ut:assert-equals($a, $b, ())
};

(:
 : Assert that a statement is true.
 :
 : @param $bool The boolean statement
 : @param $context Optional context to sent to the test output
 : @return ()
 : @throws ut:AssertionError
 :)
declare function ut:assert-true($bool, $context as item()*) as element(ut:assertion) {
	if($bool eq true()) then <ut:assertion/>
	else error(xs:QName("ut:AssertionError"), concat("[", $bool, "] is not true()"), $context)
};

(:
 : Assert that a statement is true.
 : @see ut:assert-true($bool, $context as item()*) as empty-sequence()
 :)
declare function ut:assert-true($bool) as element(ut:assertion) {
	ut:assert-true($bool, ())
};

(:
 :
 :)
declare function ut:assert-empty($seq) as element(ut:assertion) {
	if(empty($seq)) then <ut:assertion/>
	else error(xs:QName("ut:AssertionError"), concat("[",$seq,"] is not empty"))
};

(:
 : Loop through tests and accumulate a result report. Catches unhandled 
 : exceptions and continues execution until the end.
 :
 : @param $tests Pointers to the tests to run
 : @param $result The accumulated result report
 : @return The accumlated result report as a sequence of pass/fail elements
 :)
declare function ut:run($tests as xdmp:function*, $id as xs:string?) as element()* {
	<ut:run id="{$id}">{
	for $test in $tests
	let $name as xs:QName := xdmp:function-name($test)
	return try {
		let $output := xdmp:apply($test)
		return <ut:pass>
			<ut:name>{$name}</ut:name>{
			$output
			}
		</ut:pass>
	} catch($e) {
		<ut:fail>
			<ut:name>{$name}</ut:name>
			<ut:error>{$e}</ut:error>
		</ut:fail>
	}
	}</ut:run>
};

declare function ut:run-suites($paths as xs:string*, $uri as xs:string?, $tests as xs:string*) as element(ut:run)* {
	for $path in $paths
	let $p as xs:string := concat($ut:TEST-HOME, $path)
	let $available-tests as xs:QName* := xdmp:apply(
		xdmp:function(QName($uri, "get-tests"), $p)
	)
	let $selected-tests as xs:QName* := if($tests) then for $t in $tests return QName($uri, $t) else $available-tests
	(: Intersection of available and selected :) 
	let $candidate-tests as xs:QName* := distinct-values($available-tests[. = $selected-tests])
	let $test-pointers as xdmp:function* := for $t in $candidate-tests return xdmp:function($t, $p)
	return ut:run(
		$test-pointers,
		$path
	)
}; 

(:
 : Render results as HTML.
 :
 : @param $suites The path to a suite of tests. This must be relative to $ut:TEST-HOME.
 : @param $uri The namespace URI of all of the test functions. All test functions must have the same namespace.
 : @return The HTML to visually display the results.
 :)
declare function ut:render($suites as xs:string*, $tests as xs:string*, $test-uri as xs:string?) {
(
xdmp:set-response-content-type('text/html;charset=utf-8'),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<title>Test Runner</title>
	<style type="text/css">
		body {{
			font-family: Helvetica;
			padding: 0.5em  1em;
		}}
		pre {{
			font-family: Inconsolata, Consolas, monospace;
		}}
		ol.results {{
			padding-left: 0;
		}}
		.result {{
			border-top: solid 4px;
			padding: 0.25em 0.5em;
			font-size: 85%;
		}}
		li.result {{
			list-style-position: inside;
			list-style: none;
		}}
		.result h3 {{
			font-weight: normal;
			font-size: inherit;
			margin: 0;
		}}
		.result.fail h3 {{
			color: red;
		}}
		.pass {{
			border-color: green;
		}}
		.fail {{
			border-color: red;
		}}
		h2 {{
			display: inline-block;
			margin: 0;
		}}
		h2+div.stats {{
			display: inline-block;
			margin-left: 1em;
		}}
		strong.fail, 
		h2.fail {{
			border: none;
			color: red;
		}}
		h2.fail:before {{
			content: "✘ ";
		}}
		h2.pass:before {{
			content: "✔ ";
		}}
		h2 a,
		.result h3 a {{
			text-decoration: inherit;
			color: inherit;
		}}
		.fail .message {{
			font-weight: bold;
		}}
		.namespace {{
			margin-left: 1em;
			color: #999;
		}}
		.namespace:before {{
			content: "(";
		}}
		.namespace:after {{
			content: ")";
		}}
	</style>
</head>
<body>
<form action="{xdmp:get-request-path()}" method="get">{
let $runs as element(ut:run)* := ut:run-suites($suites, $test-uri, $tests)
return (
	<p><strong>{if(count($runs/ut:fail) gt 0) then attribute class {"fail"} else ()}{count($runs/ut:fail)}</strong> failed tests and <strong>{count($runs/ut:pass)}</strong> passed tests using <strong>{count($runs//ut:assertion)}</strong> assertions over <strong>{count($runs)}</strong> suites. <a href="?">All</a></p>,
	<div><button>Run Selected</button></div>,
	for $run in $runs
	return (
		<h2>{if(count($run/ut:fail) gt 0) then attribute class {"fail"} else if(count($run/ut:pass) gt 0) then attribute class {"pass"} else () }<a href="?suite={data($run/@id)}">{data($run/@id)}</a></h2>,
		<div class="stats">{count($run/ut:pass)}/{count($run/(ut:pass|ut:fail))}</div>,
		<ol class="results">{
		for $result in $run/(ut:pass|ut:fail) 
		return <li class="result {local-name($result)}">
			<h3><input name="test" value="{local-name-from-QName($result/ut:name)}" type="checkbox">{if(local-name-from-QName($result/ut:name) = $tests) then attribute checked {"checked"} else ()}</input>
				<a href="?test={local-name-from-QName($result/ut:name)}">{local-name-from-QName($result/ut:name)} <span class="namespace">{namespace-uri-from-QName($result/ut:name)}</span></a> <span style="float:right;">{count($result/ut:assertion)}</span></h3>{
				if($result/ut:error) then (
				<p class="message">{$result/ut:error/error:error/error:message}</p>, 
				<pre>{xdmp:quote($result/ut:error/*)}</pre>
				) 
				else () 
			}
		</li>
		}</ol> 
	)
)
}
	<div><button>Run Selected</button></div>
</form></body>
</html>
)};
