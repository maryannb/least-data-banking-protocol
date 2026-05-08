# Contributing to LDBP

**The Least Data Banking Protocol (LDBP) is a living standard.**

Implementation feedback, technical proposals, and use case contributions 
are welcomed. Approved changes will be integrated into the official LDBP 
specification to ensure industry-wide interoperability.

Proposals may be submitted via GitHub Pull Request or by contacting 
Mary Ann Belarmino at BelarminoAdvisory.com.

---

## Before You Submit

Please read the [LDBP Conformance Definition v1.0](./LDBP_CONFORMANCE.md) 
before submitting a proposal. The following constraints apply to all 
proposals and are permanent:

- Proposals that weaken any of the five Least-Data Principles (Data 
  Minimization, Purpose Limitation, Account Isolation, Notification 
  Sovereignty, User Control) will not be accepted regardless of commercial 
  rationale.
- Proposals that expand permissible data disclosure to Finance Apps will 
  not be accepted.
- Proposals that reduce user revocation rights will not be accepted.

These constraints reflect the architectural invariants of LDBP. A change 
that violates them is not an amendment to LDBP — it is a different protocol.

---

## Proposal Template

Use the following template for all proposals submitted via GitHub issue, 
Pull Request, or email.

**Subject**: LDBP Change Proposal — [Short Description]  
**Proposed by**: [Name / Organization]  
**Affected Version**: [e.g., v1.0.0]  
**Date**: [Submission date]

### 1. Change Description
Describe the specific modification to the protocol, architecture, or 
OpenAPI specification.

### 2. Rationale
Explain why this change is necessary. Does it fix a security vulnerability? 
Address a regulatory requirement? Resolve an implementation barrier? 
Improve performance or interoperability?

### 3. Least-Data Principles Impact
Assess how this change interacts with each of the five Least-Data Principles. 
Does it reduce data exposure? Does it affect the Boolean verification 
guarantee? Does it affect user control or notification sovereignty?

This is a required field. Proposals that do not address this section 
will be returned for revision.

### 4. Conformance Impact
Does this change affect any conformance requirement in C-01 through C-08? 
If yes, specify which requirement(s) and explain the proposed revision.

### 5. Proposed Specification Change
```yaml
# Insert proposed YAML, schema, or requirement language here
```

### 6. Intellectual Property Agreement
By submitting this proposal, the submitter agrees that if the change is 
accepted and integrated into the official LDBP specification, it will be 
governed by the project's existing CC BY 4.0 license. The submitter 
acknowledges that Mary Ann Belarmino (BelarminoAdvisory.com) is the 
Lead Architect and Sole Maintainer of the official LDBP specification 
and retains final authority over all accepted changes.

---

## Types of Contributions

**Amendment proposals** — changes to protocol requirements, endpoint 
behavior, or conformance criteria. Use the template above. Open as a 
GitHub issue with the label `amendment-proposal`.

**Implementation reports** — share how your institution has adopted or 
piloted LDBP. Open as a GitHub issue with the label `implementation-report`. 
Implementation reports are valuable for informing future versions.

**Specification bugs** — errors, ambiguities, or inconsistencies in the 
API spec, PRD, or Conformance Definition. Open as a GitHub issue with 
the label `spec-bug`.

**Future work contributions** — proposals addressing items in the Future 
Work section (federated fraud signals, ZKP integration, BNPL 
creditworthiness signal, agentic authorization standard, OpenID Connect 
profile). These are actively invited. Use the label `future-work`.

---

## What Happens After Submission

1. Mary Ann Belarmino reviews the proposal against the five Least-Data 
   Principles and the Conformance Definition.
2. Proposals that pass the initial review are published for community 
   comment via the GitHub issue thread.
3. Accepted proposals are incorporated into the next versioned release 
   with attribution to the proposer in the Document History.
4. Declined proposals receive a written explanation referencing the 
   specific principle or conformance requirement that prevents acceptance.

---

© 2026 Mary Ann Belarmino. BelarminoAdvisory.com. CC BY 4.0.
