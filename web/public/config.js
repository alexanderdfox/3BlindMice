(function(){
	// Runtime configuration for the web client
	// Priority order (highest to lowest):
	// 1) URL param ?socketServer=https://host
	// 2) localStorage key SOCKET_IO_URL
	// 3) Hardcoded fallback below
	// 4) window.location.origin
	function getParam(name){
		const url = new URL(window.location.href);
		return url.searchParams.get(name);
	}
	const fromParam = getParam('socketServer');
	const fromStorage = (function(){ try { return localStorage.getItem('SOCKET_IO_URL'); } catch(e){ return null; } })();
	const hardcoded = 'https://localhost:3000/';
	const fallback = window.location.origin;
	const chosen = fromParam || fromStorage || hardcoded || fallback;

	// Local-only mode (no server). Enable with ?local=1 or localStorage.LOCAL_MODE="1"
	const localParam = getParam('local');
	const localStorageFlag = (function(){ try { return localStorage.getItem('LOCAL_MODE'); } catch(e){ return null; } })();
	const localMode = localParam === '1' || localStorageFlag === '1';

	window.APP_CONFIG = {
		serverUrl: chosen,
		localMode: localMode
	};
})();
