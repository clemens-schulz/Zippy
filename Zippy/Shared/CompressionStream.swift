//
//  CompressionStream.swift
//  Zippy
//
//  Created by Clemens on 01.02.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation
import Compression

public enum CompressionStreamError: Error {
	case initFailed
	case processingError
	case isComplete
}

/**
Wrapper for Apple's Compression framework
*/
public class CompressionStream {

	public enum Mode {
		case encode
		case decode
	}

	public enum Algorithm {
		case lz4
		case lzfse
		case lzma
		case zlib
	}

	public let mode: Mode
	public let algorithm: Algorithm

	/**
	Is `true`, if no more data can be written or read.
	*/
	public private(set) var isComplete: Bool

	private let stream: UnsafeMutablePointer<compression_stream>

	private let bufferSize = 4194304

	/**
	Init instance for encoding or decoding compressed data stream using specified algorithm.
	*/
	public init(mode: Mode, algorithm: Algorithm) throws {
		self.mode = mode
		self.algorithm = algorithm
		self.isComplete = false

		let op: compression_stream_operation
		switch mode {
		case .encode:
			op = COMPRESSION_STREAM_ENCODE
		case .decode:
			op = COMPRESSION_STREAM_DECODE
		}

		let algo: compression_algorithm
		switch algorithm {
		case .lz4:
			algo = COMPRESSION_LZ4
		case .lzfse:
			algo = COMPRESSION_LZFSE
		case .lzma:
			algo = COMPRESSION_LZMA
		case .zlib:
			algo = COMPRESSION_ZLIB
		}

		self.stream = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
		let status = compression_stream_init(self.stream, op, algo)

		guard status == COMPRESSION_STATUS_OK else {
			throw CompressionStreamError.initFailed
		}
	}

	deinit {
		compression_stream_destroy(self.stream)
		self.stream.deallocate()
	}

	/**
	Encodes or decodes chunk of compressed data.

	- Parameter data: Chunk of data

	- Throws: An error of type `CompressionStreamError.isComplete` or `CompressionStreamError.processingError`

	- Returns: Processed chunk of data
	*/
	public func process(data: Data) throws -> Data {
		guard !self.isComplete else {
			throw CompressionStreamError.isComplete
		}

		return try data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> Data in
			var outputData = Data()

			let sourcePointer = bytes
			let sourceSize = data.count

			self.stream.pointee.src_ptr = sourcePointer
			self.stream.pointee.src_size = sourceSize

			let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: self.bufferSize)

			var status: compression_status
			repeat {
				self.stream.pointee.dst_ptr = destinationBuffer
				self.stream.pointee.dst_size = self.bufferSize

				let flags: Int32 = self.mode == .decode ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0

				status = compression_stream_process(self.stream, flags)
				if status == COMPRESSION_STATUS_ERROR {
					throw CompressionStreamError.processingError
				}

				let bytesInDestinationBuffer = self.bufferSize - self.stream.pointee.dst_size
				if bytesInDestinationBuffer > 0 {
					outputData.append(destinationBuffer, count: bytesInDestinationBuffer)
				}

				if self.mode == .decode && self.stream.pointee.src_size == 0 && bytesInDestinationBuffer < self.bufferSize {
					break
				}
			} while status == COMPRESSION_STATUS_OK && (self.stream.pointee.src_size > 0 || self.stream.pointee.dst_size == 0)

			destinationBuffer.deallocate()

			if status == COMPRESSION_STATUS_END {
				self.isComplete = true
			}

			return outputData
		})
	}

	/**
	Returns any remaining processed data and end marker. Only call this method, if `mode` is `.encode`!

	- Throws: An error of type `CompressionStreamError.isComplete` or `CompressionStreamError.processingError`

	- Returns: Remaining processed data including end marker
	*/
	public func finalize() throws -> Data {
		assert(self.mode == .encode)

		guard self.mode == .encode else {
			return Data()
		}

		guard !self.isComplete else {
			throw CompressionStreamError.isComplete
		}

		var outputData = Data()

		self.stream.pointee.src_size = 0

		let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: self.bufferSize)

		var status: compression_status
		repeat {
			self.stream.pointee.dst_ptr = destinationBuffer
			self.stream.pointee.dst_size = self.bufferSize

			let flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
			status = compression_stream_process(self.stream, flags)
			if status == COMPRESSION_STATUS_ERROR {
				throw CompressionStreamError.processingError
			}

			let bytesInDestinationBuffer = self.bufferSize - self.stream.pointee.dst_size
			if bytesInDestinationBuffer > 0 {
				outputData.append(destinationBuffer, count: bytesInDestinationBuffer)
			}
		} while status == COMPRESSION_STATUS_OK && self.stream.pointee.dst_size < self.bufferSize

		destinationBuffer.deallocate()

		assert(status == COMPRESSION_STATUS_END)
		self.isComplete = true

		return outputData
	}

}
