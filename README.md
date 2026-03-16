# mbelarmino-ldbp
M. Belarmino Least-Data Banking Protocol (LDBP)

**1. Executive Summary**

The Least Data Banking Protocol (LDBP) is a privacy-first API framework designed to replace legacy "screen-scraping" and over-permissioned data sharing. In the current fintech landscape, apps like Stripe or Venmo often gain access to a user’s entire financial history just to verify a single transaction.

LDBP shifts the paradigm from Data Extraction (sharing raw balances and history) to Insight Verification (sharing only the minimum data required for a specific outcome).

**2. Core Architecture**

Unlike traditional banking APIs that return scalar values (e.g., "$1,200.50"), LDBP utilizes a Boolean Handshake. The finance app asks a question ("Is there enough for this $50 purchase?"), and the bank provides a cryptographically signed "Yes/No" response.

**Key Technical Guardrails:**

***Scoped Alias IDs***: No raw account or routing numbers are shared.

***Idempotency-First***: Every transaction is protected against double-spending at the protocol level.

***Velocity Caps***: Built-in rate limiting to prevent "binary search" attacks on user wealth profiling.

**3. System Flow**

This diagram illustrates the "Zero-Knowledge" handshake between the User, the Finance App, and the Bank API.

sequenceDiagram
    autonumber
    participant U as User
    participant A as Finance App (Stripe)
    participant B as Bank API Gateway
    participant C as Bank Core Ledger

    Note over U, B: Phase 1: Scoped Linking
    U->>B: Login & Select ONE Account
    B-->>U: Confirm "Weekly $500 Limit"
    B->>A: Issue Scoped_Account_Token (Alias ID)
    
    Note over A, C: Phase 2: The "Least Data" Transaction
    A->>B: POST /verify (Intent_ID, Amount: $50)
    B->>B: Validate Scoped_Token & Weekly Limit
    B->>C: Check Balance (Internal Only)
    C-->>B: $1,200 (Hidden from App)
    B-->>A: 200 OK: { "is_enough": true }
    
    Note over A, C: Phase 3: Atomic Execution
    A->>B: POST /execute (Intent_ID, X-Idempotency-Key)
    B->>C: Debit $50 (Atomic Transaction)
    C-->>B: Success
    B-->>A: 201 Created (Transfer Complete)
    B->>U: Push Notification: "$50 sent to Stripe"

**4. API Specification & Compliance**

***Technical Spec***: See openapi.yaml for the full endpoint definitions.

***Acceptance Criteria***: See features/api_compliance.feature for the Gherkin-style test suite covering privacy and security edge cases.

**How to use this repository**

This repository serves as a Product Design Dossier. 

It is intended for:
* Engineering Leaders: To review the API contract and data isolation strategy.
* Risk & Compliance Officers: To evaluate the data minimization and fraud mitigation logic.
* Product Leaders: To understand the strategic shift toward privacy-as-a-feature.

**License & Intellectual Property**

© 2026 Mary Ann Belarmino. All rights reserved.

The Least-Data Banking Protocol (LDBP) framework, including its OpenAPI specifications, architectural logic, and documentation, is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0).

***🔑 Usage & Adoption***
I am highly committed to the widespread adoption of LDBP across both commercial and non-commercial sectors. The restrictive elements of this license are intended to preserve the integrity of the standard during its foundational phase.

***Attribution:***
Required. You must give appropriate credit and provide a link to this repository.

***Commercial Use:***
If you are a commercial entity (Bank, Fintech, or Vendor) looking to implement or integrate LDBP, permission is gladly granted upon request. 

***Derivatives:***
To ensure interoperability, I ask that modifications be discussed via the "Proposals" process or through direct contact before distribution.

***Interested in Implementing LDBP?***
I welcome collaboration and am open to granting commercial usage rights and derivative permissions. For formal consent, strategic advisory, or implementation support, please reach out.

**Contact:**
Mary Ann Belarmino
Email: maryann.nazario@gmail.com
LinkedIn: https://www.linkedin.com/in/maryann-belarmino/ 


