# LDBP Conformance Definition
## Least Data Banking Protocol — Principle Compliance Standard

**Version:** 1.0  
**Author:** Mary Ann Belarmino — BelarminoAdvisory.com  
**License:** CC BY 4.0 — Attribution required on all uses and implementations  
**Status:** Active  
**Last Updated:** April 2026

---

## Purpose

This document defines what it means to be **LDBP-Conformant**. Any implementation, derivative work, API specification, product, or service that claims conformance with the Least Data Banking Protocol (LDBP) must satisfy every requirement in this document.

Any implementation that does not satisfy every requirement in this document is **not LDBP-conformant**, regardless of naming, marketing, or partial compliance. Partial compliance that violates one or more of the Least-Data Principles defined here constitutes **Principle Drift** and may not be represented as LDBP.

This document is the authoritative conformance reference. In the event of any conflict between this document and any other LDBP artifact (whitepaper, API spec, PRD), this document governs.

---

## The Least-Data Principles

LDBP is founded on five Least-Data Principles. These are not implementation guidelines — they are architectural invariants. An implementation that violates any one of them is not LDBP, regardless of how many other requirements it satisfies.

### Principle 1 — Data Minimization
> *A Finance App must receive only what is necessary to complete the transaction and nothing more.*

The minimum necessary data for a payment transaction is a Boolean: does the account hold sufficient funds for this specific amount? No raw balance, no transaction history, no account metadata, and no financial profile is necessary or permitted.

### Principle 2 — Purpose Limitation
> *Data verified through LDBP must not be used for any purpose beyond the specific transaction for which it was verified.*

Verification results may not be used for profiling, upselling, credit scoring, data brokerage, or any secondary purpose. The Boolean result is transactional, not informational.

### Principle 3 — Account Isolation
> *A Finance App must be scoped to exactly one user-selected account.*

The user — not the Finance App — selects the account. The token issued by the bank is mathematically restricted to that account. Access to any other account at the same bank is architecturally impossible, not merely prohibited by policy.

### Principle 4 — Notification Sovereignty
> *When a verification is blocked for any reason, the bank notifies the user directly. The Finance App receives only False.*

The user's right to know what happens on their account belongs to the bank-user relationship, not the bank-app relationship. Reason codes for False responses are strictly internal to the bank and must never be surfaced to the Finance App.

### Principle 5 — User Control
> *The user must be able to revoke a Finance App's access to their account instantly, unilaterally, and without contacting the Finance App.*

The Kill Switch is not optional. It is a core architectural requirement. A user who cannot revoke access has not meaningfully consented to it.

---

## Conformance Requirements

The following requirements are organized by category. All requirements marked **MUST** are mandatory for conformance. Requirements marked **MUST NOT** represent absolute prohibitions — any implementation that violates a MUST NOT requirement is not LDBP-conformant. Requirements marked **SHOULD** are strongly recommended but do not affect conformance status.

---

### C-01: API Response Data Minimization

| ID | Requirement | Principle |
|---|---|---|
| C-01.1 | The `/balance/verify` and `/transfer/charge` endpoints MUST return only: `is_enough` (boolean), `intent_id` (echoed), and `evaluated_at` (timestamp) on a False response. | P1 |
| C-01.2 | The `/transfer/charge` endpoint MUST return only: `is_enough` (boolean), `transfer_id` (on True only), `intent_id`, `amount`, `currency`, and `executed_at` on a True response. | P1 |
| C-01.3 | No endpoint MUST NOT return a raw account balance to a Finance App under any circumstances, including error responses, debug responses, or partial responses. | P1 |
| C-01.4 | No endpoint MUST NOT return transaction history, account metadata, merchant data, or any financial profile data to a Finance App. | P1 |
| C-01.5 | The batch endpoints `/batch/balance/verify` and `/batch/transfer/charge` MUST apply identical data minimization constraints per intent as their single-transaction equivalents. | P1 |

**Principle Drift Indicator:** Any implementation that returns a raw balance, account history, or financial metadata to a Finance App in any response field, header, or side channel is not LDBP-conformant.

---

### C-02: Boolean Verification Integrity

| ID | Requirement | Principle |
|---|---|---|
| C-02.1 | The verification result MUST be a single Boolean (`is_enough`). No numeric, categorical, or multi-valued result is permitted as a substitute. | P1 |
| C-02.2 | The Boolean result MUST reflect the composite atomic result of balance verification AND fraud evaluation performed in a single PEP operation. These MUST NOT be separated into sequential steps. | P1 |
| C-02.3 | A False response MUST be opaque. All False conditions — insufficient funds, fraud flag, revoked token, rate limit exceeded, weekly cap hit — MUST return responses that are indistinguishable to the Finance App. | P1, P4 |
| C-02.4 | Reason codes for False responses MUST NOT be surfaced in any API response field, HTTP header, error message, or side channel accessible to the Finance App. | P1, P4 |
| C-02.5 | The bank MUST NOT implement a mechanism that allows a Finance App to determine the specific reason for a False response through repeated calls, response timing, or any other inference channel. | P1, P4 |

**Principle Drift Indicator:** Any implementation that allows a Finance App to distinguish between a False caused by insufficient funds and a False caused by a fraud flag — through any mechanism — is not LDBP-conformant.

---

### C-03: Account Isolation

| ID | Requirement | Principle |
|---|---|---|
| C-03.1 | The ScopedAccountToken MUST be mathematically restricted to exactly one user-selected account. | P3 |
| C-03.2 | The account selection MUST be made by the user, not the Finance App. The bank's authentication flow MUST present the account selector to the user directly. | P3 |
| C-03.3 | The bank's PEP MUST architecturally reject any request targeting an account not encoded in the ScopedAccountToken. Policy-based rejection is insufficient — rejection MUST be enforced at the token validation layer. | P3 |
| C-03.4 | The raw DDA (Direct Deposit Account) number MUST NOT be transmitted to the Finance App at any point, including during token exchange, verification, or execution. | P3 |
| C-03.5 | The bank MUST generate an app-specific Alias ID (opaque token) for each Finance App. The same account MUST have different Alias IDs for different Finance Apps. A compromised Alias ID for one app MUST NOT provide access via any other app or at any other bank. | P3 |

**Principle Drift Indicator:** Any implementation where a Finance App token grants access to more than one account, or where the raw DDA number is transmitted to the Finance App, is not LDBP-conformant.

---

### C-04: Execution Atomicity

| ID | Requirement | Principle |
|---|---|---|
| C-04.1 | `/transfer/charge` MUST perform balance verification, fraud evaluation, and fund deduction as a single atomic operation within the PEP. No gap between verification and execution is permitted. | P1 |
| C-04.2 | `/batch/transfer/charge` MUST apply the same atomic execution requirement per intent. Each intent MUST be independently atomically verified and executed. | P1 |
| C-04.3 | The X-Idempotency-Key MUST be cached for a minimum of 24 hours. A retry with the same key MUST return the original response without re-executing the transfer. | P1 |
| C-04.4 | The `transfer:charge` scope MUST be explicitly present in the ScopedAccountToken. It MUST NOT be implied by `balance:verify`. The user MUST have explicitly consented to immediate execution at token issuance. | P3, P5 |

**Principle Drift Indicator:** Any implementation that separates verification and execution into sequential steps — creating a window between check and debit — is not LDBP-conformant.

---

### C-05: Notification Sovereignty

| ID | Requirement | Principle |
|---|---|---|
| C-05.1 | When `/balance/verify` or `/transfer/charge` returns False due to an internal fraud flag, the bank MUST simultaneously deliver a `verification.blocked` notification directly to the authenticated user. | P4 |
| C-05.2 | The `verification.blocked` notification MUST be delivered to the user via the bank's own notification channel. It MUST NOT be delivered to or visible by the Finance App. | P4 |
| C-05.3 | The `verification.blocked` notification MUST include: event type, timestamp, app alias, intent_id, and human-readable reason from the approved status taxonomy. | P4 |
| C-05.4 | The approved status taxonomy for user-facing notifications is: `declined_insufficient_funds`, `declined_fraud_review`, `declined_rate_limit`, `declined_revoked`, `declined_cap_exceeded`. These codes MUST NOT appear in any API response to Finance Apps. | P4 |
| C-05.5 | A False result due to insufficient funds MUST NOT trigger a `verification.blocked` notification. Insufficient funds is a normal payment outcome, not a security event. | P4 |
| C-05.6 | The bank MUST send a Real-time Consent Receipt to the user after every successful transfer, detailing the amount, Finance App alias, and Consent Policy used. | P4 |

**Principle Drift Indicator:** Any implementation that notifies the Finance App of the specific reason for a False response, or that routes security notifications through the Finance App to the user, is not LDBP-conformant.

---

### C-06: User Control and Revocation

| ID | Requirement | Principle |
|---|---|---|
| C-06.1 | The bank MUST provide a user-accessible Kill Switch portal listing all active ScopedAccountTokens by Finance App alias. | P5 |
| C-06.2 | A single user action in the Kill Switch portal MUST immediately invalidate the ScopedAccountToken and terminate the Finance App's access. | P5 |
| C-06.3 | Token invalidation MUST be instantaneous. There MUST NOT be a grace period, delay, or notification to the Finance App before access is terminated. | P5 |
| C-06.4 | The Kill Switch portal MUST include a transaction log with human-readable status entries for each verification and transfer event, visible to the authenticated user only. | P5 |
| C-06.5 | The user MUST be able to revoke access without contacting the Finance App, the bank's customer service, or any third party. | P5 |

**Principle Drift Indicator:** Any implementation where revoking a Finance App's access requires user action beyond a single click, requires contacting the Finance App or bank support, or has any delay greater than one second is not LDBP-conformant.

---

### C-07: Intent-ID Integrity

| ID | Requirement | Principle |
|---|---|---|
| C-07.1 | Each Intent-ID MUST be single-use. An Intent-ID that has been consumed by a successful `/transfer/charge` call MUST be permanently invalidated. | P1 |
| C-07.2 | A False response from `/balance/verify` or `/transfer/charge` MUST immediately invalidate the Intent-ID. The Finance App MUST generate a new Intent-ID for any retry. | P1 |
| C-07.3 | Reuse of a consumed or invalidated Intent-ID MUST be rejected with a 409 error. The bank MUST NOT execute a transfer against a reused Intent-ID under any circumstances. | P1 |

**Principle Drift Indicator:** Any implementation that allows Intent-ID reuse, or that permits transfer execution without a valid unused Intent-ID, is not LDBP-conformant.

---

### C-08: Batch Operations

| ID | Requirement | Principle |
|---|---|---|
| C-08.1 | `/batch/balance/verify` is informational only. It MUST NOT move, earmark, or reserve funds. | P1 |
| C-08.2 | `/batch/transfer/charge` MUST perform atomic verify+execute per intent. There MUST NOT be a verify-execute gap between the batch verification and execution steps. | P1 |
| C-08.3 | A standalone `/batch/transfer/execute` endpoint — one that accepts pre-verified intent results and executes them in a separate call — MUST NOT be implemented. This pattern creates a race condition gap that violates the atomicity requirement and is classified as Principle Drift. | P1 |
| C-08.4 | Partial success in `/batch/transfer/charge` is valid. A False result on one intent MUST NOT block execution of other intents in the batch. | P1 |

**Principle Drift Indicator:** Any batch implementation that separates verification from execution — including any variant of `/batch/transfer/execute` — is not LDBP-conformant.

---

## What Constitutes Principle Drift

Principle Drift is any modification, extension, or implementation that violates one or more Least-Data Principles, regardless of intent, framing, or partial compliance. The following are explicit examples of Principle Drift. This list is illustrative, not exhaustive.

| Drift Pattern | Violated Principle | Classification |
|---|---|---|
| Returning raw balance alongside or instead of Boolean | P1 — Data Minimization | Principle Drift |
| Adding reason codes to False responses visible to Finance App | P1, P4 — Data Minimization, Notification Sovereignty | Principle Drift |
| Exposing transaction history via any endpoint to Finance App | P1 — Data Minimization | Principle Drift |
| Token that grants access to more than one account | P3 — Account Isolation | Principle Drift |
| Transmitting raw DDA number to Finance App | P3 — Account Isolation | Principle Drift |
| Separating balance check and fraud evaluation into sequential calls | P1 — Data Minimization | Principle Drift |
| Implementing `/batch/transfer/execute` as a separate execution endpoint | P1 — Data Minimization | Principle Drift |
| Notifying Finance App of fraud flag reason | P4 — Notification Sovereignty | Principle Drift |
| Kill Switch with delay, grace period, or app notification before revocation | P5 — User Control | Principle Drift |
| Account selector controlled by Finance App rather than user | P3 — Account Isolation | Principle Drift |
| Using verification results for profiling or secondary purposes | P2 — Purpose Limitation | Principle Drift |
| Balance verification without simultaneous fraud evaluation | P1 — Data Minimization | Principle Drift |

---

## Claiming LDBP Conformance

An implementation may claim LDBP conformance only if it satisfies every MUST and MUST NOT requirement in sections C-01 through C-08.

When claiming conformance, the implementing institution MUST include the following attribution statement in all relevant documentation, API specifications, developer portals, and regulatory filings:

> *"This implementation conforms to the Least Data Banking Protocol (LDBP) as defined by Mary Ann Belarmino (BelarminoAdvisory.com). LDBP Conformance Definition v1.0. Licensed under CC BY 4.0."*

Partial conformance claims — for example, "LDBP Phase 1 Conformant" — are permitted only for implementations that satisfy all requirements applicable to Phase 1 endpoints (`/auth/token/exchange`, `/auth/token/revoke`, `/balance/verify`, `/transfer/charge`) and include the following qualifier in all claims:

> *"Phase 1 LDBP Conformant — Phase 2 features not implemented."*

---

## Implementation-Defined Behaviors

The following behaviors are deliberately left to the implementing institution and do not affect conformance status:

- Fraud scoring model, training data, and internal flag thresholds
- Consumer notification delivery channel (push, SMS, email)
- Attribute verification method (internal comparison logic vs. Zero-Knowledge Proofs)
- Weekly/monthly Virtual Allowance cap values
- mTLS certificate authority and rotation policy
- Billing basis-point rate per execution event; whether verification calls are billed is institution-defined

---

## Versioning and Amendment

This document is versioned. Conformance requirements may be amended in future versions. An implementation conformant with a prior version remains conformant with that version. Conformance claims MUST specify the version of this document against which conformance is asserted.

Amendment proposals may be submitted via the LDBP GitHub repository. Amendments that weaken any Least-Data Principle, expand data exposure to Finance Apps, or reduce user control rights will not be accepted regardless of commercial rationale. This constraint is permanent and applies to all future versions of this document.

---

## Document History

| Version | Date | Summary |
|---|---|---|
| 1.0 | April 2026 | Initial release. Five Least-Data Principles. Eight conformance categories (C-01 through C-08). Principle Drift taxonomy. Conformance claim requirements. |

---

## Attribution and License

© 2026 Mary Ann Belarmino. BelarminoAdvisory.com.

Licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

You are free to use, implement, reference, and build upon this document for any purpose, provided that attribution to Mary Ann Belarmino and BelarminoAdvisory.com is clearly stated in all uses, implementations, derivative works, and references.

This Conformance Definition is the governing document for LDBP conformance claims. Any implementation that modifies the Least-Data Principles defined herein and claims LDBP conformance is misrepresenting its conformance status.
