import CCryptoOpenSSL
import Foundation
import Bits

// MARK: Ciphers

/// AES-128 ECB Cipher. Deprecated (see https://github.com/vapor/crypto/issues/59).
///
///     let key: Data // 16 bytes
///     let ciphertext = try AES128.encrypt("vapor", key: key)
///     print(ciphertext) // Encrypted Data
///     AES128.decrypt(ciphertext, key: key).convert(to: String.self) // "vapor"
///
@available(*, deprecated, message: "Stream encryption in ECB mode is unsafe (see https://github.com/vapor/crypto/issues/59). Use AES256 in GCM mode instead.")
public var AES128: Cipher { return .init(algorithm: .init(c: EVP_aes_128_ecb().convert())) }

/// AES-256 ECB Cipher. Deprecated (see https://github.com/vapor/crypto/issues/59).
///
///     let key: Data // 32 bytes
///     let ciphertext = try AES256.encrypt("vapor", key: key)
///     print(ciphertext) // Encrypted Data
///     AES256.decrypt(ciphertext, key: key).convert(to: String.self) // "vapor"
///
@available(*, deprecated, message: "Stream encryption in ECB mode is unsafe (see https://github.com/vapor/crypto/issues/59). Use AES256 in GCM mode instead.")
public var AES256: Cipher { return .init(algorithm: .init(c: EVP_aes_256_ecb().convert())) }

/// AES-256 CBC Cipher. Only use this if you know what you are doing; use AES-256 GCM otherwise (see https://github.com/vapor/crypto/issues/59).
///
///     let key: Data // 32 bytes
///     let iv: Data // 16 RANDOM bytes; different for each plaintext to encrypt. MUST be passed alongside the ciphertext to the receiver.
///     let ciphertext = try AES256.encrypt("vapor", key: key, iv: iv)
///     print(ciphertext) // Encrypted Data
///     AES256.decrypt(ciphertext, key: key, iv: iv).convert(to: String.self) // "vapor"
///
public var AES256CBC: Cipher { return .init(algorithm: .aes256cbc) }

/// AES-256 GCM Cipher. This will the recommended encryption mode once it works (see https://github.com/vapor/crypto/issues/59).
/// At the moment, we do not yet have a means to return/pass in the encrypted data's tag, causing authentication to fail.
///
///     let key: Data // 32 bytes
///     let iv: Data // 12 RANDOM bytes; different for each plaintext to encrypt. MUST be passed alongside the ciphertext to the receiver.
///     let ciphertext = try AES256.encrypt("vapor", key: key, iv: iv)
///     print(ciphertext) // Encrypted Data
///     AES256.decrypt(ciphertext, key: key, iv: iv).convert(to: String.self) // "vapor"
///
public var AES256GCM: Cipher { return .init(algorithm: .aes256gcm) }

/// Cryptographic encryption and decryption functions for converting plaintext to and from ciphertext.
///
/// Normally, you will use the global convenience variables for encrypting and decrypting.
///
///     let ciphertext = try AES128.encrypt("vapor", key: "passwordpassword")
///     try AES128.decrypt(ciphertext, key: "passwordpassword").convert(to: String.self) // "vapor"
///
/// You may also create a `Cipher` manually.
///
///     try Cipher(algorithm: .named("aes-128-ecb").encrypt(...)
///
/// Read more about [encryption on Wikipedia](https://en.wikipedia.org/wiki/Encryption).
///
/// Read more about OpenSSL's [EVP encryption methods](https://www.openssl.org/docs/man1.1.0/crypto/EVP_EncryptInit.html).
public final class Cipher {
    /// The `CipherAlgorithm` (e.g., AES-128 ECB) to use.
    public let algorithm: CipherAlgorithm

    /// Internal OpenSSL `EVP_CIPHER_CTX` context.
    let ctx: OpaquePointer

    /// Creates a new `Cipher` using the supplied `CipherAlgorithm`.
    ///
    /// You can use the convenience static variables for common algorithms.
    ///
    ///     try AES128.encrypt(...)
    ///
    /// You can also use this `init(algorithm:)` method manually to supply a custom `CipherAlgorithm`.
    ///
    ///     try Cipher(algorithm: .named("aes-128-ecb").encrypt(...)
    ///
    public init(algorithm: CipherAlgorithm) {
        self.algorithm = algorithm
        self.ctx = EVP_CIPHER_CTX_new().convert()
    }

    /// Encrypts the supplied plaintext into ciphertext. This method will call `reset(key:iv:mode:)`, `update(data:into:)`,
    /// and `finish(into:)` automatically.
    ///
    ///     let key: Data // 16-bytes
    ///     let ciphertext = try AES128.encrypt("vapor", key: key)
    ///     print(ciphertext) /// Encrypted Data
    ///
    /// - parameters:
    ///     - data: Plaintext data to encrypt.
    ///     - key: Cipher key to use for encryption.
    ///            This key must be an appropriate length for the cipher you are using. See `CipherAlgorithm.keySize`.
    ///     - iv: Optional initialization vector to use for encryption.
    ///           The IV must be an appropriate length for the cipher you are using. See `CipherAlgorithm.ivSize`.
    /// - returns: Encrypted ciphertext.
    /// - throws: `CryptoError` if reset, update, or finalization steps fail or if data conversion fails.
    public func encrypt(_ data: LosslessDataConvertible, key: LosslessDataConvertible, iv: LosslessDataConvertible? = nil) throws -> Data {
        var buffer = Data()
        try reset(key: key, iv: iv, mode: .encrypt)
        try update(data: data, into: &buffer)
        try finish(into: &buffer)
        return buffer
    }

    /// Decrypts the supplied ciphertext back to plaintext. This method will call `reset(key:iv:mode:)`, `update(data:into:)`,
    /// and `finish(into:)` automatically.
    ///
    ///     let key: Data // 16-bytes
    ///     let ciphertext = try AES128.encrypt("vapor", key: key)
    ///     try AES128.decrypt(ciphertext, key: key) // "vapor"
    ///
    /// - parameters:
    ///     - data: Ciphertext data to decrypt.
    ///     - key: Cipher key to use for decryption.
    ///            This key must be an appropriate length for the cipher you are using. See `CipherAlgorithm.keySize`.
    ///     - iv: Optional initialization vector to use for decryption.
    ///           The IV must be an appropriate length for the cipher you are using. See `CipherAlgorithm.ivSize`.
    /// - returns: Decrypted plaintext.
    /// - throws: `CryptoError` if reset, update, or finalization steps fail or if data conversion fails.
    public func decrypt(_ data: LosslessDataConvertible, key: LosslessDataConvertible, iv: LosslessDataConvertible? = nil) throws -> Data {
        var buffer = Data()
        try reset(key: key, iv: iv, mode: .decrypt)
        try update(data: data, into: &buffer)
        try finish(into: &buffer)
        return buffer
    }

    /// Resets / initializes the cipher algorithm context. This must be called once before calling `update(data:)`
    ///
    ///     let key: Data // 16-bytes
    ///     var aes128 = Cipher(algorithm: .aes128ecb)
    ///     try aes128.reset(key: key, mode: .encrypt)
    ///
    /// - parameters:
    ///     - key: Cipher key to use for the encryption or decryption.
    ///            This key must be an appropriate length for the cipher you are using. See `CipherAlgorithm.keySize`.
    ///     - iv: Optional initialization vector to use for the encryption or decryption.
    ///           The IV must be an appropriate length for the cipher you are using. See `CipherAlgorithm.ivSize`.
    ///     - mode: Determines whether this `Cipher` will encrypt or decrypt data.
    ///             This is set to `CipherModel.encrypt` by default.
    ///
    /// - throws: `CryptoError` if reset fails, data conversion fails, or key/iv lengths are not correct.
    public func reset(key: LosslessDataConvertible, iv: LosslessDataConvertible? = nil, mode: CipherMode = .encrypt) throws {
        let key = key.convertToData()
        let iv = iv?.convertToData()

        let keyLength = EVP_CIPHER_key_length(algorithm.c.convert())
        guard keyLength == key.count else {
            throw CryptoError(identifier: "cipherKeySize", reason: "Invalid cipher key length \(key.count) != \(keyLength).")
        }
        
        let ivLength = EVP_CIPHER_iv_length(algorithm.c.convert())
        guard (ivLength == 0 && (iv == nil || iv?.count == 0)) || (iv != nil && iv?.count == Int(ivLength)) else {
            throw CryptoError(identifier: "cipherIVSize", reason: "Invalid cipher IV length \(iv?.count ?? 0) != \(ivLength).")
        }

        guard key.withByteBuffer({ keyBuffer in
            iv.withByteBuffer { ivBuffer in
                EVP_CipherInit_ex(ctx.convert(), algorithm.c.convert(), nil, keyBuffer.baseAddress!, ivBuffer?.baseAddress, mode.rawValue)
            }
        }) == 1 else {
            throw CryptoError.openssl(identifier: "EVP_CipherInit_ex", reason: "Failed initializing cipher context.")
        }
    }

    /// Encrypts or decrypts a chunk of data into the supplied buffer.
    ///
    ///     let key: Data // 16-bytes
    ///     let aes128 = Cipher(algorithm: .aes128ecb)
    ///     try aes128.reset(key: key, mode: .encrypt)
    ///     var buffer = Data()
    ///     try aes128.update(data: "hello", into: &buffer)
    ///     try aes128.update(data: "world", into: &buffer)
    ///     print(buffer) // Partial ciphertext
    ///
    /// Note: You _must_ call `reset()` once before calling this method.
    ///
    /// - parameters:
    ///     - data: Message chunk to encrypt or decrypt.
    ///     - buffer: Mutable buffer to append newly encrypted or decrypted data to.
    /// - throws: `CryptoError` if update fails or data conversion fails.
    public func update(data: LosslessDataConvertible, into buffer: inout Data) throws {
        let input = data.convertToData()
        var chunk = Data(count: input.count + Int(algorithm.blockSize) - 1)
        var chunkLength: Int32 = 0

        guard chunk.withMutableByteBuffer({ chunkBuffer in
            input.withByteBuffer { inputBuffer in
                EVP_CipherUpdate(ctx.convert(), chunkBuffer.baseAddress!, &chunkLength, inputBuffer.baseAddress!, Int32(truncatingIfNeeded: inputBuffer.count))
            }
        }) == 1 else {
            throw CryptoError.openssl(identifier: "EVP_CipherUpdate", reason: "Failed updating cipher.")
        }
        buffer += chunk.prefix(upTo: Int(chunkLength))
    }

    /// Finalizes the encryption or decryption, appending any additional data into the supplied buffer.
    ///
    ///     let key: Data // 16-bytes
    ///     let aes128 = Cipher(algorithm: .aes128ecb)
    ///     try aes128.reset(key: key, mode: .encrypt)
    ///     var buffer = Data()
    ///     try aes128.update(data: "hello", into: &buffer)
    ///     try aes128.update(data: "world", into: &buffer)
    ///     try aes128.finish(into: &buffer)
    ///     print(buffer) // Completed ciphertext
    ///
    /// Note: You _must_ call `reset()` once and `update()` at least once before calling this method.
    ///
    /// - parameters:
    ///     - buffer: Mutable buffer to append any remaining encrypted or decrypted data to.
    /// - throws: `CryptoError` if finalization fails.
    public func finish(into buffer: inout Data) throws {
        var chunk = Data(count: Int(algorithm.blockSize))
        var chunkLength: Int32 = 0
        
        guard chunk.withMutableByteBuffer({ EVP_CipherFinal_ex(ctx.convert(), $0.baseAddress!, &chunkLength) }) == 1 else {
            throw CryptoError.openssl(identifier: "EVP_CipherFinal_ex", reason: "Failed finishing cipher.")
        }
        buffer += chunk.prefix(upTo: Int(chunkLength))
    }

    /// Frees the allocated OpenSSL cipher context.
    deinit {
        EVP_CIPHER_CTX_free(ctx.convert())
    }

}

/// Available cipher modes. Either `encrypt` or `decrypt`.
///
/// Used when calling `reset` on a `Cipher`.
public enum CipherMode: Int32 {
    /// Encrypts arbitrary data to encrypted ciphertext.
    case encrypt = 1

    /// Decrypts encrypted ciphertext back to its original value.
    case decrypt = 0
}

/// Wrapper to allow for safely working with a potentially-nil Data's byte buffer.
extension Optional where Wrapped == Data {
    func withByteBuffer<T>(_ closure: (BytesBufferPointer?) throws -> T) rethrows -> T {
        switch self {
            case .some(let data):
                return try data.withByteBuffer({ try closure($0) })
            case .none:
                return try closure(nil)
        }
    }
    
    // Note: It's iffy to try this with a mutable buffer, so an Optional version
    // of withMutableByteBuffer is not provided.
}
