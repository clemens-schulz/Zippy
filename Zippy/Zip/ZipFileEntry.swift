//
//  ZipFileEntry.swift
//  Zippy
//
//  Created by Clemens on 07.11.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

extension ZipArchive {
	
	struct FileEntry: CompressedFileInfo {

		private let centralDirectoryHeader: Zip.CentralDirectoryHeader

		let filename: String
		let comment: String?

		let lastModification: Date?

		let localFileHeaderIndex: DataReader.Index
		let compressedSize: Int
		let uncompressedSize: Int

		let crc32checksum: UInt32

		let compressionMethod: Zip.CompressionMethod
		let compressionOption1: Bool
		let compressionOption2: Bool

		let hasPassword: Bool


		init(header: Zip.CentralDirectoryHeader, encoding: String.Encoding) throws {
			self.centralDirectoryHeader = header

			// Get filename
			let filename: String! = String(bytes: header.filename, encoding: encoding)
			guard filename != nil else {
				throw ZipError.encodingError
			}
			self.filename = filename

			// Get comment
			let comment: String?
			if header.fileComment.count > 0 {
				comment = String(data: header.fileComment, encoding: encoding)
				guard comment != nil else {
					throw ZipError.encodingError
				}
			} else {
				comment = nil
			}
			self.comment = comment

			// Get compression method
			self.compressionMethod = header.compressionMethod
			self.compressionOption1 = header.flags.contains(.compressionOption1)
			self.compressionOption2 = header.flags.contains(.compressionOption2)

			// Get position and size of compressed data
			var startDiskNumber = Int(header.startDiskNumber)
			var relativeOffsetOfLocalHeader = Int(header.relativeOffsetOfLocalHeader)
			var compressedSize = Int(header.compressedSize)
			var uncompressedSize = Int(header.uncompressedSize)

			let zip64Fields = header.zip64Fields
			if zip64Fields != .none {
				// Update values, if in zip64 extra field

				let extraField = header.extraFields.fields.first(where: { (field: Zip.ExtensibleDataField) -> Bool in
					return field.headerID == Zip.Zip64ExtendedInformationExtraField.headerID
				})

				if let extraField = extraField {
					let zip64ExtraField = try Zip.Zip64ExtendedInformationExtraField(data: extraField.data, fields: zip64Fields)

					if zip64ExtraField.startDiskNumber != nil {
						startDiskNumber = Int(zip64ExtraField.startDiskNumber!)
					}

					if zip64ExtraField.relativeHeaderOffset != nil {
						relativeOffsetOfLocalHeader = Int(zip64ExtraField.relativeHeaderOffset!)
					}

					if zip64ExtraField.compressedSize != nil {
						compressedSize = Int(zip64ExtraField.compressedSize!)
					}

					if zip64ExtraField.originalSize != nil {
						uncompressedSize = Int(zip64ExtraField.originalSize!)
					}
				}
			}

			let localFileHeaderIndex = DataReader.Index(segment: Int(startDiskNumber), offset: Int(relativeOffsetOfLocalHeader))
			self.localFileHeaderIndex = localFileHeaderIndex

			self.compressedSize = compressedSize
			self.uncompressedSize = uncompressedSize

			// Get checksum
			self.crc32checksum = header.crc32checksum

			// Get modification date
			var dateComponents = DateComponents()
			dateComponents.calendar = Calendar(identifier: .gregorian)
			dateComponents.timeZone = TimeZone(abbreviation: "UTC")
			dateComponents.second = header.modificationTime.second
			dateComponents.minute = header.modificationTime.minute
			dateComponents.hour = header.modificationTime.hour
			dateComponents.day = header.modificationDate.day
			dateComponents.month = header.modificationDate.month
			dateComponents.year = header.modificationDate.year
			let lastModification = dateComponents.date
			self.lastModification = lastModification?.timeIntervalSince1970 != 0.0 ? lastModification : nil

			// Check if file requires password
			self.hasPassword = header.flags.contains(.encryptedFile)

			// TODO: check version needed and throw `CompressedArchiveError.unsupported` if not supported
		}

		// TODO: extract => make and configure compression stream, check compression method

		func extract(from reader: DataReader, to stream: OutputStream, verify: Bool) throws {
			var index = self.localFileHeaderIndex
			let localFileHeader = try Zip.LocalFileHeader(reader: reader, at: &index)

			let flags = self.centralDirectoryHeader.flags.union(localFileHeader.flags) // TODO: check if this makes sense
			if flags.contains(.encryptedFile) {
				if flags.contains(.strongEncryption) {
					// Strong encryption is not supported, because it's patented. 🤮
					throw ZipError.unsupportedEncryption
				} else {
					throw ZipError.unsupportedEncryption // TODO: read encryption header and decrypt
				}
			}

			// Data descriptors are used when file sizes and CRC-32 are not know when the header is written. If the flag
			// is set, the descriptor exist. Compressed size, uncompressed size and CRC-32 fields are set to zero.
			let usesDataDescriptor = flags.contains(.dataDescriptor)
			if usesDataDescriptor && self.centralDirectoryHeader.compressedSize == 0 {
				throw CompressedArchiveError.unsupported // TODO: add support for data descriptors
			}

			// TODO: check if there is anything useful we can do with the local file header before uncompressing data

			// Read data and uncompress

			// TODO: verify data

			var remainingLength = self.compressedSize
			let bufferSize = 1024 * 64

			stream.open()
			defer {
				stream.close()
			}

			var checksum = CRC32()

			switch self.compressionMethod {
			case .noCompression:
				while remainingLength > 0 {
					let length = Swift.min(bufferSize, remainingLength)

					var tempIndex = index
					let data = try reader.read(length, at: &tempIndex)

					let bytesWritten = data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Int in
						let bytesWritten = stream.write(bytes, maxLength: length)

						if verify {
							checksum.add(bytes: bytes, count: bytesWritten)
						}

						return bytesWritten
					}

					if bytesWritten == 0 {
						throw CompressedArchiveError.writeFailed
					} else if bytesWritten < 0 {
						throw stream.streamError ?? CompressedArchiveError.writeFailed
					}

					remainingLength -= bytesWritten
					index = try reader.offset(index: index, by: bytesWritten)
				}
			case .deflated:
				let compressionStream = try CompressionStream(mode: .decode, algorithm: .zlib)

				while remainingLength >= 0 {
					var uncompressedData: Data

					if remainingLength == 0 {
						if compressionStream.isComplete {
							break
						} else {
							uncompressedData = try compressionStream.process(data: Data())
						}
					} else {
						let length = Swift.min(bufferSize, remainingLength)
						let compressedData = try reader.read(length, at: &index)
						remainingLength -= length

						uncompressedData = try compressionStream.process(data: compressedData)
					}

					while uncompressedData.count > 0 {
						let bytesWritten = uncompressedData.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Int in
							let bytesWritten = stream.write(bytes, maxLength: uncompressedData.count)

							if verify {
								checksum.add(bytes: bytes, count: bytesWritten)
							}

							return bytesWritten
						}

						if bytesWritten == 0 {
							throw CompressedArchiveError.writeFailed
						} else if bytesWritten < 0 {
							throw stream.streamError ?? CompressedArchiveError.writeFailed
						}

						if bytesWritten == uncompressedData.count {
							break
						} else {
							uncompressedData = uncompressedData[bytesWritten...]
						}
					}
				}
			default:
				throw ZipError.unsupportedCompressionMethod
			}

			if verify {
				guard checksum.value == self.crc32checksum else {
					throw CompressedArchiveError.corrupted
				}
			}
		}
	}
}
