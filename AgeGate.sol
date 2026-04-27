// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ================================================================
// AgeGate.sol
// ================================================================
// This contract uses the auto-generated ZK verifier to gate access
// to age-restricted content on the Ethereum blockchain.
//
// How it works:
//   1. User generates a ZK proof off-chain (using snarkjs)
//   2. User calls verifyAge() with the proof + public signals
//   3. Contract verifies the proof on-chain (no age revealed!)
//   4. If valid, user is marked as "age verified"
//
// Deploy on: Sepolia testnet / Hardhat local node
// ================================================================

interface IGroth16Verifier {
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[2] calldata _pubSignals
    ) external view returns (bool);
}

contract AgeGate {
    // ── State ──────────────────────────────────────────────────
    IGroth16Verifier public immutable verifier;

    // Track which addresses have proven their age
    // address → verified or not
    mapping(address => bool) public isVerified;

    // ── Events ─────────────────────────────────────────────────
    event AgeVerified(address indexed user);
    event VerificationFailed(address indexed user);

    // ── Constructor ────────────────────────────────────────────
    // Pass the address of the deployed AgeVerifier.sol contract
    constructor(address _verifierAddress) {
        verifier = IGroth16Verifier(_verifierAddress);
    }

    // ── Core verification function ─────────────────────────────
    /**
     * @notice Verify a ZK proof that age >= 18
     * @param pA  First proof point (π_a) — from proof.json
     * @param pB  Second proof point (π_b) — from proof.json
     * @param pC  Third proof point (π_c) — from proof.json
     * @param pubSignals Public signals: [isAdult, minAge]
     *
     * How to get these values:
     *   1. Run: node scripts/prove.js --age YOUR_AGE
     *   2. Open proofs/proof.json and proofs/public.json
     *   3. Convert the hex strings to uint256 and pass here
     *
     * Or use snarkjs to get calldata directly:
     *   snarkjs generatecall
     */
    function verifyAge(
        uint[2] calldata pA,
        uint[2][2] calldata pB,
        uint[2] calldata pC,
        uint[2] calldata pubSignals
    ) external {
        // pubSignals[0] = isAdult (must be 1)
        // pubSignals[1] = minAge  (must be 18)

        // Sanity check: ensure the public signal says minAge is 18
        require(pubSignals[1] == 18, "AgeGate: minAge must be 18");

        // Verify the ZK proof using the deployed verifier contract
        bool valid = verifier.verifyProof(pA, pB, pC, pubSignals);

        if (valid) {
            isVerified[msg.sender] = true;
            emit AgeVerified(msg.sender);
        } else {
            emit VerificationFailed(msg.sender);
            revert("AgeGate: invalid ZK proof");
        }
    }

    // ── Access gate example ────────────────────────────────────
    /**
     * @notice Example of an age-gated function
     * Only callable by addresses that have proven age >= 18
     */
    function accessRestrictedContent() external view returns (string memory) {
        require(isVerified[msg.sender], "AgeGate: age not verified");
        return "Welcome! You have access to age-restricted content.";
    }

    // ── Helper: Check verification status ─────────────────────
    function checkVerified(address user) external view returns (bool) {
        return isVerified[user];
    }
}
