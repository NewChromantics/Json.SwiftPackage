/*
	Json is an encodable, sendable, dictionary type.
	Initially made as a replacement for [String:Any]
*/
import Foundation 


public typealias Json = [String: JsonValue]


//	helpful inits
public extension Json
{
	//	this is a common json representation in swift (specifically Firebase)
	init(_ jsonWithAny:[String:Any]) throws
	{
		let jsonObject = try jsonWithAny.mapValues 
		{
			try JsonValue($0) 
		}
		self = jsonObject
	} 
	
	init<ObjectType: Codable>(fromObject object: ObjectType) throws
	{
		//	encode to json, then decode to this
		//	gr; is there a better way? like a decoder that is fed from object.encode()
		let jsonData = try JSONEncoder().encode(object)
		self = try JSONDecoder().decode(Self.self, from: jsonData)
	}
}



public struct JsonError: LocalizedError
{
	public var errorDescription: String?

	public init(_ description: String) 
	{
		self.errorDescription = description
	}
}



//	a replacement for Any that only conforms to json-compatible types
public enum JsonValue : Sendable, Equatable, Hashable, Codable
{
	case string(String)
	case bool(Bool)
	case int(Int)
	case double(Double)
	case array([JsonValue])
	case object(Json)
	case null	//	technically null an object, but lets stick with this distinction as it's still different between {} and null
	
	//	Accessor properties that return nil if not the right type (same behavior as `Any as?`)
	public var string: String? 
	{
		if case .string(let value) = self { return value }
		return nil
	}
	
	public var int: Int? 
	{
		if case .int(let value) = self { return value }
		return nil
	}
	
	public var bool: Bool? 
	{
		if case .bool(let value) = self { return value }
		return nil
	}
	
	public var double: Double? 
	{
		if case .double(let value) = self { return value }
		return nil
	}
	
	public var array: [JsonValue]? 
	{
		if case .array(let value) = self { return value }
		return nil
	}
	
	public var object: Json? 
	{
		if case .object(let value) = self { return value }
		return nil
	}
	
	public var isNull: Bool 
	{
		if case .null = self { return true }
		return false
	}
	


	
	public init(_ value: Any) throws
	{
		// Convert Any to JsonValue
		switch value 
		{
			case let v as Bool:		self = .bool(v)
			case let v as Int:		self = .int(v)
			case let v as Double:	self = .double(v)
			case let v as String:	self = .string(v)
			case is NSNull:			self = .null
					
			case let v as [Any]:
				let subValues = try v.map { try JsonValue($0) }
				self = .array(subValues)
					
			case let v as [String: Any]:
				let subValues = try v.mapValues { try JsonValue($0) }
				self = .object(subValues)
				
			case let v as JsonValue:
				self = v
			
			default:
				throw JsonError("Any value (\(value)) is a value not convertible to JsonValue")
		}
	}
	
	//	object -> Json
	public init<ObjectType: Codable>(fromObject object: ObjectType) throws
	{
		//	encode to json, then decode to this
		let jsonData = try JSONEncoder().encode(object)
		self = try JSONDecoder().decode(Self.self, from: jsonData)
	}
	
	public init(from decoder: any Decoder) throws 
	{
		let container = try decoder.singleValueContainer()
		
		//	check for null explicitly first
		if container.decodeNil() 
		{
			self = .null
			return
		}
		
		//	try other types
		if let v = try? container.decode(Bool.self)         { self = .bool(v) }
		else if let v = try? container.decode(Int.self)     { self = .int(v) }
		else if let v = try? container.decode(Double.self)  { self = .double(v) }
		else if let v = try? container.decode(String.self)  { self = .string(v) }
		else if let v = try? container.decode([JsonValue].self) { self = .array(v) }
		else if let v = try? container.decode(Json.self)    { self = .object(v) }
		else 
		{
			throw DecodingError.dataCorruptedError(in: container,debugDescription: "Cannot decode JsonValue from the given data")
		}
	}
	
	public func encode(to encoder: any Encoder) throws 
	{
		var container = encoder.singleValueContainer()
		switch self 
		{
			case .bool(let v):       try container.encode(v)
			case .int(let v):        try container.encode(v)
			case .double(let v):     try container.encode(v)
			case .string(let v):     try container.encode(v)
			case .array(let v):      try container.encode(v)
			case .object(let v):     try container.encode(v)
			case .null:              try container.encodeNil()
		}
	}
	
	
	public static func == (lhs: Self, rhs: Self) -> Bool
	{
		switch (lhs, rhs) 
		{
			case (.null, .null):
				return true
			case (.bool(let l), .bool(let r)):
				return l == r
			case (.int(let l), .int(let r)):
				return l == r
			case (.double(let l), .double(let r)):
				return l == r
			case (.string(let l), .string(let r)):
				return l == r
			case (.array(let l), .array(let r)):
				return l == r
			case (.object(let l), .object(let r)):
				return l == r
				
			//	value type mismatch
			default:
				return false
		}
	}
	
	public func hash(into hasher: inout Hasher)
	{
		switch self 
		{
			case .null:
				hasher.combine(0)
			case .bool(let v):
				hasher.combine(1)
				hasher.combine(v)
			case .int(let v):
				hasher.combine(2)
				hasher.combine(v)
			case .double(let v):
				hasher.combine(3)
				hasher.combine(v)
			case .string(let v):
				hasher.combine(4)
				hasher.combine(v)
			case .array(let v):
				hasher.combine(5)
				hasher.combine(v)
			case .object(let v):
				hasher.combine(6)
				hasher.combine(v)
		}
	}
}



