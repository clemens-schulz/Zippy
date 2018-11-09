# Zippy

Zippy is an iOS and macOS Framework for reading ZIP files. It's written in Swift 4 and uses [Apple's compression framework](https://developer.apple.com/reference/compression) for efficient decompression.

## TODO

The framework should not yet be used in production. Some stuff doesn't work yet. Please wait until version 1.0!

### TODO for version 1.0

- A lot of small stuff (see "// TODO:" in source code)
- Support for weak password-protected ZIP files
- Support for more compression algorithms (currently only no compression and deflate are supported)
- Support for data descriptors (Field in ZIP format)
- Complete Zip64 support 
- More and better tests
- More documentation in code
- More consistent errors

### Future releases

- Support for encrypted zip files (NOT PKZip strong encryption!)
- Creating and editing ZIP files
- Option to provide passwords without delegate

## Features

- Easy to use
- Support for reading ZIP files from `URL`, `FileWrapper`, or `Data`
- Support for split ZIP files
- Support for 64-bit ZIP files
- Support for (some) password protected ZIP files
- Optional verification of checksums
- Uses Apple's built-in compression framework
- Uses XCTest for testing

## Usage

### Get filenames and data

``` swift
import Zippy

let fileURL = <URL to file>
let zipFile = try! ZipArchive(url: fileURL)

print(zipFile.filenames)

for oneFilename in zipFile {
	let data = file[oneFilename]
	// Do something with file data…
}
```

### Extract and verify

``` swift
import Zippy

let fileURL = <URL to file>
let zipFile = try! ZipArchive(url: fileURL)

do {
	let data = try zipFile.extract(file: "filename.txt", verify: true)
	//Do something with file data
} catch CompressedArchiveError.corrupted {
	// Error handling
}
```

### Extract to file

``` swift
import Zippy

let fileURL = <URL to file>
let zipFile = try! ZipArchive(url: fileURL)

do {
	let filename = "filename.txt"
	let outputURL = URL(fileURLWithPath: "path/to/output.txt")
	
	try zipFile.extract(file: filename, to: outputURL, verify: false)
} catch {
	// Error handling
}
```

## Installation

### Requirements

- Swift 4
- iOS 11 or macOS 10.11
- 64-bit

### CocoaPods

1. Make sure [CocoaPods](https://cocoapods.org) is installed and `cd` into your project directory.

2. Update your Podfile to include the following

``` ruby
pod 'Zippy'
```

3. Run `pod install`

### Carthage

TODO

### Manual

1. Submodule, clone, or download Zippy and drag the **Zippy.xcodeproj** file into your own project.

2. Select your project file in the Xcode sidebar, then select your target. In the **General** tab, click the **+** button under **Embedded Binaries**.

3. Select **Zippy.framework**. Make sure it's for the right platform (i.e. iOS or macOS)

4. Click **Add**.

The framework should appear under **Embedded Binaries** and **Linked Frameworks and Libraries**

## Contribution

TODO: rules for pull requests. (use "feature/feature-name" branch from "develop" branch)

Feel free to send pull requests or report bugs.
