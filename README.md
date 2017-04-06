# Zippy

Zippy is an iOS framework for reading ZIP files. It's written in Swift 3 and uses [Apple's compression framework](https://developer.apple.com/reference/compression) for decompression.

Please read the [TODO section](#todo) before using it!

## Features

- Easy to use
- Support for reading ZIP files using `FileWrapper` or `URL`
- Support for split ZIP files
- Tests

## Usage

	import Zippy
	
	let fileURL = <URL to file>
	let file = try! ZipFile(url: fileURL)
	
	for filename in file {
		let data = file[filename]
		// Do something with file data…
	}

## Tests

Testdata is generated automatically when running the tests for the first time. It's **about 640MB big** to test the framework with large files. I should probably add an option to skip the large file test…

## TODO

The framework is already usable, but it still ignores a lot of information in ZIP files. It has not been tested with ZIP files from different sources. Make sure to test it thoroughly before shipping your app.

There is still a lot do to:

- A lot of small stuff (see "// TODO:" in source code)
- Support for password-protected ZIP files
- Creating and editing ZIP files
- Support for more compression algorithms
- More and better tests
- More documentation in code
- Support for macOS (new target and tests)
- CocoaPods

Feel free to send push requests or report bugs.
