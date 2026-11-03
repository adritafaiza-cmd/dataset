# Resolved in benchmark v2

The typed DUT is elaborated through a flat wrapper using Slang; the symbolic
harness and assertions are loaded with the native formal frontend. An explicit
clock net crosses the frontend boundary. The old harness lost symbolic/clock
semantics and did not provide a sound golden PASS.

The revised harness models both register address ranges, partial byte strobes,
readback, state persistence, and asynchronous reset cancellation. It includes
reachable write/read covers. The RTL also corrects the initialization-state
feedback and limits writes to the APB access phase. Enhanced strobe expectations
now preserve unstrobed bytes rather than encoding the old clearing behavior.
