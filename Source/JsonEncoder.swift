import Foundation

public extension JSONEncoder
{
	convenience init(prettyPrint:Bool) 
	{
		self.init()
		self.outputFormatting = [.prettyPrinted, .sortedKeys]
	}
}
