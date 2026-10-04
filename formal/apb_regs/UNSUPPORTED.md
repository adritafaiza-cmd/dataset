# Unsupported for a sound golden PASS

Slang can elaborate the typed APB structs, but BMC does not preserve the
combo identity `resp.pready == (psel && penable)` that is written in
`apb_regs.sv`. Shipping a cover-only contract would make every candidate
look proved. This circuit stays unscored until that struct-port mapping
is trusted.
