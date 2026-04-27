# 🔐 Age Verification using Zero-Knowledge Proof (ZKP)

## 📌 Overview
This project implements a privacy-preserving age verification system using Zero-Knowledge Proofs (ZKP). It allows users to prove that they are above a required age (e.g., 18+) without revealing their actual date of birth or any personal identity information.

---

## ❗ Problem Statement
Traditional age verification systems require users to share sensitive personal data such as date of birth or ID proofs. This creates risks like:
- Data breaches  
- Identity theft  
- Privacy loss  

---

## 💡 Solution
This project uses Zero-Knowledge Proofs to verify age without exposing any confidential data. The system only proves whether the condition (age ≥ required limit) is true or false.

---

## ⚙️ How It Works
1. User enters their date of birth (kept private)  
2. System calculates age securely  
3. ZKP proof is generated for condition (age ≥ 18)  
4. Proof is sent to verifier  
5. Verifier validates proof without seeing actual data  
6. Access is granted or denied  

---

## 🛠️ Tech Stack
- ZKP Framework: Circom, SnarkJS  
- Programming: JavaScript / Python  
- Cryptography: Hash functions, constraint systems  
- (Optional) Blockchain integration  

---

## 📁 Project Structure
