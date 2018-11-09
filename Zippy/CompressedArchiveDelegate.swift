//
//  CompressedArchiveDelegate.swift
//  Zippy-iOS
//
//  Created by Clemens on 09.11.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

public protocol CompressedArchiveDelegate: AnyObject {

	/**
	Returns contents of archive segment, usually the content of another file belonging to a split archive. If accessing
	files requires user interaction, it's a good idea to ask the user to provide all segments at once and caching the
	file URLs for future delegate calls.

	It's recommended to use file-mapped `Data` objects to reduce memory usage. This is required, if you want to open
	very large files. Take a look at `Data.init(contentsOf: URL, options: Data.ReadingOptions)` or `FileWrapper`, if
	you don't know where to start.

	- Parameter archive: Compressed archive
	- Parameter segmentIndex: Segment index starting at 0.
	- Parameter segmentCount: Total number of segments, including already opened archive file.

	- Returns: Contents of file as `Data? or `nil` if file doesn't exist or reading failed
	*/
	func compressedArchive(_ archive: CompressedArchive, dataForSegment segmentIndex: Int, segmentCount: Int) -> Data?

	/**
	Returns password for archive or file in archive. If the password is wrong, this method is called again until it
	returns the right password or `nil`.

	- Parameter archive: Compressed archive
	- Parameter filename: Name of file or `nil`, if for whole archive
	- Parameter attempts: Number of failed attempts. Is `0` for first attempt

	- Returns: Password or `nil` to cancel
	*/
	func compressedArchive(_ archive: CompressedArchive, passwordForFile filename: String?, attempts: Int) -> String?

	/**
	Return `false` to cancel extraction before it even starts. This method is intened for performing sanity checks (e.g.
	by checking compression ratio or output file size) before extracting data.

	- Parameter archive: Compressed archive
	- Parameter filename: Name of file
	- Parameter info: Info about file

	- Returns: `true` to allow, `false` to cancel extraction
	*/
	func compressedArchive(_ archive: CompressedArchive, shouldExtractFile filename: String, withInfo info: CompressedFileInfo) -> Bool
}

extension CompressedArchiveDelegate {

	func compressedArchive(_ archive: CompressedArchive, dataForSegment segmentIndex: Int) -> Data? {
		return nil
	}

	func compressedArchive(_ archive: CompressedArchive, passwordForFile filename: String?, attempts: Int) -> String? {
		return nil
	}

	func compressedArchive(_ archive: CompressedArchive, shouldExtractFile filename: String, withInfo info: CompressedFileInfo) -> Bool {
		return true
	}
}
