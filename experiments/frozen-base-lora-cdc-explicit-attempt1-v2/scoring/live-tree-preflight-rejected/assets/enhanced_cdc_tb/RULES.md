# Enhanced testbench violation records

Enhanced testbenches emit one typed record for every detected error:

```text
CDC/RESET VIOLATION [RULE_ID]: circuit-specific evidence
PROTOCOL VIOLATION [RULE_ID]: circuit-specific evidence
```

`RULE_ID` is stable uppercase snake case. A final `TESTS FAILED (N)` line is
only a summary and is not itself attributed to CDC.

## Classification

- `CDC/RESET VIOLATION` covers cross-domain synchronization, reset-domain
  crossing, reset sequencing, handshake transfer, pulse crossing, FIFO
  coherency/order, and cross-domain bundled-data stability.
- `PROTOCOL VIOLATION` covers local functional or bus-protocol behavior that
  does not by itself establish a CDC/reset defect.
- `TIMEOUT` is an infrastructure/liveness status and is not automatically a
  design or CDC failure.
- An untyped `TESTS FAILED` remains ambiguous and enters manual review.

The result parser preserves every typed line, including its rule ID, message,
log path, and stage. A CDC/reset finding is confirmed automatically only when
the candidate compiles and a typed CDC/reset record or structured CDC lint
finding is attributable to that candidate.

## Detection boundary

These procedural monitors detect digital manifestations of CDC/reset defects.
They do not simulate analog metastability or establish MTBF. Structural RTL
lint remains a separate strict-pass gate for synchronization structures that
cannot be proven through ordinary digital simulation.
