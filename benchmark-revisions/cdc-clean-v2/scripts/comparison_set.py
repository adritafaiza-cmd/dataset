"""Which generated RTL is in the comparison set.

The 16 repaired circuits use the generations made after the repair.
The other circuits keep their earlier pass@10 results.
archive/broken-16-pre-repair is not part of any comparison.
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

FIXED_16 = frozenset(
    {
        "afifo",
        "apb_cdc",
        "apbxclk",
        "async_bidir_fifo",
        "async_bidir_ramif_fifo",
        "async_fifo",
        "async_fifo_sv",
        "axis_async_fifo",
        "axis_async_fifo_adapter",
        "axixclk",
        "cdc_2phase_clearable",
        "cdc_fifo_2phase",
        "cdc_fifo_gray",
        "cdc_fifo_gray_clearable",
        "cdc_reset_ctrlr",
        "wbxclk",
    }
)

# Roots scanned for generated RTL. A root listed in ONLY_THESE_CIRCUITS
# contributes only those circuits; Qwen 3.5 also contains the other 28,
# and those copies are not the comparison set.
EXPERIMENT_ROOTS = [
    ROOT / "experiments/complexvcoder-3prompt-10attempt-v1",
    ROOT / "experiments/rtlcoder-deepseek-3prompt-10attempt-v1",
    ROOT / "experiments/multi-llm-3prompt-v1/openrouter",
    ROOT / "experiments/multi-llm-observable-v1/openrouter",
    ROOT / "experiments/llama-16fix-3prompt-10attempt-v1/openrouter",
    ROOT / "experiments/qwen35-3prompt-10attempt-v1",
    ROOT / "experiments/qwen25-16fix-3prompt-10attempt-v1/openrouter",
    ROOT / "experiments/qwen38-27b-3prompt-10attempt-v1",
]

ONLY_THESE_CIRCUITS = {
    ROOT / "experiments/qwen35-3prompt-10attempt-v1": FIXED_16,
}
