# Least Data Banking Protocol (LDBP)

**A Privacy-by-Design API Framework for Intent-Based Banking**

> *Replacing "All-Access" data extraction with Boolean verification — the "is_enough" check.*

**Author:** Mary Ann Belarmino — [BelarminoAdvisory.com](https://belarminoadvisory.com)  
**Version:** 1.0 — April 2026  
**License:** [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — Attribution required on all uses and implementations  
**Status:** Active — Open for implementation feedback and technical contributions

---

## The Problem

Every time a user links a bank account to a payment app — Stripe, Venmo, Starbucks, Klarna — they unknowingly hand that app 24/7 access to their entire financial life: all accounts, 24 months of transaction history, exact balances, and spending patterns. This is not a bug. It is the designed behavior of every major financial aggregator operating today.

To verify a single $50 transaction, the app receives everything.

## The Solution

The Least Data Banking Protocol (LDBP) shifts the paradigm from **Data Extraction** to **Insight Verification**.

Instead of returning a raw balance of $1,402.21, the bank's Policy Enforcement Point (PEP) returns a single Boolean: *does this account hold sufficient funds for this specific transaction?* Nothing else leaves the bank.

The Finance App asks: *"Is there enough for this $50 purchase?"*  
The bank answers: *"Yes"* or *"No."*

That is the entire data transfer. No balance. No history. No profile.

---

## The Five Least-Data Principles

Every LDBP-conformant implementation must satisfy these five architectural invariants. Violation of any one is **Principle Drift** — the implementation is not LDBP.

| Principle | Statement |
|---|---|
| **P1 — Data Minimization** | A Finance App must receive only what is necessary to complete the transaction and nothing more. |
| **P2 — Purpose Limitation** | Verification results must not be used for profiling, upselling, credit scoring, or any secondary purpose. |
| **P3 — Account Isolation** | A Finance App must be scoped to exactly one user-selected account. Access to any other account is architecturally impossible, not merely prohibited by policy. |
| **P4 — Notification Sovereignty** | When a verification is blocked, the bank notifies the user directly. The Finance App receives only False — with no reason code. |
| **P5 — User Control** | The user must be able to revoke a Finance App's access instantly, unilaterally, and without contacting the Finance App. |

---

## System Flow

The following diagram illustrates the LDBP transaction flow under the final protocol architecture. Note: there is no separate verify→execute step. `POST /transfer/charge` atomically re-verifies and executes in a single locked PEP operation — eliminating the race condition gap entirely.

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant A as Finance App (e.g. Stripe)
    participant B as Bank API Gateway / PEP
    participant C as Bank Core Ledger

    Note over U, B: Phase 1 — Scoped Token Issuance
    U->>B: Authenticate & select ONE account (Checking)
    B-->>U: Account selector confirmed
    B->>A: Issue ScopedAccountToken (Alias ID — never raw DDA)

    Note over A, B: Phase 2 — Informational Verification (Optional)
    A->>B: POST /balance/verify (Intent_ID, Amount: $50)
    B->>B: PEP: atomically checks balance + fraud (internal only)
    B-->>A: 200 OK { "is_enough": true } — Boolean only, no balance returned

    Note over A, C: Phase 3 — Atomic Verify + Execute
    A->>B: POST /transfer/charge (Intent_ID, X-Idempotency-Key)
    B->>B: PEP: atomically re-verifies balance + fraud + deducts funds
    B->>C: Single locked operation — no gap between check and debit
    C-->>B: Confirmed
    B-->>A: 201 Created { "is_enough": true, "transfer_id": "..." }
    B->>U: verification.blocked webhook (only on fraud/rate/revocation — never to app)
    B->>U: Real-time Consent Receipt: "$50 authorized to Stripe"
```

**Key design points visible in the flow:**
- The Finance App receives only a Boolean — never a raw balance
- `POST /transfer/charge` re-verifies atomically at execution time — the Phase 2 verify result is informational only
- All notifications go bank → user directly — never bank → app → user
- The raw DDA account number never leaves the bank at any point

---

## API Surface

Full specification: [`ldbp_api_v1.yaml`](./ldbp_api_v1.yaml) — OpenAPI 3.0, validated

| Endpoint | Phase | Purpose |
|---|---|---|
| `POST /auth/token/exchange` | 1 | Issues ScopedAccountToken — user selects one account, bank issues Alias ID (never raw DDA) |
| `POST /auth/token/revoke` | 1 | Kill Switch — instantly terminates Finance App access |
| `POST /balance/verify` | 1 | The "is_enough" check — composite atomic Boolean: balance + fraud in one PEP operation |
| `POST /transfer/charge` | 1 | The only fund movement path — atomic verify + execute, no separate execute step |
| `GET /governance/permission-budget` | 2 | Returns remaining Virtual Allowance — threshold only, no balance returned |
| `POST /batch/balance/verify` | 2 | Batch informational verify — no funds moved, per-intent Boolean results |
| `POST /batch/transfer/charge` | 2 | Batch atomic verify + execute — partial success valid, HTTP 207 |
| `GET /billing/metering` | 2 | Real-time fee attribution for bank basis-point royalties |
| `POST /webhooks/verification.blocked` | 2 | Bank-to-user fraud block notification — never forwarded to Finance App |

**Phase 1** (required for LDBP conformance): `/auth/token/exchange`, `/auth/token/revoke`, `/balance/verify`, `/transfer/charge`  
**Phase 2** (optional governance and batch extensions): all remaining endpoints

---

## Dossier Contents

This repository is a complete Product Design Dossier. All artifacts are mutually consistent as of April 2026.

| File | What It Is | Primary Audience |
|---|---|---|
| [`LDBP_Whitepaper_v1.docx`](./docs/LDBP_Whitepaper_v1.docx) | Foundational concept document — the problem, the principles, the rationale | Executives, regulators, product leaders, journalists |
| [`ldbp_api_v1.yaml`](./ldbp_api_v1.yaml) | OpenAPI 3.0 specification — all endpoints, schemas, behavioral contracts | Bank architects, Finance App developers |
| [`LDBP_PRD_v1.docx`](./docs/LDBP_PRD_v1.docx) | Product Requirements Document — functional requirements, use cases, architecture, regulatory mapping | Engineering teams, product managers, compliance officers |
| [`LDBP_CONFORMANCE.md`](./LDBP_CONFORMANCE.md) | Conformance Definition — what counts as LDBP, Principle Drift taxonomy, required attribution statement | Implementing institutions, legal and compliance teams, auditors |
| [`LDBP_Conformance_v1.docx`](./docs/LDBP_Conformance_v1.docx) | Formal distribution version of the Conformance Definition | Regulatory submissions, vendor contracts |
| [`LDBP_READER_GUIDE.md`](./LDBP_READER_GUIDE.md) | Navigation guide — what each artifact is and who should read it | All readers new to the dossier |

**Not sure where to start?** Read the [`LDBP_READER_GUIDE.md`](./LDBP_READER_GUIDE.md).

---

## Conformance

Any implementation claiming LDBP conformance must satisfy every requirement in the [LDBP Conformance Definition v1.0](./LDBP_CONFORMANCE.md).

Any modification that violates the five Least-Data Principles constitutes **Principle Drift** and may not be represented as LDBP, regardless of naming, marketing, or partial compliance.

When claiming conformance, the implementing institution must include the following attribution in all relevant documentation, API specifications, developer portals, and regulatory filings:

> *"This implementation conforms to the Least Data Banking Protocol (LDBP) as defined by Mary Ann Belarmino (BelarminoAdvisory.com). LDBP Conformance Definition v1.0. Licensed under CC BY 4.0."*

---

## Intended Audiences

**Bank API Architects and Engineering Teams**
Review the OpenAPI spec and PRD for implementation requirements. Phase 1 is achievable in 6–9 months without core ledger replacement. The Translation and Governance Layer sits on top of your existing core (FIS, Fiserv, Jack Henry).

**Finance App Developers**
Review the API spec for integration contracts. LDBP reduces your data liability, eliminates NSF race conditions, and removes the compliance surface area that comes with holding raw user financial data.

**Risk and Compliance Officers**
Review the PRD's Regulatory Compliance Mapping section for CFPB Section 1033, GDPR Purpose Limitation, PSD3, FiDA, and Regulation E alignment. Review the Conformance Definition for enforcement criteria.

**Regulators and Policy Makers**
Review the Whitepaper for the protocol's alignment with data minimization mandates. LDBP transforms "reasonably necessary" from a legal assertion into a technical guarantee — making over-collection architecturally impossible, not just contractually prohibited.

**AI and Agentic System Developers**
LDBP's scoped proof model is the correct authorization primitive for autonomous financial agents. Each intent is bounded by its declared purpose — a compromised sub-agent cannot accumulate account state beyond its scoped proof. Review the Whitepaper's Agentic Governance section and the batch endpoints in the API spec.

---

## Regulatory Alignment

| Regulation | How LDBP Addresses It |
|---|---|
| CFPB Section 1033 | Transforms "reasonably necessary" data collection from legal assertion to technical guarantee via Boolean-only responses |
| GDPR — Purpose Limitation | Finance App never possesses raw data — cannot use for secondary purposes by design |
| PSD3 / PSR (EU) | Provides the dedicated secure API PSD3 mandates, with Boolean verification exceeding PSD3's current raw-balance standard |
| FiDA (EU, 2026) | Kill Switch portal directly implements FiDA's consent dashboard and one-click revocation requirements |
| Regulation E (US) | Real-time Consent Receipts on every transfer; verification.blocked webhooks on blocked events |

---

## Contributing

Implementation feedback, technical proposals, and use case contributions are welcomed.

- **Amendment proposals:** Open an issue with the label `amendment-proposal`. Note: proposals that weaken any of the five Least-Data Principles will not be accepted. See the [Conformance Definition](./LDBP_CONFORMANCE.md) for the permanent constraint clause.
- **Implementation reports:** Open an issue with the label `implementation-report` to share how your institution has adopted LDBP.
- **Bug reports in the spec:** Open an issue with the label `spec-bug`.

---

## Citation

If you use, implement, or reference LDBP in your work, please cite:

```
Mary Ann Belarmino. "Least Data Banking Protocol (LDBP)." 
BelarminoAdvisory.com, April 2026.
https://github.com/maryannb/least-data-banking-protocol
```

---

## License and Attribution

© 2026 Mary Ann Belarmino. [BelarminoAdvisory.com](https://belarminoadvisory.com)

Licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

You are free to use, implement, adapt, and build upon this work for any purpose — including commercial — provided that **attribution to Mary Ann Belarmino and BelarminoAdvisory.com is clearly stated** in all derivative works, implementations, and references.

For commercial licensing inquiries, implementation partnerships, or regulatory advisory: [BelarminoAdvisory.com](https://belarminoadvisory.com)  
LinkedIn: [linkedin.com/in/maryann-belarmino](https://www.linkedin.com/in/maryann-belarmino/)
