# LDBP Sequence Diagrams

Visual representations of key LDBP protocol flows.

---

## Diagram 1 — Standard Payment Flow (Phase 1)

The core LDBP transaction flow for a single payment.
`POST /transfer/charge` atomically re-verifies and executes
in one locked PEP operation — there is no separate execute step.

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant A as Finance App
  participant B as Bank API Gateway / PEP
  participant C as Bank Core Ledger

  Note over U, B: Phase 1 — Scoped Token Issuance
  U->>B: Authenticate & select ONE account (Checking)
  B-->>U: Account selector confirmed
  B->>A: Issue ScopedAccountToken (Alias ID — never raw DDA)

  Note over A, B: Phase 2 — Informational Verification (Optional)
  A->>B: POST /balance/verify (Intent_ID, Amount: $50)
  B->>B: PEP atomically checks balance + fraud (internal only)
  Note right of B: Raw balance never leaves the bank
  B-->>A: 200 OK { "is_enough": true } — Boolean only

  Note over A, C: Phase 3 — Atomic Verify + Execute
  A->>B: POST /transfer/charge (Intent_ID, X-Idempotency-Key)
  B->>B: PEP atomically re-verifies balance + fraud + deducts funds
  B->>C: Single locked operation — no gap between check and debit
  C-->>B: Confirmed
  B-->>A: 201 Created { "is_enough": true, "transfer_id": "..." }
  B->>U: Real-time Consent Receipt: "$50 authorized to [App]"
```

---

## Diagram 2 — Fraud Flag Flow

What happens when the bank's internal fraud model blocks a verification.
The Finance App receives only False — indistinguishable from
insufficient funds. The user is notified directly by the bank.

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant A as Finance App
  participant B as Bank API Gateway / PEP

  A->>B: POST /balance/verify (Intent_ID, Amount: $50)
  B->>B: PEP atomically checks balance + fraud
  Note right of B: Internal fraud model flags the request
  B-->>A: 200 OK { "is_enough": false } — no reason code
  Note right of B: False is opaque — Finance App cannot<br/>distinguish fraud flag from insufficient funds
  B->>U: verification.blocked webhook
  Note right of B: Payload: event type, timestamp,<br/>app alias, intent_id, reason: declined_fraud_review
  Note over A: Finance App never learns it was flagged
```

---

## Diagram 3 — Kill Switch Revocation

User revokes Finance App access instantly from the Connected Apps portal.
No Finance App involvement required. Takes effect in under one second.

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant B as Bank Kill Switch Portal
  participant A as Finance App

  U->>B: Tap "Revoke Access" for [Finance App]
  B->>B: Instantly invalidates ScopedAccountToken
  B->>B: Voids all pending Intent-IDs
  B-->>U: Revocation confirmed with timestamp
  Note over A: Finance App receives no notification
  A->>B: Subsequent API call (any endpoint)
  B-->>A: 403 TOKEN_REVOKED
```

---

## Diagram 4 — Agentic Batch Payment

An AI agent processing a queue of pre-authorized subscription payments
using `/batch/transfer/charge`. Each intent is atomically verified
and executed independently — no agent accumulates account state.

```mermaid
sequenceDiagram
  autonumber
  participant AG as AI Agent
  participant B as Bank API Gateway / PEP
  participant C as Bank Core Ledger

  AG->>B: POST /batch/transfer/charge
  Note right of AG: [ {intent_id: "sub_001", amount: 15.99},<br/>  {intent_id: "sub_002", amount: 9.99},<br/>  {intent_id: "sub_003", amount: 87.50} ]
  loop Per intent — atomic and independent
    B->>B: PEP atomically verifies balance + fraud + deducts
    B->>C: Single locked operation per intent
    C-->>B: Confirmed
  end
  B-->>AG: 207 Multi-Status
  Note right of B: { results: [<br/>    { intent_id: "sub_001", is_enough: true, transfer_id: "..." },<br/>    { intent_id: "sub_002", is_enough: true, transfer_id: "..." },<br/>    { intent_id: "sub_003", is_enough: false }<br/>  ] }
  Note over AG: Agent never sees account balance.<br/>Each Intent-ID expires on use.
```

---

## Key Design Points Across All Flows

| Design Point | Where Visible |
|---|---|
| Raw DDA never transmitted to Finance App | Diagram 1 — token issuance shows Alias ID only |
| Composite atomic verification: balance + fraud | Diagrams 1, 2 — PEP note on every verify/charge call |
| False response is opaque — all failure modes identical | Diagram 2 — Finance App receives same False regardless |
| Notification sovereignty — bank notifies user directly | Diagrams 2, 3 — notifications go bank → user only |
| Kill Switch is instant and unilateral | Diagram 3 — no Finance App involvement |
| Agentic least-privilege — no accumulated state | Diagram 4 — each intent scoped, each ID expires on use |

---

*© 2026 Mary Ann Belarmino. BelarminoAdvisory.com. CC BY 4.0.*
