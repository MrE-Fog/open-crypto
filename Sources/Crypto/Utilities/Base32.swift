import libbase32

extension Data {
    // MARK: Base32
    
    /// Decodes a base32 encoded `String`.
    public init?(base32Encoded: String) {
        guard let data = base32Encoded.data(using: .utf8) else {
            return nil
        }
        self.init(base32Encoded: data)
    }
    
    /// Decodes base32 encoded `Data`.
    public init?(base32Encoded: Data) {
        let maxSize = (base32Encoded.count * 5 + 4) / 8
        var result = UnsafeMutablePointer<UInt8>.allocate(capacity: maxSize)
        defer {
            result.deinitialize(count: maxSize)
            result.deallocate()
        }
        let size = base32Encoded.withUnsafeBytes { base32_decode($0, result, numericCast(maxSize)) }
        self = .init(buffer: UnsafeBufferPointer(start: result, count: numericCast(size)))
    }
    
    /// Encodes data to a base32 encoded `String`.
    ///
    /// - returns: The base32 encoded string.
    public func base32EncodedString() -> String {
        return String(data: base32EncodedData(), encoding: .utf8)!
    }
    
    /// Encodes data to base32 encoded `Data`.
    ///
    /// - returns: The base32 encoded data.
    public func base32EncodedData() -> Data {
        let maxSize = (count * 8 + 4) / 5
        var result = UnsafeMutablePointer<UInt8>.allocate(capacity: maxSize)
        defer {
            result.deinitialize(count: maxSize)
            result.deallocate()
        }
        let size = withUnsafeBytes { ptr in
            return base32_encode(ptr, numericCast(count), result, numericCast(maxSize))
        }
        return .init(buffer: UnsafeBufferPointer(start: result, count: numericCast(size)))
    }
}
