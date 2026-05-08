# LDBP Regulatory Compliance Reference

This document maps LDBP's technical implementation to the specific 
requirements of relevant US and EU regulations. It is intended as a 
reference for bank compliance officers, legal reviewers, and regulatory 
bodies evaluating LDBP for implementation or citation.

For the full technical implementation of each item, see:
- API Spec: `ldbp_api.yaml`
- PRD Section 10: Regulatory Compliance Mapping
- Conformance Definition: `LDBP_CONFORMANCE.md`

---

## Regulatory Mapping Table

| Regulation | Specific Requirement | LDBP Technical Implementation |
|---|---|---|
| **CFPB Section 1033** | Mandatory developer interface for authorized third parties | `ldbp_api.yaml` — standardized OpenAPI 3.0 contract for all Finance Apps |
| **CFPB Section 1033** | "Reasonably necessary" data only — no over-collection | `POST /balance/verify` — Boolean True/False replaces raw balance; over-collection is architecturally impossible |
| **CFPB Section 1033** | Consumer revocation rights | `POST /auth/token/revoke` — instant cryptographic token invalidation; Kill Switch portal |
| **CFPB Section 1033** | No secondary use of consumer financial data | Finance App never possesses raw data — cannot repurpose what it never received |
| **GDPR Art. 5 — Data Minimization** | Only minimum necessary data collected for stated purpose | Boolean-only response; no transaction history, no raw balance, no account metadata transmitted to Finance App |
| **GDPR Art. 5 — Purpose Limitation** | Data collected only for stated purpose; not used for secondary purposes | Finance App receives only a Boolean per transaction — no data exists at the app layer to repurpose |
| **GDPR Art. 17 — Right to Erasure** | Users can request deletion of their data | Alias ID deletion severs the mapping between the Finance App and the user's account without touching the core ledger |
| **GDPR Art. 7 — Consent** | Freely given, specific, informed, unambiguous consent | Account selector UI ensures user-selected scoping; `transfer:charge` scope requires explicit consent at token issuance |
| **PSD3 / PSR (EU)** | Ban on screen scraping; dedicated secure APIs required | LDBP provides the dedicated secure API PSD3 mandates — Boolean verification exceeds PSD3's current raw-balance standard |
| **FiDA (EU, pending)** | Transparent consent dashboards; one-click revocation | Kill Switch portal directly implements FiDA consent dashboard requirements |
| **Regulation E (US)** | Consumer notification on electronic fund transfers | Real-time Consent Receipts on every transfer; `verification.blocked` webhooks on blocked events |
| **GLBA — Safeguards Rule** | Protection of customer financial information | Raw DDA never transmitted; Alias ID system ensures a Finance App breach exposes no usable account data |
| **NIST CSF 2.0** | Identity governance; strong authentication for high-value transactions | mTLS required for `/transfer/charge` and `/batch/transfer/charge`; ScopedAccountToken with cryptographic expiry |
| **EU AI Act** | Deterministic boundaries for high-risk AI financial operations | `GET /governance/permission-budget` — hard Virtual Allowance cap an AI agent cannot bypass; Intent-ID bounds each operation to its declared purpose |

*Note: As of April 2026, CFPB Section 1033 is subject to ongoing 
litigation and CFPB reconsideration. LDBP's technical approach 
remains valid regardless of the rule's litigation status.*

---

## Compliance Checklist

### 1. CFPB Section 1033 — Personal Financial Data Rights

- [ ] Developer interface implemented as a standardized OpenAPI 3.0 
      contract (`ldbp_api.yaml`)
- [ ] Boolean-only responses ensure data collection is limited to 
      what is reasonably necessary for each transaction
- [ ] `POST /auth/token/revoke` immediately invalidates the 
      ScopedAccountToken and terminates Finance App access
- [ ] Kill Switch portal lists all active Finance App connections 
      by alias and allows single-action revocation
- [ ] No secondary use of consumer financial data — Finance App 
      never receives raw data to repurpose
- [ ] CFPB 1033 litigation status noted; implementation does not 
      depend on the rule's final status

### 2. GDPR and EU Privacy Regulations

- [ ] `POST /balance/verify` returns only True/False — data 
      collection is the technical minimum for the stated purpose
- [ ] Finance App layer holds no raw financial data — Purpose 
      Limitation is enforced architecturally, not by contract
- [ ] Alias ID deletion severs Finance App mapping without 
      touching core ledger — supports Right to Erasure
- [ ] Account selector UI ensures user-directed, specific consent 
      to one account at time of token issuance
- [ ] `transfer:charge` scope requires explicit user consent at 
      token issuance — not implied by `balance:verify`
- [ ] `verification.blocked` webhook delivers fraud notifications 
      bank → user directly, never through the Finance App
- [ ] FiDA consent dashboard requirements met by Kill Switch portal 
      *(FiDA pending — monitor trilogue negotiations)*

### 3. PSD3 / PSR — EU Payment Services

- [ ] No screen scraping fallback interfaces — all access via 
      dedicated LDBP API
- [ ] Boolean-only responses exceed PSD3's current raw-balance 
      standard
- [ ] mTLS enforced on all fund-movement endpoints

### 4. US Security and Safety — GLBA / Regulation E / NIST

- [ ] All endpoints enforced with TLS 1.3 minimum
- [ ] mTLS enforced at gateway layer for `POST /transfer/charge` 
      and `POST /batch/transfer/charge`
- [ ] Raw DDA account number never transmitted to Finance App 
      at any point — Alias ID used throughout
- [ ] `X-Idempotency-Key` cached for set duration (e.g. 24 hours) 
      — prevents double-charging on network retry
- [ ] Real-time Consent Receipts sent to user after every 
      successful transfer (Regulation E)
- [ ] All PEP decisions logged with `request_id` for audit trail 
      — minimum 2 years for transfer records per 
      Regulation E (12 CFR 1005.13)
- [ ] Encryption at rest for Alias ID → DDA mapping — 
      method is institution-defined

### 5. Agentic and AI Governance — EU AI Act

- [ ] Each AI agent operation scoped to a single Intent-ID that 
      expires on use — no accumulated account state
- [ ] `GET /governance/permission-budget` enforces hard Virtual 
      Allowance cap that no agent can bypass regardless of 
      reasoning (Phase 2)
- [ ] `POST /batch/transfer/charge` provides atomic per-intent 
      execution for agent queues — partial success valid
- [ ] Rate limiting on `POST /balance/verify` prevents agent 
      binary search attacks — institution-defined limit
- [ ] `request_id` in all API responses provides audit trail 
      for agent-initiated operations
- [ ] ScopedAccountToken restricts agent to declared account — 
      a compromised sub-agent cannot laterally access other accounts

---

## Implementation-Defined Items

The following are not mandated by LDBP but are recommended for 
regulatory compliance at the institution level:

| Item | Recommendation | Regulatory Driver |
|---|---|---|
| Encryption at rest for Alias ID mapping | AES-256 with hardware-backed keys | GLBA Safeguards Rule |
| MFA for `/auth/token/exchange` flow | Required for high-value account linking | NIST CSF 2.0 |
| Rate limit value for `/balance/verify` | Institution-defined; sufficient to prevent binary search attacks | CFPB 1033 security requirements |
| Virtual Allowance cap values | User-configured and institution-defined | EU AI Act; GDPR consent scope |
| Fraud scoring model thresholds | Institution-defined | FFIEC guidance |

---

*© 2026 Mary Ann Belarmino. BelarminoAdvisory.com. CC BY 4.0.*
