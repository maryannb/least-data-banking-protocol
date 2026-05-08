# =============================================================================
# LDBP Phase 2 Acceptance Criteria
# Least Data Banking Protocol — Risk Capping & Governance Extension
#
# Endpoints covered:
#   GET  /governance/permission-budget
#   POST /batch/balance/verify
#   POST /batch/transfer/charge
#   GET  /billing/metering
#   POST /webhooks/verification.blocked
#
# Conformance reference: LDBP Conformance Definition v1.0 (C-08)
# API Spec reference:    ldbp_api_v1.yaml
# Author:                Mary Ann Belarmino — BelarminoAdvisory.com
# License:               CC BY 4.0
# =============================================================================

Feature: LDBP Phase 2 — Risk Capping & Governance Compliance
  As a Banking Platform Administrator,
  I want to ensure all Phase 2 LDBP endpoints enforce Virtual Allowances,
  batch atomicity, notification sovereignty, and bank monetization,
  while maintaining all Phase 1 least-data guarantees at batch scale.

  Background:
    Given the bank has implemented a LDBP-compliant API Gateway
    And Phase 1 endpoints are fully operational and compliant
    And a test user "Alice" exists with a Checking account containing $2,000
    And a Virtual Allowance policy of $500/week is configured for Alice
    And a test user "Bob" exists with a Checking account containing $100

  # ===========================================================================
  # VIRTUAL ALLOWANCE — /governance/permission-budget
  # ===========================================================================

  Scenario: Permission budget returns remaining allowance — no raw balance
    Given Alice has a valid ScopedAccountToken with scope "governance:read"
    And Alice has spent $200 in the current weekly allowance period
    When the Finance App calls GET /governance/permission-budget
    Then the response status code should be 200
    And the response body should contain "remaining_budget": 300.00
    And the response body should contain "period_type": "weekly"
    And the response body should contain "period_resets_at"
    And the response body should NOT contain Alice's raw account balance
    And the response body should NOT contain Alice's transaction history

  Scenario: Permission budget is a threshold value not an account balance
    Given Alice's Checking account contains $2,000
    And Alice's weekly Virtual Allowance cap is $500
    And Alice has spent $200 this week
    When the Finance App calls GET /governance/permission-budget
    Then the response body should return "remaining_budget": 300.00
    And the remaining_budget should reflect the governance cap delta
      NOT the account balance

  Scenario: PEP rejects verification when weekly cap is exhausted
    Given Alice has exhausted her $500 weekly Virtual Allowance
    When the Finance App calls POST /balance/verify for any amount
    Then the response status code should be 200
    And the response body should contain "is_enough": false
    And the bank should send a verification.blocked webhook to Alice
      with reason "declined_cap_exceeded"
    And the Finance App should receive NO indication that a cap was hit

  Scenario: No permission budget configured returns 404
    Given a ScopedAccountToken exists for a user with no Virtual Allowance configured
    When the Finance App calls GET /governance/permission-budget
    Then the response status code should be 404

  # ===========================================================================
  # C-08, C-01: BATCH VERIFICATION — /batch/balance/verify
  # ===========================================================================

  Scenario: Batch verification returns per-intent Boolean results — informational only
    Given Alice has a valid ScopedAccountToken with scope "balance:verify"
    When the Finance App calls POST /batch/balance/verify with 3 intents:
      | intent_id      | amount  |
      | int_batch_001  | 100.00  |
      | int_batch_002  | 50.00   |
      | int_batch_003  | 800.00  |
    Then the response status code should be 200
    And the response body should contain a "results" array with 3 entries
    And each result should contain ONLY: intent_id, is_enough, evaluated_at
    And the result for int_batch_001 should return is_enough: true
    And the result for int_batch_002 should return is_enough: true
    And the result for int_batch_003 should return is_enough: false
    And the response should contain a "summary" with:
      | total          | 3 |
      | verified_true  | 2 |
      | verified_false | 1 |

  Scenario: Batch verification does NOT move or earmark funds
    Given Alice has a valid ScopedAccountToken with scope "balance:verify"
    When the Finance App calls POST /batch/balance/verify with 5 intents
    Then the response status code should be 200
    And Alice's account balance should be UNCHANGED
    And no funds should be earmarked, held, or reserved for any intent
    And Alice's transaction ledger should show no pending debits

  Scenario: Batch verification returns no raw financial data
    Given Alice has a valid ScopedAccountToken
    When the Finance App calls POST /batch/balance/verify
    Then each result entry in the response should NOT contain:
      | balance          |
      | amount_available |
      | account_number   |
      | transaction_data |
      | merchant_info    |
    And all False results should be opaque — no reason code exposed

  Scenario: Partial False results in batch are valid — some True some False
    Given Alice has a valid ScopedAccountToken
    When the Finance App calls POST /batch/balance/verify with intents
      where some amounts exceed available funds
    Then the response status code should be 200
    And some results may return is_enough: true
    And some results may return is_enough: false
    And partial success is expected and valid

  Scenario: Batch verification is informational — results do NOT authorize execution
    Given Alice has a valid ScopedAccountToken with scopes "balance:verify" and "transfer:charge"
    And the Finance App has called POST /batch/balance/verify and received True results
    When the Finance App calls POST /batch/transfer/charge
    Then the batch charge endpoint should perform its own independent
      atomic verification per intent at execution time
    And the batch verify results should NOT be consumed as authorization tokens

  Scenario: Batch verification rate limiting applies across single and batch calls
    Given Alice has made calls up to the institution-defined rate limit for POST /balance/verify this hour
    When the Finance App calls POST /batch/balance/verify with additional intents
    Then the response status code should be 429
    And each intent in the batch counts as one call against the rate limit
    And the X-RateLimit-Reset header should indicate the reset time

  Scenario: False result in batch triggers verification.blocked webhook per intent
    Given the bank's fraud model flags one intent in a batch
    When the Finance App calls POST /batch/balance/verify
    Then the flagged intent should return is_enough: false in the results
    And the Finance App response should contain NO fraud signal for that intent
    And the bank should send a verification.blocked webhook to the authenticated user
      for the flagged intent only
    And the webhook should NOT be sent to the Finance App

  Scenario: Batch size must meet minimum of 2 intents; maximum is institution-defined
    Given Alice has a valid ScopedAccountToken
    When the Finance App calls POST /batch/balance/verify with 1 intent
    Then the response status code should be 400
    And the error_code should be "MALFORMED_REQUEST"
    When the Finance App calls POST /batch/balance/verify with more intents than the institution-defined maximum
    Then the response status code should be 400
    And the error_code should be "MALFORMED_REQUEST"

  # ===========================================================================
  # C-08, C-04: BATCH ATOMIC EXECUTION — /batch/transfer/charge
  # ===========================================================================

  Scenario: Batch charge atomically executes multiple intents — partial success valid
    Given Alice has a valid ScopedAccountToken with scope "transfer:charge"
    When the Finance App calls POST /batch/transfer/charge with 3 intents:
      | intent_id      | amount  |
      | int_bc_001     | 50.00   |
      | int_bc_002     | 75.00   |
      | int_bc_003     | 5000.00 |
    Then the response status code should be 207
    And the result for int_bc_001 should show is_enough: true with a transfer_id
    And the result for int_bc_002 should show is_enough: true with a transfer_id
    And the result for int_bc_003 should show is_enough: false with no transfer_id
    And the response summary should contain:
      | total    | 3 |
      | executed | 2 |
      | declined | 1 |

  Scenario: Batch charge performs atomic verify+execute per intent — no gap
    Given Alice has a valid ScopedAccountToken with scope "transfer:charge"
    When the Finance App calls POST /batch/transfer/charge
    Then for each intent, the bank's PEP should evaluate balance sufficiency,
      fraud risk, and execute fund deduction in a single locked database operation
    And there should be NO window between verification and execution for any intent
    And the batch should NOT implement a separate verify-then-execute flow

  Scenario: Batch charge is independent of batch verify results
    Given Alice has called POST /batch/balance/verify and received True results
    When Alice's account balance changes before calling POST /batch/transfer/charge
    Then POST /batch/transfer/charge should re-verify at execution time
    And an intent that was True at verify time may return False at charge time
      if funds are no longer available
    And this is correct and expected behavior

  Scenario: Batch charge idempotency prevents duplicate execution on retry
    Given Alice has a valid ScopedAccountToken with scope "transfer:charge"
    And the Finance App calls POST /batch/transfer/charge with X-Idempotency-Key "batch_idem_001"
    And the first request results in 207 Multi-Status
    When the Finance App retries the exact same batch request
      with the same X-Idempotency-Key "batch_idem_001"
    Then the response status code should be 207
    And Alice's account should reflect only the original execution amounts
    And no intent should be executed more than once

  Scenario: C-08.3 — A separate /batch/transfer/execute endpoint must NOT exist
    When the Finance App attempts to call POST /batch/transfer/execute
    Then the response status code should be 404
    And no endpoint matching this pattern should be available
    And the only supported batch execution path should be POST /batch/transfer/charge

  Scenario: Batch charge False results are opaque — no reason code per intent
    Given a batch contains intents that fail for different internal reasons
    When the Finance App calls POST /batch/transfer/charge
    Then all False intent results should contain ONLY: intent_id, is_enough: false, evaluated_at
    And no False result should contain a reason_code
    And all False results should be structurally identical regardless of the failure cause

  Scenario: Batch charge requires transfer:charge scope
    Given Alice has a ScopedAccountToken with "balance:verify" scope only
    When the Finance App calls POST /batch/transfer/charge
    Then the response status code should be 403
    And the error_code should be "ACCOUNT_SCOPE_MISMATCH"

  # ===========================================================================
  # BILLING METERING — /billing/metering
  # ===========================================================================

  Scenario: Billing metering returns fee attribution — no user financial data
    Given a registered Finance App "app_stripe_test" has made
      10 /balance/verify calls and 5 /transfer/charge calls this billing period
    When the Finance App calls GET /billing/metering
      with X-Client-Billing-ID "client_stripe_prod_001"
    Then the response status code should be 200
    And the response body should contain:
      | execution_calls     | 5    |
      | accrued_total       | (calculated fee based on execution events) |
      | basis_points_rate   | (institution-defined rate) |
    And the response body MAY contain:
      | verification_calls  | 10   |
    And if verification_calls is present it should be labeled for operational reporting
    And whether verification calls contribute to accrued_total is institution-defined
    And the response body should NOT contain any user account balances
    And the response body should NOT contain any user transaction data
    And the response body should NOT contain any user personal information

  Scenario: Billing metering requires valid X-Client-Billing-ID
    When the Finance App calls GET /billing/metering without X-Client-Billing-ID
    Then the response status code should be 400
    And the error_code should be "MALFORMED_REQUEST"

  # ===========================================================================
  # C-05: WEBHOOKS — verification.blocked
  # ===========================================================================

  Scenario: verification.blocked webhook delivered to user — never to Finance App
    Given the bank's PEP has blocked a verification for any reason
    When the bank triggers a verification.blocked event
    Then the webhook payload should be delivered to the authenticated user's
      registered notification channel (push, SMS, or email)
    And the webhook should NOT be delivered to the Finance App
    And the webhook should NOT be accessible via any Finance App API endpoint
    And the webhook payload should contain:
      | event     | verification.blocked    |
      | timestamp | ISO 8601 timestamp      |
      | app_alias | opaque Finance App ID   |
      | intent_id | the blocked intent      |
      | reason    | from approved taxonomy  |

  Scenario: verification.blocked uses only approved reason taxonomy
    Given a verification is blocked for various internal reasons
    When the bank sends verification.blocked webhooks
    Then each webhook reason field should be one of:
      | declined_insufficient_funds |
      | declined_fraud_review       |
      | declined_rate_limit         |
      | declined_revoked            |
      | declined_cap_exceeded       |
    And no other reason values should be used
    And the reason codes should NEVER appear in any API response to Finance Apps

  Scenario: verification.blocked includes portal_url for Kill Switch deep link
    Given a verification is blocked
    When the bank sends the verification.blocked webhook to the user
    Then the webhook payload should contain a "portal_url" field
    And the portal_url should deep-link to the specific event in the Kill Switch portal
    And the user should be able to view the event details and take action from that URL

  Scenario: Insufficient funds False does NOT trigger verification.blocked webhook
    Given Bob's account contains $100
    When the Finance App calls POST /balance/verify for $500
    Then the response should return is_enough: false
    And the bank should NOT send a verification.blocked webhook
    And no security notification of any kind should be sent to Bob

  # ===========================================================================
  # PHASE 2 — CONFORMANCE BOUNDARY
  # ===========================================================================

  Scenario: Phase 2 endpoints are optional — Phase 1 compliance is independent
    Given a bank has implemented only Phase 1 endpoints
    When a compliance review is conducted
    Then the bank should be assessed as "Phase 1 LDBP Conformant"
    And the absence of Phase 2 endpoints should NOT disqualify Phase 1 conformance
    And the bank's Phase 1 conformance claim should include the qualifier:
      "Phase 1 LDBP Conformant — Phase 2 features not implemented"
