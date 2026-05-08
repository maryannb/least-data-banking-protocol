# =============================================================================
# LDBP Phase 1 Acceptance Criteria
# Least Data Banking Protocol — Clean Pipe MVP
#
# Endpoints covered:
#   POST /auth/token/exchange
#   POST /auth/token/revoke
#   POST /balance/verify
#   POST /transfer/charge
#
# Conformance reference: LDBP Conformance Definition v1.0 (C-01 through C-07)
# API Spec reference:    ldbp_api_v1.yaml
# Author:                Mary Ann Belarmino — BelarminoAdvisory.com
# License:               CC BY 4.0
# =============================================================================

Feature: LDBP Phase 1 — Clean Pipe Compliance
  As a Banking Platform Administrator,
  I want to ensure all Phase 1 LDBP endpoints strictly enforce
  data minimization, account isolation, atomic execution,
  notification sovereignty, and user control principles,
  so that every Finance App connecting to this bank
  automatically operates under least-data principles.

  Background:
    Given the bank has implemented a LDBP-compliant API Gateway
    And the Policy Enforcement Point (PEP) is active
    And a test user "Alice" exists with a Checking account containing $1,000
    And a test user "Bob" exists with a Checking account containing $50

  # ===========================================================================
  # C-03: ACCOUNT ISOLATION — /auth/token/exchange
  # ===========================================================================

  Scenario: Successful scoped token issuance for one user-selected account
    Given Alice has authenticated with the bank
    And Alice has selected her Checking account in the account selector UI
    When the Finance App calls POST /auth/token/exchange with:
      | user_selected_account_id | alice_checking_001        |
      | finance_app_id           | app_stripe_test           |
      | consent_scope            | ["balance:verify"]        |
    Then the response status code should be 200
    And the response body should contain a "scoped_account_token"
    And the response body should contain an "alias_id"
    And the response body should contain "account_type": "checking"
    And the response body should NOT contain a raw DDA account number
    And the response body should NOT contain a routing number
    And the alias_id should be unique to the Finance App "app_stripe_test"

  Scenario: Token is mathematically restricted to the selected account only
    Given Alice has been issued a ScopedAccountToken for her Checking account
    When the Finance App calls POST /balance/verify using that token
      | amount    | 100.00 |
      | intent_id | int_abc_001 |
      | currency  | USD |
    Then the PEP should only evaluate Alice's Checking account
    And the PEP should NOT evaluate Alice's Savings account
    And the PEP should NOT evaluate any other accounts at the bank

  Scenario: Token exchange rejected when Finance App requests unapproved scope
    Given Alice has authenticated with the bank
    When the Finance App calls POST /auth/token/exchange with:
      | user_selected_account_id | alice_checking_001                     |
      | finance_app_id           | app_stripe_test                        |
      | consent_scope            | ["balance:verify", "history:read"]     |
    Then the response status code should be 403
    And the error_code should be "ACCOUNT_SCOPE_MISMATCH"

  Scenario: Token exchange requires explicit transfer:charge scope for execution
    Given Alice has authenticated with the bank
    When the Finance App calls POST /auth/token/exchange with:
      | user_selected_account_id | alice_checking_001   |
      | finance_app_id           | app_stripe_test      |
      | consent_scope            | ["balance:verify"]   |
    Then the response status code should be 200
    And the issued token should NOT include transfer:charge scope
    When the Finance App subsequently calls POST /transfer/charge using that token
    Then the response status code should be 403
    And the error_code should be "ACCOUNT_SCOPE_MISMATCH"

  # ===========================================================================
  # C-01, C-02: DATA MINIMIZATION — /balance/verify
  # ===========================================================================

  Scenario: Boolean verification returns True with no raw financial data
    Given Alice has a valid ScopedAccountToken with scope "balance:verify"
    When the Finance App calls POST /balance/verify with:
      | amount    | 250.00      |
      | intent_id | int_abc_002 |
      | currency  | USD         |
    Then the response status code should be 200
    And the response body should contain "is_enough": true
    And the response body should contain "intent_id": "int_abc_002"
    And the response body should contain "evaluated_at"
    And the response body should NOT contain any field named "balance"
    And the response body should NOT contain any field named "amount_available"
    And the response body should NOT contain any field named "current_balance"
    And the response body should NOT contain a raw account number
    And the response body should NOT contain transaction history
    And the response body should NOT contain merchant data

  Scenario: Boolean verification returns False with no reason code exposed
    Given Bob has a valid ScopedAccountToken with scope "balance:verify"
    And Bob's account contains $50
    When the Finance App calls POST /balance/verify with:
      | amount    | 200.00      |
      | intent_id | int_abc_003 |
      | currency  | USD         |
    Then the response status code should be 200
    And the response body should contain "is_enough": false
    And the response body should NOT contain a reason_code field
    And the response body should NOT contain an error_reason field
    And the response body should NOT disclose whether the reason is insufficient funds

  Scenario: False due to fraud flag is indistinguishable from False due to insufficient funds
    Given the bank's internal fraud model flags a transaction as suspicious
    When the Finance App calls POST /balance/verify for that transaction
    Then the response status code should be 200
    And the response body should contain "is_enough": false
    And the response body should be identical in structure to a False due to insufficient funds
    And the Finance App should receive no signal that a fraud flag was triggered
    And the bank should simultaneously send a verification.blocked webhook to the authenticated user

  Scenario: Composite atomic verification — balance and fraud evaluated together
    Given Alice has a valid ScopedAccountToken
    When the Finance App calls POST /balance/verify
    Then the bank's PEP should evaluate balance sufficiency AND fraud risk
      in a single atomic operation
    And the bank's PEP should NOT perform balance check and fraud check
      as separate sequential API calls

  Scenario: Verification response contains only the three permitted fields
    Given Alice has a valid ScopedAccountToken
    When the Finance App calls POST /balance/verify with a valid request
    Then the response body on a True result should contain ONLY:
      | field        | type    |
      | is_enough    | boolean |
      | intent_id    | string  |
      | evaluated_at | string  |
    And the response body should contain no additional fields

  # ===========================================================================
  # C-02: RATE LIMITING — Binary Search Attack Prevention
  # ===========================================================================

  Scenario: Rate limit enforced at institution-defined limit per scoped token
    Given Alice has a valid ScopedAccountToken
    And the Finance App has exceeded the institution-defined rate limit for POST /balance/verify in the current hour
    When the Finance App makes another POST /balance/verify call
    Then the response status code should be 429
    And the response should include a "X-RateLimit-Reset" header
      with the ISO 8601 timestamp when the window resets
    And the bank should send a verification.blocked webhook to Alice
      with reason "declined_rate_limit"

  Scenario: Rate limit applies per scoped token not per Finance App
    Given two users Alice and Bob each have valid ScopedAccountTokens
      issued to the same Finance App "app_stripe_test"
    And Alice's token has exceeded the institution-defined rate limit this hour
    When the Finance App calls POST /balance/verify using Bob's token
    Then the response status code should be 200
    And Bob's request should succeed normally

  # ===========================================================================
  # C-07: INTENT-ID INTEGRITY
  # ===========================================================================

  Scenario: Intent-ID is single-use and invalidated after True verification
    Given Alice has a valid ScopedAccountToken with scope "transfer:charge"
    And the Finance App generated Intent-ID "int_xyz_100"
    When the Finance App calls POST /transfer/charge with intent_id "int_xyz_100"
    And the charge returns is_enough: true and is executed
    When the Finance App calls POST /transfer/charge again with the same intent_id "int_xyz_100"
    Then the response status code should be 409
    And the error_code should be "INTENT_ID_CONSUMED"

  Scenario: Intent-ID is invalidated immediately on a False response
    Given Bob has a valid ScopedAccountToken with scope "balance:verify"
    And Bob's account contains $50
    And the Finance App generated Intent-ID "int_xyz_101"
    When the Finance App calls POST /balance/verify with:
      | amount    | 200.00      |
      | intent_id | int_xyz_101 |
    Then the response should return "is_enough": false
    And intent_id "int_xyz_101" should be immediately invalidated
    When the Finance App retries POST /balance/verify with the same intent_id "int_xyz_101"
    Then the response status code should be 409
    And the error_code should be "INTENT_ID_CONSUMED"

  # ===========================================================================
  # C-04: ATOMIC EXECUTION — /transfer/charge
  # ===========================================================================

  Scenario: Successful atomic verify-and-execute charge
    Given Alice has a valid ScopedAccountToken with scope "transfer:charge"
    When the Finance App calls POST /transfer/charge with:
      | amount              | 50.00              |
      | intent_id           | int_charge_001     |
      | currency            | USD                |
      | X-Idempotency-Key   | idem_key_charge_01 |
    Then the response status code should be 201
    And the response body should contain "is_enough": true
    And the response body should contain a "transfer_id"
    And the response body should contain "executed_at"
    And the response body should NOT contain a raw account number
    And the response body should NOT contain a raw balance
    And Alice's account should be debited $50 exactly once

  Scenario: Charge fails cleanly when funds are insufficient — False is opaque
    Given Bob has a valid ScopedAccountToken with scope "transfer:charge"
    And Bob's account contains $50
    When the Finance App calls POST /transfer/charge with:
      | amount    | 200.00         |
      | intent_id | int_charge_002 |
      | currency  | USD            |
    Then the response status code should be 200
    And the response body should contain "is_enough": false
    And the response body should NOT contain a "transfer_id"
    And the response body should NOT contain a reason_code
    And Bob's account balance should be unchanged

  Scenario: Charge atomically combines verification and execution in one PEP operation
    Given Alice has a valid ScopedAccountToken with scope "transfer:charge"
    When the Finance App calls POST /transfer/charge
    Then the bank's PEP should evaluate balance sufficiency, fraud risk,
      and execute fund deduction in a single locked database operation
    And there should be NO window between the balance check and the debit
      during which funds could be spent elsewhere

  Scenario: Idempotency key prevents double-charging on network retry
    Given Alice has a valid ScopedAccountToken with scope "transfer:charge"
    And the Finance App calls POST /transfer/charge with:
      | amount            | 75.00          |
      | intent_id         | int_charge_003 |
      | currency          | USD            |
      | X-Idempotency-Key | idem_key_003   |
    And the first request results in 201 Created
    When the Finance App retries the exact same request
      with the same X-Idempotency-Key "idem_key_003"
    Then the response status code should be 201
    And Alice's account should be debited $75 exactly once
    And the bank ledger should show only one debit for intent_id "int_charge_003"

  Scenario: Expired scoped token is rejected on charge
    Given Alice's ScopedAccountToken has passed its cryptographic expiry time
    When the Finance App calls POST /transfer/charge using the expired token
    Then the response status code should be 401
    And the error_code should be "INVALID_TOKEN"

  # ===========================================================================
  # C-04: TRANSFER:CHARGE SCOPE REQUIREMENT
  # ===========================================================================

  Scenario: Charge endpoint requires explicit transfer:charge scope
    Given Alice has a ScopedAccountToken with scope "balance:verify" only
    When the Finance App calls POST /transfer/charge
    Then the response status code should be 403
    And the error_code should be "ACCOUNT_SCOPE_MISMATCH"

  # ===========================================================================
  # C-05: NOTIFICATION SOVEREIGNTY
  # ===========================================================================

  Scenario: Fraud flag triggers bank-to-user webhook — app receives only False
    Given the bank's internal fraud model flags a verification request
    When the Finance App calls POST /balance/verify
    Then the Finance App response should be:
      | status_code | 200              |
      | is_enough   | false            |
    And the response should contain NO reason code indicating fraud
    And the bank should simultaneously send a verification.blocked webhook
      to the authenticated user containing:
      | event     | verification.blocked    |
      | app_alias | (Finance App alias_id)  |
      | intent_id | (the request intent_id) |
      | reason    | declined_fraud_review   |
    And the webhook should NOT be sent to the Finance App

  Scenario: Insufficient funds does NOT trigger a verification.blocked webhook
    Given Bob's account contains $50
    When the Finance App calls POST /balance/verify for $200
    Then the response should return "is_enough": false
    And the bank should NOT send a verification.blocked webhook to Bob
    And no security notification should be triggered

  Scenario: Real-time Consent Receipt sent to user after successful transfer
    Given Alice has a valid ScopedAccountToken with scope "transfer:charge"
    When the Finance App calls POST /transfer/charge and receives 201 Created
    Then the bank should send a Consent Receipt notification to Alice containing:
      | amount         | the charged amount         |
      | app_alias      | the Finance App alias name |
      | consent_policy | the applicable policy      |
    And the notification should be sent within 30 seconds of execution

  # ===========================================================================
  # C-05, C-06: KILL SWITCH — /auth/token/revoke
  # ===========================================================================

  Scenario: Kill Switch immediately terminates Finance App access
    Given Alice has a valid ScopedAccountToken issued to "app_stripe_test"
    When Alice calls POST /auth/token/revoke with her ScopedAccountToken
    Then the response status code should be 200
    And the response body should contain "revoked_at" timestamp
    And the response body should contain the "alias_id" of the revoked connection
    When the Finance App subsequently calls POST /balance/verify
      using the revoked token
    Then the response status code should be 403
    And the error_code should be "TOKEN_REVOKED"

  Scenario: Kill Switch revocation takes effect in under one second
    Given Alice has a valid ScopedAccountToken
    When Alice calls POST /auth/token/revoke
    Then within 1 second the Finance App should receive 403 TOKEN_REVOKED
      on any subsequent API call using that token

  Scenario: Kill Switch invalidates all pending Intent-IDs for that token
    Given Alice has a valid ScopedAccountToken
    And the Finance App has a pending Intent-ID "int_pending_001" for that token
    When Alice calls POST /auth/token/revoke
    Then intent_id "int_pending_001" should be immediately invalidated
    When the Finance App attempts to use intent_id "int_pending_001"
    Then the response should return 403 TOKEN_REVOKED or 409 INTENT_ID_INVALID

  Scenario: Kill Switch requires no action from the Finance App
    Given Alice has a valid ScopedAccountToken
    When Alice calls POST /auth/token/revoke from her bank's Connected Apps portal
    Then the Finance App should receive NO notification or reason for the revocation
    And access should be terminated without any Finance App involvement
