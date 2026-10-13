# =============================================================================
# CNK-FarmaStatR — Platform · SHA-256 (FIPS 180-4), yalnızca temel R
#   Denetim izi zincirinin parmak izleri SUNUCU tarafında bu fonksiyonla hesaplanır.
#   32 bitlik sözcükler [0, 2^32) aralığında double olarak tutulur; bit işlemleri
#   16 bitlik yarımlar üzerinden yapılır (bitwAnd/bitwXor 32 bitlik işaretli tamsayı sınırı).
#   Doğrulama: NIST FIPS 180-4 örnek vektörleri ve bağımsız araçla karşılaştırma (sha256_tests.R).
# Sürüm: 0.3.0
# =============================================================================
.S256_K <- c(
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2)
.S256_H0 <- c(0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19)
.S2_32 <- 4294967296

.s_xor <- function(a, b) { ah <- a %/% 65536; al <- a %% 65536; bh <- b %/% 65536; bl <- b %% 65536
  bitwXor(ah, bh) * 65536 + bitwXor(al, bl) }
.s_and <- function(a, b) { ah <- a %/% 65536; al <- a %% 65536; bh <- b %/% 65536; bl <- b %% 65536
  bitwAnd(ah, bh) * 65536 + bitwAnd(al, bl) }
.s_not <- function(a) (.S2_32 - 1) - a
.s_rotr <- function(x, n) (x %/% 2^n) + (x %% 2^n) * 2^(32 - n)
.s_shr <- function(x, n) x %/% 2^n

sha256_raw <- function(x) {
  stopifnot(is.raw(x))
  n <- length(x)
  pad <- c(x, as.raw(0x80), raw((55 - n) %% 64))
  L <- n * 8                                                      # 64 bitlik uzunluk, big-endian
  pad <- c(pad, as.raw(rev(floor(L / 256^(0:7)) %% 256)))
  b <- as.numeric(pad)
  W <- b[c(TRUE, FALSE, FALSE, FALSE)] * 16777216 + b[c(FALSE, TRUE, FALSE, FALSE)] * 65536 +
       b[c(FALSE, FALSE, TRUE, FALSE)] * 256 + b[c(FALSE, FALSE, FALSE, TRUE)]
  H <- .S256_H0
  for (blok in seq_len(length(W) / 16)) {
    w <- numeric(64); w[1:16] <- W[(blok - 1) * 16 + 1:16]
    for (t in 17:64) {
      s0 <- .s_xor(.s_xor(.s_rotr(w[t - 15], 7), .s_rotr(w[t - 15], 18)), .s_shr(w[t - 15], 3))
      s1 <- .s_xor(.s_xor(.s_rotr(w[t - 2], 17), .s_rotr(w[t - 2], 19)), .s_shr(w[t - 2], 10))
      w[t] <- (w[t - 16] + s0 + w[t - 7] + s1) %% .S2_32
    }
    a <- H[1]; bb <- H[2]; c <- H[3]; d <- H[4]; e <- H[5]; f <- H[6]; g <- H[7]; h <- H[8]
    for (t in 1:64) {
      S1 <- .s_xor(.s_xor(.s_rotr(e, 6), .s_rotr(e, 11)), .s_rotr(e, 25))
      ch <- .s_xor(.s_and(e, f), .s_and(.s_not(e), g))
      t1 <- (h + S1 + ch + .S256_K[t] + w[t]) %% .S2_32
      S0 <- .s_xor(.s_xor(.s_rotr(a, 2), .s_rotr(a, 13)), .s_rotr(a, 22))
      maj <- .s_xor(.s_xor(.s_and(a, bb), .s_and(a, c)), .s_and(bb, c))
      t2 <- (S0 + maj) %% .S2_32
      h <- g; g <- f; f <- e; e <- (d + t1) %% .S2_32; d <- c; c <- bb; bb <- a; a <- (t1 + t2) %% .S2_32
    }
    H <- (H + c(a, bb, c, d, e, f, g, h)) %% .S2_32
  }
  paste(sprintf("%08x", as.integer(H - (H >= 2^31) * .S2_32)), collapse = "")
}
sha256_metin <- function(s) sha256_raw(charToRaw(enc2utf8(s)))
