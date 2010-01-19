/* This is a fucking mess (but works) */                
YUI().use("node", "io", "dump", "anim", "collection", function(Y) {
	var self = document.URL; // For some reason, Safari decodes document.location.href and others
	var state = document.location.hash.slice(1) || "document";
	var states = ["document", "properties", "metadata"];
	
	var editor;
	var properties;
	
	function onChange(e) {
		console.log("Changed!");
	}
	
	Y.one("#Document").on("submit", function(evt) {
		evt.preventDefault(false);
	});
	
	Y.on("domready", function(e) {
		editor = CodeMirror.fromTextArea('DocumentXML', {
		    height: "100%",
		    width: "100%",
		    path: "/assets/cm/js/",
		    parserfile: "parsexml.js",
		    stylesheet: ["/assets/cm/css/xmlcolors.css", "/assets/cm/extra/editor.css"],
		    continuousScanning: 500,
		    lineNumbers: false,
		    textWrapping: false,
		    tabMode: "indent"
		    //onChange: onChange
		 });
		//editor.grabKeys(function() { console.log("asdf");});
		properties = CodeMirror.fromTextArea('PropertiesXML', {
		    height: "100%",
		    width: "100%",
		    path: "/assets/cm/js/",
		    parserfile: "parsexml.js",
		    stylesheet: ["/assets/cm/css/xmlcolors.css", "/assets/cm/extra/editor.css"],
		    continuousScanning: 500,
		    lineNumbers: false,
		    textWrapping: false,
		    tabMode: "indent"
		    //onChange: onChange
		 });
		
		//console.log("state: " + state);
		Y.Array.some(states, function(i) {
			if(state === i) {
				//console.log("id: " + Y.one("#" + state).get("id"));
				Y.one("#" + i).setStyles({"display": "block"});
				Y.one("#" + i + "-nav").addClass("selected");
			} else {
				//console.log("nope: " + i);
				Y.one("#" + i).setStyles({"display": "none"});
			}
		});
		//Y.all("#metadata, #properties").setStyles({"display":"none"});
		//Y.one("#document").setStyles({"display":"block"});
		//Y.one("#DocumentNav li").addClass("selected");
		
		Y.all(".collection .delete-action").on("click", function(evt){
			var target = evt.currentTarget;
			target.ancestor("li").remove();
		});
	});
	
	/* TODO: Probably should use Y.delegate here. Clicks on non-a children aren't bubbling. */ 
	Y.all("#DocumentNav li").on("click", function(evt) {
		//alert(evt.target.get("nodeName"));
		var target = (evt.target.get("nodeName")=="A") ? evt.target : evt.target.one("a");
		var dest = target.getAttribute("href").slice(1);
		target.ancestor("ul").all("li").removeClass("selected");
		target.ancestor("li").addClass("selected");
		switch(dest) {
			case "properties":
				Y.all("#metadata, #document").setStyles({"display":"none"});
				Y.one("#properties").setStyles({"display":"block"});
				break;
			case "metadata":
				Y.all("#document, #properties").setStyles({"display":"none"});
				Y.one("#metadata").setStyles({"display":"block"});
				break;
			default:
				Y.all("#metadata, #properties").setStyles({"display":"none"});
				Y.one("#document").setStyles({"display":"block"});
				break;
		}
	});
	
	Y.all(".actions .save-action").on("click", function(e) {
		var doc = editor.getCode();
		var props = properties.getCode(); 
		var form = Y.one("#Document");
		var collections = [];
		form.all("input[name=collections]").each(function(n) {
			collections.push(n.get("value"));
		});
		var permissions = Y.Array.map(Y.NodeList.getDOMNodes(form.all("tr.permission")), function(row) {
			row = Y.one(row);
			return {
				"role": row.one("input[name=permission-role-id]").get("value"),
				"capability": row.one("select[name=permission-capability]").get("value")
			}
		});
		
		var quality = form.one("input[name=quality]").get("value");
		var forest = form.one("select[name=forest]").get("value");
		
		var data = '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:ml="ml">'+
	    	'<atom:id>asdf</atom:id>'+
	    	'<atom:tite>title</atom:tite>'+
	    	'<atom:updated>'+new Date()+'</atom:updated>' +
	    	Y.Array.map(permissions, function(p) {
	    		return '<sec:permission xmlns:sec="http://marklogic.com/xdmp/security">'+
	    		  '<sec:capability>'+p.capability+'</sec:capability>'+
	    		  '<sec:role-id>'+p.role+'</sec:role-id>'+
	    		'</sec:permission>';
	    	}).join('') +
	    	Y.Array.map(collections, function(c) {
	    		return '<ml:collection href="/collections/">'+c+'</ml:collection>';
	    	}).join('') + 
	    	props +
	    	// TODO: Make this a look-up
	    	//'<ml:forest>'+forest+'</ml:forest>'+
	  		'<ml:quality>'+quality+'</ml:quality>'+
		  	'<atom:content type="application/xml">'+doc.replace(/<\?xml [^\?]+\?>/,'')+'</atom:content>'+
		  	'</atom:entry>';
	    //console.log(data);
		
		var config = {
			method: "PUT",
			headers: { "Content-Type": "application/atom+xml;type=entry", "Accept": "application/atom+xml;type=entry" },
			data: data, 
			on: {
				start: function(id, o) {
				Y.one("#Notification")
					.setStyle("opacity","1")
					.setStyle("background", "yellow")
					.set("innerHTML", "Saving…");
				},
				success: function(id, o) {
					//editor.setCode(o.responseText);
					var xml = o.responseXML;
					var entry = xml.getElementsByTagNameNS("http://www.w3.org/2005/Atom", "content")[0].firstChild;
					var serializer = new XMLSerializer();
					editor.setCode(serializer.serializeToString(entry));
					Y.one("#Notification").setStyle("opacity","1").setStyle("background", "#0c6").setAttribute("title", o.status + " " + o.statusText).set("innerHTML", "Saved.");
					var myAnim = new Y.Anim({
                        node: '#Notification',
                        to: {
                            opacity: 0
                        }
                    });
                    // Bind the function to this (Where's Prototype when I need it?)
                    window.setTimeout(function() {(function() {myAnim.run()}).apply(this)}, 2500);
				},
				failure: function(e) {
					Y.one("#Notification").setStyle("opacity","1").setStyle("background", "red").set("innerHTML", "Oops!");
					console.dir(e); 
				},
				end: function(id) {}
			}
		}
		console.log("PUT to " + self);
		var request = Y.io(self, config);
	});
	
	Y.all(".actions .delete-action").on("click", function(e) {
		var config = {
			method: "DELETE",
			on: {
				success: function(id, o) {
					console.log(o.statusCode);
					Y.one("#Notification")
						.setStyle("opacity","1")
						.setStyle("background", "#333")
						.setAttribute("title", o.status + " " + o.statusText)
						.set("innerHTML", "Removed.");
					var myAnim = new Y.Anim({
		                node: '#Notification',
		                to: {
		                    opacity: 0
		                }
		            });
					myAnim.on("end", function() {
						// Is this the best thing to do?
						document.location.href = self;
					});
					window.setTimeout(function() {(function() {myAnim.run()}).apply(this)}, 2500);
				},
				failure: function(e) {
					console.dir(e);
					Y.one("#Notification")
						.setStyle("opacity","1")
						.setStyle("background", "red")
						.set("innerHTML", "Oops!");
				}
			}
		}
		if(confirm("Really remove it?\r\rReally?")) {
			var request = Y.io(self, config);
		}
	});
	Y.all(".savemeta-action").on("click", function(evt){
		var config = {
				method: "PUT",
				headers: { "Content-Type": "application/xml", "Accept": "application/xml" },
				data: editor.getCode(), 
				on: {
					start: function(id, o) {
					Y.one("#Notification")
						.setStyle("opacity","1")
						.setStyle("background", "yellow")
						.set("innerHTML", "Saving…");
					},
					success: function(id, o) {
						//Y.one("#DocumentXML").set("value", o.responseText);
						editor.setCode(o.responseText);
						console.log(editor.getCode())
						Y.one("#Notification").setStyle("opacity","1").setStyle("background", "#0c6").setAttribute("title", o.status + " " + o.statusText).set("innerHTML", "Saved.");
						var myAnim = new Y.Anim({
	                        node: '#Notification',
	                        to: {
	                            opacity: 0
	                        }
	                    });
	                    // Bind the function to this (Where's Prototype when I need it?)
	                    window.setTimeout(function() {(function() {myAnim.run()}).apply(this)}, 2500);
					},
					failure: function(e) {
						Y.one("#Notification").setStyle("opacity","1").setStyle("background", "red").set("innerHTML", "Oops!");
						console.dir(e); 
					},
					end: function(id) {}
				}
			}
			var request = Y.io(self + "", config);
	});
	Y.all(".add-collection-action").on("click", function(evt) {
		var collections = Y.one("#collections");
		var name = Y.one(".add-collection-name").get("value");
		var collection = Y.Node.create('<li class="collection new">'+name+'<input type="hidden" name="collections" value="'+name+'"/><button class="delete-action" title="Remove collection"></button></li>');
		collections.append(collection);
		Y.one(".add-collection-name").set("value", "").focus();
		
		// TODO: DRY in domready
		collection.one(".delete-action").on("click", function(evt){
			var target = evt.currentTarget;
			target.ancestor("li").remove();
		});
	});
	
});