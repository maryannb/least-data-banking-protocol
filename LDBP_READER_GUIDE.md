# LDBP Dossier — Reader's Guide
## Least Data Banking Protocol: What's Here and How to Read It

**Author:** Mary Ann Belarmino — BelarminoAdvisory.com  
**License:** CC BY 4.0 — Attribution required on all uses and implementations  
**Version:** 1.0 — April 2026

---

## Overview

This repository contains the complete LDBP dossier — a set of five coordinated artifacts that together define, specify, govern, and document the Least Data Banking Protocol. Each artifact serves a distinct audience and purpose. This guide tells you which document to read first based on who you are and what you need.

---

## The Five Artifacts

### 1. Whitepaper — `LDBP_Whitepaper_v1.docx`

**What it is:** The foundational concept document. Explains the problem (all-access banking data extraction), the principle (Boolean verification over data extraction), and the rationale for LDBP's architecture. Written for a mixed audience — executives, product leaders, regulators, and technically curious non-engineers.

**Read this if you are:**
- New to LDBP and want to understand what it is and why it exists
- A regulator, policy maker, or compliance officer evaluating the protocol's intent
- A journalist, researcher, or analyst covering open banking privacy
- A business stakeholder deciding whether to evaluate LDBP for adoption

**What it covers:**
- The all-access data extraction problem and its four harms
- The five Least-Data Principles in plain language
- How LDBP works conceptually — the "is_enough" check, scoped tokens, the Kill Switch
- How current apps (Cash App, Stripe, Venmo, Klarna) exploit the all-access model — with documented regulatory findings
- The fraud detection ownership argument
- EU and US regulatory alignment
- The bank's commercial case for adoption
- Agentic governance — why LDBP is the right primitive for AI agents

**What it does not cover:** Detailed API endpoint specifications, implementation requirements, or conformance criteria. For those, see the API Spec and PRD.

---

### 2. API Specification — `ldbp_api_v1.yaml`

**What it is:** The machine-readable OpenAPI 3.0 specification defining every LDBP endpoint, request schema, response schema, error code, security scheme, and behavioral contract. This is the technical implementation reference.

**Read this if you are:**
- A bank API architect implementing LDBP
- A Finance App developer integrating with an LDBP-compliant bank
- A security reviewer auditing the protocol's technical surface
- A standards body evaluating LDBP for formal adoption

**What it covers:**

| Endpoint | Phase | Purpose |
|---|---|---|
| `POST /auth/token/exchange` | 1 | Issues a ScopedAccountToken restricted to one user-selected account |
| `POST /auth/token/revoke` | 1 | Kill Switch — instantly terminates Finance App access |
| `POST /balance/verify` | 1 | The "is_enough" check — composite atomic Boolean verification |
| `POST /transfer/charge` | 1 | Single-call atomic verify+execute — the only fund movement path |
| `GET /governance/permission-budget` | 2 | Returns remaining Virtual Allowance for the period |
| `POST /batch/balance/verify` | 2 | Batch informational verification — no funds moved |
| `POST /batch/transfer/charge` | 2 | Batch atomic verify+execute — partial success valid |
| `GET /billing/metering` | 2 | Real-time fee attribution for bank basis-point royalties |
| `POST /webhooks/verification.blocked` | 2 | Bank-to-user fraud block notification contract |

**Key design principles documented in the spec:**
- Composite atomic verification: balance + fraud in one PEP operation
- False response opacity: all False conditions indistinguishable to Finance App
- Notification sovereignty: blocked events go bank → user, never bank → app → user
- Intent-ID lifecycle: single-use, invalidated on False, must not be reused
- No raw financial data in any response to Finance Apps

**What it does not cover:** The business rationale for these decisions (see Whitepaper) or the conformance enforcement criteria (see Conformance Definition).

---

### 3. Product Requirements Document — `LDBP_PRD_v1.docx`

**What it is:** A FAANG-caliber PRD defining the complete product requirements for implementing LDBP — functional requirements, non-functional requirements, use cases, architecture, fraud detection design, regulatory mapping, and success metrics. Written for engineering teams, product managers, and technical program managers at implementing institutions.

**Read this if you are:**
- An engineering team planning an LDBP implementation
- A product manager scoping a Phase 1 or Phase 2 build
- A compliance officer mapping LDBP to specific regulatory requirements (CFPB 1033, GDPR, PSD3, Regulation E)
- A bank architect evaluating LOE and system architecture changes
- An enterprise stakeholder reviewing the business case and stakeholder impact

**What it covers:**
- Goals and non-goals (what LDBP deliberately does not mandate)
- Five primary personas including the AI Agent as a first-class persona
- Five detailed use cases with step-by-step flows and outcome callouts
- Functional requirements FR-01 through FR-08 with auditable requirement IDs
- Non-functional requirements (performance, availability, security, rate limiting)
- Full API surface reference with behavioral contracts
- System architecture: the Translation & Governance Layer model
- Fraud detection architecture and transition risk mitigations
- Regulatory compliance mapping table
- Business model and stakeholder impact analysis
- Agentic governance requirements
- Implementation-defined behaviors
- Risk register with mitigations
- Success metrics with zero-tolerance thresholds
- Future Work — six roadmap items for future LDBP versions

**What it does not cover:** The specific endpoint schemas (see API Spec) or the conformance enforcement criteria (see Conformance Definition).

---

### 4. Conformance Definition — `LDBP_CONFORMANCE.md` / `LDBP_Conformance_v1.docx`

**What it is:** The authoritative governance document defining what it means to be LDBP-conformant. Any implementation, product, or service claiming LDBP conformance must satisfy every requirement in this document. In the event of conflict with any other LDBP artifact, this document governs.

**Read this if you are:**
- An implementing institution evaluating whether your implementation qualifies as LDBP-conformant
- A bank or fintech preparing to make a public LDBP conformance claim
- A legal or compliance team reviewing what obligations a conformance claim creates
- A regulator or auditor assessing whether a product's LDBP claim is valid
- A researcher or standards body evaluating LDBP's governance structure

**What it covers:**
- The five Least-Data Principles stated as architectural invariants
- Eight conformance categories (C-01 through C-08) with numbered MUST/MUST NOT requirements
- A Principle Drift taxonomy — 12 explicit drift patterns that disqualify an LDBP conformance claim
- The required attribution statement for any conformance claim
- Implementation-defined behaviors that do not affect conformance status
- Versioning and amendment rules — including a permanent constraint that no future version may weaken the five Least-Data Principles

**Two formats:** The `.md` file is the canonical living reference in this repository. The `.docx` file is the formal distribution artifact for regulatory submissions and vendor contracts. Both contain identical content.

**What it does not cover:** Implementation guidance (see PRD) or API schemas (see API Spec).

---

### 5. Reader's Guide — `LDBP_READER_GUIDE.md` / `LDBP_Reader_Guide_v1.docx`

**What it is:** This document. A navigation guide to the LDBP dossier explaining what each artifact is, who it is for, what it covers, and what it does not cover. The starting point for any reader new to the dossier.

**Read this if you are:**
- New to LDBP and unsure where to start
- Sharing the dossier with colleagues and want to orient them quickly

**Two formats:** The `.md` file lives in the GitHub repository root. The `.docx` file is for formal distribution. Both contain identical content.

---

## How the Artifacts Relate

```
WHITEPAPER
"Why LDBP exists and what it does"
       │
       │ establishes principles and rationale for
       ▼
API SPECIFICATION                    PRD
"What to build"                      "How to build it"
Endpoint schemas,                    Requirements, use cases,
behavioral contracts,                architecture, LOE,
security schemes                     regulatory mapping
       │                                    │
       └──────────────┬─────────────────────┘
                      │ both governed by
                      ▼
             CONFORMANCE DEFINITION
             "What counts as LDBP"
             Principles, MUST/MUST NOT requirements,
             Principle Drift taxonomy,
             conformance claim rules
```

---

## Reading Order by Role

| You Are | Start Here | Then Read |
|---|---|---|
| Executive / Business Stakeholder | Whitepaper | PRD §11 (Business Model) |
| Regulator / Policy Maker | Whitepaper | Conformance Definition, PRD §10 (Regulatory Mapping) |
| Bank Product Manager | Whitepaper | PRD (full) |
| Bank API Architect | PRD §8 (Architecture) | API Spec |
| Finance App Developer | API Spec | Whitepaper §Fraud Detection |
| Compliance Officer | Conformance Definition | PRD §10 (Regulatory Mapping) |
| Legal / Contract Review | Conformance Definition | Whitepaper |
| AI/Agent System Developer | Whitepaper §Agentic Governance | API Spec (batch endpoints) |
| Researcher / Academic | Whitepaper | Conformance Definition |
| Standards Body | Conformance Definition | API Spec, PRD |

---

## Version Reference

| Artifact | Current Version | Date |
|---|---|---|
| Whitepaper | v1.0 RFC | April 2026 |
| API Specification | v1.0.0 | April 2026 |
| PRD | v1.0 | April 2026 |
| Conformance Definition | v1.0 | April 2026 |
| Reader's Guide | v1.0 | April 2026 |

All artifacts are mutually consistent as of April 2026. In the event of any inconsistency, the Conformance Definition governs on matters of principle compliance, and the API Specification governs on matters of technical implementation.

---

## Attribution and License

© 2026 Mary Ann Belarmino. BelarminoAdvisory.com.

Licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

Attribution to Mary Ann Belarmino and BelarminoAdvisory.com is required on all uses, implementations, derivative works, and references. For commercial licensing inquiries: BelarminoAdvisory.com.
