/* This is a mess (but works) */                
YUI().use("node", "io", "dump", "anim", function(Y) {
	var self = document.URL; // For some reason, Safari decodes document.location.href and others
	var state = document.location.hash.slice(1);
	
	var editor;
	
	//Y.on("domready", function(e) {});
	
	Y.all("button.delete-action").on("click", function(e) {
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
					//myAnim.on("end", function() {});
					window.setTimeout(function() {(function() {myAnim.run()}).apply(this)}, 2500);
					// update the client state
					e.target.ancestor("tr").remove();
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
		var uri = e.currentTarget.getAttribute("data-uri");
		if(confirm("Remove " + uri + "?\r\rReally?")) {
			var url = e.currentTarget.getAttribute("data-url");
			var request = Y.io(url, config);
		}
	});
});