//
//  CentralDirectory.swift
//  Zippy
//
//  Created by Clemens on 01.02.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

extension Zip {

	/**
	Struct for header in central directory. The header has the following memory layout:

		    | Description                      | Size      | Value
		----+----------------------------------+-----------+------------
		0   | Signature                        | 4 bytes   | 0x02014b50
		----+----------------------------------+-----------+------------
		4   | Version made by                  | 2 bytes   |
		----+----------------------------------+-----------+------------
		6   | Version needed to extract        | 2 bytes   |
		----+----------------------------------+-----------+------------
		8   | General purpose bit flag         | 2 bytes   |
		----+----------------------------------+-----------+------------
		10  | Compression method               | 2 bytes   |
		----+----------------------------------+-----------+------------
		12  | Last mod file time               | 2 bytes   |
		----+----------------------------------+-----------+------------
		14  | Last mod file date               | 2 bytes   |
		----+----------------------------------+-----------+------------
		16  | CRC-32                           | 4 bytes   |
		----+----------------------------------+-----------+------------
		20  | Compressed size                  | 4 bytes   |
		----+----------------------------------+-----------+------------
		24  | Uncompressed size                | 4 bytes   |
		----+----------------------------------+-----------+------------
		28  | File name length                 | 2 bytes   |
		----+----------------------------------+-----------+------------
		30  | Extra field length               | 2 bytes   |
		----+----------------------------------+-----------+------------
		32  | File comment length              | 2 bytes   |
		----+----------------------------------+-----------+------------
		34  | Disk number start                | 2 bytes   |
		----+----------------------------------+-----------+------------
		36  | Internal file attributes         | 2 bytes   |
		----+----------------------------------+-----------+------------
		40  | External file attributes         | 4 bytes   |
		----+----------------------------------+-----------+------------
		44  | Relative offset of local header  | 4 bytes   |
		----+----------------------------------+-----------+------------
		48  | File name                        | variable  |
		----+----------------------------------+-----------+------------
		*   | Extra field                      | variable  |
		----+----------------------------------+-----------+------------
		*   | File comment                     | variable  |

	*/
	struct CentralDirectoryHeader {

		static let signature: UInt32 = 0x02014b50
		static let minLength: Int = 48

		let versionMadeBy: Version
		let versionNeeded: Version

		let flags: GeneralPurposeBitFlag
		let compressionMethod: CompressionMethod
		let modificationTime: MSDOSTime
		let modificationDate: MSDOSDate

		let crc32checksum: UInt32
		let compressedSize: UInt32
		let uncompressedSize: UInt32

		let filenameLength: UInt16
		let extraFieldLength: UInt16
		let fileCommentLength: UInt16

		let startDiskNumber: UInt16
		let internalFileAttributes: InternalFileAttributes
		let externalFileAttributes: UInt32
		let relativeOffsetOfLocalHeader: UInt32

		let filename: Data
		let extraFields: ExtensibleData
		let fileComment: Data

		init(reader: DataReader, at index: inout DataReader.Index) throws {
			do {
				try reader.expect(value: CentralDirectoryHeader.signature, at: &index)
			} catch DataReaderError.valueNotFound {
				throw ZipError.unexpectedSignature
			}

			self.versionMadeBy = Version(rawValue: try reader.read(at: &index))
			self.versionNeeded = Version(rawValue: try reader.read(at: &index))

			self.flags = GeneralPurposeBitFlag(rawValue: try reader.read(at: &index))
			let compressionMethodRaw: UInt16 = try reader.read(at: &index)
			if let compressionMethod = CompressionMethod(rawValue: compressionMethodRaw) {
				self.compressionMethod = compressionMethod
			} else {
				throw ZipError.unknownCompressionMethod(method: compressionMethodRaw)
			}
			self.modificationTime = MSDOSTime(rawValue: try reader.read(at: &index))
			self.modificationDate = MSDOSDate(rawValue: try reader.read(at: &index))

			self.crc32checksum = try reader.read(at: &index)
			self.compressedSize = try reader.read(at: &index)
			self.uncompressedSize = try reader.read(at: &index)

			self.filenameLength = try reader.read(at: &index)
			self.extraFieldLength = try reader.read(at: &index)
			self.fileCommentLength = try reader.read(at: &index)

			self.startDiskNumber = try reader.read(at: &index)
			self.internalFileAttributes = InternalFileAttributes(rawValue: try reader.read(at: &index))
			self.externalFileAttributes = try reader.read(at: &index)
			self.relativeOffsetOfLocalHeader = try reader.read(at: &index)

			self.filename = try reader.read(Int(self.filenameLength), at: &index)
			self.extraFields = try ExtensibleData(reader: reader, at: &index, length: Int(self.extraFieldLength))
			self.fileComment = try reader.read(Int(self.fileCommentLength), at: &index)
		}

		var zip64Fields: Zip.Zip64ExtendedInformationExtraField.Fields {
			var zip64Fields: Zip.Zip64ExtendedInformationExtraField.Fields = .none

			if self.startDiskNumber == type(of: self.startDiskNumber).max {
				zip64Fields.insert(.startDiskNumber)
			}

			if self.relativeOffsetOfLocalHeader == type(of: self.relativeOffsetOfLocalHeader).max {
				zip64Fields.insert(.relativeHeaderOffset)
			}

			if self.uncompressedSize == type(of: self.uncompressedSize).max {
				zip64Fields.insert(.originalSize)
			}

			if self.compressedSize == type(of: self.compressedSize).max {
				zip64Fields.insert(.compressedSize)
			}

			return zip64Fields
		}
	}

	/**
	Struct for digital signature of central directory. The structure has the following memory layout:

		    | Description           | Size      | Value
		----+-----------------------+-----------+------------
		0   | Signature             | 4 bytes   | 0x05054b50
		----+-----------------------+-----------+------------
		4   | Size of data          | 2 bytes   |
		----+-----------------------+-----------+------------
		6   | Signature data        | variable  |

	*/
	struct CentralDirectorySignature {
		static let signature: UInt32 = 0x05054b50
		static let minLength: Int = 6

		let signatureLength: UInt16
		let signatureData: Data

		init(reader: DataReader, at index: inout DataReader.Index) throws {
			do {
				try reader.expect(value: CentralDirectorySignature.signature, at: &index)
			} catch DataReaderError.valueNotFound {
				throw ZipError.unexpectedSignature
			}

			self.signatureLength = try reader.read(at: &index)
			self.signatureData = try reader.read(Int(self.signatureLength), at: &index)
		}
	}

	/**
	Struct for central directory
	*/
	struct CentralDirectory {

		let headers: [CentralDirectoryHeader]
		let digitalSignature: CentralDirectorySignature?

		init(reader: DataReader, at index: inout DataReader.Index, length: Int) throws {
			var headers = [CentralDirectoryHeader]()
			var digitalSignature: CentralDirectorySignature? = nil

			guard length >= 0 else {
				throw ZipError.invalidCentralDirectoryLength
			}

			let expectedEndIndex = try reader.offset(index: index, by: length)

			while index < expectedEndIndex {
				let nextHeaderSignature: UInt32 = try reader.peek(at: index)
				if nextHeaderSignature == CentralDirectoryHeader.signature {
					let header = try CentralDirectoryHeader(reader: reader, at: &index)
					headers.append(header)
				} else if nextHeaderSignature == CentralDirectorySignature.signature {
					digitalSignature = try CentralDirectorySignature(reader: reader, at: &index)
					break
				} else {
					throw ZipError.unexpectedSignature
				}
			}

			guard index == expectedEndIndex else {
				throw ZipError.invalidCentralDirectoryLength
			}

			self.headers = headers
			self.digitalSignature = digitalSignature
		}

	}

}
