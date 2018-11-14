//
//  CompressedArchive.swift
//  Zippy
//
//  Created by Clemens on 09.01.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

public protocol CompressedArchive: AnyObject {

	/**
	List of names of all compressed files in archive
	*/
	var filenames: [String] { get }

	/**
	The delegate is used to provide passwords or data of additional segments
	*/
	var delegate: CompressedArchiveDelegate? { get set }

	/**
	Reads compressed archive at URL.

	- Parameter url: URL to archive file. Symbolic links will be resolved.
	- Parameter delegate: Optional delegate that may provide additional segments and passwords.

	- Throws: An error of type `CompressedArchiveError`, `CocoaError` (especially `CocoaError.fileNoSuchFile` or
	`CocoaError.fileReadNoPermission`), or format specific error.
	*/
	init(url: URL, delegate: CompressedArchiveDelegate?) throws

	/**
	Reads compressed archive from file wrapper.

	- Parameter fileWrapper: File wrapper for archive file. Must be regular file.
	- Parameter delegate: Optional delegate that may provide additional segments and passwords.

	- Throws: An instance of `CompressedArchiveError` or format specific error.
	*/
	init(fileWrapper: FileWrapper, delegate: CompressedArchiveDelegate?) throws

	/**
	Reads compressed archive from data.

	It's recommended to use file-mapped `Data` objects to reduce memory usage. This is required, if you want to open
	very large files. Take a look at `Data.init(contentsOf: URL, options: Data.ReadingOptions)` or `FileWrapper`, if
	you don't know where to start.

	- Parameter data: Data of compressed archive
	- Parameter delegate: Optional delegate that may provide additional segments and passwords.

	- Throws: An instance of `CompressedArchiveError` or format specific error.
	*/
	init(data: Data, delegate: CompressedArchiveDelegate?) throws

	/**
	Returns uncompressed data of file with specific filename. May return `nil` if file does not exist or an error
	occurred. To get more detailed error reason, use `extract(file:verify:)`.

	- Parameter filename: Name of file

	- Returns: Uncompressed data of file or `nil`
	*/
	subscript(filename: String) -> Data? { get }

	/**
	Returns uncompressed data of specified file.

	- Parameter filename: Name of file
	- Parameter verify: Verify checksum of extracted data. Throws `CompressedArchiveError.corrupted` if check fails. Do
	not use this option, if performance is important.

	- Throws: An instance of `CompressedArchiveError`

	- Returns: Uncompressed data
	*/
	func extract(file filename: String, verify: Bool) throws -> Data

	/**
	Writes uncompressed data of file to URL. Use this method for files that are too large to fit into memory.

	If `url` points to a folder, the extracted file will be placed inside using their original names. Throws error, if
	file already exists.

	- Parameter filename: Name of file
	- Parameter url: Output URL pointing to existing folder or not-existing file.
	- Parameter verify: Verify checksum of extracted data. Throws `CompressedArchiveError.corrupted` if check fails, but
	already written data will not be removed. Do not use this option, if performance is important.

	- Throws: An instance of `CompressedArchiveError` or `CocoaError`
	*/
	func extract(file filename: String, to url: URL, verify: Bool) throws

	/**
	Returns file info

	- Parameter filename: Name of file

	- Throws: An error of type `CompressedArchiveError.noSuchFile`
	*/
	func info(for filename: String) throws -> CompressedFileInfo
}

extension CompressedArchive {

	public init(url: URL, delegate: CompressedArchiveDelegate? = nil) throws {
		var fileWrapper: FileWrapper

		fileWrapper = try FileWrapper(url: url, options: [])

		if fileWrapper.isSymbolicLink {
			var visitedURLs = [url]
			repeat {
				if let destinationURL = fileWrapper.symbolicLinkDestinationURL {
					if visitedURLs.contains(destinationURL) {
						break
					}

					fileWrapper = try FileWrapper(url: destinationURL, options: [])
					visitedURLs.append(destinationURL)
				}
			} while fileWrapper.isSymbolicLink
		}

		guard fileWrapper.isRegularFile else {
			throw CompressedArchiveError.noRegularFile
		}

		try self.init(fileWrapper: fileWrapper, delegate: delegate)
	}

	public init(fileWrapper: FileWrapper, delegate: CompressedArchiveDelegate? = nil) throws {
		guard fileWrapper.isRegularFile else {
			throw CompressedArchiveError.noRegularFile
		}

		if let data = fileWrapper.regularFileContents {
			try self.init(data: data, delegate: delegate)
		} else {
			throw CompressedArchiveError.readFailed
		}
	}

	public init(data: Data) throws {
		try self.init(data: data, delegate: nil)
	}

	public subscript(filename: String) -> Data? {
		return try? self.extract(file: filename, verify: false)
	}
}

extension Sequence where Self: CompressedArchive {

	public func makeIterator() -> IndexingIterator<[String]> {
		return self.filenames.makeIterator()
	}
}
