(: Copyright 2009 Mark Logic Corporation.  All Rights  Reserved. :)

xquery version "1.0-ml";

(
xdmp:set-response-content-type('text/html;charset=utf-8'),
	'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
	<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<meta http-equiv="content-type" content="text/html; charset=utf-8" />
		<title>Narthex: {xdmp:database-name(xdmp:database())}</title>
		<link type="text/css" rel="stylesheet" href="/assets/base.css"/>
	  <link type="text/css" rel="stylesheet" href="/assets/prettify.css"/>
	  <link type="text/css" rel="stylesheet" href="/assets/home.css"/>
	  <script type="text/javascript" src="/assets/yui-min.js">//</script>
	  <script type="text/javascript" src="/assets/prettify.js">//</script>
	</head>
		<body>
			<h1>Narthex</h1>
			<p>A <acronymn title="Representational State Transfer">REST</acronymn> interface for MarkLogic Server.</p>
			<ul>
				<li><a href="/documents">Documents</a></li>
				<li><a href="/collections">Collections</a></li>
			</ul>
			<table>
				<col width="10%"/>
				<col width="10%"/>
				<col width="20%"/>
				<col width="20%"/>
				<col width="20%"/>
				<col width="20%"/>
				<thead>
					<tr>
						<th><acronymn title="Uniform Resource Locator">URL</acronymn></th>
						<th>Description</th>
						<th>GET/HEAD</th>
						<th>PUT</th>
						<th>DELETE</th>
						<th>POST</th>
					</tr>
				</thead>
				<tbody>
					<tr class="level-1">
						<td><a href="/documents">/documents</a></td>
						<td>All documents in a database</td>
						<td>
							<p>Human-readable HTML document report</p>
							<div class="request">Accept: text/html, application/html+xml or User-Agent: {{BROWSER}}</div>
							<div class="response">Content-Type: text/html</div>
							<p>List of document links</p>
							<div class="request">Accept: all, none</div>
							<div class="response">Content-Type: application/atomcoll+xml</div>
							<p>Sequence of full documents (binaries base64)</p>
							<div class="request">Accept: application/xml</div>
							<div class="response">Content-Type: application/xml</div>
						</td>
						<td><div class="response">405</div></td>
						<td class="unimplemented">
							<p>Clears a database</p>
							<div class="request"></div>
							<div class="response">204</div>
						</td>
						<td>
							<p>Create a document and metadata</p>
							<div class="request">Content-Type: application/atom+xml;type=entry<br/>Slug: {{URI}}</div>
							<div class="response">201<br/>Content-Type: application/atom+xml;type=entry<br/>Location: {{URL}}</div>
							<p class="notes">Future support for multiple URI policies via Slug</p>
						</td>
					</tr>
					<tr class="level-2">
						<td>?q={{SEARCH}}</td>
						<td>Full text search, relevance order</td>
						<td><p class="notes">Same as above</p></td>
						<td><div class="response">405</div></td>
						<td><div class="response">405</div></td>
						<td><div class="response">405</div></td>
					</tr>
					<tr class="level-2">
						<td>/{{URI}}</td>
						<td>A single document</td>
						<td>
							<p>Document as stored in the database (default)</p>
							<div class="request">Accept: */*, none</div>
							<div class="response">Content-Type: [application/xml, text/plain, application/octet-stream]</div>
							
							<p>Document + metadata</p>
							<div class="request">Accept: application/atom+xml;type=entry</div>
							<div class="response">Content-Type: application/atom+xml;type=entry</div>

							<p>Human-readable HTML document report</p>
							<div class="request">Accept: text/html, application/html+xml OR User-Agent: {{BROWSER}}</div>
							<div class="response">Content-Type: text/html</div>
						</td>
						<td>
							<p>Create/update naked document</p>
							<div class="request">Content-Type: application/xml, text/plain, */*</div>
							<div class="response">201/200<br/>Content-Type: application/xml, text/plain, application/octet-stream<br/>Location: {{URL}}</div>

							<p>Create/update document and metadata</p>
							<div class="request">Content-Type: application/atom+xml;type=entry</div>
							<div class="response">201/200<br/>Content-Type: application/atom+xml;type=entry</div>
						</td>
						<td>
							<p>Remove</p>
							<div class="request"></div>
							<div class="response">204</div>
						</td>
						<td><div class="response">405</div></td>
					</tr>
					<tr class="level-3">
						<td>/metadata</td>
						<td>Document metadata</td>
						<td class="GET">
							<p>Document metadata</p>
							<div class="request">Accept: application/atom+xml;type=entry</div>
							<div class="response">Content-Type: Content-Type: application/atom+xml;type=entry</div>
							<p class="notes">Where <code>content</code> is referenced by source (<code>@src</code>), <em>not</em> inline</p>
						</td>
						<td class="PUT">
							<p>Create/update document metadata</p>
							<div class="request">Content-Type: application/xml, text/plain, */*</div>
							<div class="response">201/200 Content-Type: application/xml, text/plain, application/octet-stream</div>
							<p>Create/update document and metadata</p>
							<div class="request">Content-Type: application/vnd.marklogic.document-envelope</div>
							<div class="response">201/200 Content-Type: application/vnd.marklogic.document-envelope</div>
						</td>
						<td class="DELETE">
							<p>Remove</p>
							<div class="request"></div>
							<div class="response">204</div>
						</td>
						<td class="POST"><div class="response">405</div></td>
					</tr>
					<tr class="level-1">
						<td><a href="/collections">/collections</a></td>
						<td></td>
						<td>
							<p>Human-readable HTML document report</p>
							<div class="request">Accept: text/html, application/html+xml or User-Agent: {{BROWSER}}</div>
							<div class="response">Content-Type: application/vnd.marklogic.document-envelope</div>
						</td>
						<td><div class="response">405</div></td>
						<td><div class="response">405</div></td>
						<td><div class="response">405</div></td>
					</tr>
					<tr class="level-2">
						<td>?q={{SEARCH}}</td>
						<td>Full text search, relevance order</td>
						<td><p class="notes">Same as above</p></td>
						<td><div class="response">405</div></td>
						<td><div class="response">405</div></td>
						<td><div class="response">405</div></td>
					</tr>
					<tr class="level-2">
						<td>/{{COLL}}[+{{COLL}}]*</td>
						<td>One or more collections</td>
						<td class="GET">
							<p class="notes">See /documents</p>
							<!--div class="unimplemented">
							<p>List of document links</p>
							<div class="request">Accept: all, none</div>
							<div class="response">Content-Type: application/atomcoll+xml</div>
							<p>Sequence of full documents (binaries base64)</p>
							<div class="request">Accept: application/xml</div>
							<div class="response">Content-Type: application/xml</div>
							</div-->
						</td>
						<td class="PUT"><div class="response">405</div></td>
						<td class="DELETE"><div class="response">405</div></td>
						<td class="POST">
							<p>Create a document and metadata</p>
							<div class="request">Content-Type: application/atom+xml;type=entry<br/>Slug: {{URI}}</div>
							<div class="response">201<br/>Content-Type: application/atom+xml;type=entry<br/>Location: {{URL}}</div>
						</td>
					</tr>
				</tbody>
			</table>
		</body>
	</html>
)