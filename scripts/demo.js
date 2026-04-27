/**
 * demo.js
 * =======
 * Full end-to-end demo showing:
 *   1. Age 20 → proof generated → verified ✅
 *   2. Age 15 → proof CANNOT be generated ❌
 *
 * Run: node scripts/demo.js
 */

const snarkjs = require("snarkjs");
const fs = require("fs");
const path = require("path");

const WASM_PATH  = path.join(__dirname, "../build/AgeVerify_js/AgeVerify.wasm");
const ZKEY_PATH  = path.join(__dirname, "../build/AgeVerify_0001.zkey");
const VKEY_PATH  = path.join(__dirname, "../build/verification_key.json");

function banner(text) {
  const line = "═".repeat(54);
  console.log(`\n╔${line}╗`);
  console.log(`║  ${text.padEnd(52)}║`);
  console.log(`╚${line}╝`);
}

function separator() {
  console.log("─".repeat(56));
}

async function tryProveAndVerify(age, minAge = 18) {
  const label = `Testing age = ${age} (minimum required: ${minAge})`;
  banner(label);

  try {
    // ── 1. Generate witness + proof ───────────────────────
    console.log(`\n⚙️  Attempting to generate proof for age = ${age}...`);
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
      { age, minAge },
      WASM_PATH,
      ZKEY_PATH
    );
    console.log(`✅ Proof generated!`);
    console.log(`   Public output: isAdult = ${publicSignals[0]}`);

    // ── 2. Verify the proof ──────────────────────────────
    console.log(`\n⚙️  Verifying proof...`);
    const vKey = JSON.parse(fs.readFileSync(VKEY_PATH, "utf8"));
    const isValid = await snarkjs.groth16.verify(vKey, publicSignals, proof);

    if (isValid) {
      console.log(`\n✅ RESULT: VERIFIED — Age ${age} ≥ ${minAge}`);
      console.log(`   The person is an adult. Access GRANTED.`);
      console.log(`   Actual age remains: SECRET 🔒`);
    } else {
      console.log(`\n❌ RESULT: VERIFICATION FAILED for age ${age}`);
    }

    return { success: true, isValid };

  } catch (err) {
    // Proof generation failed — this is EXPECTED for invalid ages
    console.log(`\n❌ RESULT: Cannot prove age ${age} ≥ ${minAge}`);
    console.log(`   Proof generation failed at the circuit level.`);
    console.log(`   The math REFUSES to produce a valid proof.`);
    console.log(`   Access DENIED. No cheating possible. 🛡️`);
    return { success: false, isValid: false };
  }
}

async function main() {
  console.log("\n");
  banner("ZK-SNARK Age Verification — Full Demo");

  // Sanity check
  if (!fs.existsSync(WASM_PATH) || !fs.existsSync(ZKEY_PATH)) {
    console.error("\n❌ Please run setup first: npm run setup");
    process.exit(1);
  }

  console.log(`
📚 What this demo shows:
   • A person can PROVE they are 18+ without revealing their age
   • An underage person CANNOT forge a valid proof
   • The verifier learns ONLY: "age ≥ 18" — nothing more
  `);

  separator();

  // ── CASE 1: Valid age (20) ────────────────────────────
  const result1 = await tryProveAndVerify(20, 18);

  separator();

  // ── CASE 2: Invalid age (15) ──────────────────────────
  const result2 = await tryProveAndVerify(15, 18);

  separator();

  // ── CASE 3: Edge case — exactly 18 ───────────────────
  const result3 = await tryProveAndVerify(18, 18);

  separator();

  // ── SUMMARY ──────────────────────────────────────────
  banner("Demo Summary");
  console.log(`
  Age 20  → Proof valid:   ${result1.isValid ? "✅ YES" : "❌ NO"}
  Age 15  → Proof valid:   ${result2.isValid ? "✅ YES" : "❌ NO (expected)"}
  Age 18  → Proof valid:   ${result3.isValid ? "✅ YES" : "❌ NO"}

  Key takeaways:
  • The circuit enforces "age >= 18" mathematically
  • Invalid proofs CANNOT be generated — impossible to cheat
  • The verifier NEVER learns the actual age values
  • This is the power of Zero-Knowledge Proofs! 🔮
  `);
}

main().catch(console.error);