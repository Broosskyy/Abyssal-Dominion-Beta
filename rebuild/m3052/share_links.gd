extends RefCounted
## One invitation for every client: try immediately in the browser, or install Android.
const BROWSER := "https://abyssal-dominion-browser.vercel.app/"
const DOWNLOADS := "https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases"
static func invitation() -> String:
	return "Komm mit mir auf See bei Abyssal Dominion! Direkt im Browser testen: "+BROWSER+"\nAndroid und weitere Downloads: "+DOWNLOADS
