#!/usr/bin/env bash
# =============================================================
# setup.sh — Full ZK-SNARK Setup Pipeline
# Run this ONCE to compile the circuit and generate trusted setup
# =============================================================

set -e  # Exit immediately if any command fails
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ZK-SNARK Age Verification — Setup Pipeline         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# ─── STEP 1: Install npm dependencies ──────────────────────
echo -e "${YELLOW}[Step 1/7] Installing npm dependencies...${NC}"
npm install
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# ─── STEP 2: Compile the Circom circuit ────────────────────
# This converts AgeVerify.circom into:
#   - AgeVerify.r1cs  → the rank-1 constraint system (math representation)
#   - AgeVerify.wasm  → WebAssembly for witness generation in browser
#   - AgeVerify_js/   → JS helper files
echo -e "${YELLOW}[Step 2/7] Compiling Circom circuit...${NC}"
echo -e "  → Input:  circuits/AgeVerify.circom"
echo -e "  → Output: build/ (r1cs + wasm + js)"

circom circuits/AgeVerify.circom \
  --r1cs \
  --wasm \
  --sym \
  --output build/

echo -e "${GREEN}✓ Circuit compiled${NC}"
echo ""

# ─── STEP 3: View circuit info (optional but educational) ──
echo -e "${YELLOW}[Step 3/7] Circuit statistics:${NC}"
snarkjs r1cs info build/AgeVerify.r1cs
echo ""

# ─── STEP 4: Powers of Tau (Phase 1 Trusted Setup) ─────────
# This generates cryptographic randomness (called "toxic waste").
# In production, this is done by many parties (Multi-Party Computation).
# For testing, we do it ourselves with pot12_0000.ptau
# "pot12" = "powers of tau with 2^12 = 4096 max constraints"
# Our circuit has only ~50 constraints, so pot12 is more than enough.
echo -e "${YELLOW}[Step 4/7] Phase 1: Powers of Tau ceremony...${NC}"
echo -e "  → Generating initial powers of tau..."

snarkjs powersoftau new bn128 12 build/pot12_0000.ptau -v 2>&1 | tail -3

echo -e "  → Contributing randomness (Phase 1 contribution)..."
snarkjs powersoftau contribute build/pot12_0000.ptau build/pot12_0001.ptau \
  --name="First Contribution" -v -e="random entropy for age verification" 2>&1 | tail -3

echo -e "${GREEN}✓ Powers of Tau complete${NC}"
echo ""

# ─── STEP 5: Phase 2 (Circuit-Specific Trusted Setup) ──────
# Phase 2 is specific to YOUR circuit. It takes the generic
# powers of tau and "tailors" them to AgeVerify's constraints.
echo -e "${YELLOW}[Step 5/7] Phase 2: Circuit-specific setup...${NC}"
echo -e "  → Preparing phase 2..."

snarkjs powersoftau prepare phase2 build/pot12_0001.ptau build/pot12_final.ptau -v 2>&1 | tail -3

echo -e "  → Running Groth16 setup for AgeVerify circuit..."
snarkjs groth16 setup build/AgeVerify.r1cs build/pot12_final.ptau build/AgeVerify_0000.zkey

echo -e "  → Contributing to phase 2..."
snarkjs zkey contribute build/AgeVerify_0000.zkey build/AgeVerify_0001.zkey \
  --name="Age Verify Contribution" -v -e="more entropy for circuit" 2>&1 | tail -3

echo -e "  → Exporting final proving key..."
snarkjs zkey export verificationkey build/AgeVerify_0001.zkey build/verification_key.json

echo -e "${GREEN}✓ Trusted setup complete${NC}"
echo ""

# ─── STEP 6: Export Solidity verifier (bonus!) ─────────────
echo -e "${YELLOW}[Step 6/7] Generating Solidity smart contract verifier...${NC}"
snarkjs zkey export solidityverifier build/AgeVerify_0001.zkey contracts/AgeVerifier.sol
echo -e "${GREEN}✓ Solidity verifier exported to contracts/AgeVerifier.sol${NC}"
echo ""

# ─── STEP 7: Summary ───────────────────────────────────────
echo -e "${YELLOW}[Step 7/7] Setup complete! Files generated:${NC}"
echo ""
echo -e "  build/"
echo -e "  ├── AgeVerify.r1cs          ← Constraint system"
echo -e "  ├── AgeVerify.wasm          ← Witness generator (WASM)"
echo -e "  ├── AgeVerify_js/           ← JS witness helper"
echo -e "  ├── AgeVerify.sym           ← Symbols (signal names)"
echo -e "  ├── pot12_final.ptau        ← Powers of Tau"
echo -e "  ├── AgeVerify_0001.zkey     ← Proving key"
echo -e "  └── verification_key.json  ← Verification key (public)"
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Setup done! Now run:${NC}"
echo -e "   npm run demo              ← Run full demo"
echo -e "   node scripts/prove.js     ← Generate a proof"
echo -e "   node scripts/verify.js    ← Verify a proof"
echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"