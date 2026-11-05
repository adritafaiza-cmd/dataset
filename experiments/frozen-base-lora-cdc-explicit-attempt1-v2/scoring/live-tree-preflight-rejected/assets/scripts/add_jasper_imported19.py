#!/usr/bin/env python3
"""Add JasperGold CDC scripts for the original 19 imported circuits."""

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
        "sync",
        top="sync",
        rtl=[f"{r}/sync.sv"],
        clocks=["clk_i"],
        reset_lines=["config_rtlds -reset -async rst_ni -polarity low"],
        port_blocks=[("clk_i", ["rst_ni serial_i serial_o"])],
        analyze="-sv12",
    )
    emit(
        "sync_multistage",
        top="sync",
        rtl=[f"{r}/sync.sv"],
        clocks=["clk_i"],
        reset_lines=["config_rtlds -reset -async rst_ni -polarity low"],
        port_blocks=[("clk_i", ["rst_ni serial_i serial_o"])],
        analyze="-sv12",
    )
    emit(
        "edge_propagator",
        top="edge_propagator",
        rtl=[
            f"{r}/edge_propagator.sv",
            f"{r}/edge_propagator_ack.sv",
            f"{r}/pulp_sync_wedge.sv",
            f"{r}/pulp_sync.sv",
            "$BENCH_DIR/tb/pulp_clock_gating.sv",
        ],
        clocks=["clk_tx_i", "clk_rx_i"],
        reset_lines=[
            "config_rtlds -reset -async rstn_tx_i -polarity low",
            "config_rtlds -reset -async rstn_rx_i -polarity low",
        ],
        port_blocks=[
            ("clk_tx_i", ["rstn_tx_i edge_i"]),
            ("clk_rx_i", ["rstn_rx_i edge_o"]),
        ],
        analyze="-sv12",
    )
    emit(
        "rstgen",
        top="rstgen",
        rtl=[f"{r}/rstgen.sv", f"{r}/rstgen_bypass.sv"],
        clocks=["clk_i"],
        reset_lines=["config_rtlds -reset -async rst_ni -polarity low"],
        port_blocks=[("clk_i", ["rst_ni test_mode_i rst_no init_no"])],
        analyze="-sv12",
    )
    emit(
        "pulse_sync",
        top="pulse_sync",
        rtl=[f"{r}/pulse_sync.v"],
        clocks=["clk_a", "clk_b"],
        reset_lines=[
            "config_rtlds -reset -sync rstn_a -clock clk_a -polarity low",
            "config_rtlds -reset -sync rstn_b -clock clk_b -polarity low",
        ],
        port_blocks=[
            ("clk_a", ["rstn_a pulseA_i busy_o"]),
            ("clk_b", ["rstn_b pulseB_o"]),
        ],
    )
    emit(
        "areset_sync",
        top="areset_sync",
        rtl=[f"{r}/areset_sync.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -async async_rst_i -polarity high"],
        port_blocks=[("clk", ["async_rst_i sync_rst_o"])],
    )
    emit(
        "async_fifo_sv",
        top="async_fifo",
        rtl=[
            f"{r}/async_fifo.sv",
            f"{r}/fifomem.sv",
            f"{r}/rptr_empty.sv",
            f"{r}/wptr_full.sv",
            f"{r}/sync_r2w.sv",
            f"{r}/sync_w2r.sv",
        ],
        clocks=["wclk", "rclk"],
        reset_lines=["config_rtlds -reset -async {wrst_n rrst_n} -polarity low"],
        port_blocks=[
            ("wclk", ["wrst_n winc wdata wfull waddr"]),
            ("rclk", ["rrst_n rinc rdata rempty raddr"]),
        ],
        analyze="-sv12",
        bbox=True,
    )
    emit(
        "axis_register",
        top="axis_register",
        rtl=[f"{r}/axis_register.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -sync rst -clock clk -polarity high"],
        port_blocks=[
            (
                "clk",
                [
                    "rst s_axis_tdata s_axis_tkeep s_axis_tvalid s_axis_tready",
                    "s_axis_tlast s_axis_tid s_axis_tdest s_axis_tuser",
                    "m_axis_tdata m_axis_tkeep m_axis_tvalid m_axis_tready",
                    "m_axis_tlast m_axis_tid m_axis_tdest m_axis_tuser",
                ],
            )
        ],
    )
    emit(
        "axis_fifo",
        top="axis_fifo",
        rtl=[f"{r}/axis_fifo.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -sync rst -clock clk -polarity high"],
        port_blocks=[
            (
                "clk",
                [
                    "rst s_axis_tdata s_axis_tkeep s_axis_tvalid s_axis_tready",
                    "s_axis_tlast s_axis_tid s_axis_tdest s_axis_tuser",
                    "m_axis_tdata m_axis_tkeep m_axis_tvalid m_axis_tready",
                    "m_axis_tlast m_axis_tid m_axis_tdest m_axis_tuser",
                ],
            )
        ],
        bbox=True,
    )
    emit(
        "axis_adapter",
        top="axis_adapter",
        rtl=[f"{r}/axis_adapter.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -sync rst -clock clk -polarity high"],
        port_blocks=[
            (
                "clk",
                [
                    "rst s_axis_tdata s_axis_tkeep s_axis_tvalid s_axis_tready",
                    "s_axis_tlast s_axis_tid s_axis_tdest s_axis_tuser",
                    "m_axis_tdata m_axis_tkeep m_axis_tvalid m_axis_tready",
                    "m_axis_tlast m_axis_tid m_axis_tdest m_axis_tuser",
                ],
            )
        ],
    )
    emit(
        "arbiter",
        top="arbiter",
        rtl=[f"{r}/arbiter.v", f"{r}/priority_encoder.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -sync rst -clock clk -polarity high"],
        port_blocks=[("clk", ["rst request acknowledge grant grant_valid grant_encoded"])],
    )
    emit(
        "axis_switch",
        top="axis_switch",
        rtl=[
            f"{r}/axis_switch.v",
            f"{r}/axis_register.v",
            f"{r}/arbiter.v",
            f"{r}/priority_encoder.v",
        ],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -sync rst -clock clk -polarity high"],
        port_blocks=[("clk", ["rst"])],
        bbox=True,
    )
    emit(
        "apb_regs",
        top="apb_regs_wrap",
        rtl=[
            f"{r}/cf_math_pkg.sv",
            f"{r}/apb_pkg.sv",
            f"{r}/apb_intf.sv",
            f"{r}/addr_decode.sv",
            f"{r}/apb_regs.sv",
            "$BENCH_DIR/jasper/apb_regs_wrap.sv",
        ],
        clocks=["pclk_i"],
        reset_lines=["config_rtlds -reset -async preset_ni -polarity low"],
        port_blocks=[
            (
                "pclk_i",
                [
                    "preset_ni psel penable pwrite paddr pwdata pstrb",
                    "pready prdata pslverr base_addr_i",
                ],
            )
        ],
        analyze="-sv12",
        extra_analyze="+incdir+$BENCH_DIR/fixed/rtl/include +incdir+$env(DS)/vendor/common_cells/include",
    )
    emit(
        "apbslave",
        top="apbslave",
        rtl=[f"{r}/apbslave.v"],
        clocks=["PCLK"],
        reset_lines=["config_rtlds -reset -sync PRESETn -clock PCLK -polarity low"],
        port_blocks=[
            (
                "PCLK",
                [
                    "PRESETn PSEL PENABLE PREADY PADDR PWRITE PWDATA PWSTRB",
                    "PPROT PRDATA PSLVERR",
                ],
            )
        ],
        bbox=True,
    )
    emit(
        "uart16550",
        top="uart_top",
        rtl=[
            f"{r}/raminfr.v",
            f"{r}/uart_debug_if.v",
            f"{r}/uart_receiver.v",
            f"{r}/uart_regs.v",
            f"{r}/uart_rfifo.v",
            f"{r}/uart_sync_flops.v",
            f"{r}/uart_tfifo.v",
            f"{r}/uart_top.v",
            f"{r}/uart_transmitter.v",
            f"{r}/uart_wb.v",
        ],
        clocks=["wb_clk_i"],
        reset_lines=["config_rtlds -reset -sync wb_rst_i -clock wb_clk_i -polarity high"],
        port_blocks=[
            (
                "wb_clk_i",
                [
                    "wb_rst_i wb_adr_i wb_dat_i wb_dat_o wb_we_i wb_stb_i",
                    "wb_cyc_i wb_ack_o wb_sel_i int_o stx_pad_o srx_pad_i",
                    "rts_pad_o cts_pad_i dtr_pad_o dsr_pad_i ri_pad_i dcd_pad_i",
                ],
            )
        ],
        extra_analyze="+define+DATA_BUS_WIDTH_8 +incdir+$BENCH_DIR/fixed/rtl",
        bbox=True,
    )
    emit(
        "i2c_master",
        top="i2c_master",
        rtl=[f"{r}/i2c_master.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -sync rst -clock clk -polarity high"],
        port_blocks=[
            (
                "clk",
                [
                    "rst s_axis_cmd_address s_axis_cmd_start s_axis_cmd_read",
                    "s_axis_cmd_write s_axis_cmd_write_multiple s_axis_cmd_stop",
                    "s_axis_cmd_valid s_axis_cmd_ready s_axis_data_tdata",
                    "s_axis_data_tvalid s_axis_data_tready s_axis_data_tlast",
                    "m_axis_data_tdata m_axis_data_tvalid m_axis_data_tready",
                    "m_axis_data_tlast scl_i scl_o scl_t sda_i sda_o sda_t",
                    "busy bus_control bus_active missed_ack prescale stop_on_idle",
                ],
            )
        ],
    )
    emit(
        "spi_master_slave",
        top="spi_master",
        rtl=[f"{r}/spi_master.v"],
        clocks=["sclk_i", "pclk_i"],
        reset_lines=["config_rtlds -reset -async rst_i -polarity high"],
        port_blocks=[
            (
                "sclk_i",
                ["spi_ssel_o spi_sck_o spi_mosi_o spi_miso_i"],
            ),
            (
                "pclk_i",
                ["di_req_o di_i wren_i wr_ack_o do_valid_o do_o"],
            ),
        ],
    )
    emit(
        "axi_dma",
        top="axi_dma",
        rtl=[f"{r}/axi_dma.v", f"{r}/axi_dma_rd.v", f"{r}/axi_dma_wr.v"],
        clocks=["clk"],
        reset_lines=["config_rtlds -reset -sync rst -clock clk -polarity high"],
        port_blocks=[("clk", ["rst"])],
        bbox=True,
    )
    emit(
        "axidma",
        top="axidma",
        rtl=[f"{r}/axidma.v", f"{r}/skidbuffer.v", f"{r}/sfifo.v"],
        clocks=["S_AXI_ACLK"],
        reset_lines=["config_rtlds -reset -async S_AXI_ARESETN -polarity low"],
        port_blocks=[("S_AXI_ACLK", ["S_AXI_ARESETN"])],
        bbox=True,
    )
    print("wrote jasper scripts for 19 imported circuits")


if __name__ == "__main__":
    main()
