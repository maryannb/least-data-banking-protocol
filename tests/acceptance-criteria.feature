Feature: Least Data Banking Protocol Compliance
As a Banking Platform Administrator, 
I want to ensure the API strictly adheres to "Least Data" and "Idempotency" standards, 
so that user privacy is protected and financial transactions are immutable.

Scenario: Verify "Least Data" enforcement on balance check
Given a valid Scoped_Account_Token for a user with exactly $500 in their account 
When the Finance App calls POST /balance/verify with an amount of $250 
Then the response status code should be 200 
And the response body should contain "is_enough": true 
And the response body should not contain any field named "balance" or "amount_available" 
And the response body should not contain the user's raw account number

Scenario: Prevent data harvesting via "Binary Search" (Rate Limiting)
Given a Finance App has made 5 successful is_enough calls within the last 60 seconds 
When the Finance App calls POST /balance/verify for a 6th time 
Then the response status code should be 429 
And the error message should indicate "Rate limit exceeded for privacy protection"

Scenario: Ensure transaction idempotency for money movement
Given a Finance App initiates a transfer with X-Idempotency-Key: "txn-unique-7788" 
And the first request results in a 201 Created status 
When the Finance App retries the exact same request with the same X-Idempotency-Key 
Then the response status code should be 200 
And the Bank Core Ledger should show only one debit of the specified amount 
And the response should include a header or body flag indicating the request was "idempotent_duplicate"

Scenario: Enforce Time-Bound Scoped Consent
Given a Scoped_Account_Token was issued with a "Weekly" duration 
And the token was issued more than 7 days ago 
When the Finance App calls POST /transfer/execute 
Then the response status code should be 403 
And the error code should be "CONSENT_EXPIRED" 
And the user should be prompted via a webhook to re-authorize the link
