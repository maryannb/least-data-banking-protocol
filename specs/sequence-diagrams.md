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
