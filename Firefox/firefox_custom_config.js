// IMPORTANT: This first line must always be a comment

// Method 1
// const searchKeybind = document.getElementById("key_search2");
// if (searchKeybind) searchKeybind.remove();
// To use with ctrl + alt
// searchKeybind.setAttribute("modifiers", "accel,alt");

// Method 2

try {
	let {classes:Cc, interfaces:Ci, manager:Cm, utils:Cu} = Components;
	let Services = globalThis.Services || ChromeUtils.import("resource://gre/modules/Services.jsm").Services;
	function ConfigJS() { Services.obs.addObserver(this, 'chrome-document-global-created', false); }
	ConfigJS.prototype = {
	observe: function (aSubject) { aSubject.addEventListener('DOMContentLoaded', this, {once: true}); },
	handleEvent: function (aEvent) {
		let document = aEvent.originalTarget;
		let window = document.defaultView;
		let location = window.location;
		if (/^(chrome:(?!\/\/(global\/content\/commonDialog|browser\/content\/webext-panels)\.x?html)|about:(?!blank))/i.test(location.href)) {
		if (window._gBrowser) {
			let attr, elm, key, mbo;
			let KEYS = ['key_search2'];
			let ATTR = ['key','modifiers','command','oncommand'];
			for (key in KEYS){
				elm = window.document.getElementById(KEYS[key]);
				if (elm) for (attr in ATTR) if (ATTR[attr] in elm.attributes) elm.removeAttribute(ATTR[attr]);
			}
		}
		}
	}
	};
	if (!Services.appinfo.inSafeMode) { new ConfigJS(); }
} catch(e) {Cu.reportError(e);}
