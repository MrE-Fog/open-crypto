import CCryptoOpenSSL

/// Cryptographic hash function algorithm.
///
///     let algorithm = try DigestAlgorithm.named("sha256")
///
/// https://en.wikipedia.org/wiki/Cryptographic_hash_function
/// https://www.openssl.org/docs/man1.1.0/crypto/EVP_MD_CTX_free.html
public final class DigestAlgorithm: Equatable {
    /// Looks up a hash function algorithm by name (e.g., "sha256").
    /// Uses OpenSSL's `EVP_get_digestbyname` function.
    ///
    ///     let algorithm = try DigestAlgorithm.named("sha256")
    ///
    /// - parameters:
    ///     - name: Hash function name
    /// - returns: Found DigestAlgorithm
    /// - throws: `CryptoError` if no digest for that name is found.
    public static func named(_ name: String) throws -> DigestAlgorithm {
        guard let digest = EVP_get_digestbyname(name) else {
            throw CryptoError.openssl(identifier: "EVP_get_digestbyname", reason: "No digest named \(name) was found.")
        }
        return .init(c: digest.convert())
    }

    /// See `Equatable`.
    public static func == (lhs: DigestAlgorithm, rhs: DigestAlgorithm) -> Bool {
        return lhs.type == rhs.type
    }

    /// OpenSSL `EVP_MD` context.
    let c: OpaquePointer

    /// Internal init accepting a `EVP_MD`.
    init(c: OpaquePointer) {
        self.c = c
    }

    /// Returns the OpenSSL NID type for this algorithm.
    public var type: Int32 {
        return EVP_MD_type(c.convert())
    }

    /// MD4 digest.
    ///
    /// https://en.wikipedia.org/wiki/MD4
    public static let md4: DigestAlgorithm = .init(c: EVP_md4().convert())

    /// MD5 digest.
    ///
    /// https://en.wikipedia.org/wiki/MD5
    public static let md5: DigestAlgorithm = .init(c: EVP_md5().convert())

    /// SHA-1 digest.
    ///
    /// https://en.wikipedia.org/wiki/SHA-1
    public static let sha1: DigestAlgorithm = .init(c: EVP_sha1().convert())

    /// SHA-224 (SHA-2) digest.
    ///
    /// https://en.wikipedia.org/wiki/SHA-2
    public static let sha224: DigestAlgorithm = .init(c: EVP_sha224().convert())

    /// SHA-256 (SHA-2) digest.
    ///
    /// https://en.wikipedia.org/wiki/SHA-2
    public static let sha256: DigestAlgorithm = .init(c: EVP_sha256().convert())

    /// SHA-384 (SHA-2) digest.
    ///
    /// https://en.wikipedia.org/wiki/SHA-2
    public static let sha384: DigestAlgorithm = .init(c: EVP_sha384().convert())

    /// SHA-512 (SHA-2) digest.
    ///
    /// https://en.wikipedia.org/wiki/SHA-2
    public static let sha512: DigestAlgorithm = .init(c: EVP_sha512().convert())
}
