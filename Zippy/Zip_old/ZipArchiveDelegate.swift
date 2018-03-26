//
//  ZipArchiveDelegate.swift
//  Zippy
//
//  Created by Clemens on 11.01.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

public protocol ZipArchiveDelegate: class {
	/**
	Returns contents of segment file. Segment files belong to split ZIP archives and usually end with .z01, .z02, ...

	It's recommended to use file-mapped `Data` objects to reduce memory usage. This is required, if you want to open
	very large files. Take a look at `Data.init(contentsOf: URL, options: Data.ReadingOptions)` or `FileWrapper`, if
	you don't know where to start.

	- Parameter archive: Zip archive
	- Parameter segment: Segment number starting at 1. Usually equals number in file extension (e.g. .z01 -> segment 1)

	- Returns: Contents of file as `Data? or `nil` if file doesn't exist or reading failed.
	*/
	func zipArchive(_ archive: ZipArchive, dataForSegment segment: Int) -> Data?

	/**
	Returns password for archive or file in archive.

	- Parameter archive: Zip archive
	- Parameter filename: Name of file or `nil`, if for whole archive

	- Returns: Password or `nil` to cancel.
	*/
	func zipArchive(_ archive: ZipArchive, passwordForFile filename: String?) -> String?
}

extension ZipArchiveDelegate {

	func zipArchive(_ archive: ZipArchive, dataForSegment segment: Int) -> Data? {
		return nil
	}

	func zipArchive(_ archive: ZipArchive, passwordForFile filename: String?) -> String? {
		return nil
	}
}
