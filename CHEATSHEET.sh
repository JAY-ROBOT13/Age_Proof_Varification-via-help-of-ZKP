#!/usr/bin/env bash
# =============================================================
# CHEATSHEET.sh — All commands in one place
# This file shows EVERY command you need, in order.
# DO NOT run this file directly. Copy-paste the commands.
# =============================================================

# ──────────────────────────────────────────────────────────────
# SECTION 1: INSTALL DEPENDENCIES (do this once)
# ──────────────────────────────────────────────────────────────

## Install Node.js 20 (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

## Install Node.js (macOS)
brew install node

## Install Rust (needed for Circom compiler)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

## Install Circom 2.0 (compile from source)
git clone https://github.com/iden3/circom.git
cd circom && cargo build --release && cargo install --path circom && cd ..

## Install SnarkJS globally
npm install -g snarkjs

## Verify all installs
node --version       # v18+ or v20+
circom --version     # circom compiler 2.x.x
snarkjs --version    # 0.7.x

# ──────────────────────────────────────────────────────────────
# SECTION 2: PROJECT SETUP (from project root)
# ──────────────────────────────────────────────────────────────

## Install npm dependencies (circomlib + snarkjs)
npm install

## Run the full setup script (compiles circuit + trusted setup)
bash scripts/setup.sh

## OR run each step manually:

# 2a. Compile circuit
circom circuits/AgeVerify.circom --r1cs --wasm --sym --output build/

# 2b. Inspect circuit
snarkjs r1cs info build/AgeVerify.r1cs
snarkjs r1cs print build/AgeVerify.r1cs build/AgeVerify.sym

# 2c. Powers of Tau Phase 1
snarkjs powersoftau new bn128 12 build/pot12_0000.ptau -v
snarkjs powersoftau contribute build/pot12_0000.ptau build/pot12_0001.ptau \
  --name="First" -v -e="$(openssl rand -hex 32)"

# 2d. Phase 2
snarkjs powersoftau prepare phase2 build/pot12_0001.ptau build/pot12_final.ptau -v
snarkjs groth16 setup build/AgeVerify.r1cs build/pot12_final.ptau build/AgeVerify_0000.zkey
snarkjs zkey contribute build/AgeVerify_0000.zkey build/AgeVerify_0001.zkey \
  --name="Circuit" -v -e="$(openssl rand -hex 32)"

# 2e. Export keys
snarkjs zkey export verificationkey build/AgeVerify_0001.zkey build/verification_key.json
snarkjs zkey export solidityverifier build/AgeVerify_0001.zkey contracts/AgeVerifier.sol

# ──────────────────────────────────────────────────────────────
# SECTION 3: GENERATE WITNESS MANUALLY (optional)
# ──────────────────────────────────────────────────────────────

## Generate witness using Node.js (the normal way):
node build/AgeVerify_js/generate_witness.js \
  build/AgeVerify_js/AgeVerify.wasm \
  inputs/input_valid.json \
  build/witness.wtns

## Inspect witness
snarkjs wtns check build/AgeVerify.r1cs build/witness.wtns

# ──────────────────────────────────────────────────────────────
# SECTION 4: GENERATE PROOF
# ──────────────────────────────────────────────────────────────

## Method A: Using our script (recommended)
node scripts/prove.js                 # uses inputs/input_valid.json
node scripts/prove.js --age 25        # custom age
node scripts/prove.js --age 15        # will FAIL (expected)

## Method B: Using snarkjs CLI directly
# First generate witness manually (see section 3), then:
snarkjs groth16 prove \
  build/AgeVerify_0001.zkey \
  build/witness.wtns \
  proofs/proof.json \
  proofs/public.json

# ──────────────────────────────────────────────────────────────
# SECTION 5: VERIFY PROOF
# ──────────────────────────────────────────────────────────────

## Method A: Using our script
node scripts/verify.js

## Method B: Using snarkjs CLI directly
snarkjs groth16 verify \
  build/verification_key.json \
  proofs/public.json \
  proofs/proof.json

# Expected output: OK  (or INVALID if proof is bad)

# ──────────────────────────────────────────────────────────────
# SECTION 6: FULL DEMO
# ──────────────────────────────────────────────────────────────

## Run everything at once (shows valid + invalid cases)
node scripts/demo.js

# ──────────────────────────────────────────────────────────────
# SECTION 7: FRONTEND
# ──────────────────────────────────────────────────────────────

## Open in browser (no server needed)
open frontend/index.html           # macOS
xdg-open frontend/index.html       # Linux

## Or use a local dev server
npx serve frontend/
npx http-server frontend/ -p 8080

# ──────────────────────────────────────────────────────────────
# SECTION 8: BLOCKCHAIN (optional)
# ──────────────────────────────────────────────────────────────

## Generate Solidity calldata from proof
snarkjs generatecall

## Output (paste directly into Remix IDE or Hardhat test):
## ["0x123...", "0x456..."],           ← pA
## [["0xabc...", "0xdef..."],          ← pB
##  ["0xghi...", "0xjkl..."]],
## ["0xmno...", "0xpqr..."],           ← pC
## ["0x1", "0x12"]                     ← pubSignals [isAdult, minAge]

## Install Hardhat (for blockchain deployment)
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npx hardhat init

## Deploy contracts
npx hardhat run scripts/deploy.js --network sepolia

# ──────────────────────────────────────────────────────────────
# SECTION 9: DEBUGGING TIPS
# ──────────────────────────────────────────────────────────────

## If circom not found:
export PATH="$HOME/.cargo/bin:$PATH"

## If snarkjs not found globally:
export PATH="$(npm root -g)/../bin:$PATH"

## Check what's in build/ folder:
ls -la build/

## Check proof contents:
cat proofs/proof.json | python3 -m json.tool
cat proofs/public.json

## Rerun setup from scratch:
rm -rf build/ proofs/
bash scripts/setup.sh