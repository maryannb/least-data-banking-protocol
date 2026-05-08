# =============================================================================
# LDBP Optional & Edge Case Acceptance Criteria
# Least Data Banking Protocol — Security, Drift Detection & Agentic Scenarios
#
# This file covers:
#   - Principle Drift detection (C-01 through C-08 violation scenarios)
#   - Security hardening edge cases
#   - Agentic / Multi-Agent System (MAS) authorization scenarios
#   - High-value human-authorization loop scenarios
#   - Cross-cutting concerns (token lifecycle, error handling)
#
# Conformance reference: LDBP Conformance Definition v1.0 — Principle Drift Taxonomy
# API Spec reference:    ldbp_api.yaml
# Author:                Mary Ann Belarmino — BelarminoAdvisory.com
# License:               CC BY 4.0
# =============================================================================

Feature: LDBP Optional Scenarios — Security, Drift Detection & Agentic Use Cases
  As a Banking Platform Administrator and LDBP Conformance Reviewer,
  I want to verify that Principle Drift patterns are rejected,
  that security edge cases are handled correctly,
  and that agentic financial authorization works safely,
  so that LDBP's least-data guarantees cannot be circumvented.

  Background:
    Given the bank has implemented a fully LDBP-compliant API Gateway
    And the Policy Enforcement Point (PEP) is active
    And a test user "Alice" exists with a Checking account containing $1,000
    And an AI Agent "agent_subscription_mgr" has been granted a ScopedAccountToken
      with scope "balance:verify" and "transfer:charge"

  # ===========================================================================
  # PRINCIPLE DRIFT DETECTION — C-01 violations
  # ===========================================================================

  Scenario: DRIFT — Raw balance in response is rejected (C-01.3)
    Given a non-compliant bank implementation returns a raw balance field
    When the compliance test calls POST /balance/verify
    And the response body contains any field named "balance", "current_balance",
      "available_balance", or "amount_available"
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Returning raw balance alongside or instead of Boolean — P1 Data Minimization"

  Scenario: DRIFT — Transaction history in response is rejected (C-01.4)
    Given a non-compliant bank implementation returns transaction data
    When the compliance test calls POST /balance/verify
    And the response body contains any transaction history, merchant data,
      or spending category data
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Exposing transaction history via any endpoint to Finance App — P1 Data Minimization"

  Scenario: DRIFT — Reason code in False response is rejected (C-02.4)
    Given a non-compliant bank implementation returns reason codes
    When the compliance test calls POST /balance/verify and receives a False response
    And the response body contains a "reason", "reason_code", "decline_reason",
      or any field indicating why the result is False
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Adding reason codes to False responses visible to Finance App — P1, P4"

  Scenario: DRIFT — Token grants access to multiple accounts (C-03.1)
    Given a non-compliant bank issues a token that covers all accounts
    When the compliance test uses a token issued for "Checking"
    And the Finance App can access "Savings" account data using that token
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Token that grants access to more than one account — P3 Account Isolation"

  Scenario: DRIFT — DDA transmitted to Finance App (C-03.4)
    Given a non-compliant bank transmits the raw account number
    When the compliance test calls POST /auth/token/exchange
    And the response body contains a raw 12-digit DDA number or routing number
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Transmitting raw DDA number to Finance App — P3 Account Isolation"

  Scenario: DRIFT — Sequential balance check and fraud evaluation (C-02.2)
    Given a non-compliant bank separates balance and fraud into two calls
    When the compliance test examines the PEP implementation
    And balance verification and fraud evaluation are sequential API calls
      with a time gap between them
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Separating balance check and fraud evaluation into sequential calls — P1"

  Scenario: DRIFT — /batch/transfer/execute endpoint exists (C-08.3)
    Given a non-compliant bank implements a separate batch execution endpoint
    When the compliance test discovers POST /batch/transfer/execute is available
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Implementing /batch/transfer/execute — P1 Data Minimization"

  Scenario: DRIFT — Fraud flag notification routed through Finance App (C-05.2)
    Given a non-compliant bank routes fraud notifications via the Finance App
    When a verification is blocked due to fraud
    And the Finance App receives a flag or signal indicating fraud was detected
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Notifying Finance App of fraud flag reason — P4 Notification Sovereignty"

  Scenario: DRIFT — Kill Switch requires Finance App involvement (C-06.5)
    Given a non-compliant bank requires the Finance App to confirm revocation
    When the user calls POST /auth/token/revoke
    And the revocation is not effective until the Finance App acknowledges it
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Kill Switch requires more than a single user action — P5 User Control"

  Scenario: DRIFT — Kill Switch has a grace period before taking effect (C-06.3)
    Given a non-compliant bank delays token invalidation
    When the user calls POST /auth/token/revoke
    And the Finance App can still successfully call POST /balance/verify
      more than 1 second after the revocation call
    Then this implementation is NOT LDBP-conformant
    And the implementation should be flagged as Principle Drift:
      "Kill Switch delay greater than 1 second — P5 User Control"

  # ===========================================================================
  # SECURITY EDGE CASES — Binary Search & Timing Attacks
  # ===========================================================================

  Scenario: Binary search attack on account balance is prevented by rate limiting
    Given a malicious Finance App attempts to determine Alice's exact balance
      by making repeated POST /balance/verify calls with incrementing amounts
    When the Finance App makes calls up to the institution-defined rate limit:
      | call | amount   |
      | 1    | 500.00   |
      | 2    | 750.00   |
      | 3    | 875.00   |
      | ...  | ...      |
    And the Finance App attempts a call exceeding the rate limit
    Then the response status code should be 429
    And the Finance App should receive no additional balance information
    And the bank should send a verification.blocked webhook to Alice
      with reason "declined_rate_limit"
    And after the rate limit is hit, Alice's balance remains undisclosed

  Scenario: Timing side-channel attack is prevented — all False responses return in constant time
    Given a malicious Finance App attempts to distinguish False reasons via response timing
    When the Finance App receives multiple False responses for different internal reasons:
      | scenario             | internal_reason     |
      | Insufficient funds   | insufficient_funds  |
      | Fraud flag           | fraud_flag          |
      | Revoked token        | token_revoked       |
      | Rate limit           | rate_limit          |
    Then the response time for each False response should be statistically indistinguishable
    And no timing information should leak the internal reason for the False response

  Scenario: Parallel API calls cannot create a double-spend race condition
    Given Alice's account contains exactly $100
    And two Finance Apps both have valid ScopedAccountTokens for Alice's Checking account
    When both Finance Apps simultaneously call POST /transfer/charge for $100
    Then only one charge should succeed with 201 Created
    And the other charge should return is_enough: false
    And Alice's account should be debited exactly $100 — not $200
    And no double-spend should occur

  Scenario: Compromised alias_id provides no access to other banks or apps
    Given the alias_id "alias_8822_stripe" has been compromised
    When a malicious actor attempts to use the compromised alias_id
      to access Alice's account at a different bank
    Then access should be denied
    When a malicious actor attempts to use the compromised alias_id
      against a different Finance App at the same bank
    Then access should be denied
    And the alias_id should be valid ONLY for the specific bank-app pairing
      for which it was issued

  # ===========================================================================
  # AGENTIC / MULTI-AGENT SYSTEM SCENARIOS
  # ===========================================================================

  Scenario: AI agent executes a bounded payment using LDBP — least privilege by design
    Given the AI Agent "agent_subscription_mgr" has a ScopedAccountToken
      with scopes "balance:verify" and "transfer:charge"
    And the agent has been tasked with paying a $15.99 Netflix subscription
    When the agent generates a new Intent-ID "int_agent_netflix_001"
    And the agent calls POST /balance/verify for $15.99
    Then the response should return is_enough: true
    And the agent should receive NO information about the remaining balance
    When the agent calls POST /transfer/charge for $15.99
      with intent_id "int_agent_netflix_001"
    Then the response status code should be 201
    And the transfer should execute successfully
    And the agent should have received ONLY a Boolean and a transfer_id
    And the agent should have NO knowledge of the account balance before or after

  Scenario: Compromised AI agent cannot access account state beyond its scoped proof
    Given the AI Agent "agent_subscription_mgr" has been compromised
    When the compromised agent attempts to call POST /balance/verify
      with amounts designed to infer the account balance
    Then the institution-defined rate limit should prevent balance inference
    When the compromised agent attempts to access Alice's Savings account
    Then the ScopedAccountToken should reject access — it is restricted to Checking only
    When the compromised agent attempts to reuse a consumed Intent-ID
    Then the response should return 409 INTENT_ID_CONSUMED
    And the blast radius of the compromise should be bounded to
      the single declared task — not Alice's full account

  Scenario: Multi-agent delegation — each sub-agent receives only its scoped proof
    Given an orchestrating agent has decomposed Alice's payments into 3 sub-tasks
    And sub-agent A is tasked with paying Netflix $15.99
    And sub-agent B is tasked with paying Spotify $9.99
    And sub-agent C is tasked with paying a utility bill $87.50
    When sub-agent A calls POST /transfer/charge for $15.99
      with its own Intent-ID "int_agent_A_001"
    And sub-agent B calls POST /transfer/charge for $9.99
      with its own Intent-ID "int_agent_B_001"
    And sub-agent C calls POST /transfer/charge for $87.50
      with its own Intent-ID "int_agent_C_001"
    Then each sub-agent should receive only its own Boolean and transfer_id
    And sub-agent A should have NO knowledge of sub-agent B's or C's transactions
    And sub-agent B should have NO knowledge of sub-agent A's or C's transactions
    And no agent in the chain should accumulate account state across tasks

  Scenario: Agentic batch subscription payment via /batch/transfer/charge
    Given the AI Agent has a queue of 5 pre-authorized subscription payments
    When the agent calls POST /batch/transfer/charge with 5 intents:
      | intent_id     | amount |
      | int_sub_001   | 15.99  |
      | int_sub_002   | 9.99   |
      | int_sub_003   | 12.99  |
      | int_sub_004   | 4.99   |
      | int_sub_005   | 87.50  |
    Then the response status code should be 207
    And each intent should be atomically verified and executed independently
    And the agent should receive per-intent Boolean results only
    And no intent result should disclose Alice's account balance at any point
    And a compromised intent result should not affect other intents in the batch

  # ===========================================================================
  # HIGH-VALUE HUMAN AUTHORIZATION LOOP
  # ===========================================================================

  Scenario: High-value transaction with human approval between verify and charge
    Given Alice's organization requires human approval for transfers over $500
    And the Finance App generates Intent-ID "int_hv_001" for a $750 payment
    When the Finance App calls POST /balance/verify for $750
    Then the response should return is_enough: true
    And the Finance App presents the result to a human approver
    And the human approver takes 10 minutes to review and approve
    When the Finance App calls POST /transfer/charge for $750
      with intent_id "int_hv_001"
    Then the charge endpoint should atomically re-verify at execution time
    And if Alice's balance is still sufficient, the charge should return 201 Created
    And if Alice's balance has changed in the interim, the charge should return
      is_enough: false — protecting against stale verification state

  Scenario: Human approval loop does not require a separate execute endpoint
    Given a Finance App implements a human-in-the-loop approval workflow
    When the approval loop is: verify → human approval → charge
    Then the correct LDBP flow should use POST /balance/verify followed by
      POST /transfer/charge (not a hypothetical POST /transfer/execute)
    And the charge's independent re-verification at execution time
      provides stronger protection than a pre-verified execute endpoint would

  # ===========================================================================
  # TOKEN LIFECYCLE EDGE CASES
  # ===========================================================================

  Scenario: Token expiry is cryptographically enforced — not policy-based
    Given Alice's ScopedAccountToken has reached its cryptographic expiry time
    When the Finance App calls POST /balance/verify using the expired token
    Then the response status code should be 401
    And the error_code should be "INVALID_TOKEN"
    And the token should NOT be renewable via any mechanism
    And Alice must re-authenticate and issue a new token to restore access

  Scenario: Token cannot be extended after issuance
    Given Alice has an active ScopedAccountToken
    When the Finance App attempts to extend the token's expiry
      by calling any available endpoint
    Then no mechanism should exist to extend a token's expiry without user re-consent
    And Alice must complete the full /auth/token/exchange flow
      to obtain a token with a new expiry

  Scenario: Invalid token returns 401 — not 403 — to distinguish auth failure from scope failure
    Given a Finance App presents a malformed or non-existent token
    When the Finance App calls POST /balance/verify
    Then the response status code should be 401
    And the error_code should be "INVALID_TOKEN"
    And the error should be distinguishable from a 403 ACCOUNT_SCOPE_MISMATCH
      which indicates a valid token with insufficient scope

  # ===========================================================================
  # ERROR HANDLING & RESPONSE CONSISTENCY
  # ===========================================================================

  Scenario: All error responses follow the standard ErrorResponse schema
    Given any LDBP endpoint returns an error
    When the error response is examined
    Then the response body should contain:
      | error_code | from the defined error_code enum |
      | message    | human-readable developer message |
      | request_id | unique UUID for bank audit log   |
    And the message field should NOT disclose internal system state
    And the message field should NOT disclose user account details
    And the message field should NOT disclose fraud model signals

  Scenario: 200 status on False response — HTTP status reflects evaluation success not approval
    Given a Finance App calls POST /balance/verify
    When the evaluation completes but is_enough is false
    Then the HTTP response status code should be 200
    And the HTTP status code 200 should NOT be interpreted as transaction approval
    And the Finance App should always check the is_enough Boolean — not the HTTP status code

  Scenario: Malformed request returns 400 with MALFORMED_REQUEST error code
    When the Finance App calls POST /balance/verify with a missing "amount" field
    Then the response status code should be 400
    And the error_code should be "MALFORMED_REQUEST"
    When the Finance App calls POST /balance/verify with a missing "intent_id" field
    Then the response status code should be 400
    And the error_code should be "MALFORMED_REQUEST"
    When the Finance App calls POST /balance/verify with a missing "currency" field
    Then the response status code should be 400
    And the error_code should be "MALFORMED_REQUEST"

  Scenario: IDEMPOTENCY_CONFLICT returned on duplicate idempotency key with different payload
    Given the Finance App previously submitted a transfer with X-Idempotency-Key "idem_abc"
      for $50.00
    When the Finance App submits a new transfer with the same X-Idempotency-Key "idem_abc"
      but a different amount of $75.00
    Then the response status code should be 409
    And the error_code should be "IDEMPOTENCY_CONFLICT"
    And the bank should NOT execute the second transfer

  # ===========================================================================
  # KILL SWITCH PORTAL — USER-FACING STATUS TAXONOMY
  # ===========================================================================

  Scenario: Kill Switch portal displays correct human-readable status taxonomy
    Given Alice's Kill Switch portal contains transaction log entries
    When Alice reviews her portal activity log
    Then each entry should display one of the following human-readable statuses:
      | approved                    |
      | declined_insufficient_funds |
      | declined_fraud_review       |
      | declined_rate_limit         |
      | declined_revoked            |
      | declined_cap_exceeded       |
    And no technical error codes or internal system identifiers
      should be displayed to Alice in the portal
    And these status codes should NEVER appear in API responses to Finance Apps

  Scenario: Kill Switch portal shows all Finance App connections
    Given Alice has granted ScopedAccountTokens to 3 different Finance Apps
    When Alice opens her Connected Apps portal
    Then the portal should list all 3 active Finance App connections
    And each connection should be identified by the Finance App's alias name
    And NOT by the raw alias_id technical identifier
    And each connection should have a visible single-click revoke option
