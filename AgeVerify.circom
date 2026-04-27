pragma circom 2.0.0;

// ============================================================
// AgeVerify Circuit
// Purpose: Prove age >= 18 WITHOUT revealing the actual age
// ============================================================

// Include the standard library for comparison components
include "node_modules/circomlib/circuits/comparators.circom";

// The main template — think of this like a "function" in ZK world
template AgeVerify() {

    // ── INPUTS ──────────────────────────────────────────────
    // `private` means this value is kept SECRET from the verifier
    // The prover (user) knows their age, but it never leaves their machine
    signal private input age;

    // `public` means this IS visible to the verifier (blockchain, website, etc.)
    // We choose to expose the minimum age threshold so the verifier knows
    // what rule is being checked.
    signal input minAge;   // will be set to 18

    // ── OUTPUTS ─────────────────────────────────────────────
    // 1 = age is valid (>= 18), 0 = age is NOT valid
    signal output isAdult;

    // ── COMPONENTS ──────────────────────────────────────────
    // GreaterEqThan(n) checks: is A >= B?
    // The number inside (8) = number of bits used to represent the values.
    // 8 bits → values from 0 to 255, which is enough for age (0-150).
    // Using more bits = bigger proof, using fewer = risk of overflow.
    component ageCheck = GreaterEqThan(8);

    // ── CONSTRAINTS (the heart of the ZK circuit) ───────────
    // Wire the inputs to our comparison component
    // ageCheck.in[0] is the LEFT side:  age
    // ageCheck.in[1] is the RIGHT side: minAge (18)
    // So this checks: age >= minAge
    ageCheck.in[0] <== age;
    ageCheck.in[1] <== minAge;

    // Wire the comparison result to our output signal
    // ageCheck.out = 1 if age >= minAge, else 0
    isAdult <== ageCheck.out;

    // ── FINAL CONSTRAINT ────────────────────────────────────
    // THIS IS THE CRITICAL LINE:
    // We FORCE the proof to only be valid when isAdult == 1
    // If someone tries to prove with age=15, isAdult would be 0,
    // and 0 === 1 is FALSE → the proof generation FAILS → they cannot cheat!
    isAdult === 1;
}

// Instantiate the template as the main component
// This is what gets compiled into the actual ZK circuit
component main {public [minAge]} = AgeVerify();
