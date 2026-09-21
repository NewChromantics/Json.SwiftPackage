//	ios/ipados/tvos
#if canImport(UIKit)
import UIKit
#endif

//	macos
#if canImport(AppKit)
import AppKit

//	maybe not much point doing this as APIs are different
typealias UIPasteboard = NSPasteboard
#endif




//	https://stackoverflow.com/a/70500647/355753
public class Clipboard 
{
	public static func set(text: String)
	{
#if os(tvOS)
		//	no clipboard
#elseif canImport(UIKit)
		UIPasteboard.general.string = text
#else
		//	what happens if we dont clear?
		UIPasteboard.general.clearContents()
		UIPasteboard.general.setString(text, forType: .string)
#endif
	}
	
	//@available(macOS 10.13, *)
	public static func set(url: URL) 
	{
#if os(tvOS)
		//	no clipboard
#elseif canImport(UIKit)
		UIPasteboard.general.url = url
#else
		//	what happens if we dont clear?
		UIPasteboard.general.clearContents()
		UIPasteboard.general.setData(url.dataRepresentation, forType: .URL)
#endif
	}
	
	/*	expand this properly to copy an image
	@available(macOS 10.13, *)
	public static func set(urlContent: URL) 
	{
		guard let url = urlContent,
			  let nsImage = NSImage(contentsOf: url)
		else { return }
		
		let pasteBoard = NSPasteboard.general
		pasteBoard.clearContents()
		pasteBoard.writeObjects([nsImage])
	}
	*/
	public static func clear()
	{
#if os(tvOS)
		//	no clipboard
#elseif canImport(UIKit)
		UIPasteboard.general.string = nil
#else
		UIPasteboard.general.clearContents()
#endif
	}
}


