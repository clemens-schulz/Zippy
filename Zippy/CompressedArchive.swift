//
//  CompressedArchive.swift
//  Zippy
//
//  Created by Clemens on 09.01.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

public enum CompressedArchiveError: Error {

	/// File does not exist
	case noSuchFile

	/// Reading file failed
	case readFailed

	/// Extracting file failed, because file at output path already exists
	case fileAlreadyExists

	/// Writing extracted data to file failed
	case writeFailed

	/// Delegate did not provide data for missing segment
	case segmentMissing

	/// Password provided by delegate is wrong
	case wrongPassword

	/// Checksum of uncompressed data does not match expected checksum
	case corruptedData
}

public protocol CompressedFileInfo {
	var compressedSize: Int { get }
	var uncompressedSize: Int { get }
}

public protocol CompressedArchive: AnyObject {

	/**
	The delegate is used to provide additional data or passwords
	*/
	weak var delegate: CompressedArchiveDelegate? { get set }

	/**
	Number of files, if archive is split into multiple files. For regular archives this value is 1.
	*/
	var numberOfSegments: Int { get }

	/**
	List of names of all compressed files in archive
	*/
	var filenames: [String] { get }

	/**
	Reads compressed archive from data.

	It's recommended to use file-mapped `Data` objects to reduce memory usage. This is required, if you want to open
	very large files. Take a look at `Data.init(contentsOf: URL, options: Data.ReadingOptions)` or `FileWrapper`, if
	you don't know where to start.

	- Parameter data: Data of compressed archive
	- Parameter delegate: The delegate is needed, if the archive requires a password or is split into multiple files

	- Throws: An instance of `CompressedArchiveError` or file type specific error
	*/
	init(data: Data, delegate: CompressedArchiveDelegate?) throws

	/**
	Returns uncompressed data of specified file.

	- Parameter filename: Name of file
	- Parameter verify: Verify checksum of file

	- Throws: An instance of `CompressedArchiveError` or file type specific error

	- Returns: Uncompressed data
	*/
	func extract(file filename: String, verify: Bool) throws -> Data

	/**
	Writes uncompressed data of file to URL. Use this method for files that are too large to fit into memory.

	If `url` points to a folder, the extracted file will be placed inside using their original names. Throws error, if
	file already exists.

	- Parameter filename: Name of file
	- Parameter url: Output URL pointing to existing folder or not-existing file.
	- Parameter verify: Verify checksum of file(s)

	- Throws: An instance of `CompressedArchiveError` or file type specific error
	*/
	func extract(file filename: String, to url: URL, verify: Bool) throws

	/**
	Returns file info

	- Parameter filename: Name of file

	- Throws: An instance of `CompressedArchiveError` or file type specific error
	*/
	func info(for filename: String) throws -> CompressedFileInfo

}

extension CompressedArchive {

	/**
	Reads compressed archive at URL.

	- Parameter url: URL to archive file. Symbolic links will be resolved.
	- Parameter delegate: The delegate is needed, if the archive requires a password or is split into multiple files.

	- Throws: An instance of `CompressedArchiveError` or file type specific error
	*/
	public init(url: URL, delegate: CompressedArchiveDelegate? = nil) throws {
		var fileWrapper: FileWrapper

		do {
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
		} catch let error as NSError {
			if error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
				throw CompressedArchiveError.noSuchFile
			} else {
				throw CompressedArchiveError.readFailed
			}
		}

		if !fileWrapper.isRegularFile {
			throw CompressedArchiveError.readFailed
		}

		try self.init(fileWrapper: fileWrapper, delegate: delegate)
	}

	/**
	Reads compressed archive from file wrapper.

	- Parameter fileWrapper: File wrapper for archive file. Must be regular file.
	- Parameter delegate: The delegate is needed, if the archive requires a password or is split into multiple files.

	- Throws: An instance of `CompressedArchiveError` or file type specific error
	*/
	public init(fileWrapper: FileWrapper, delegate: CompressedArchiveDelegate? = nil) throws {
		if !fileWrapper.isRegularFile {
			throw CompressedArchiveError.readFailed
		}

		if let data = fileWrapper.regularFileContents {
			try self.init(data: data, delegate: delegate)
		} else {
			throw CompressedArchiveError.readFailed
		}
	}

	/**
	Reads compressed archive from data.

	- Parameter data: Data of compressed archive

	- Throws: An instance of `CompressedArchiveError` or file type specific error
	*/
	public init(data: Data) throws {
		try self.init(data: data, delegate: nil)
	}

	/**
	Returns uncompressed data of file with specific filename. May return `nil` if file does not exist or an error
	occurred. To get more detailed error reason, use `extract(file:verify:)`.

	- Parameter filename: Name of file

	- Returns: Uncompressed data of file or `nil`
	*/
	public subscript(filename: String) -> Data? {
		return try? self.extract(file: filename, verify: false)
	}

	func extract(file filename: String) throws -> Data {
		return try self.extract(file: filename, verify: false)
	}

	func extract(file filename: String, to url: URL) throws {
		return try self.extract(file: filename, to: url, verify: false)
	}

}

extension Sequence where Self: CompressedArchive {

	public func makeIterator() -> IndexingIterator<[String]> {
		return self.filenames.makeIterator()
	}

}

public protocol CompressedArchiveDelegate: AnyObject {
	
	/**
	Returns contents of archive segment, usually the content of another file belonging to a split archive.

	It's recommended to use file-mapped `Data` objects to reduce memory usage. This is required, if you want to open
	very large files. Take a look at `Data.init(contentsOf: URL, options: Data.ReadingOptions)` or `FileWrapper`, if
	you don't know where to start.

	- Parameter archive: Compressed archive
	- Parameter segment: Segment index starting at 0.

	- Returns: Contents of file as `Data? or `nil` if file doesn't exist or reading failed.
	*/
	func compressedArchive(_ archive: CompressedArchive, dataForSegment segmentIndex: Int) -> Data?

	/**
	Returns password for archive or file in archive. If the password is wrong, this method is called again until it
	returns the right password or `nil`.

	- Parameter archive: Zip archive
	- Parameter filename: Name of file or `nil`, if for whole archive
	- Parameter attempts: Number of failed attempts. Is `0` for first attempt

	- Returns: Password or `nil` to cancel.
	*/
	func compressedArchive(_ archive: CompressedArchive, passwordForFile filename: String?, attempts: Int) -> String?

}

extension CompressedArchiveDelegate {
	func compressedArchive(_ archive: CompressedArchive, dataForSegment segmentIndex: Int) -> Data? {
		return nil
	}

	func compressedArchive(_ archive: CompressedArchive, passwordForFile filename: String?, attempts: Int) -> String? {
		return nil
	}

}
