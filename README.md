# Zippy

Zippy is an iOS framework for reading ZIP files. It's written completely in Swift 3 and uses [Apple's compression framework](https://developer.apple.com/reference/compression) for decompression.

# Usage

	import Zippy
	
	let fileURL = <URL to file>
	let file = try ZipFile(url: fileURL)
	
	for filename in file {
		let data = file[filename]
		// Do something with file data…
	}

# TODO

- Everything
- Support for password-protected ZIP files
- Support for split ZIP files
- Writing ZIP files
- License + CocoaPods
