/*

	Tree view for viewing Json
 
*/
import SwiftUI


fileprivate extension JsonValue
{
	var textColour : Color
	{
		switch self
		{
			case .string(_):	.green
			case .int(_):		.blue
			case .bool(_):		.orange
			case .double(_):	.cyan
			case .null:			.secondary
			case .array(_):		.secondary
			case .object(_):	.secondary
		}
	}
	
	var type : String
	{
		switch self
		{
			case .string(_):	"String"
			case .int(_):		"Int"
			case .bool(_):		"Bool"
			case .double(_):	"Float"
			case .null:			"Null"
			case .array(_):		"Array"
			case .object(_):	"Object"
		}
	}
}



enum JsonNode: Identifiable
{
	case leaf(id: UUID = UUID(), key: String?, value: JsonValue)
	case object(id: UUID = UUID(), key: String?, value: JsonValue, children: [JsonNode])
	case array(id: UUID = UUID(), key: String?, value: JsonValue, children: [JsonNode])
	
	//	when we fail to go from Any to JsonValue
	case parseError(id:UUID=UUID(), key: String?, value:Error)
	
	var id: UUID 
	{
		switch self {
			case .leaf(let id, _, _): return id
			case .object(let id, _,_, _): return id
			case .array(let id, _,_, _): return id
			case .parseError(let id, _, _): return id
		}
	}
	
	
	var key: String? 
	{
		switch self 
		{
			case .leaf(_, let k, _), 
				.object(_, let k,_, _), 
				.array(_, let k,_, _),
				.parseError(_, let k, _):
				return k
		}
	}
	
	static func from(_ value: Any, key: String? = nil) -> JsonNode 
	{
		do
		{
			let jsonValue = try JsonValue(value)
			switch jsonValue
			{
				case .object(let dict):
					let children = dict.sorted { $0.key < $1.key }.map { JsonNode.from($0.value, key: $0.key) }
					return .object(key: key, value:jsonValue, children: children)
					
				case .array(let arr):
					let children = arr.enumerated().map { JsonNode.from($0.element, key: "[\($0.offset)]") }
					return .array(key: key, value:jsonValue, children: children)
			
				default:
					return .leaf(key: key, value: jsonValue)
			}
		}
		catch
		{
			return .parseError(key: key, value: error)
		}
	}
	
	static func from(json: Json, key: String? = nil) -> JsonNode 
	{
		let children = json.sorted{$0.key < $1.key }.map { JsonNode.from($0.value, key: $0.key) }
		return .object(key: key, value:.object(json), children: children)
	}
}


struct JsonTreeRow: View 
{
	let node : JsonNode
	@State var isExpanded = false
	var indent = CGFloat(16)
	let keyColour = Color.purple
	let seperatorColour = Color.secondary
	let disclosureGroupPadding = CGFloat(2)	//	disclosure group adds some inherit padding. We apply this elsewhere to match
	let disclosureGroupIndent = CGFloat(12)	//	align values, so we need to move past >
	
	var body: some View 
	{
		switch node 
		{
			case .leaf(_, let key, let value):
				HStack(spacing: 0)
				{
					NonDisclosureRowPrefix()
					leafRow(key: key, value: value)
					//.padding(.horizontal,disclosureGroupIndent)	//	 use NonDisclosureRowPrefix instead
				}
				//.background(.yellow)
				.padding(.vertical,disclosureGroupPadding)
				//.background(.green)
				
			case .parseError(_,let key,let error):
				errorRow(key: key, error: error)
				
			case .object(_, let key,let jsonValue, let children):
				expandableRow(key: key, value:jsonValue, count: children.count, children: children)

			case .array(_, let key,let jsonValue, let children):
				expandableRow(key: key, value:jsonValue, count: children.count, children: children)
		}
		
	}
	
	@ViewBuilder private func NonDisclosureRowPrefix() -> some View
	{
		//	indent alternative to disclosure >
		Rectangle()
			.fill(.clear)
			.frame(width: disclosureGroupIndent)
			.overlay
		{
			Text("-")
				.monospaced()
				.foregroundStyle(.tertiary)
				//.font(.system(size: 10))
				.fontWeight(.bold)
				.offset(x:-2)
		}
	}
	
	private func errorRow(key: String?, error: Error) -> some View 
	{
		HStack 
		{
			if let key { KeyLabel(key) }
			
			Text("Error: \(error.localizedDescription)")
				.background(.red)
				.foregroundStyle(.white)
			Spacer()
		}
	}
	
	private func leafRow(key: String?, value: JsonValue) -> some View 
	{
		HStack(spacing:0)
		{
			if let key { KeyLabel(key) }
			LeafValueView(value)
				.padding(.trailing,10)
			TypeLabel(value)
			Spacer()
		}
	}
	
	@ViewBuilder
	private func LeafValueView(_ value: JsonValue) -> some View
	{
		switch value
		{
			case .string(let s):
				Text("\"\(s)\"")
					.foregroundStyle(value.textColour)
				
			case .int(let i):
				Text("\(i)")
					.foregroundStyle(value.textColour)
				
			case .bool(let b):
				Text(b ? "true" : "false")
					.foregroundStyle(value.textColour)
				
			case .double(let d):
				Text(String(format: "%g", d))
					.foregroundStyle(value.textColour)
				
			case .null:
				Text("null")
					.foregroundStyle(value.textColour)
			
			case .array(_):
				Text("array")
					.foregroundStyle(value.textColour)
				
			case .object(_):
				Text("object")
					.foregroundStyle(value.textColour)
		}
	}
	
	
	private func expandableRow(
		key: String?,
		value: JsonValue,
		count: Int,
		children: [JsonNode],
	) -> some View 
	{
		DisclosureGroup(isExpanded: $isExpanded)
		{
			VStack(spacing: 0)
			{
				ForEach(children) 
				{ 
					child in
					JsonTreeRow(node: child)
						.padding(.leading, indent)
						//.background(.cyan)
				}
			}
			.padding(0)
		}
		label: 
		{
			let color = value.textColour
			
			HStack(spacing: 0)
			{
				if let key { KeyLabel(key) }
				
				//TypeLabel(.object(Json()))
				Text("Object")
					.monospaced()
					.foregroundStyle(.secondary)
				
				Text("\(count)")
					.font(.caption2)
					.padding(.horizontal, 5)
					.padding(.vertical, 1)
					.background(color.opacity(0.1))
					.foregroundStyle(color)
					.clipShape(Capsule())
				 
				Spacer()
			}
			.padding(.vertical, 0)
			//.background(.green)
		}
		//.background(.yellow)
		.frame(maxWidth: .infinity)
		//.background(.blue)

	}
	
	private func KeyLabel(_ key: String) -> some View 
	{
		Group 
		{
			Text(key).foregroundStyle(keyColour).fontWeight(.medium)
			+ Text(" : ").foregroundStyle(seperatorColour)
		}
		.font(.system(.body, design: .monospaced))
	}
	
	//	if this is null, its an error
	private func TypeLabel(_ value:JsonValue?) -> some View 
	{
		//	use .secondary and .background for dark/light mode adaptivity
		Text(value?.type ?? "Error")
			.font(.system(size:8, design: .monospaced))
			.foregroundStyle(.background)
			.padding(.horizontal, 8)
			.padding(.vertical, 4)
			.background(.secondary.opacity(0.5), in: Capsule())
	}
}


public struct JsonTreeView: View 
{
	struct IdentifiableString : Identifiable
	{
		var id : String			{	string	}
		var string : String
		
		init(_ string:String)
		{
			self.string = string
		}
	}
	
	let json : Json
	var root : JsonNode		{	JsonNode.from(json: json)	}
	var rootInitiallyExpanded : Bool
	var copyToClipboardButton : Bool
	@State var popupMessage : IdentifiableString? 
	
	public init(json:Json,rootInitiallyExpanded:Bool=true,copyToClipboardButton:Bool=true)
	{
		self.json = json
		self.rootInitiallyExpanded = rootInitiallyExpanded
		self.copyToClipboardButton = copyToClipboardButton
	}
	
	public var body: some View 
	{
		VStack
		{
			ScrollView
			{
				VStack(alignment: .leading, spacing: 0)
				{
					JsonTreeRow(node: root, isExpanded: rootInitiallyExpanded)
				}
				.font(.system(.body, design: .monospaced))
				.padding(.leading,4)
			}
			.background(Color(.textBackgroundColor))
			.clipShape(RoundedRectangle(cornerRadius: 5))
			
			//	built in copy-to-clipboard functionality
			//	todo: turn this into a toolbar to toggle word wrap, types labels etc
			if copyToClipboardButton
			{
				Button(action:OnCopyToClipboard)
				{
					Label("Copy to clipboard", systemImage: "sparkle.text.clipboard")
				}
				.popover(item: $popupMessage)
				{
					Text($0.string)
						.padding(20)
				}
			}
		}
	}

	func OnCopyToClipboard()
	{
		do
		{
			let jsonData = try JSONEncoder(prettyPrint: true).encode(self.json)
			guard let jsonString = String(data: jsonData, encoding: .utf8) else
			{
				throw JsonError("Failed to convert json encoding to string")
			}
			Clipboard.set(text: jsonString)
			self.popupMessage = IdentifiableString("Copied JSON to clipboard")
		}
		catch
		{
			self.popupMessage = IdentifiableString(error.localizedDescription)
		}
	}
}



#Preview 
{
	let sampleJson: Json = 
	[
		"user": try! JsonValue(
			[
			"id": 42,
			"name": "Graham Graham",
			"active": true,
			"address": [
				"city": "London",
				"postcode": "AA11 2BB"
			] as [String: Any],
			"tags": ["swift", "ios"] as [Any]
			] as [String: Any]),
		
		"version": try! JsonValue("1.0.0")
	]
	
	VStack
	{
		JsonTreeView(json: sampleJson)
			.padding(20)
	}
	.frame(height:200)
	.background(.blue)
}
