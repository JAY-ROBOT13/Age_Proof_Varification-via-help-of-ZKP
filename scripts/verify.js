/**
 * verify.js
 * =========
 * Verifies a ZK-SNARK proof WITHOUT knowing the private input (age).
 *
 * This simulates what a VERIFIER (e.g., a website or blockchain) does.
 * They receive:
 *   - The proof (3 elliptic curve points)
 *   - The public signals (isAdult=1, minAge=18)
 *   - The verification key (public, from trusted setup)
 *
 * They do NOT need and do NOT receive: the actual age!
 *
 * Usage: node scripts/verify.js
 */

const snarkjs = require("snarkjs");
const fs = require("fs");
const path = require("path");

async function verifyProof() {
  console.log("\n╔══════════════════════════════════════════════╗");
  console.log("║        ZK-SNARK Proof Verification           ║");
  console.log("╚══════════════════════════════════════════════╝\n");

  const vKeyPath   = path.join(__dirname, "../build/verification_key.json");
  const proofPath  = path.join(__dirname, "../proofs/proof.json");
  const publicPath = path.join(__dirname, "../proofs/public.json");

  // ── Check files exist ──────────────────────────────────
  if (!fs.existsSync(vKeyPath)) {
    console.error("❌ Verification key not found. Run: npm run setup");
    process.exit(1);
  }
  if (!fs.existsSync(proofPath)) {
    console.error("❌ Proof not found. Run: node scripts/prove.js");
    process.exit(1);
  }

  // ── Load files ────────────────────────────────────────
  const vKey         = JSON.parse(fs.readFileSync(vKeyPath, "utf8"));
  const proof        = JSON.parse(fs.readFileSync(proofPath, "utf8"));
  const publicSignals = JSON.parse(fs.readFileSync(publicPath, "utf8"));

  console.log("📋 What the verifier sees:");
  console.log("   ✓ Verification key (public, from trusted setup)");
  console.log("   ✓ Proof (3 elliptic curve points)");
  console.log("   ✓ Public signal: isAdult =", publicSignals[0]);
  console.log("   ✓ Public signal: minAge  =", publicSignals[1]);
  console.log("   ✗ Private input: age     = ??? (HIDDEN — verifier never sees this)");

  console.log("\n⚙️  Running Groth16 verification algorithm...");
  console.log("   (This does pairing-based cryptography on elliptic curves)");

  // ── THE ACTUAL VERIFICATION ───────────────────────────
  // snarkjs performs the Groth16 verification equation:
  //   e(π_a, π_b) = e(α, β) · e(∑ aᵢ·γᵢ, γ) · e(π_c, δ)
  // If this equation holds → proof is valid
  // This verification takes ~milliseconds, proving takes ~seconds
  const isValid = await snarkjs.groth16.verify(vKey, publicSignals, proof);

  console.log("\n╔══════════════════════════════════════════════╗");
  if (isValid) {
    console.log("║  ✅  VERIFICATION RESULT: PROOF IS VALID     ║");
    console.log("╚══════════════════════════════════════════════╝");
    console.log("\n🎉 The person has PROVEN they are 18 or older!");
    console.log("   WITHOUT revealing their actual age.");
    console.log("\n   What the verifier now knows:");
    console.log("   → The person's age ≥ 18 ✅");
    console.log("   → The actual age:   UNKNOWN ✅ (preserved privacy)");
  } else {
    console.log("║  ❌  VERIFICATION RESULT: PROOF IS INVALID   ║");
    console.log("╚══════════════════════════════════════════════╝");
    console.log("\n🚫 The proof failed verification.");
    console.log("   The person could NOT prove they are 18 or older.");
    console.log("   Access should be DENIED.");
  }

  console.log("\n═══════════════════════════════════════════════\n");
  return isValid;
}

verifyProof();