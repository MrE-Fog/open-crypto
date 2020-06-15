import XCTest
import Bits
import Crypto

class RSATests: XCTestCase {
    func testPrivateKey() throws {
        let plaintext = Data("vapor".utf8)
        let key: RSAKey = try .private(pem: privateKeyString)
        let ciphertext = try RSA.SHA512.sign(plaintext, key: key)
        let verified = try RSA.SHA512.verify(ciphertext, signs: plaintext, key: key)
        XCTAssertTrue(verified)
    }

    func testPublicKey() throws {
        let plaintext = Data("vapor".utf8)
        let key: RSAKey = try .public(pem: publicKeyString)
        try XCTAssertTrue(RSA.SHA512.verify(testSignature, signs: plaintext, key: key))
    }

    func testMalformedKeys() throws {
        XCTAssertThrowsError(try RSAKey.public(pem: malformedKey))
        XCTAssertThrowsError(try RSAKey.private(pem: malformedKey))
        XCTAssertThrowsError(try RSAKey.public(certificate: malformedKey))
    }

    func testFailure() throws {
        let plaintext = Data("vapor".utf8)
        let key: RSAKey = try .public(pem: publicKeyString)
        try XCTAssertFalse(RSA.SHA512.verify(Data("fake".utf8), signs: plaintext, key: key))
    }

    func testKey1024() throws {
        let ciphertext = try RSA.SHA512.sign("vapor", key: .private(pem: privateKey2String))
        let verified = try RSA.SHA512.verify(ciphertext, signs: "vapor", key: .public(pem: publicKey2String))
        XCTAssertTrue(verified)
    }

    func testKey2048() throws {
        let plaintext = Data("vapor".utf8)
        let rsaPublic: RSAKey = try .public(pem: publicKey3String)
        let rsaPrivate: RSAKey = try .private(pem: privateKey3String)
        let ciphertext = try RSA.SHA512.sign(plaintext, key: rsaPrivate)
        let verified = try RSA.SHA512.verify(ciphertext, signs: plaintext, key: rsaPublic)
        XCTAssertTrue(verified)
    }

    func testKey4096() throws {
        let plaintext = Data("vapor".utf8)
        let rsaPublic: RSAKey = try .public(pem: publicKey4String)
        let rsaPrivate: RSAKey = try .private(pem: privateKey4String)
        let ciphertext = try RSA.SHA512.sign(plaintext, key: rsaPrivate)
        let verified = try RSA.SHA512.verify(ciphertext, signs: plaintext, key: rsaPublic)
        XCTAssertTrue(verified)
    }

    func testKeyCert() throws {
        let plaintext = Data("vapor".utf8)
        let rsaPublic: RSAKey = try .public(certificate: publicCertString)
        let rsaPrivate: RSAKey = try .private(pem: privateCertString)
        let ciphertext = try RSA.SHA512.sign(plaintext, key: rsaPrivate)
        let verified = try RSA.SHA512.verify(ciphertext, signs: plaintext, key: rsaPublic)
        XCTAssertTrue(verified)
    }

    func testEncrypt() throws {
        let plaintext = Data("vapor".utf8)
        let rsaPublic: RSAKey = try .public(certificate: publicCertString)
        let rsaPrivate: RSAKey = try .private(pem: privateCertString)
        let encryptedData = try RSA.encrypt(plaintext, padding: .pkcs1, key: rsaPublic)
        let decryptedData = try RSA .decrypt(encryptedData, padding: .pkcs1, key: rsaPrivate)
        let decryptedPlaintext = String(data: decryptedData, encoding: .utf8)
        XCTAssertTrue(decryptedPlaintext == "vapor")
    }

    func testRand() throws {
        let rand = CryptoRandom()
        let data1 = try rand.generateData(count: 4)
        let data2 = try rand.generateData(count: 4)
        XCTAssertNotEqual(data1.hexDebug, data2.hexDebug)
    }

    func testComps() throws {
        //"kty": "RSA",
        //"alg": "RS256",
        //"use": "sig",
        //"kid": "3b547886ff85a3428df4f61db73c1c23982a928e",
        //"n": "mjJLokVSf3F_7MAPPEZzT0fQO2AQwlpzDdYG1EHH9WTxm0Dk4KB8vIBCp6lWm0fV8-pv0N7zF9rJ0CHKgkxuC02VwHVtuegE7XikfRCZJaPAn-MHm-eowW2SpSmsudi0_Gs1cvjxms_lVvoHUBaDTjhHWqCRGX_oOiNCglJKPFaYtyTA4ZiUfQ3FE_uVeoC_gYTYxuUzVxLsKJynrFaOVGIvnp9uRdbS0WtUhs7BY-tgqzJEt42_PFo-DAgWFIpdUzfG0AxAHZQ7TxDM09MaWBVoUMrBMqpMT6TaRtWiKOYeGEfV-ZH2d8qWoJHaKbZjMiSL64sgTNw2T_pZAyTI3Q",
        //"e": "AQAB"
        let key: RSAKey = try .components(
            n: "mjJLokVSf3F_7MAPPEZzT0fQO2AQwlpzDdYG1EHH9WTxm0Dk4KB8vIBCp6lWm0fV8-pv0N7zF9rJ0CHKgkxuC02VwHVtuegE7XikfRCZJaPAn-MHm-eowW2SpSmsudi0_Gs1cvjxms_lVvoHUBaDTjhHWqCRGX_oOiNCglJKPFaYtyTA4ZiUfQ3FE_uVeoC_gYTYxuUzVxLsKJynrFaOVGIvnp9uRdbS0WtUhs7BY-tgqzJEt42_PFo-DAgWFIpdUzfG0AxAHZQ7TxDM09MaWBVoUMrBMqpMT6TaRtWiKOYeGEfV-ZH2d8qWoJHaKbZjMiSL64sgTNw2T_pZAyTI3Q",
            e: "AQAB"
        )
        XCTAssertEqual(key.type, .public)
    }
    
    // https://github.com/vapor/crypto/issues/78
    func testGH78() throws {
        let passphrase = "abcdef"
        
        // From https://www.googleapis.com/oauth2/v3/certs
        let key: RSAKey = try .components(
            n: "vvAaaSpfr934Qx0ioFiWsopq7UCfLNn0zjYVbq4bvUcGSXU9kowYmQArR7WlIkjk1moffla0UV75QRaQPATva1oD5xQnnW-20haeMWTSsMgUHoN0Np9AD8ffPz-DfMJBOHIo4REL1BFFS33HSZgPl0hxJ-5UScqr4lW1JMy5XGeRho30dnmKTpakU1Oc35hFYKSea_O2SXfmbqiAkWlWkilEzgHq4pzVWiDZe4ZgfMdD4vqkSNrO_PkBFBT1mnBJztQ1h4v1jvUW-zeYYwIcPTaOX-xOTiGH9uQkcNPpe5pBrIZJqR5VNrDl_bJOmvVlhhXZSn4fkxA8kyQcZXGaTw",
            e: "AQAB"
        )
        let encrypted = try RSA.encrypt(passphrase, padding: .pkcs1, key: key)
        XCTAssertThrowsError(try RSA.decrypt(encrypted, padding: .pkcs1, key: key))
    }

    func testDERCert() throws {
        //Split JWS parts
        let parts = jwsToken.convertToData().split(separator: .period)
        let headerData = Data(parts[0])
        let payloadData = Data(parts[1])
        let signatureData = Data(parts[2])

        let urlEncodedDer = Data(base64URLEncoded: derEncodedCer.trimmingCharacters(in: .whitespaces))!
        let signature = Data(base64URLEncoded: signatureData)!
        let message = headerData + Data([0x2E]) + payloadData
        let rsa = try RSAKey.public(der: urlEncodedDer)

        try XCTAssertTrue(RSA.SHA256.verify(signature, signs: message, key: rsa))
    }

    static var allTests = [
        ("testPrivateKey", testPrivateKey),
        ("testPublicKey", testPublicKey),
        ("testMalformedKeys", testMalformedKeys),
        ("testFailure", testFailure),
        ("testKey1024", testKey1024),
        ("testKey2048", testKey2048),
        ("testKey4096", testKey4096),
        ("testKeyCert", testKeyCert),
        ("testRand", testRand),
        ("testComps", testComps),
        ("testEncrypt", testEncrypt),
        ("testGH78", testGH78),
        ("testDERCert", testDERCert),
    ]
}

let testSignature = Data([0x27, 0xF2, 0xDC, 0xA1, 0x1F, 0xE8, 0x88, 0x1D, 0xFC, 0x8A, 0x33, 0x59, 0x0A, 0x2E, 0xBC, 0x35, 0x98, 0x10, 0xD7, 0x31, 0xA6, 0xF5, 0xCC, 0xDC, 0xD6, 0x8D, 0x8A, 0x36, 0xBD, 0xD5, 0xAA, 0x62, 0x22, 0x2B, 0x9C, 0x2A, 0xE1, 0x42, 0x0F, 0x56, 0x71, 0xB3, 0x44, 0x40, 0x0E, 0x8F, 0x15, 0x10, 0xF9, 0x75, 0xED, 0x18, 0x47, 0xF3, 0xE7, 0x99, 0x23, 0x37, 0x4B, 0x05, 0xB2, 0x1F, 0xBD, 0xD1, 0x67, 0xF0, 0x8E, 0xE5, 0x3E, 0xF7, 0xB3, 0x38, 0x4F, 0xE9, 0x14, 0x75, 0x2B, 0x2A, 0x97, 0x72, 0x29, 0xDD, 0x63, 0x7F, 0x13, 0x1F, 0xC8, 0xD9, 0xB4, 0x1F, 0x2C, 0x22, 0xBB, 0x24, 0x85, 0x0C, 0x57, 0x48, 0x2D, 0x41, 0x57, 0xED, 0x63, 0x6D, 0x23, 0x71, 0x82, 0xD1, 0xAC, 0xB5, 0x2F, 0x2B, 0xF4, 0xD1, 0xDB, 0x60, 0xAB, 0xBB, 0x13, 0x80, 0xE9, 0xED, 0x51, 0x8C, 0x46, 0x6F, 0xCD, 0xBF, 0x8F, 0x6C, 0xDE, 0xAF, 0x08, 0x02, 0xD3, 0xC6, 0x80, 0x1C, 0x47, 0xCC, 0xB6, 0x68, 0xB3, 0x36, 0x38, 0x04, 0xC0, 0x49, 0x2F, 0xEB, 0x94, 0xF0, 0x86, 0x9B, 0xC6, 0x70, 0x74, 0x32, 0x0D, 0x5B, 0xF6, 0x43, 0xA7, 0xB0, 0xA5, 0xFA, 0xE9, 0x73, 0xBB, 0x8C, 0x7D, 0x9C, 0xB8, 0x64, 0x11, 0x24, 0x95, 0x6F, 0xDF, 0xE5, 0x05, 0xC6, 0x28, 0x7C, 0xC6, 0xB4, 0xFC, 0xCC, 0xA4, 0x70, 0x89, 0xD6, 0x37, 0xDE, 0xE2, 0xCA, 0x98, 0x69, 0x41, 0x47, 0x46, 0xCC, 0x5D, 0x64, 0x5B, 0xC5, 0x56, 0x5E, 0x67, 0x1F, 0xA7, 0xF8, 0xAF, 0x5B, 0x8A, 0x4B, 0xB4, 0x30, 0x8B, 0xC3, 0xEF, 0xEF, 0x32, 0xA2, 0x16, 0x50, 0x57, 0x54, 0xC6, 0x7D, 0x57, 0x12, 0x93, 0x55, 0xB6, 0x75, 0x60, 0x62, 0x0B, 0x94, 0xE7, 0x6E, 0xFD, 0x16, 0x5F, 0x7F, 0x1D, 0x77, 0x07, 0x79, 0x28, 0xC6, 0xF2, 0x26, 0xB4, 0x97])

let privateKeyString = """
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAuCdcY4yWdJXcKbfcaUe5enjyBhHXNg3P6ope9UiiCeUDlCT0
KR85WnCeIibnl9GtuvxfmMkW5xmg0l4FScZ5uEeBjCUnZG7tcZFKVTFkFIxviLEt
iQWxOFhuWhJotkApGM4gG/u58GFwZnd8p1surSYmUICoslr3FJXOyMi53F+uaB2r
nX56Y2JfUAtNTSsAUVdP5TsSQ7Bq1rCHPefLDcqzdcM15ql5XJe/9UCOmN0DWaRF
dFcbw92bWEyBB11rEPbGCFi3pgXnEbOeudiLS3uDHtxfVvLLqJhJueQRb3KwSb2X
ASDFBq/bUcktiRNe2jZbX8+0t19DXq0Rs1N4AwIDAQABAoIBAAYAgmpcMqsqFzrk
2zIzPEBZoMnB2xnP6W7jg6TK8T0RUcSKT8rnUZ84/G5whivUkaz+fL8mDrEJjMxO
dC2rYlw3OGmw7E/Brct9yMZuDaz9xsTVwX4tyVDk0PPulasa/Dvqu/Etiynigx9T
1aQ+vI64J5eIGfd2L4dkOpEgua4NAh1tdWN+VR8W+1Cf0LHxO+zpONVUCt4zv/L2
Z43rexJstQacmvxGWrBSqcMXkLg39q/khD/W4WBkisIv4W8lkh6z5F6cpemiM8M+
fczqeYtYwGK862QPMKDY/yZvLYWiQ6s+8lBTdwwLMWi+yVeMaZjOAmog1Pmk6FLl
0dhmycECgYEA5WorqpcB5jCcoBONQ8H+ZCbkdQ1iWMDU4lZQVqG8zNRMMKa6+3wc
jDB3w7GqLhmafYjhBHbEqGiklvrKxhT8aLplUGqh7MomOqPJl7Bb1NZkINK9+jr6
KVnPwBjW5ssJk79sJ1fv0zVbKc9LmQ5N1kGF0PLMS0rXYmrKOrYFcc8CgYEAzX55
0PieEDFSZxLjgxnN8bixcoHty3WZmPSWijgWvUbxog0ootHwxBo5n4eA05RFh8AU
QW1gcnwSSY0haoYnVEhsqCHoG5qpVXwGqpVwbs7xixuK9rrSrc8RaCOmGcQTnzxX
e0Dysph+OiV2nkRjmTrGNRN0qGh4TVISNh++540CgYEA2HrxLY5FWoOwqFUKzk92
z+brWZEBpqJ/v/yW3sjMMbR7GMWcV8br4VWzDdTOs6WxZJgPTXkNZaUo+tc5FOWk
sOaCx/l3RswSeu8nQZ5HaXXNEjQK1N9mRDLdmXVXBH2/Uc4mLpIKWpFUrwVPXuRi
irVVorAaG0pKKDKBFhnA1X0CgYEAvBaxxVZqxwN+Gx4s5Iiv+jpFITxPvdTsPBZT
3DuuhJz0+pD0yuNCbxxZ9ez/O6oRYkmrwJ8ukluCGZR2K5yTTw/jdJlkbC/KIpad
O3IBMUt1xw/0yBUEVVac5icLF7ZjB3Mh140BF/uAPhSgWAjc6Rnk5hviwWquAofG
Z4fzItkCgYEAiJack6DxuJzfUVy0q+Zth6PFK7DBeKeV6r6A0yHIRzzRpG4HXh57
+WgR7nA/v09NkVGeuKLTVo+2oiWYjuFctr2fW6moAsuq1eNjPzC9SH8G1h+W8Osq
85PPb6OGKt+MD2rHJytEC8znQoDLEQ0IFGpObLIf6tS2fB8LerrWSog=
-----END RSA PRIVATE KEY-----
"""

let publicKeyString = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuCdcY4yWdJXcKbfcaUe5
enjyBhHXNg3P6ope9UiiCeUDlCT0KR85WnCeIibnl9GtuvxfmMkW5xmg0l4FScZ5
uEeBjCUnZG7tcZFKVTFkFIxviLEtiQWxOFhuWhJotkApGM4gG/u58GFwZnd8p1su
rSYmUICoslr3FJXOyMi53F+uaB2rnX56Y2JfUAtNTSsAUVdP5TsSQ7Bq1rCHPefL
DcqzdcM15ql5XJe/9UCOmN0DWaRFdFcbw92bWEyBB11rEPbGCFi3pgXnEbOeudiL
S3uDHtxfVvLLqJhJueQRb3KwSb2XASDFBq/bUcktiRNe2jZbX8+0t19DXq0Rs1N4
AwIDAQAB
-----END PUBLIC KEY-----
"""



let privateKey2String = """
-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQCa5NX/zL+V5zSlLQNLH9BBX/90lkM68apm3uDrG26xvfd9GqYp
0ee7wyiI25/362HfNzavSXl2kRmzArBiW9mGAPq/HgH/7ZIg5iwaD02DpcJbUwux
bhUS+ptWcIbWxXjn46AAHJySymLyPXFxHy2wVXCli78DhKMr0OXaQDAeKQIDAQAB
AoGADrLGZ+a7C3OMOFxkIp3bOkjsydh0esRyAh8GQukwgOdg89syh2dm0Rd84jfN
H06T1AW+R7X2M70jLiyEJmFG691NwR57ueVzTC4wxKLl6TymAiKaoDWSiCZW5jRx
CTN4gamAH7tdsVPf8am0uqKHNwN/yZgZ/ez7aoR1KfNbZnECQQDjYKAPaGA9wQpz
AGPioeQKgmOBmUYsDNRGgxUFd8UZChpTmWo2ew8KYYRfVOHzBKfCiPwZq5y8QyFX
sHWPgEplAkEArmRieWLmpYSJm25yJNOhJcxjUFMkUuuQoCDLl6E3cQD4s85jCoCo
XN7+aNGV1Jw6zlAh+pfd3yqBxb7yerTGdQJBAJ9ZMzM5GeGNbO5Fgrrsa+11jZjg
uw3Z+9ZivRO06TtwGh0mcgo2WccTqnpI+YSfaZZq/Apde51wimhy8SCdbwUCQEag
pTkgEuVJ7iki69t6UjNquXYYlgd3G9WeMpYwVrHPgOnhVj80p/sk3Mg6yYGX3EEe
NwS0aMku/+vET5PejtkCQBm8NzMt+kU21b8+t0jF1ditn6eiYqP9H2PRqHFmKKJY
lSIbdOy6ZyOEtNU9rTY4oS5mwniEo1INrnKeArVL7RI=
-----END RSA PRIVATE KEY-----
"""

let publicKey2String = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCa5NX/zL+V5zSlLQNLH9BBX/90
lkM68apm3uDrG26xvfd9GqYp0ee7wyiI25/362HfNzavSXl2kRmzArBiW9mGAPq/
HgH/7ZIg5iwaD02DpcJbUwuxbhUS+ptWcIbWxXjn46AAHJySymLyPXFxHy2wVXCl
i78DhKMr0OXaQDAeKQIDAQAB
-----END PUBLIC KEY-----
"""



let privateKey3String = """
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAlznyd/pK9bVqC8JUv8q3SN8yCuk1vagIyHgF0MJPPIlU5fpX
HyUKN60IaIjD4ujjHu0mDnmJo9rh4gkXlfymIWl5gAD1tQ6K4u9TwIOB7oowBKYG
1xHNYBHZxP3pj/7rgKkQEvBZUrdBi4ss9wVvqjFK0wz7GiN8F2uxvR0foeqT/RV/
HZoglhVmj2FwC2hHIQFCrOgmzmbtEEyvC+h9DaSr7h5d6UM5Konqktq6OaZCALbo
IriaQnTjcyexcpSENLnPFMiNdUiOTQyXOKEI+ar59AdIpmEespwlQDFMka0MoxsX
vr4tRmeyl49En0EqYYRH5AIeeblkHfPh/fiBXwIDAQABAoIBAAzJLHPyaIYPuZCW
9J1moUp6/Hspro6Dd4KjizJUS2i937y2BsmuUwfUDGLyNUWpFRLXUCFnKzj8V57J
0AGxY8ZtaYVmD2Aog5ueSoF7XO/zJQ4vj2J9sdSOjc/2+9ld30F4idBgG90/ez42
HS4heoh0NHRVo6FZILPGOjfYD4Wb83L0gai+5kkhecDg8UWtVSzYbIyhB7G7SeWW
ogyQrugQbptB6TYTnoPsmraouU2aVEMOhC5sHLk3s7YGKce1UWJB95SUBSNE3itr
ljLkYBP42gjEzvc0sfNrXuxRXiQyrD+Go5lptsWE7aBpJk9nsXFsN1Kl6FqBTn+s
eFJSC1kCgYEAx1/AVsY2Isc96go9Owfz+PTrR8/PaWbcrjZLMmq5G7f0rTCRjUc9
MhYu2AiD1khauZD3TBsspO6WKALAJJlsv2GCuBCo42tUNz1JWystIYcfe64u3zaz
HVWV3H6mwfoND4EMoT0cytwadpf6629ql/b0o/vRwXAjxP2LTDnuIu0CgYEAwi1v
jmNI3raY46uv6X4LQEHpSQiLiNazVd2J724ZXeGdZCqDsRQCZYkZqyFZtd1yEiTd
6Ah1CS3H3a/MUt80AgPNb4MaRZWetZNavtNZ/JdqpN5FFsgrnmU7xOmhV+4HjQpE
pqU8qFpUey+L6A+iyZ8D2P+OVhaVKM5+2qlF7/sCgYA/x2S7HZtR0tT+mpnt2WR1
nrvpdBQQzsQHwvyZO0TOFjHieWgGfuSXsjr4BvlNwkWrmTFTGlpUxLIqSH749k+w
hVwQz9uHLN168lMWJCDC2fv7T8RUyaXQ24EeUTG9WeV1sT2+EtO0HWclywaM7E54
IJswHi2CqQH4UXePQfTpHQKBgQC284BMNBeQX5Kl0DmqUWvgWzml6jst7ryBhn5T
7PRRlCVrHvN9gFDRwd9BcebIh6DWn43E9VLwFwZdRSnKWyrxSwvgqTGzpkkm43N4
oEIEz9VXCWUnFeqjDtbFrSqrYkYTCT2tlboVFSbL+fxj5XeHaB+D8ST2z8gx7n1v
IFYYyQKBgClVy+MWDCJPMm2dRk6AEKGdAs4yiO5Sb710t29kvxKtZzUuyFCRZAtt
ENIcr0ZvAo6rQwP+DgsvYdKeUQbQaKDR82HkT/SUNPergdp5SFaR2C2XpRyYHh5q
Xj9uKUw0ExH06Qa5GGAcVhcw0PyGtM09Mu93iQbMUukBqQGQN5Z3
-----END RSA PRIVATE KEY-----
"""

let publicKey3String = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlznyd/pK9bVqC8JUv8q3
SN8yCuk1vagIyHgF0MJPPIlU5fpXHyUKN60IaIjD4ujjHu0mDnmJo9rh4gkXlfym
IWl5gAD1tQ6K4u9TwIOB7oowBKYG1xHNYBHZxP3pj/7rgKkQEvBZUrdBi4ss9wVv
qjFK0wz7GiN8F2uxvR0foeqT/RV/HZoglhVmj2FwC2hHIQFCrOgmzmbtEEyvC+h9
DaSr7h5d6UM5Konqktq6OaZCALboIriaQnTjcyexcpSENLnPFMiNdUiOTQyXOKEI
+ar59AdIpmEespwlQDFMka0MoxsXvr4tRmeyl49En0EqYYRH5AIeeblkHfPh/fiB
XwIDAQAB
-----END PUBLIC KEY-----
"""




let privateKey4String = """
-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----
"""

let publicKey4String = """
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAnyOElrdcKlFqFQ11oQfc
BHT+NK5QQPn6xOkfHD/rOPD+lBEiuEQhdHIXuq1w7ibu7HystOR3qdP0G2q9yu/w
Wr5KtIbTIjngAsCvssWJOIY4kHRJDgV/YJV2zl+GaNKMbZuT3c7BfZ4CWYtWqy8j
I9YETZdk2CDla832QIXtGCvaE5OBY3mUQQ3UNlBtmZ0PANO9nAXZ6Og+A2R7+LTU
MwpzXK6VJDc9g+IhYTTT3S5xJgZgWsYZ1fEsfo0Q1oSAk5qflGGe2YHlO+nkzP0D
6DnlzB66+sM4nBGRbq6PUJFB/KLqXOTMku5u7GTy0yjsd35C1VLY1r2qdUxou6p9
XH8GJVzYrD4yBF0hbqyQxYhPclhyXrDCsPQS6Ml6skezogFGgytQ9Fyy1fUS3l2k
J9JVLIt9Y+b1lB+y7ZrWKiY8Jlwgz73cRbJP3IHKbUzTpJjofZo0HN7bnWjCwGkZ
wN7GYiNxYQNMV+3hf46JckmmmlzPH/FPm2d+WDU4qAGP3za/jDIC9E9nhPnP6gKu
zj4IJGb5RU3UiHxiahqvsanTkvxO3EYH4qKbYkitX4FhXjkCiZ5kI77M2/H5EVCj
Z+9FnMSIhirIJiJovWmws+vQmInEU7HoNkCEOmFA2zZBIdaL2fqer6h91byHe58k
TyCpwGe1qaBvcaPHTnh5Y4kCAwEAAQ==
-----END PUBLIC KEY-----
"""


let publicCertString = """
-----BEGIN CERTIFICATE-----
MIIDtTCCAp2gAwIBAgIJAPXwrCN6SAAWMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMTgwMzIwMTQ0MjMwWhcNMTkwMzIwMTQ0MjMwWjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAwYYtMx5VQ+g3mZ8WIyemRaVT0A3/9A24cwnzOAFJ9rE8h1hqvLV6Ot8v
ypB42ObhKbuY5YSxIGZk9N3PSxLb0YxZLCjIBQT5WI2ZWkIcX8IdvXf1JAXKii9J
58Wi0vO1Ti4fGeaUv+cUItuzQM7A5CUuo3AiSiGKTZpWceo3SgZO1LfhNkVMqmxY
2mynDsJROPB3CyWgXC7DdLEKgdeQFxoN1k90MZkXvlVbo47axcOctkrS1ZGxF9lM
2AHUnqdQjreCwIZXwoBc+PU3AbbyGE/0I8OHVekK+XqMHyjv1MjHQVyP0xDnqUni
bPSNVhbp+kwNiJfvkWCzotjAIFTr4wIDAQABo4GnMIGkMB0GA1UdDgQWBBSE2uPi
QiMeBeaDbYVuIwjQfSNUqTB1BgNVHSMEbjBsgBSE2uPiQiMeBeaDbYVuIwjQfSNU
qaFJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUtU3RhdGUxITAfBgNV
BAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJAPXwrCN6SAAWMAwGA1UdEwQF
MAMBAf8wDQYJKoZIhvcNAQEFBQADggEBAD+uEfIEeugcS2iUe/+gDd7HQ0rTKLcf
7gOR6WT3hyIbiTNBkoxdcM/r7dAZgCvixiKuFOya64BmE/M51fS17WiZAr63gUBx
/6ab6eN55BZUDBsMsBuZDbV8yismvr5LFFYOgzo/yKcyBlofYTdKfhrdhWisb7vr
1/socgSwPJCECWSYrwp6UTL+WzCL/mn/fuYkrQdn20xla1B4UB4K7IGpnIVuK9no
zNv9tMz9E+TCFy1rC5C6AVXJgwoOrZGGi7kt94GTH31pztHAEGC1uaDcRmoIP08+
TOIPx7dMgL5hDE78C2Ly2j40ifKdlFsHvKyTodpo+xAdRl5k7WpavDA=
-----END CERTIFICATE-----
"""

let privateCertString = """
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAwYYtMx5VQ+g3mZ8WIyemRaVT0A3/9A24cwnzOAFJ9rE8h1hq
vLV6Ot8vypB42ObhKbuY5YSxIGZk9N3PSxLb0YxZLCjIBQT5WI2ZWkIcX8IdvXf1
JAXKii9J58Wi0vO1Ti4fGeaUv+cUItuzQM7A5CUuo3AiSiGKTZpWceo3SgZO1Lfh
NkVMqmxY2mynDsJROPB3CyWgXC7DdLEKgdeQFxoN1k90MZkXvlVbo47axcOctkrS
1ZGxF9lM2AHUnqdQjreCwIZXwoBc+PU3AbbyGE/0I8OHVekK+XqMHyjv1MjHQVyP
0xDnqUnibPSNVhbp+kwNiJfvkWCzotjAIFTr4wIDAQABAoIBAQCs/t3++VmtZ7P0
PvNSH8qSLbWbojgxGebN55IleXl97ng2YUKhSPVoFUWqpbVx6ApV/R4z5odUeFQ9
VN9OtCAO1ZCNWjNb0VN45rO0rK6ip2tgiRB50Dd7icReTR09yKBFsBMbWzWTyuUE
ODOodmqWR+rGLaJpdEwnDRXDpWUhZKyVR6dxJfCiArExVJG2AcEyk1c0+A5g0EVo
uaqK1KDP/PnaJo47e27JcO43EIu+HT25u7UpBQd0SmE+MhcBImM+fQrlGe6csMrl
5NQVzo+fcrPYo9Cmd9B6i1mqescjkXxOe6/FYcF3FLt1TA9scjUG4GuwfEe//W7z
ARuk7U0hAoGBAPOuqDNY1+cxD/MahHlM6gBBAogwxvis243MDSgFZLlRF0XP3oW4
qf2SDFw7dgUmdzitn4aawO0kC46TOJOlMMLXEZ2hHy+5UxcYlBehAhrhhcvLKANA
a/uYcosqlWWTeS80/nnoSWz0yytded2514vqFb57hw4chTDyLHX1cG4zAoGBAMtO
dDJwUFNaYe/31yQaG15lKmpOEez0R96EkD3dD/VI11e5CvrdYLj13I0uo/9sqqIY
22eLyjjOVYVsxIMEdcCU2ceFhQmsHPipGWlEVdqt3hLQpSidoSQdu+U502EDH2n5
YHLSR7+sTQdtn2E2A+OdXGEy6qUFptRWH5lyfHuRAoGAan588Zu1F0tgvgxrsptD
dIL0uVIf0pOwi8KOSVw6Dab7tb3HcMcoOzH1huVRiaSq27E9E1VUVQ64okGCqzu5
GJ1nDG1atL+YKXLLXZw20EqY71xEi08/IcAY5urgSXjusAvH3rz+QcildbkvRhAu
u+28PPe9KRSbvK1Jcu+lh/MCgYAHzUvyP5Mlj7tgbR9peEMCnVlCWRqhAELdzDKI
3TnmjNQOvsAoHmS+1FiRZm/OtonZzKBm2dt50JlBlIn6CSrHqC6vVHVliKBX/o1G
F+Q/jxqNmEouQ9ZSP33dbxmoiGklNPe5kE5GkcMm/NL39Q2zJ2/LHxwYFx5u2Zs+
1UDnsQKBgQCl9zrOGMPylRsIXW2A96HxWiaLN7u8bdDDI9BM04SzLqoCL2eP2TWp
CvG1EHycbZ7TkKAg0RZf6znl7fdovNpTYwE5Dsp6yfVHaZQrCt40C7lkTQp3jJdO
JnaPRNI/r2om80rCKK7xczqLVdFVzEmHn3wYN68ZpQx7Ivz8kLGgDw==
-----END RSA PRIVATE KEY-----
"""

let malformedKey = """
-----BEGIN RSA PUBLIC KEY-----
Ha ha ha, this is not a public key.
-----END RSA PUBLIC KEY-----
"""

let derEncodedCer = "MIIFkjCCBHqgAwIBAgIQRXroN0ZOdRkBAAAAAAPunzANBgkqhkiG9w0BAQsFADBCMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVR29vZ2xlIFRydXN0IFNlcnZpY2VzMRMwEQYDVQQDEwpHVFMgQ0EgMU8xMB4XDTE4MTAxMDA3MTk0NVoXDTE5MTAwOTA3MTk0NVowbDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxEzARBgNVBAoTCkdvb2dsZSBMTEMxGzAZBgNVBAMTEmF0dGVzdC5hbmRyb2lkLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANjXkz0eK1SE4m+/G5wOo+XGSECrqdn88sCpR7fs14fK0Rh3ZCYZLFHqBk6AmZVw2K9FG0O9rRPeQDIVRyE30QunS9ugHC4eg9ovvOm+QdZ2p93XhzunQEhUWXCxADIEGJK3S2aAfze99PLS29hLcQuYXHDaC7OZqNnosiOGifs8v1ji6H/xhltCZe2lJ+7GutzexKpxvpE/tZSfbY905qSlBh9fpj015cjnQFkUsAUwmKVAUueUz4tKcFK4pevNLaxEAl+OkilMtIYDacD5nel4xJiys413hagqW0Whh5FP39hGk9E/BwQTjazSxGdvX0m6xFYhh/2VMyZjT4KzPJECAwEAAaOCAlgwggJUMA4GA1UdDwEB/wQEAwIFoDATBgNVHSUEDDAKBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBQqBQwGWoJBa1oTKqupo4W6xT6j2DAfBgNVHSMEGDAWgBSY0fhuEOvPm+xgnxiQG6DrfQn9KzBkBggrBgEFBQcBAQRYMFYwJwYIKwYBBQUHMAGGG2h0dHA6Ly9vY3NwLnBraS5nb29nL2d0czFvMTArBggrBgEFBQcwAoYfaHR0cDovL3BraS5nb29nL2dzcjIvR1RTMU8xLmNydDAdBgNVHREEFjAUghJhdHRlc3QuYW5kcm9pZC5jb20wIQYDVR0gBBowGDAIBgZngQwBAgIwDAYKKwYBBAHWeQIFAzAvBgNVHR8EKDAmMCSgIqAghh5odHRwOi8vY3JsLnBraS5nb29nL0dUUzFPMS5jcmwwggEEBgorBgEEAdZ5AgQCBIH1BIHyAPAAdwCkuQmQtBhYFIe7E6LMZ3AKPDWYBPkb37jjd80OyA3cEAAAAWZdD3PLAAAEAwBIMEYCIQCSZCWeLJvsiVW6Cg+gj/9wYTJRzu4Hiqe4eY4c/myzjgIhALSbi/Thzczqtij3dk3vbLcIW3Ll2B0o75GQdhMigbBgAHUAVhQGmi/XwuzT9eG9RLI+x0Z2ubyZEVzA75SYVdaJ0N0AAAFmXQ9z5AAABAMARjBEAiBcCwA9j7NTGXP278z4hr/uCHiAFLyoCq2K0+yLRwJUbgIgf8gHjvpw2mB1ESjq2Of3A0AEAwCknCaEKFUyZ7f/QtIwDQYJKoZIhvcNAQELBQADggEBAI9nTfRKIWgtlWl3wBL55ETV6kazsphW1yAc5Dum6XO41kZzwJ61wJmdRRT/UsCIy1KEt2c0EjglnJCF2eawcEWlLQY2XPLyFjkWQNbShB1i4W2NRGzPht3m1b49hbstuXM6tX5CyEHnTh8Bom4/WlFihzhgn81Dldogz/K2UwM6S6CB/SExkiVfv+zbJ0rjvg94AldjUfUwkI9VNMjEP5e8ydB3oLl6glpCeF5dgfSX4U9x35oj/IId3UE/dPpb/qgGvskfdeztmUte/KSmriwcgUWWeXfTbI3zsikwZbkpmRYKmjPmhv4rlizGCGt8Pn8pq8M2KDf/P3kVot3e18Q="

let jwsToken = "eyJhbGciOiJSUzI1NiIsIng1YyI6WyJNSUlGa2pDQ0JIcWdBd0lCQWdJUVJYcm9OMFpPZFJrQkFBQUFBQVB1bnpBTkJna3Foa2lHOXcwQkFRc0ZBREJDTVFzd0NRWURWUVFHRXdKVlV6RWVNQndHQTFVRUNoTVZSMjl2WjJ4bElGUnlkWE4wSUZObGNuWnBZMlZ6TVJNd0VRWURWUVFERXdwSFZGTWdRMEVnTVU4eE1CNFhEVEU0TVRBeE1EQTNNVGswTlZvWERURTVNVEF3T1RBM01UazBOVm93YkRFTE1Ba0dBMVVFQmhNQ1ZWTXhFekFSQmdOVkJBZ1RDa05oYkdsbWIzSnVhV0V4RmpBVUJnTlZCQWNURFUxdmRXNTBZV2x1SUZacFpYY3hFekFSQmdOVkJBb1RDa2R2YjJkc1pTQk1URU14R3pBWkJnTlZCQU1URW1GMGRHVnpkQzVoYm1SeWIybGtMbU52YlRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTmpYa3owZUsxU0U0bSsvRzV3T28rWEdTRUNycWRuODhzQ3BSN2ZzMTRmSzBSaDNaQ1laTEZIcUJrNkFtWlZ3Mks5RkcwTzlyUlBlUURJVlJ5RTMwUXVuUzl1Z0hDNGVnOW92dk9tK1FkWjJwOTNYaHp1blFFaFVXWEN4QURJRUdKSzNTMmFBZnplOTlQTFMyOWhMY1F1WVhIRGFDN09acU5ub3NpT0dpZnM4djFqaTZIL3hobHRDWmUybEorN0d1dHpleEtweHZwRS90WlNmYlk5MDVxU2xCaDlmcGowMTVjam5RRmtVc0FVd21LVkFVdWVVejR0S2NGSzRwZXZOTGF4RUFsK09raWxNdElZRGFjRDVuZWw0eEppeXM0MTNoYWdxVzBXaGg1RlAzOWhHazlFL0J3UVRqYXpTeEdkdlgwbTZ4RlloaC8yVk15WmpUNEt6UEpFQ0F3RUFBYU9DQWxnd2dnSlVNQTRHQTFVZER3RUIvd1FFQXdJRm9EQVRCZ05WSFNVRUREQUtCZ2dyQmdFRkJRY0RBVEFNQmdOVkhSTUJBZjhFQWpBQU1CMEdBMVVkRGdRV0JCUXFCUXdHV29KQmExb1RLcXVwbzRXNnhUNmoyREFmQmdOVkhTTUVHREFXZ0JTWTBmaHVFT3ZQbSt4Z254aVFHNkRyZlFuOUt6QmtCZ2dyQmdFRkJRY0JBUVJZTUZZd0p3WUlLd1lCQlFVSE1BR0dHMmgwZEhBNkx5OXZZM053TG5CcmFTNW5iMjluTDJkMGN6RnZNVEFyQmdnckJnRUZCUWN3QW9ZZmFIUjBjRG92TDNCcmFTNW5iMjluTDJkemNqSXZSMVJUTVU4eExtTnlkREFkQmdOVkhSRUVGakFVZ2hKaGRIUmxjM1F1WVc1a2NtOXBaQzVqYjIwd0lRWURWUjBnQkJvd0dEQUlCZ1puZ1F3QkFnSXdEQVlLS3dZQkJBSFdlUUlGQXpBdkJnTlZIUjhFS0RBbU1DU2dJcUFnaGg1b2RIUndPaTh2WTNKc0xuQnJhUzVuYjI5bkwwZFVVekZQTVM1amNtd3dnZ0VFQmdvckJnRUVBZFo1QWdRQ0JJSDFCSUh5QVBBQWR3Q2t1UW1RdEJoWUZJZTdFNkxNWjNBS1BEV1lCUGtiMzdqamQ4ME95QTNjRUFBQUFXWmREM1BMQUFBRUF3QklNRVlDSVFDU1pDV2VMSnZzaVZXNkNnK2dqLzl3WVRKUnp1NEhpcWU0ZVk0Yy9teXpqZ0loQUxTYmkvVGh6Y3pxdGlqM2RrM3ZiTGNJVzNMbDJCMG83NUdRZGhNaWdiQmdBSFVBVmhRR21pL1h3dXpUOWVHOVJMSSt4MFoydWJ5WkVWekE3NVNZVmRhSjBOMEFBQUZtWFE5ejVBQUFCQU1BUmpCRUFpQmNDd0E5ajdOVEdYUDI3OHo0aHIvdUNIaUFGTHlvQ3EySzAreUxSd0pVYmdJZ2Y4Z0hqdnB3Mm1CMUVTanEyT2YzQTBBRUF3Q2tuQ2FFS0ZVeVo3Zi9RdEl3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCQUk5blRmUktJV2d0bFdsM3dCTDU1RVRWNmthenNwaFcxeUFjNUR1bTZYTzQxa1p6d0o2MXdKbWRSUlQvVXNDSXkxS0V0MmMwRWpnbG5KQ0YyZWF3Y0VXbExRWTJYUEx5RmprV1FOYlNoQjFpNFcyTlJHelBodDNtMWI0OWhic3R1WE02dFg1Q3lFSG5UaDhCb200L1dsRmloemhnbjgxRGxkb2d6L0syVXdNNlM2Q0IvU0V4a2lWZnYremJKMHJqdmc5NEFsZGpVZlV3a0k5Vk5NakVQNWU4eWRCM29MbDZnbHBDZUY1ZGdmU1g0VTl4MzVvai9JSWQzVUUvZFBwYi9xZ0d2c2tmZGV6dG1VdGUvS1Ntcml3Y2dVV1dlWGZUYkkzenNpa3daYmtwbVJZS21qUG1odjRybGl6R0NHdDhQbjhwcThNMktEZi9QM2tWb3QzZTE4UT0iLCJNSUlFU2pDQ0F6S2dBd0lCQWdJTkFlTzBtcUdOaXFtQkpXbFF1REFOQmdrcWhraUc5dzBCQVFzRkFEQk1NU0F3SGdZRFZRUUxFeGRIYkc5aVlXeFRhV2R1SUZKdmIzUWdRMEVnTFNCU01qRVRNQkVHQTFVRUNoTUtSMnh2WW1Gc1UybG5iakVUTUJFR0ExVUVBeE1LUjJ4dlltRnNVMmxuYmpBZUZ3MHhOekEyTVRVd01EQXdOREphRncweU1URXlNVFV3TURBd05ESmFNRUl4Q3pBSkJnTlZCQVlUQWxWVE1SNHdIQVlEVlFRS0V4VkhiMjluYkdVZ1ZISjFjM1FnVTJWeWRtbGpaWE14RXpBUkJnTlZCQU1UQ2tkVVV5QkRRU0F4VHpFd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUURRR005RjFJdk4wNXprUU85K3ROMXBJUnZKenp5T1RIVzVEekVaaEQyZVBDbnZVQTBRazI4RmdJQ2ZLcUM5RWtzQzRUMmZXQllrL2pDZkMzUjNWWk1kUy9kTjRaS0NFUFpSckF6RHNpS1VEelJybUJCSjV3dWRnem5kSU1ZY0xlL1JHR0ZsNXlPRElLZ2pFdi9TSkgvVUwrZEVhbHROMTFCbXNLK2VRbU1GKytBY3hHTmhyNTlxTS85aWw3MUkyZE44RkdmY2Rkd3VhZWo0YlhocDBMY1FCYmp4TWNJN0pQMGFNM1Q0SStEc2F4bUtGc2JqemFUTkM5dXpwRmxnT0lnN3JSMjV4b3luVXh2OHZObWtxN3pkUEdIWGt4V1k3b0c5aitKa1J5QkFCazdYckpmb3VjQlpFcUZKSlNQazdYQTBMS1cwWTN6NW96MkQwYzF0Skt3SEFnTUJBQUdqZ2dFek1JSUJMekFPQmdOVkhROEJBZjhFQkFNQ0FZWXdIUVlEVlIwbEJCWXdGQVlJS3dZQkJRVUhBd0VHQ0NzR0FRVUZCd01DTUJJR0ExVWRFd0VCL3dRSU1BWUJBZjhDQVFBd0hRWURWUjBPQkJZRUZKalIrRzRRNjgrYjdHQ2ZHSkFib090OUNmMHJNQjhHQTFVZEl3UVlNQmFBRkp2aUIxZG5IQjdBYWdiZVdiU2FMZC9jR1lZdU1EVUdDQ3NHQVFVRkJ3RUJCQ2t3SnpBbEJnZ3JCZ0VGQlFjd0FZWVphSFIwY0RvdkwyOWpjM0F1Y0d0cExtZHZiMmN2WjNOeU1qQXlCZ05WSFI4RUt6QXBNQ2VnSmFBamhpRm9kSFJ3T2k4dlkzSnNMbkJyYVM1bmIyOW5MMmR6Y2pJdlozTnlNaTVqY213d1B3WURWUjBnQkRnd05qQTBCZ1puZ1F3QkFnSXdLakFvQmdnckJnRUZCUWNDQVJZY2FIUjBjSE02THk5d2Eya3VaMjl2Wnk5eVpYQnZjMmwwYjNKNUx6QU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFHb0ErTm5uNzh5NnBSamQ5WGxRV05hN0hUZ2laL3IzUk5Ha21VbVlIUFFxNlNjdGk5UEVhanZ3UlQyaVdUSFFyMDJmZXNxT3FCWTJFVFV3Z1pRK2xsdG9ORnZoc085dHZCQ09JYXpwc3dXQzlhSjl4anU0dFdEUUg4TlZVNllaWi9YdGVEU0dVOVl6SnFQalk4cTNNRHhyem1xZXBCQ2Y1bzhtdy93SjRhMkc2eHpVcjZGYjZUOE1jRE8yMlBMUkw2dTNNNFR6czNBMk0xajZieWtKWWk4d1dJUmRBdktMV1p1L2F4QlZielltcW13a201ekxTRFc1bklBSmJFTENRQ1p3TUg1NnQyRHZxb2Z4czZCQmNDRklaVVNweHU2eDZ0ZDBWN1N2SkNDb3NpclNtSWF0ai85ZFNTVkRRaWJldDhxLzdVSzR2NFpVTjgwYXRuWnoxeWc9PSJdfQ.eyJub25jZSI6InZuS3ByU3o4UHNvczd3eWtSVHEzTnl2RVh6M3pvMk9QVTJGbVpYUjVJRTVsZENCVFlXMXdiR1U2SURFMU5UUTVPVE0xT0RBd05EUT0iLCJ0aW1lc3RhbXBNcyI6MTU1NDk5MzU4MjIyMSwiYXBrUGFja2FnZU5hbWUiOiJjb20uZXhhbXBsZS5hbmRyb2lkLnNhZmV0eW5ldHNhbXBsZSIsImFwa0RpZ2VzdFNoYTI1NiI6Imw4ZDRmU3hCclNxS0J6aExCczAyT3ZKMk1WRGRFQVY0K3F6L1Btdmd4Wkk9IiwiY3RzUHJvZmlsZU1hdGNoIjpmYWxzZSwiYXBrQ2VydGlmaWNhdGVEaWdlc3RTaGEyNTYiOlsiOG1NQ2N4eHVRRFpNM2w2b1J5UWM3MlgwSVlKd3BzK2RrSUVVZjZhdXI5VT0iXSwiYmFzaWNJbnRlZ3JpdHkiOmZhbHNlLCJhZHZpY2UiOiJMT0NLX0JPT1RMT0FERVIifQ.NscMEoJCCqlcm40OYMvg3H_dMLeLEhOA6idxvC76ZluKuCR9mT2qRw-b5uVU-_yPMYeSSf8cdv-u3M3-Is_SG6RnS5t1kctWwGiEURsKlADN9wiPkPRmuN8NuWmXMkP9EPoqig1W93Wmvflsec0vQJaF6jD3Id1M86L62gvHRgD_PQVd-mk1rxqWh2ItWdcbjexTg0azvcppkc6wH6lBMRXqSSRqvt38ag6X6u2inhjYxAxFZONprPLegcrTUnkLFff9mzSmD554LcxkU1j621sYFfYtxShSZ9-4KARHiZ8gyKEaRYrEV54rHFdWegQKtkZGyUH0UpKdOSWBEbCxnQ"

