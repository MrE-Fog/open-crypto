import XCTest
import CryptoKit

public class MD5Tests: XCTestCase {
    public func testBasic() throws {
        // Source: https://github.com/bcgit/bc-java/blob/adecd89d33edf278a5c601af2de696f0a6f65251/core/src/test/java/org/bouncycastle/crypto/test/MD5DigestTest.java
        let tests: [(CryptoData, String)] = [
            ("", "d41d8cd98f00b204e9800998ecf8427e"),
            ("a", "0cc175b9c0f1b6a831c399e269772661"),
            ("abc", "900150983cd24fb0d6963f7d28e17f72"),
            ("message digest", "f96b697d7cb7938d525a2f31aaf161d0"),
            ("abcdefghijklmnopqrstuvwxyz", "c3fcd3d76192e4007dfb496cca67e13b"),
            ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", "d174ab98d277d9f5a5611c2c9f419d9f"),
            ("12345678901234567890123456789012345678901234567890123456789012345678901234567890", "57edf4a22be3c955ac49da2e2107b67a"),
        ]
        
        for test in tests {
            try XCTAssertEqual(MD5.hash(test.0).hexEncodedString(), test.1)
        }
    }
    
    public func testUpdated() throws {
        let hash = Digest(algorithm: .md5)
        let buffers = [
            Data("1234567890123456789012345678901234".utf8),
            Data("5678901234567890123456789012345678901234567890".utf8)
        ]

        try hash.reset()
        
        for buffer in buffers {
            try hash.update(.data(buffer))
        }

        try XCTAssertEqual(hash.finish().hexEncodedString().lowercased(), "57edf4a22be3c955ac49da2e2107b67a")
    }

    public func testHMAC() throws {
        let tests: [(key: CryptoData, message: CryptoData, expected: CryptoData)] = [
            (
                "vapor",
                "hello",
                "bbd98ab1dbed72cdf3e924ae7eaf7943"
            ),
            (
                "true",
                "2+2=4",
                "37bda9a2b521d4623883b3acb7d9c3f7"
            )
        ]

        for test in tests {
            let result = try HMAC.MD5.authenticate(test.message, key: test.key).hexEncodedString().lowercased()
            XCTAssertEqual(result, test.expected.string().lowercased())
        }
    }
    
    public static var allTests = [
        ("testBasic", testBasic),
        ("testUpdated", testUpdated),
        ("testHMAC", testHMAC),
    ]
}
