# Skill Index

This directory contains local workflow skills for Enterprise SDD.

Curated skills are stored under `.github/skills/`.

## Available Skills

- memory-loop: enforce status -> doctor -> sync cadence before gates
- traceability-audit: verify US/AC/T/TC references before Gate 3
- extension-safety: check namespace/core immutability before extension install

## Curated Skills

- sdd-auto-implement: incremental implementation flow with gate-safe stop points
- sdd-challenge: assumption challenge flow with confidence and risk scoring

## Command Surface

- sdd skill list
- sdd skill validate <name>
- sdd skill run <name> <feature-id> [--dry-run]
- sdd skill validate-mapping
- sdd skill install <path> [--explain-policy]
- sdd skill adopt <path>
