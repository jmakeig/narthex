(:
 : To run this suite of tests:
 :   - Set up an app server on a separate port from Narthex
 :   - Point its root to the parent "test" directory
 :   - Load this page in a browser (or other client)
 :)

xquery version "1.0-ml";
import module namespace ut="http://marklogic.com/test/unit" at "lib/unit-test.xqy";

let $all-suites as xs:string* := ("test-atompub.xqy")
let $suites as xs:string* := if(empty(xdmp:get-request-field("suite"))) then $all-suites else xdmp:get-request-field("suite")
let $tests as xs:string* := if(empty(xdmp:get-request-field("test"))) then () else xdmp:get-request-field("test")
return ut:render($suites, $tests, "my")