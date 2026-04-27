/**
 * prove.js
 * ========
 * Generates a ZK-SNARK proof for age verification.
 *
 * Usage:
 *   node scripts/prove.js             → uses inputs/input_valid.json
 *   node scripts/prove.js --age 25   → custom age
 *   node scripts/prove.js --age 15   → will FAIL (proof cannot be made)
 */

const snarkjs = require("snarkjs");
const fs = require("fs");
const path = require("path");

// ─── Parse CLI arguments ──────────────────────────────────
const args = process.argv.slice(2);
const ageArgIndex = args.indexOf("--age");

let input;
if (ageArgIndex !== -1 && args[ageArgIndex + 1]) {
  // Custom age from CLI: node scripts/prove.js --age 25
  const age = parseInt(args[ageArgIndex + 1]);
  input = { age, minAge: 18 };
  console.log(`\n🔑 Using custom input: age = ${age}`);
} else {
  // Default: read from inputs/input_valid.json
  const inputFile = path.join(__dirname, "../inputs/input_valid.json");
  input = JSON.parse(fs.readFileSync(inputFile, "utf8"));
  console.log(`\n🔑 Using input from: inputs/input_valid.json`);
  console.log(`   age = ${input.age} (PRIVATE — never leaves your machine)`);
  console.log(`   minAge = ${input.minAge} (PUBLIC — verifier can see this)`);
}

async function generateProof(input) {
  console.log("\n╔══════════════════════════════════════════════╗");
  console.log("║        ZK-SNARK Proof Generation             ║");
  console.log("╚══════════════════════════════════════════════╝\n");

  const wasmPath   = path.join(__dirname, "../build/AgeVerify_js/AgeVerify.wasm");
  const zkeyPath   = path.join(__dirname, "../build/AgeVerify_0001.zkey");
  const proofPath  = path.join(__dirname, "../proofs/proof.json");
  const publicPath = path.join(__dirname, "../proofs/public.json");

  // Check that setup has been run
  if (!fs.existsSync(wasmPath) || !fs.existsSync(zkeyPath)) {
    console.error("❌ Circuit not compiled yet. Please run: npm run setup");
    process.exit(1);
  }

  try {
    console.log("⚙️  Step 1: Generating witness...");
    console.log("   (The witness is the internal computation trace — stays private)");

    // ── WITNESS GENERATION ──────────────────────────────────
    // The witness is the complete assignment of ALL signals in the circuit.
    // It includes your private input (age) and all intermediate values.
    // The witness is NEVER sent to the verifier — only the proof is.
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
      input,    // { age: 20, minAge: 18 }
      wasmPath, // compiled circuit (WASM)
      zkeyPath  // proving key from trusted setup
    );

    console.log("✅ Witness generated successfully\n");

    console.log("⚙️  Step 2: Generating Groth16 proof...");
    console.log("   (This creates 3 elliptic curve points: π_a, π_b, π_c)");

    // Save proof to file
    fs.mkdirSync(path.join(__dirname, "../proofs"), { recursive: true });
    fs.writeFileSync(proofPath, JSON.stringify(proof, null, 2));
    fs.writeFileSync(publicPath, JSON.stringify(publicSignals, null, 2));

    console.log("✅ Proof generated!\n");

    // ── DISPLAY RESULTS ────────────────────────────────────
    console.log("╔══════════════════════════════════════════════╗");
    console.log("║              PROOF DETAILS                   ║");
    console.log("╚══════════════════════════════════════════════╝");
    console.log("\n📋 Public Signals (visible to verifier):");
    console.log("   isAdult =", publicSignals[0], "  (1 = valid, 0 = invalid)");
    console.log("   minAge  =", publicSignals[1]);

    console.log("\n🔐 ZK Proof (cryptographic — reveals NOTHING about age):");
    console.log("   π_a (G1 point):", proof.pi_a[0].substring(0, 20) + "...");
    console.log("   π_b (G2 point):", proof.pi_b[0][0].substring(0, 20) + "...");
    console.log("   π_c (G1 point):", proof.pi_c[0].substring(0, 20) + "...");

    console.log("\n📁 Files saved:");
    console.log("   proofs/proof.json   ← The ZK proof");
    console.log("   proofs/public.json  ← Public inputs/outputs");

    console.log("\n✅ PROOF READY! Run: node scripts/verify.js");
    console.log("═══════════════════════════════════════════════\n");

    return { proof, publicSignals };

  } catch (err) {
    // ── ERROR: Constraint violated ─────────────────────────
    // If age < 18, the circuit's constraint "isAdult === 1" fails,
    // and snarkjs throws an error. This is the ZK magic:
    // you CANNOT generate a valid proof for invalid data!
    console.error("\n╔══════════════════════════════════════════════╗");
    console.error("║           PROOF GENERATION FAILED            ║");
    console.error("╚══════════════════════════════════════════════╝");
    console.error(`\n❌ Cannot generate proof for age = ${input.age}`);
    console.error(`   Reason: Age is less than ${input.minAge}`);
    console.error("\n   This is ZK working correctly!");
    console.error("   The math PREVENTS generating a valid proof");
    console.error("   for invalid inputs. No cheating possible.\n");
    process.exit(1);
  }
}

generateProof(input);