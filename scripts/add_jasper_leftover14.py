#!/usr/bin/env python3
"""Add JasperGold CDC scripts for the 14 leftover Verilog CDC benches."""

from __future__ import annotations

from pathlib import Path

ROOT = Path("/home/ft2335/dataset")
BENCH = ROOT / "benchmarks"


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def tcl(
    bench: str,
    top: str,
    rtl: list[str],
    clocks: list[str],
    reset_lines: list[str],
    port_blocks: list[tuple[str, list[str]]],
    analyze: str = "-v2k",
    extra_analyze: str = "",
    bbox: bool = False,
) -> str:
    rtl_list = " \\\n    ".join(rtl)
    clock_cmds = "\n".join(f"clock {c}" for c in clocks)
    reset_cmds = "\n".join(reset_lines)
    port_cmds = []
    for clk, ports in port_blocks:
        joined = " \\\n     ".join(ports)
        port_cmds.append(
            f"config_rtlds -port \\\n    {{{joined}}} \\\n    -clock {clk}"
        )
    ports = "\n".join(port_cmds)
    elab = "elaborate -bbox_a 50000 -top $TOP" if bbox else "elaborate -top $TOP"
    extra = f" {extra_analyze}" if extra_analyze else ""
    return f"""# JasperGold CDC run: {bench}
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/{bench}/jasper/run.tcl

set TOP      {top}
set BENCH_DIR $env(DS)/benchmarks/{bench}
set SDC_FILE $BENCH_DIR/constraints/{bench}.sdc
set RPT_DIR  $env(DS)/build/jasper/{bench}

set RTL_FILES [list \\
    {rtl_list}
]

file mkdir $RPT_DIR
clear -all
analyze {analyze}{extra} {{*}}$RTL_FILES
{elab}

read_sdc $SDC_FILE
check_cdc -init
{clock_cmds}
{reset_cmds}
{ports}

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\\[cdc_run\\] $TOP: reports written to $RPT_DIR"
"""


def add_jasper_field(bench: str) -> None:
    man = BENCH / bench / "manifest.yaml"
    text = man.read_text(encoding="utf-8")
    if "jasper:" in text:
        return
    text = text.replace(
        "simulation: sim/run.sh\n",
        "jasper: jasper/run.tcl\nsimulation: sim/run.sh\n",
    )
    man.write_text(text, encoding="utf-8")


def emit(bench: str, **kwargs) -> None:
    write(BENCH / bench / "jasper/run.tcl", tcl(bench, **kwargs))
    add_jasper_field(bench)


def main() -> None:
    r = "$BENCH_DIR/fixed/rtl"

    emit(
        "cdc_fifo_gray",
        top="cdc_fifo_gray",
        rtl=[f"{r}/cdc_fifo_gray.v"],
        clocks=["src_clk_i", "dst_clk_i"],
        reset_lines=[
            "config_rtlds -reset -async src_rst_ni -polarity low",
            "config_rtlds -reset -async dst_rst_ni -polarity low",
        ],
        port_blocks=[
            ("src_clk_i", ["src_rst_ni src_data_i src_valid_i src_ready_o"]),
            ("dst_clk_i", ["dst_rst_ni dst_data_o dst_valid_o dst_ready_i"]),
        ],
    )
    emit(
        "cdc_fifo_gray_clearable",
        top="cdc_fifo_gray_clearable",
        rtl=[f"{r}/cdc_fifo_gray_clearable.v"],
        clocks=["src_clk_i", "dst_clk_i"],
        reset_lines=[
            "config_rtlds -reset -async common_rst_ni -polarity low",
        ],
        port_blocks=[
            (
                "src_clk_i",
                ["src_rst_ni src_clear_i src_clear_pending_o src_data_i src_valid_i src_ready_o"],
            ),
            (
                "dst_clk_i",
                ["dst_rst_ni dst_clear_i dst_clear_pending_o dst_data_o dst_valid_o dst_ready_i"],
            ),
        ],
    )
    emit(
        "cdc_fifo_2phase",
        top="cdc_fifo_2phase",
        rtl=[f"{r}/cdc_fifo_2phase.v", f"{r}/cdc_2phase.v"],
        clocks=["src_clk_i", "dst_clk_i"],
        reset_lines=[
            "config_rtlds -reset -async common_rst_ni -polarity low",
        ],
        port_blocks=[
            ("src_clk_i", ["src_rst_ni src_data_i src_valid_i src_ready_o"]),
            ("dst_clk_i", ["dst_rst_ni dst_data_o dst_valid_o dst_ready_i"]),
        ],
    )
    emit(
        "cdc_reset_ctrlr",
        top="cdc_reset_ctrlr",
        rtl=[f"{r}/cdc_reset_ctrlr.v"],
        clocks=["a_clk_i", "b_clk_i"],
        reset_lines=[
            "config_rtlds -reset -async a_rst_ni -polarity low",
            "config_rtlds -reset -async b_rst_ni -polarity low",
        ],
        port_blocks=[
            (
                "a_clk_i",
                [
                    "a_rst_ni a_clear_i a_clear_o a_clear_ack_i",
                    "a_isolate_o a_isolate_ack_i",
                ],
            ),
            (
                "b_clk_i",
                [
                    "b_rst_ni b_clear_i b_clear_o b_clear_ack_i",
                    "b_isolate_o b_isolate_ack_i",
                ],
            ),
        ],
    )
    emit(
        "sync_wedge",
        top="sync_wedge",
        rtl=[f"{r}/sync_wedge.v", f"{r}/sync.v"],
        clocks=["clk_i"],
        reset_lines=["config_rtlds -reset -async rst_ni -polarity low"],
        port_blocks=[
            ("clk_i", ["rst_ni en_i serial_i r_edge_o f_edge_o serial_o"]),
        ],
    )
    emit(
        "isochronous_spill_register",
        top="isochronous_spill_register",
        rtl=[f"{r}/isochronous_spill_register.v"],
        clocks=["src_clk_i", "dst_clk_i"],
        reset_lines=[
            "config_rtlds -reset -async src_rst_ni -polarity low",
            "config_rtlds -reset -async dst_rst_ni -polarity low",
        ],
        port_blocks=[
            ("src_clk_i", ["src_rst_ni src_valid_i src_ready_o src_data_i"]),
            ("dst_clk_i", ["dst_rst_ni dst_valid_o dst_ready_i dst_data_o"]),
        ],
    )
    emit(
        "isochronous_4phase_handshake",
        top="isochronous_4phase_handshake",
        rtl=[f"{r}/isochronous_4phase_handshake.v"],
        clocks=["src_clk_i", "dst_clk_i"],
        reset_lines=[
            "config_rtlds -reset -async common_rst_ni -polarity low",
        ],
        port_blocks=[
            ("src_clk_i", ["src_rst_ni src_valid_i src_ready_o"]),
            ("dst_clk_i", ["dst_rst_ni dst_valid_o dst_ready_i"]),
        ],
    )
    emit(
        "apb_cdc",
        top="apb_cdc",
        rtl=[f"{r}/apb_cdc.v", f"{r}/cdc_fifo_gray.v"],
        clocks=["src_pclk_i", "dst_pclk_i"],
        reset_lines=[
            "config_rtlds -reset -async src_preset_ni -polarity low",
            "config_rtlds -reset -async dst_preset_ni -polarity low",
        ],
        port_blocks=[
            (
                "src_pclk_i",
                [
                    "src_preset_ni src_psel_i src_penable_i src_pwrite_i",
                    "src_paddr_i src_pwdata_i src_pstrb_i src_pprot_i",
                    "src_pready_o src_prdata_o src_pslverr_o",
                ],
            ),
            (
                "dst_pclk_i",
                [
                    "dst_preset_ni dst_psel_o dst_penable_o dst_pwrite_o",
                    "dst_paddr_o dst_pwdata_o dst_pstrb_o dst_pprot_o",
                    "dst_pready_i dst_prdata_i dst_pslverr_i",
                ],
            ),
        ],
    )
    emit(
        "axil_cdc",
        top="axil_cdc",
        rtl=[f"{r}/axil_cdc.v", f"{r}/axil_cdc_wr.v", f"{r}/axil_cdc_rd.v"],
        clocks=["s_clk", "m_clk"],
        reset_lines=[
            "config_rtlds -reset -sync s_rst -clock s_clk -polarity high",
            "config_rtlds -reset -sync m_rst -clock m_clk -polarity high",
        ],
        port_blocks=[
            (
                "s_clk",
                [
                    "s_rst s_axil_awaddr s_axil_awprot s_axil_awvalid s_axil_awready",
                    "s_axil_wdata s_axil_wstrb s_axil_wvalid s_axil_wready",
                    "s_axil_bresp s_axil_bvalid s_axil_bready",
                    "s_axil_araddr s_axil_arprot s_axil_arvalid s_axil_arready",
                    "s_axil_rdata s_axil_rresp s_axil_rvalid s_axil_rready",
                ],
            ),
            (
                "m_clk",
                [
                    "m_rst m_axil_awaddr m_axil_awprot m_axil_awvalid m_axil_awready",
                    "m_axil_wdata m_axil_wstrb m_axil_wvalid m_axil_wready",
                    "m_axil_bresp m_axil_bvalid m_axil_bready",
                    "m_axil_araddr m_axil_arprot m_axil_arvalid m_axil_arready",
                    "m_axil_rdata m_axil_rresp m_axil_rvalid m_axil_rready",
                ],
            ),
        ],
        bbox=True,
    )
    emit(
        "sync_reset",
        top="sync_reset",
        rtl=[f"{r}/sync_reset.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -async rst -polarity high"],
        port_blocks=[("clk", ["rst out"])],
    )
    emit(
        "data_sync",
        top="data_sync",
        rtl=[f"{r}/data_sync.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -sync rstn -clock clk -polarity low"],
        port_blocks=[("clk", ["rstn din dready_i dout dready_o"])],
    )
    emit(
        "areset_deassert_sync",
        top="areset_deassert_sync",
        rtl=[f"{r}/areset_deassert_sync.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -async async_rst_i -polarity high"],
        port_blocks=[("clk", ["async_rst_i sync_rst_o"])],
    )
    emit(
        "synchronizer",
        top="synchronizer",
        rtl=[f"{r}/synchronizer.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -sync rstn -clock clk -polarity low"],
        port_blocks=[("clk", ["rstn async_sig_i sync_sig_o"])],
    )
    emit(
        "afifo",
        top="afifo",
        rtl=[f"{r}/afifo.v"],
        clocks=["i_wclk", "i_rclk"],
        reset_lines=[
            "config_rtlds -reset -async i_wr_reset_n -polarity low",
            "config_rtlds -reset -async i_rd_reset_n -polarity low",
        ],
        port_blocks=[
            ("i_wclk", ["i_wr_reset_n i_wr i_wr_data o_wr_full"]),
            ("i_rclk", ["i_rd_reset_n i_rd o_rd_data o_rd_empty"]),
        ],
        bbox=True,
    )
    print("wrote jasper scripts for 14 leftover CDC circuits")


if __name__ == "__main__":
    main()
