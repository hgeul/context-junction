# ADR-001: AI Workspace Status Derivation

## Status

Accepted

## Date

2026-08-24

## Context

The v0.1 workspace needs useful status output before plan and ADR metadata schemas exist.

## Decision

Derive research status only from matching request and result IDs: a request without a result is `WAITING`; a request with a result is `DONE`. Count plans as a total until a plan status schema exists.

## Alternatives

### Add draft and active status fields now

This adds a schema and lifecycle that v0.1 has not validated.

### Infer plan status from filenames or document text

This would be unreliable and create undocumented conventions.

## Rationale

Matching IDs provide an objective, file-based research state, while total plan count avoids claiming precision the protocol does not yet support.

## Consequences

### Positive

- The first CLI can report stable research counts without parsing free-form content.
- The protocol remains minimal for dogfooding.

### Negative

- Plan lifecycle progress is not visible in v0.1 status output.

## Related Research

- None; this is a repository protocol decision.

## Revisit When

- Dogfooding establishes a stable plan status schema.
- CLI consumers need plan lifecycle counts.
