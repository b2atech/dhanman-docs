# ADR 0001  Use PostgreSQL 18

## Status
Accepted

## Context
PostgreSQL provides advanced JSONB, replication, and procedural extensions (PL/pgSQL) used across modules.

## Decision
Use PostgreSQL 18 for all environments with streaming replication for HA.

## Consequences
Requires versioned schema sync across QA/Prod using nightly jobs.
