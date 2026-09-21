// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription



let package = Package(
	name: "Json",
	
	platforms: [
		.iOS(.v14),
		.macOS(.v14)	//	14 for .foregroundStyle
	],
	

	products: [
		.library(
			name: "Json",
			targets: [
				"Json"
			]),
	],
	
	dependencies: [
	],
	
	targets: [

		.target(
			name: "Json",
		)
	]
)
