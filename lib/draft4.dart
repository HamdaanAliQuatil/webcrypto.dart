/// Outline of all classes **including those not implemented yet**.
///
/// Questions:
///  * Naming of hash algorithms, ideas:
///    * `Hasher` (Proposed in draft3),
///    * `Hash` (golang),
///    * `HashAlgorithm` (.Net),
///    * `MessageDigest` (Java),
///    * `Digest` (rust-crypto)
///  * Are we sure about using `Uint8List` for input arguments, all other
///    platform libraries uses `List<int>` for input? And I'll still have to
///    do a test that it's the right type and fallback to copy for custom types.
///  * Can we agree omit `<operation>ToBuffer` methods? These are hard to write
///    for streaming, and we don't support this for `utf8` encoding either.
///  * I would still prefer to avoid `<operation>Stream` methods and instead
///    have all methods default to operate on streams, and leave easy to use
///    methods for working on byte buffers to users.
///    (Countering with examples in documentation and utility methods on pub)
///     - Overhead seems limited (sure, buffering a stream isn't free),
///     - Everything is always async, anyways,
///     - Having multiple methods is unnecessarily complicated,
///     - `<operation>(List<int>)` is largely a convenience method,
///    Counter arguments:
///     - Probably, I _feel_ this ugly, this is a bad argument and I should stop
///       arguing for this :)
///     - `<operation>(List<int>)` won't polute the global namespace, so who cares.
///     - `<operation>(List<int>)` can be slightly more efficient, so maybe it's not
///       entirely convenience.
///     - Most users cannot figure out how to use streams, and the SDK doesn't
///       provide convenience functions for buffering streams, so these are
///       exceptionally hard to use for ordinary users.
///     - 99% of all users will operate on buffers, not streams.
///     - Not providing any convenience methods is an unnecessarily strong
///       oppinion, borderline fanatical :) hehe
///   * Should we rename `<operation>(List<int>)` to `<operation>Buffer(List<int>)`
///     or `<operation>Bytes` (as we call the other `<operation>Stream>`).
///
/// ## CHANGELOG
///
/// Since `draft3.dart`:
///
///  * Renamed `getRandomValues` to `getRandomBytes` and accept `TypedData`.
///  * Renamed `Hasher` to `Hash`
///  * Moved `Hash` instances to be static properties on `Hash`.
///  * Now using `UnsupportedError` instead of adding `NotSupportedException`
///  * Using `Map<String, dynamic>` for JSON values.
///  * Added methods `<operation>(List<int>)` for working on buffers.
///  * Renamed methods for operations on stream to `<operation>Stream`.
///
/// Since `draft2.dart`:
///
///  * Return types are `UInt8List` instead of `List<int>`
///  * `TypedData` no longer used for input parameter (uses `List<int>` consistently)
///  * Added a series of `QUESTION:` comments in source code.
///
/// Since initial draft in `webcrypto.dart` and `incomplete.dart`:
///
///  * Removed `CryptoKey` base class.
///  * Removed `KeyUsages` (all keys can be used for all operations).
///  * Removed `extractable` (all keys can be extracted).
///  * Renamed `CryptoKeyPair` to `KeyPair`.
///  * Required parameters are now all positional parameters.
///  * Removed the `HashAlgorithm` enum.
///  * Added the `Hasher` abstract class.
///  * Added constants `sha1`, `sha256`, `sha384`, and, `sha512`.
///
///
/// ## Exceptions
/// This library will throw the following exceptions:
///  * [FormatException], if input data could not be parsed.
///
/// ## Errors
/// This library will throw the following errors:
///  * [ArgumentError], when an parameter is out of range,
///  * [UnsupportedError], when an operation isn't supported,
///  * [OperationError], when an operation fails operation specific reason, this
///    typically when the underlying cryptographic library returns an error.
///
/// ## Mapping Web Crypto Error
///
///  * `SyntaxError` becomes [ArgumentError],
///  * `QuotaExceededError` becomes [ArgumentError],
///  * `NotSupportedError` becomes [UnsupportedError],
///  * `DataError` becomes [FormatException],
///  * `OperationError` becomes [OperationError],
///  * `InvalidAccessError` shouldn't occur, if it does it's an
///    [OperationError], because it's an unknown error.
///
library draft4;

import 'dart:async';
import 'dart:typed_data';

/// Thrown when an operation failed for an operation-specific reason.
class OperationError extends Error {
  final String message;
  OperationError._(this.message);
  @override
  String toString() => this.message;
}

/// A key-pair as returned from key generation.
abstract class KeyPair<S, T> {
  KeyPair._(); // keep the constructor private.

  /// Private key for [publicKey].
  S get privateKey;

  /// Public key matching [privateKey].
  T get publicKey;
}

/// Fill [destination] with cryptographically random values.
///
/// Does not accept a [destination] larger than `65536` bytes, use multiple
/// calls to obtain more random bytes.
///
/// **Example**
/// ```dart
/// import 'dart:convert' show base64;
/// import 'dart:typed_data' show Uint8List;
/// import 'dart:crypto';
///
/// // Allocated a byte array of 64 bytes.
/// final bytes = Uint8List(64);
///
/// // Fill with random bytes.
/// getRandomValues(bytes);
///
/// // Print base64 encoded random bytes.
/// print(base64.encode(bytes));
/// ```
void getRandomBytes(
  TypedData destination,
  // Note: Uint8List and friends all implement TypedData, but dartdoc has a bug
  //       where it's not reporting this.
) {
  ArgumentError.checkNotNull(destination, 'destination');
  // This limitation is given in the Web Cryptography Specification, see:
  // https://www.w3.org/TR/WebCryptoAPI/#Crypto-method-getRandomValues
  if (destination.lengthInBytes > 65536) {
    throw ArgumentError.value(destination, 'destination',
        'array of more than 65536 bytes is not allowed');
  }

  throw UnimplementedError('TODO: Implement this');
}

/// A cryptographic hash algorithm implementation.
///
/// The `dart:crypto` library provides the following implementations of this
/// class:
///  * [Hash.sha1], (this is considered weak, only included for compatibility),
///  * [Hash.sha256],
///  * [Hash.sha384], and,
///  * [Hash.sha512].
///
/// **WARNING:** Custom implementations of this class cannot be passed to
/// to other methods in this library.
abstract class Hash {
  /// Compute a cryptographic hash-sum of [data] using this [Hash].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show base64, utf8;
  /// import 'dart:crypto';
  ///
  /// // Convert 'hello world' to a byte array
  /// final bytesToHash = utf8.encode('hello world');
  ///
  /// // Compute hash of bytesToHash with sha-256
  /// List<int> hash = await Hash.sha256.digest(bytesToHash);
  ///
  /// // Print the base64 encoded hash
  /// print(base64.encode(hash));
  /// ```
  Future<Uint8List> digest(List<int> data);

  /// Compute a cryptographic hash-sum of [data] stream using this [Hash].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:io' show File;
  /// import 'dart:convert' show base64;
  /// import 'dart:crypto';
  ///
  /// // Pick a file to hash.
  /// String fileToHash = '/etc/passwd';
  ///
  /// // Compute hash of fileToHash with sha-256
  /// List<int> hash;
  /// final stream = File(fileToHash).openRead();
  /// try {
  ///   hash = await Hash.sha256.digestStream(stream);
  /// } finally {
  ///   await stream.close(); // always close the stream
  /// }
  ///
  /// // Print the base64 encoded hash
  /// print(base64.encode(hash));
  /// ```
  Future<Uint8List> digestStream(Stream<List<int>> data);

  /// SHA-1 as specified in [FIPS PUB 180-4][1].
  ///
  /// **This algorithm is considered weak** and should not be used in new
  /// cryptographic applications.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show base64, utf8;
  /// import 'dart:crypto';
  ///
  /// // Convert 'hello world' to a byte array
  /// final bytesToHash = utf8.encode('hello world');
  ///
  /// // Compute hash of bytesToHash with sha-256
  /// List<int> hash = await Hash.sha256.digest(bytesToHash);
  ///
  /// // Print the base64 encoded hash
  /// print(base64.encode(hash));
  /// ```
  ///
  /// [1]: https://doi.org/10.6028/NIST.FIPS.180-4
  static const Hash sha1 = null; // TODO: Implement this

  /// SHA-256 as specified in [FIPS PUB 180-4][1].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show base64, utf8;
  /// import 'dart:crypto';
  ///
  /// // Convert 'hello world' to a byte array
  /// final bytesToHash = utf8.encode('hello world');
  ///
  /// // Compute hash of bytesToHash with sha-256
  /// List<int> hash = await Hash.sha256.digest(bytesToHash);
  ///
  /// // Print the base64 encoded hash
  /// print(base64.encode(hash));
  /// ```
  ///
  /// [1]: https://doi.org/10.6028/NIST.FIPS.180-4
  static const Hash sha256 = null; // TODO: Implement this

  /// SHA-384 as specified in [FIPS PUB 180-4][1].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show base64, utf8;
  /// import 'dart:crypto';
  ///
  /// // Convert 'hello world' to a byte array
  /// final bytesToHash = utf8.encode('hello world');
  ///
  /// // Compute hash of bytesToHash with sha-384
  /// List<int> hash = await Hash.sha384.digest(bytesToHash);
  ///
  /// // Print the base64 encoded hash
  /// print(base64.encode(hash));
  /// ```
  ///
  /// [1]: https://doi.org/10.6028/NIST.FIPS.180-4
  static const Hash sha384 = null; // TODO: Implement this

  /// SHA-512 as specified in [FIPS PUB 180-4][1].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show base64, utf8;
  /// import 'dart:crypto';
  ///
  /// // Convert 'hello world' to a byte array
  /// final bytesToHash = utf8.encode('hello world');
  ///
  /// // Compute hash of bytesToHash with sha-512
  /// List<int> hash = await Hash.sha512.digest(bytesToHash);
  ///
  /// // Print the base64 encoded hash
  /// print(base64.encode(hash));
  /// ```
  ///
  /// [1]: https://doi.org/10.6028/NIST.FIPS.180-4
  static const Hash sha512 = null; // TODO: Implement this
}

/// Key for signing/verifying with HMAC.
///
/// An [HmacSecretKey] instance holds a symmetric secret key and a
/// [Hash], which can be used to create and verify HMAC signatures as
/// specified in [FIPS PUB 180-4][1].
///
/// Instances of [HmacSecretKey] can be imported using
/// [HmacSecretKey.importRawKey] or generated using [HmacSecretKey.generateKey].
///
/// [1]: https://doi.org/10.6028/NIST.FIPS.180-4
abstract class HmacSecretKey {
  HmacSecretKey._(); // keep the constructor private.

  /// Import [HmacSecretKey] from raw [keyData].
  ///
  /// Creates an [HmacSecretKey] using [keyData] as secret key, and running
  /// HMAC with given [hash] algorithm.
  ///
  /// If given [length] specifies the length of the key, this must be not be
  /// less than number of bits in [keyData] - 7. The [length] only allows
  /// cutting bits of the last byte in [keyData]. In practice this is the same
  /// as zero'ing the last bits in [keyData].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8;
  /// import 'dart:crypto';
  ///
  /// final key = await HmacSecretKey.importRawKey(
  ///   utf8.encode('a-secret-key'),  // don't use string in practice
  ///   Hash.sha256,
  /// );
  /// ```
  static Future<HmacSecretKey> importRawKey(
    List<int> keyData,
    Hash hash, {
    int length,
  }) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(hash, 'hash');
    // These limitations are given in Web Cryptography Spec:
    // https://www.w3.org/TR/WebCryptoAPI/#hmac-operations
    if (length != null && length > keyData.length * 8) {
      throw ArgumentError.value(
          length, 'length', 'must be less than number of bits in keyData');
    }
    if (length != null && length <= (keyData.length - 1) * 8) {
      throw ArgumentError.value(
        length,
        'length',
        'must be greater than number of bits in keyData - 8, you can attain '
            'the same effect by removing bytes from keyData',
      );
    }

    throw UnimplementedError('TODO: Implement this');
  }

  /// Import [HmacSecretKey] from [JWK][1].
  ///
  /// TODO: finish implementation and documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  static Future<HmacSecretKey> importJsonWebKey(
    Map<String, dynamic> jwk,
    Hash hash, {
    int length,
  }) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(hash, 'hash');
    // TODO: Validate length in the native implememtation

    throw UnimplementedError('TODO: Implement this');
  }

  /// Generate random [HmacSecretKey].
  ///
  /// The [length] specifies the length of the secret key in bits. If omitted
  /// the random key will use the same number of bits as the underlying hash
  /// algorithm given in [hash].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:crypto';
  ///
  /// // Generate a new random HMAC secret key.
  /// final key = await HmacSecretKey.generate(Hash.sha256);
  /// ```
  static Future<HmacSecretKey> generateKey(Hash hash, {int length}) {
    ArgumentError.checkNotNull(hash, 'hash');
    if (length != null && length <= 0) {
      throw ArgumentError.value(length, 'length', 'must be positive');
    }

    throw UnimplementedError('TODO: Implement this');
  }

  /// Compute an HMAC signature of given [data].
  ///
  /// This computes an HMAC signature of the [data] using hash algorithm
  /// and secret key material held by this [HmacSecretKey].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show base64, utf8;
  /// import 'dart:crypto';
  ///
  /// // Generate an HmacSecretKey.
  /// final key = await HmacSecretKey.generateKey(Hash.sha256);
  ///
  /// String stringToSign = 'example-string-to-signed';
  ///
  /// // Compute signature.
  /// final signature = await key.sign(utf8.encode(stringToSign));
  ///
  /// // Print as base64
  /// print(base64.encode(signature));
  /// ```
  ///
  /// **Warning**, this method should **not** be used for **validating**
  /// other signatures by generating a new signature and then comparing the two.
  /// While this technically works, you application might be vulnerable to
  /// timing attacks. To validate signatures use [verify()], this method
  /// computes a signature and does a fixed-time comparison.
  Future<Uint8List> sign(List<int> data);

  /// Compute an HMAC signature of given [data] stream.
  ///
  /// This computes an HMAC signature of the [data] stream using hash algorithm
  /// and secret key material held by this [HmacSecretKey].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show base64, utf8;
  /// import 'dart:crypto';
  ///
  /// // Generate an HmacSecretKey.
  /// final key = await HmacSecretKey.generateKey(Hash.sha256);
  ///
  /// String stringToSign = 'example-string-to-signed';
  ///
  /// // Compute signature.
  /// final signature = await key.signStream(Stream.fromIterable([
  ///   utf8.encode(stringToSign),
  /// ]));
  ///
  /// // Print as base64
  /// print(base64.encode(signature));
  /// ```
  ///
  /// **Warning**, this method should **not** be used for **validating**
  /// other signatures by generating a new signature and then comparing the two.
  /// While this technically works, you application might be vulnerable to
  /// timing attacks. To validate signatures use [verifyStream()], this method
  /// computes a signature and does a fixed-time comparison.
  Future<Uint8List> signStream(Stream<List<int>> data);

  /// Verify the HMAC [signature] of given [data].
  ///
  /// This computes an HMAC signature of the [data] in the same manner
  /// as [sign()] and conducts a fixed-time comparison against [signature],
  /// returning `true` if the two signatures are equal.
  ///
  /// Notice that it's possible to compute a signature for [data] using
  /// [sign()] and then simply compare the two signatures. This is strongly
  /// discouraged as it is easy to introduce side-channels opening your
  /// application to timing attacks. Use this method to verify signatures.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show base64, utf8;
  /// import 'dart:crypto';
  ///
  /// // Generate an HmacSecretKey.
  /// final key = await HmacSecretKey.generateKey(Hash.sha256);
  ///
  /// String stringToSign = 'example-string-to-signed';
  ///
  /// // Compute signature.
  /// final signature = await key.sign(utf8.encode(stringToSign));
  ///
  /// // Verify signature.
  /// final result = await key.verify(signature, utf8.encode(stringToSign));
  /// assert(result == true, 'this signature should be valid');
  /// ```
  Future<bool> verify(List<int> signature, List<int> data);

  /// Verify the HMAC [signature] of given [data] stream.
  ///
  /// This computes an HMAC signature of the [data] stream in the same manner
  /// as [sign()] and conducts a fixed-time comparison against [signature],
  /// returning `true` if the two signatures are equal.
  ///
  /// Notice that it's possible to compute a signature for [data] using
  /// [sign()] and then simply compare the two signatures. This is strongly
  /// discouraged as it is easy to introduce side-channels opening your
  /// application to timing attacks. Use this method to verify signatures.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show base64, utf8;
  /// import 'dart:crypto';
  ///
  /// // Generate an HmacSecretKey.
  /// final key = await HmacSecretKey.generateKey(Hash.sha256);
  ///
  /// String stringToSign = 'example-string-to-signed';
  ///
  /// // Compute signature.
  /// final signature = await key.sign(Stream.fromIterable([
  ///   utf8.encode(stringToSign),
  /// ]));
  ///
  /// // Verify signature.
  /// final result = await key.verify(signature, Stream.fromIterable([
  ///   utf8.encode(stringToSign),
  /// ]));
  /// assert(result == true, 'this signature should be valid');
  /// ```
  Future<bool> verifyStream(List<int> signature, Stream<List<int>> data);

  /// Export [HmacSecretKey] as raw bytes.
  ///
  /// This returns raw bytes making up the secret key. This does not encode the
  /// [Hash] hash algorithm used.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:crypto';
  ///
  /// // Generate a new random HMAC secret key.
  /// final key = await HmacSecretKey.generate(Hash.sha256);
  ///
  /// // Extract the secret key.
  /// final secretBytes = await key.extractRawKey();
  ///
  /// // Print the key as base64
  /// print(base64.encode(secretBytes));
  ///
  /// // If we wanted to we could import the key as follows:
  /// // key = await HmacSecretKey.importRawKey(secretBytes, Hash.sha256);
  /// ```
  Future<Uint8List> exportRawKey();

  /// Export [HmacSecretKey] from [JWK][1].
  ///
  /// TODO: finish implementation and documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  Future<Map<String, dynamic>> exportJsonWebKey();
}

/// RSASSA-PKCS1-v1_5 private key for signing messages.
///
/// An [RsassaPkcs1V15PrivateKey] instance hold a private RSA key for computing
/// signatures using the RSASSA-PKCS1-v1_5 scheme as specified in [RFC 3447][1].
///
/// Instances of [RsassaPkcs1V15PrivateKey] can be imported using
/// [RsassaPkcs1V15PrivateKey.importPkcs8Key] or generated using
/// [RsassaPkcs1V15PrivateKey.generateKey] which generates a public-private
/// key-pair.
///
/// [1]: https://tools.ietf.org/html/rfc3447
abstract class RsassaPkcs1V15PrivateKey {
  RsassaPkcs1V15PrivateKey._(); // keep the constructor private.

  /// Import RSASSA-PKCS1-v1_5 private key in PKCS #8 format.
  ///
  /// Creates an [RsassaPkcs1V15PrivateKey] from [keyData] given as the DER
  /// encoding of the _PrivateKeyInfo structure_ specified in [RFC 5208][1].
  /// The hash algorithm to be used is specified by [hash].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:crypto';
  /// import 'package:pem/pem.dart';
  ///
  /// // Read key data from PEM encoded block. This will remove the
  /// // '----BEGIN...' padding, decode base64 and return encoded bytes.
  /// List<int> keyData = PemCodec(PemLabel.privateKey).decode("""
  ///   -----BEGIN PRIVATE KEY-----
  ///   MIGEAgEAMBAGByqG...
  ///   -----END PRIVATE KEY-----
  /// """);
  ///
  /// // Import private key from binary PEM decoded data.
  /// final privateKey = await RsassaPkcs1V15PrivateKey.importPkcs8Key(
  ///   keyData,
  ///   Hash.sha256,
  /// );
  ///
  /// // Export the key again (print it in same format as it was given).
  /// List<int> rawKeyData = await privateKey.exportPkcs8Key();
  /// print(PemCodec(PemLabel.privateKey).encode(rawKeyData));
  /// ```
  ///
  /// [1]: https://tools.ietf.org/html/rfc5208
  static Future<RsassaPkcs1V15PrivateKey> importPkcs8Key(
    List<int> keyData,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: Implement this');
  }

  /// Import RSASSA-PKCS1-v1_5 private key in [JWK][1] format.
  ///
  /// TODO: finish implementation and documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  static Future<RsassaPkcs1V15PrivateKey> importJsonWebKey(
    Map<String, dynamic> jwk,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: Implement this');
  }

  /// Generate an RSASSA-PKCS1-v1_5 public/private key-pair.
  ///
  /// Generate an RSA key with given [modulusLength], this should be at-least
  /// `2048` (though `4096` is often recommended). [publicExponent] should be
  /// `3` or `65537` these are the only values [supported by Chrome][1], unless
  /// you have a good reason to use something else `65537` is recommended.
  ///
  /// The hash algorithm to be used is specified by [hash].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8;
  /// import 'dart:crypto';
  /// import 'package:pem/pem.dart';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Export public, so Alice can use it later.
  /// final rawPublicKey = await keyPair.publicKey.exportSpkiKey();
  /// final pemPublicKey = PemCodec(PemLabel.publicKey).encode(rawPublicKey);
  /// print(pemPublicKey); // print key in PEM format: -----BEGIN PUBLIC KEY....
  ///
  /// // Sign a message for Alice.
  /// final message = 'Hi Alice';
  /// final signature = await keyPair.privateKey.sign(
  ///   Stream.fromIterable([utf8.encode(message)]),
  /// );
  ///
  /// // On the other side of the world, Alice has written down the pemPublicKey
  /// // on a trusted piece of paper, but receives the message and signature
  /// // from an untrusted source (thus, desires to verify the signature).
  /// final publicKey = await RsassaPkcs1V15PublicKey.importSpkiKey(
  ///   PemCodec(PemLabel.publicKey).decode(pemPublicKey),
  ///   Hash.sha256,
  /// );
  /// final isValid = await publicKey.verify(
  ///   signature,
  ///   Stream.fromIterable([utf8.encode(message)]),
  /// );
  /// if (isValid) {
  ///   print('Authentic message from Bob: $message');
  /// }
  /// ```
  ///
  /// [1]: https://chromium.googlesource.com/chromium/src/+/43d62c50b705f88c67b14539e91fd8fd017f70c4/components/webcrypto/algorithms/rsa.cc#286
  static Future<KeyPair<RsassaPkcs1V15PrivateKey, RsassaPkcs1V15PublicKey>>
      generateKey(
    int modulusLength,
    BigInt publicExponent,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(modulusLength, 'modulusLength');
    ArgumentError.checkNotNull(publicExponent, 'publicExponent');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: Implement this');
  }

  /// Sign [data] with this RSASSA-PKCS1-v1_5 private key.
  ///
  /// Returns a signature as a list of raw bytes. This uses the [Hash]
  /// specified when the key was generated or imported.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8, base64;
  /// import 'dart:crypto';
  /// import 'package:pem/pem.dart';
  ///
  /// // Read prviate key data from PEM encoded block. This will remove the
  /// // '----BEGIN...' padding, decode base64 and return encoded bytes.
  /// List<int> keyData = PemCodec(PemLabel.privateKey).decode("""
  ///   -----BEGIN PRIVATE KEY-----
  ///   MIGEAgEAMBAGByqG...
  ///   -----END PRIVATE KEY-----
  /// """);
  ///
  /// // Import private key from binary PEM decoded data.
  /// final privatKey = await RsassaPkcs1V15PrivateKey.importPkcs8Key(
  ///   keyData,
  ///   Hash.sha256,
  /// );
  ///
  /// // Create a signature for UTF-8 encoded message
  /// final message = 'hello world';
  /// final signature = await privateKey.sign(utf8.encode(message));
  ///
  /// print('signature: ${base64.encode(signature)}');
  /// ```
  Future<Uint8List> sign(List<int> data);

  /// Sign [data] with this RSASSA-PKCS1-v1_5 private key.
  ///
  /// Returns a signature as a list of raw bytes. This uses the [Hash]
  /// specified when the key was generated or imported.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8, base64;
  /// import 'dart:crypto';
  /// import 'package:pem/pem.dart';
  ///
  /// // Read prviate key data from PEM encoded block. This will remove the
  /// // '----BEGIN...' padding, decode base64 and return encoded bytes.
  /// List<int> keyData = PemCodec(PemLabel.privateKey).decode("""
  ///   -----BEGIN PRIVATE KEY-----
  ///   MIGEAgEAMBAGByqG...
  ///   -----END PRIVATE KEY-----
  /// """);
  ///
  /// // Import private key from binary PEM decoded data.
  /// final privatKey = await RsassaPkcs1V15PrivateKey.importPkcs8Key(
  ///   keyData,
  ///   Hash.sha256,
  /// );
  ///
  /// // Create a signature for UTF-8 encoded message
  /// final message = 'hello world';
  /// final signature = await privateKey.signStream(Stream.fromIterable([
  ///   utf8.encode(message),
  /// ]));
  ///
  /// print('signature: ${base64.encode(signature)}');
  /// ```
  Future<Uint8List> signStream(Stream<List<int>> data);

  /// Export this RSASSA-PKCS1-v1_5 private key in PKCS #8 format.
  ///
  /// Returns the DER encoding of the _PrivateKeyInfo structure_ specified in
  /// [RFC 5208][1] as a list of bytes.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:crypto';
  /// import 'package:pem/pem.dart';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Export the private key.
  /// final rawPrivateKey = await keypair.privateKey.exportPkcs8Key();
  ///
  /// // Private keys are often encoded as PEM.
  /// // This encodes the key in base64 and wraps it with:
  /// // '-----BEGIN PRIVATE KEY----'...
  /// print(PemCodec(PemLabel.privateKey).encode(rawPrivateKey));
  /// ```
  ///
  /// [1]: https://tools.ietf.org/html/rfc5208
  Future<Uint8List> exportPkcs8Key();

  /// Export RSASSA-PKCS1-v1_5 private key in [JWK][1] format.
  ///
  /// TODO: finish implementation and documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  Future<Map<String, dynamic>> exportJsonWebKey();
}

/// RSASSA-PKCS1-v1_5 public key for signing messages.
///
/// An [RsassaPkcs1V15PublicKey] instance hold a public RSA key for verification
/// of signatures following the RSASSA-PKCS1-v1_5 scheme as specified
/// in [RFC 3447][1].
///
/// Instances of [RsassaPkcs1V15PublicKey] can be imported using
/// [RsassaPkcs1V15PublicKey.importSpkiKey] or generated using
/// [RsassaPkcs1V15PrivateKey.generateKey] which generates a public-private
/// key-pair.
///
/// [1]: https://tools.ietf.org/html/rfc3447
abstract class RsassaPkcs1V15PublicKey {
  RsassaPkcs1V15PublicKey._(); // keep the constructor private.

  /// Import RSASSA-PKCS1-v1_5 public key in SPKI format.
  ///
  /// Creates an [RsassaPkcs1V15PublicKey] from [keyData] given as the DER
  /// encoding of the _SubjectPublicKeyInfo structure_ specified in
  /// [RFC 5280][1]. The hash algorithm to be used is specified by [hash].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:crypto';
  /// import 'package:pem/pem.dart';
  ///
  /// // Read key data from PEM encoded block. This will remove the
  /// // '----BEGIN...' padding, decode base64 and return encoded bytes.
  /// List<int> keyData = PemCodec(PemLabel.publicKey).decode("""
  ///   -----BEGIN PUBLIC KEY-----
  ///   MIGEAgEAMBAGByqG...
  ///   -----END PUBLIC KEY-----
  /// """);
  ///
  /// // Import public key from binary PEM decoded data.
  /// final publicKey = await RsassaPkcs1V15PublicKey.importSpkiKey(
  ///   keyData,
  ///   Hash.sha256,
  /// );
  ///
  /// // Export the key again (print it in same format as it was given).
  /// List<int> rawKeyData = await publicKey.exportSpkiKey();
  /// print(PemCodec(PemLabel.publicKey).encode(rawKeyData));
  /// ```
  ///
  /// [1]: https://tools.ietf.org/html/rfc5280
  static Future<RsassaPkcs1V15PublicKey> importSpkiKey(
    List<int> keyData,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: Implement this');
  }

  /// Import RSASSA-PKCS1-v1_5 public key from [JWK][1].
  ///
  /// TODO: finish implementation and documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  static Future<RsassaPkcs1V15PublicKey> importJsonWebKey(
    Map<String, dynamic> jwk,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: Implement this');
  }

  /// Verify [signature] of [data] using this RSASSA-PKCS1-v1_5 public key.
  ///
  /// Returns `true` if the signature was made the private key matching this
  /// public key. This uses the [Hash] specified when the key was
  /// generated or imported.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8;
  /// import 'dart:crypto';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Using privateKey Bob can sign a message for Alice.
  /// final message = 'Hi Alice';
  /// final signature = await keyPair.privateKey.sign(utf8.encode(message));
  ///
  /// // Given publicKey and signature Alice can verify the message from Bob.
  /// final isValid = await keypair.publicKey.verify(
  ///   signature,
  ///   utf8.encode(message),
  /// );
  /// if (isValid) {
  ///   print('Authentic message from Bob: $message');
  /// }
  /// ```
  Future<bool> verify(List<int> signature, List<int> data);

  /// Verify [signature] of [data] using this RSASSA-PKCS1-v1_5 public key.
  ///
  /// Returns `true` if the signature was made the private key matching this
  /// public key. This uses the [Hash] specified when the key was
  /// generated or imported.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8;
  /// import 'dart:crypto';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Using privateKey Bob can sign a message for Alice.
  /// final message = 'Hi Alice';
  /// final signature = await keyPair.privateKey.sign(utf8.encode(message));
  ///
  /// // Given publicKey and signature Alice can verify the message from Bob.
  /// final isValid = await keypair.publicKey.verifyStream(
  ///   signature,
  ///   Stream.fromIterable([utf8.encode(message)]),
  /// );
  /// if (isValid) {
  ///   print('Authentic message from Bob: $message');
  /// }
  /// ```
  Future<bool> verifyStream(List<int> signature, Stream<List<int>> data);

  /// Export this RSASSA-PKCS1-v1_5 private key in SPKI format.
  ///
  /// Returns the DER encoding of the _SubjectPublicKeyInfo structure_ specified
  /// in [RFC 5280][1] as a list of bytes. This operation is only allowed if the
  /// key was imported or generated with the [extractable] bit set to `true`.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:crypto';
  /// import 'package:pem/pem.dart';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Export the public key.
  /// final rawPublicKey = await keyPair.publicKey.exportSpkiKey();
  ///
  /// // Public keys are often encoded as PEM.
  /// // This encode the key in base64 and wraps it with:
  /// // '-----BEGIN PUBLIC KEY-----'...
  /// print(PemCodec(PemLabel.publicKey).encode(rawPublicKey));
  /// ```
  ///
  /// [1]: https://tools.ietf.org/html/rfc5280
  Future<Uint8List> exportSpkiKey();

  /// Export RSASSA-PKCS1-v1_5 public key in [JWK][1] format.
  ///
  /// TODO: finish implementation and documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class RsaPssPrivateKey {
  RsaPssPrivateKey._(); // keep the constructor private.

  static Future<RsaPssPrivateKey> importPkcs8Key(
    List<int> keyData,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-PSS');
  }

  static Future<RsaPssPrivateKey> importJsonWebKey(
    Map<String, dynamic> jwk,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-PSS');
  }

  static Future<KeyPair<RsaPssPrivateKey, RsaPssPublicKey>> generateKey(
    int modulusLength,
    BigInt publicExponent,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(modulusLength, 'modulusLength');
    ArgumentError.checkNotNull(publicExponent, 'publicExponent');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-PSS');
  }

  Future<Uint8List> sign(List<int> data, int saltLength);
  Future<Uint8List> signStream(Stream<List<int>> data, int saltLength);

  Future<Uint8List> exportPkcs8Key();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class RsaPssPublicKey {
  RsaPssPublicKey._(); // keep the constructor private.

  static Future<RsaPssPublicKey> importSpkiKey(
    List<int> keyData,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-PSS');
  }

  static Future<RsaPssPublicKey> importJsonWebKey(
    List<int> jwk,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-PSS');
  }

  Future<bool> verify(
    List<int> signature,
    List<int> data,
    int saltLength,
  );

  Future<bool> verifyStream(
    List<int> signature,
    Stream<List<int>> data,
    int saltLength,
  );

  Future<Uint8List> exportSpkiKey();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

/// Elliptic curves supported by ECDSA and ECDH.
///
/// **Remark**, additional values may be added to this enum in the future.
enum EllipticCurve {
  p256,
  p384,
  p521,
}

abstract class EcdsaPrivateKey {
  EcdsaPrivateKey._(); // keep the constructor private.

  static Future<EcdsaPrivateKey> importPkcs8Key(
    List<int> keyData,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDSA');
  }

  static Future<EcdsaPrivateKey> importJsonWebKey(
    List<int> jwk,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDSA');
  }

  static Future<KeyPair<EcdsaPrivateKey, EcdsaPublicKey>> generateKey(
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDSA');
  }

  Future<Uint8List> sign(List<int> data, Hash hash);
  Future<Uint8List> signStream(Stream<List<int>> data, Hash hash);

  Future<Uint8List> exportPkcs8Key();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class EcdsaPublicKey {
  EcdsaPublicKey._(); // keep the constructor private.

  static Future<EcdsaPublicKey> importRawKey(
    List<int> keyData,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDSA');
  }

  static Future<EcdsaPublicKey> importSpkiKey(
    List<int> keyData,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDSA');
  }

  static Future<EcdsaPublicKey> importJsonWebKey(
    List<int> jwk,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDSA');
  }

  Future<bool> verify(
    List<int> signature,
    List<int> data,
    Hash hash,
  );

  Future<bool> verifyStream(
    List<int> signature,
    Stream<List<int>> data,
    Hash hash,
  );

  Future<Uint8List> exportRawKey();

  Future<Uint8List> exportSpkiKey();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class RsaOaepPrivateKey {
  RsaOaepPrivateKey._(); // keep the constructor private.

  static Future<RsaOaepPrivateKey> importPkcs8Key(
    List<int> keyData,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-OAEP');
  }

  static Future<RsaOaepPrivateKey> importJsonWebKey(
    List<int> jwk,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-OAEP');
  }

  static Future<KeyPair<RsaOaepPrivateKey, RsaPssPublicKey>> generateKey(
    int modulusLength,
    BigInt publicExponent,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(modulusLength, 'modulusLength');
    ArgumentError.checkNotNull(publicExponent, 'publicExponent');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-OAEP');
  }

  Future<Uint8List> decrypt(List<int> data, {List<int> label});

  Stream<Uint8List> decryptStream(Stream<List<int>> data, {List<int> label});

  Future<Uint8List> exportPkcs8Key();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class RsaOaepPublicKey {
  RsaOaepPublicKey._(); // keep the constructor private.

  static Future<RsaOaepPublicKey> importSpkiKey(
    List<int> keyData,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-OAEP');
  }

  static Future<RsaOaepPublicKey> importJsonWebKey(
    List<int> jwk,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(hash, 'hash');

    throw UnimplementedError('TODO: implement RSA-OAEP');
  }

  Future<Uint8List> encrypt(List<int> data, {List<int> label});

  Stream<Uint8List> encryptStream(Stream<List<int>> data, {List<int> label});

  Future<Uint8List> exportSpkiKey();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class AesCtrSecretKey {
  AesCtrSecretKey._(); // keep the constructor private.

  static Future<AesCtrSecretKey> importRawKey(List<int> keyData) {
    ArgumentError.checkNotNull(keyData, 'keyData');

    throw UnimplementedError('TODO: implement AES-CTR');
  }

  static Future<AesCtrSecretKey> importJsonWebKey(List<int> jwk) {
    ArgumentError.checkNotNull(jwk, 'jwk');

    throw UnimplementedError('TODO: implement AES-CTR');
  }

  static Future<AesCtrSecretKey> generateKey(int length) {
    ArgumentError.checkNotNull(length, 'length');

    throw UnimplementedError('TODO: implement AES-CTR');
  }

  Future<Uint8List> encrypt(
    List<int> data,
    List<int> counter,
    int length,
  );

  Stream<Uint8List> encryptStream(
    Stream<List<int>> data,
    List<int> counter,
    int length,
  );

  Future<Uint8List> decrypt(
    List<int> data,
    List<int> counter,
    int length,
  );

  Stream<Uint8List> decryptStream(
    Stream<List<int>> data,
    List<int> counter,
    int length,
  );

  Future<Uint8List> exportRawKey();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class AesCbcSecretKey {
  AesCbcSecretKey._(); // keep the constructor private.

  static Future<AesCbcSecretKey> importRawKey(List<int> keyData) {
    ArgumentError.checkNotNull(keyData, 'keyData');

    throw UnimplementedError('TODO: implement AES-CBC');
  }

  static Future<AesCbcSecretKey> importJsonWebKey(List<int> jwk) {
    ArgumentError.checkNotNull(jwk, 'jwk');

    throw UnimplementedError('TODO: implement AES-CBC');
  }

  static Future<AesCbcSecretKey> generateKey(int length) {
    ArgumentError.checkNotNull(length, 'length');

    throw UnimplementedError('TODO: implement AES-CBC');
  }

  Future<Uint8List> encrypt(List<int> data, List<int> iv);

  Stream<Uint8List> encryptStream(Stream<List<int>> data, List<int> iv);

  Future<Uint8List> decrypt(List<int> data, List<int> iv);

  Stream<Uint8List> decryptStream(Stream<List<int>> data, List<int> iv);

  Future<Uint8List> exportRawKey();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class AesGcmSecretKey {
  AesGcmSecretKey._(); // keep the constructor private.

  static Future<AesGcmSecretKey> importRawKey(List<int> keyData) {
    ArgumentError.checkNotNull(keyData, 'keyData');

    throw UnimplementedError('TODO: implement AES-GCM');
  }

  static Future<AesGcmSecretKey> importJsonWebKey(List<int> jwk) {
    ArgumentError.checkNotNull(jwk, 'jwk');

    throw UnimplementedError('TODO: implement AES-GCM');
  }

  static Future<AesGcmSecretKey> generateKey(int length) {
    ArgumentError.checkNotNull(length, 'length');

    throw UnimplementedError('TODO: implement AES-GCM');
  }

  Future<Uint8List> encrypt(
    List<int> data,
    List<int> iv, {
    List<int> additionalData,
    int tagLength = 128,
  });

  Stream<Uint8List> encryptStream(
    Stream<List<int>> data,
    List<int> iv, {
    List<int> additionalData,
    int tagLength = 128,
  });

  Future<Uint8List> decrypt(
    List<int> data,
    List<int> iv, {
    List<int> additionalData,
    int tagLength = 128,
  });

  Stream<Uint8List> decryptStream(
    Stream<List<int>> data,
    List<int> iv, {
    List<int> additionalData,
    int tagLength = 128,
  });

  Future<Uint8List> exportRawKey();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class EcdhPrivateKey {
  EcdhPrivateKey._(); // keep the constructor private.

  static Future<EcdhPrivateKey> importPkcs8Key(
    List<int> keyData,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDH');
  }

  static Future<EcdhPrivateKey> importJsonWebKey(
    List<int> jwk,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDH');
  }

  static Future<KeyPair<EcdhPrivateKey, EcdhPublicKey>> generateKey(
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDH');
  }

  Future<Uint8List> deriveBits(EcdhPublicKey publicKey, int length);

  Future<Uint8List> exportPkcs8Key();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class EcdhPublicKey {
  EcdhPublicKey._(); // keep the constructor private.

  static Future<EcdhPublicKey> importRawKey(
    List<int> keyData,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDH');
  }

  static Future<EcdhPublicKey> importSpkiKey(
    List<int> keyData,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDH');
  }

  static Future<EcdhPublicKey> importJsonWebKey(
    List<int> jwk,
    EllipticCurve curve,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(curve, 'curve');

    throw UnimplementedError('TODO: implement ECDH');
  }

  Future<Uint8List> exportRawKey();

  Future<Uint8List> exportSpkiKey();

  Future<Map<String, dynamic>> exportJsonWebKey();
}

abstract class HkdfSecretKey {
  HkdfSecretKey._(); // keep the constructor private.

  static Future<HkdfSecretKey> importRawKey(List<int> keyData) {
    ArgumentError.checkNotNull(keyData, 'keyData');

    throw UnimplementedError('TODO: implement HKDF');
  }

  Future<Uint8List> deriveBits(
    Hash hash,
    List<int> salt,
    List<int> info,
  );
}

abstract class Pbkdf2SecretKey {
  Pbkdf2SecretKey._(); // keep the constructor private.

  static Future<Pbkdf2SecretKey> importRawKey(List<int> keyData) {
    ArgumentError.checkNotNull(keyData, 'keyData');

    throw UnimplementedError('TODO: implement PBKDF2');
  }

  Future<Uint8List> deriveBits(
    Hash hash,
    List<int> salt,
    int iterations,
  );
}