xquery version "1.0-ml";
declare namespace foo="http://foo";
let $el := <el xmlns="asdf"/>
let $hash := xdmp:md5(concat($el/namespace-uri(), "|", $el/local-name()))
return <div style="padding: 4em; background-color: #{substring($hash, 1, 6)}">.</div>