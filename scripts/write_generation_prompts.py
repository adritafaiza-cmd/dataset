#!/usr/bin/env python3
"""Write every circuit prompt in one labeled standard.

Template follows RTLCoder's IO+behavior sections, RTLLM's named ports,
and VerilogEval's code-only close. CDC-explicit adds one frozen paragraph.

Does not mention Gray-code recipes, 2-flop recipes, or reference RTL.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BENCH = ROOT / "benchmarks"
OUT = ROOT / "experiments" / "prompts"

CDC_LINE = """The implementation must be safe for clock-domain and reset-domain crossings
and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
release must be safe in each clock domain, and transferred multi-bit data must
remain coherent. Select the architecture yourself."""

CLOSER = """Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation."""

# One sentence. What a human designer would implement.
IMPLEMENT = {
    "afifo": "an asynchronous FIFO with 2**LGFIFO entries of WIDTH bits.",
    "apb_cdc": "an APB clock-domain bridge.",
    "apb_regs": "an APB-mapped register file.",
    "apbslave": "a single-clock APB slave.",
    "apbxclk": "an APB clock-domain bridge.",
    "arbiter": "a multi-port request arbiter.",
    "areset_deassert_sync": "a destination-clock reset-release synchronizer.",
    "areset_sync": "a destination-clock reset-release synchronizer.",
    "async_bidir_fifo": "a bidirectional asynchronous FIFO.",
    "async_bidir_ramif_fifo": "a bidirectional asynchronous FIFO with an external dual-port RAM interface.",
    "async_fifo": "an asynchronous FIFO with 2**ASIZE entries of DSIZE bits.",
    "async_fifo_sv": "an asynchronous FIFO with 2**ADDR_WIDTH entries of DATA_WIDTH bits.",
    "axi_dma": "a single-clock AXI DMA engine.",
    "axidma": "a single-clock AXI DMA with an AXI4-Lite control port.",
    "axil_cdc": "an AXI4-Lite clock-domain bridge.",
    "axis_adapter": "a single-clock AXI-Stream width converter.",
    "axis_async_fifo": "an asynchronous AXI-Stream FIFO.",
    "axis_async_fifo_adapter": "an asynchronous AXI-Stream FIFO with a width adapter.",
    "axis_fifo": "a single-clock AXI-Stream FIFO.",
    "axis_register": "a single-clock AXI-Stream register slice.",
    "axis_switch": "a single-clock AXI-Stream switch.",
    "axixclk": "an AXI4 clock-domain bridge.",
    "cdc_2phase": "a two-phase valid/ready channel that transfers WIDTH-bit data between asynchronous clocks.",
    "cdc_2phase_clearable": "a clearable two-phase valid/ready channel between asynchronous clocks.",
    "cdc_4phase": "a four-phase valid/ready channel that transfers WIDTH-bit data between asynchronous clocks.",
    "cdc_fifo_2phase": "a valid/ready asynchronous FIFO with 2**LOG_DEPTH entries of WIDTH bits.",
    "cdc_fifo_gray": "a valid/ready asynchronous FIFO with 2**LOG_DEPTH entries of WIDTH bits.",
    "cdc_fifo_gray_clearable": "a clearable valid/ready asynchronous FIFO.",
    "cdc_reset_ctrlr": "a two-domain isolate-then-clear reset controller.",
    "data_sync": "a multi-bit destination-clock data synchronizer.",
    "edge_propagator": "a pulse/edge propagator between asynchronous clocks.",
    "i2c_master": "a single-clock I2C master.",
    "isochronous_4phase_handshake": "a four-phase valid/ready handshake between related clocks.",
    "isochronous_spill_register": "a 2-deep valid/ready spill buffer between related clocks.",
    "pulse_sync": "a one-pulse-in, one-pulse-out crossing between asynchronous clocks.",
    "rstgen": "a reset generator that releases a synchronized reset in clk_i.",
    "spi_master_slave": "an SPI master with a parallel-side word interface.",
    "sync": "a single-bit destination-clock synchronizer.",
    "sync_multistage": "a single-bit destination-clock synchronizer.",
    "sync_reset": "a destination-clock reset synchronizer.",
    "sync_wedge": "a destination-clock bit synchronizer with edge detect.",
    "synchronizer": "a single-bit destination-clock synchronizer.",
    "uart16550": "a 16550-compatible UART with a Wishbone slave.",
    "wbxclk": "a pipelined Wishbone clock-domain bridge.",
}

# clock_mode: async | related | single
CLOCK_MODE = {
    "isochronous_4phase_handshake": "related",
    "isochronous_spill_register": "related",
}

# Pilot behavior kept verbatim from the frozen prompts.
BEHAVIOR = {
    "cdc_2phase": [
        "A source transfer is accepted on a rising src_clk_i edge when src_valid_i and src_ready_o are both high.",
        "Every accepted source item must appear exactly once at the destination, in the original order.",
        "A destination transfer completes on a rising dst_clk_i edge when dst_valid_o and dst_ready_i are both high.",
        "While dst_valid_o is high and dst_ready_i is low, dst_valid_o must remain asserted and dst_data_o must remain stable.",
        "The design may support one outstanding item.",
        "src_ready_o must be low whenever a new source item cannot safely be accepted.",
        "Reset must return both interfaces to an idle state and must not create a spurious destination transaction.",
    ],
    "async_fifo": [
        "A write is accepted on a rising wclk edge when winc is high and wfull is low.",
        "Writes attempted while full must not alter FIFO contents.",
        "A read is accepted on a rising rclk edge when rinc is high and rempty is low.",
        "Reads attempted while empty must not advance the FIFO.",
        "Accepted data must be returned exactly once and in write order.",
        "wfull is generated in the write domain and rempty in the read domain.",
        "awfull indicates that the FIFO is approaching full, and arempty indicates that it is approaching empty.",
        "After reset, wfull must be low and rempty must be high.",
        'When FALLTHROUGH equals "TRUE", rdata presents the current oldest unread word without requiring an additional registered-read cycle. Otherwise, rdata may be updated by an accepted read.',
    ],
    "apbxclk": [
        "Accept standard APB transfers on the S_APB interface.",
        "Forward each accepted request exactly once to the M_APB interface using a normal APB setup phase followed by an access phase.",
        "Keep the downstream request fields stable until M_APB_PREADY completes the transfer.",
        "Return read data and slave-error status to the source interface.",
        "Assert S_APB_PREADY only when the corresponding downstream transaction has completed.",
        "Do not lose, duplicate, or reorder requests.",
        "Supporting one outstanding transaction is sufficient.",
        "Both interfaces must remain inactive during reset, and reset must not create a transaction.",
        "OPT_REGISTERED selects whether crossing payload and response fields are explicitly registered. Both parameter settings must preserve APB behavior.",
    ],
}

# Extra circuits: short bullets (behavior only, no architecture recipe).
BEHAVIOR.update(
    {
        "afifo": [
            "A write is accepted when i_wr is high and o_wr_full is low.",
            "A read is accepted when i_rd is high and o_rd_empty is low.",
            "Accepted data must return exactly once in write order.",
            "Writes while full and reads while empty must not change stored data.",
            "After reset, o_wr_full is low and o_rd_empty is high.",
            "WRITE_ON_POSEDGE selects the write edge. OPT_REGISTER_READS selects whether reads are registered.",
            "Do not emit FORMAL-only ports.",
        ],
        "apb_cdc": [
            "Accept standard APB transfers on the source ports.",
            "Forward each accepted request exactly once to the destination with a setup phase then an access phase.",
            "Keep destination request fields stable until dst_pready_i completes the transfer.",
            "Return read data and slave error to the source.",
            "Assert src_pready_o only after the destination transfer completes.",
            "Do not lose, duplicate, or reorder requests. One outstanding transaction is enough.",
            "Reset must idle both interfaces and must not create a transaction.",
        ],
        "apb_regs": [
            "Map NoApbRegs registers of RegDataWidth, spaced AddrOffset bytes apart, starting at base_addr_i.",
            "req_i / resp_o use the APB request and response types supplied by the testbench.",
            "Initialize from reg_init_i and drive reg_q_o with current values.",
            "Read-only bits in ReadOnly must ignore writes.",
            "After reset, registers return to reg_init_i.",
        ],
        "apbslave": [
            "Accept standard APB setup/access transfers and complete each access by asserting PREADY.",
            "Support reads and writes of C_APB_DATA_WIDTH using PWSTRB.",
            "PSLVERR may stay low for in-range accesses.",
            "After reset the slave must be idle.",
        ],
        "arbiter": [
            "Grant one of PORTS requestors.",
            "When ARB_TYPE_ROUND_ROBIN is set, rotate priority; otherwise use fixed priority.",
            "ARB_LSB_HIGH_PRIORITY selects whether the LSB wins ties.",
            "When ARB_BLOCK is set, hold the grant until acknowledge (ARB_BLOCK_ACK nonzero) or until request drops (ARB_BLOCK_ACK zero).",
            "grant_valid and grant_encoded must match grant.",
        ],
        "areset_deassert_sync": [
            "sync_rst_o must follow assertion of async_rst_i immediately.",
            "sync_rst_o may release only after clk has observed a safe deassert.",
            "CHAINS is the release-pipeline depth. RST_POL is 1 for active-high async_rst_i.",
            "After a completed release, sync_rst_o is inactive.",
        ],
        "areset_sync": [
            "sync_rst_o asserts with async_rst_i and deasserts only in clk.",
            "STAGES is the release-pipeline depth.",
        ],
        "async_bidir_fifo": [
            "a_dir / b_dir select the direction on that side: 1 means write, 0 means read.",
            "Accepted writes must appear in order on the opposite side when that side reads.",
            "Full/empty and almost-full/almost-empty flags are local to each side.",
            "After reset the FIFO is empty.",
            "FALLTHROUGH selects first-word fall-through.",
        ],
        "async_bidir_ramif_fifo": [
            "Same bidirectional FIFO rules as a two-port async FIFO.",
            "Drive o_ram_* clocks, addresses, write data, and enables. Read data returns on i_ram_*_rdata.",
            "Do not infer an internal payload memory.",
            "After reset the FIFO is empty.",
        ],
        "async_fifo_sv": [
            "A write is accepted when winc is high and wfull is low.",
            "A read is accepted when rinc is high and rempty is low.",
            "Data must return exactly once in write order.",
            "After reset, wfull is low and rempty is high.",
            "waddr and raddr are debug pointer outputs.",
        ],
        "axi_dma": [
            "Accept read and write descriptors on the AXIS descriptor inputs.",
            "Perform AXI memory reads/writes and stream data on the AXI-Stream data ports.",
            "Return descriptor status with the original tag.",
            "Honor LEN_WIDTH, AXI_MAX_BURST_LEN, and the AXIS sideband enables.",
            "After reset all interfaces are idle.",
        ],
        "axidma": [
            "Software programs source, destination, and length through the 32-bit Lite registers.",
            "The core then copies memory using AXI4.",
            "OPT_UNALIGNED and OPT_WRAPMEM change address handling as named.",
            "After reset the engine is stopped and must not issue AXI transfers.",
        ],
        "axil_cdc": [
            "Accept AXI4-Lite write and read channels on the slave ports.",
            "Forward each accepted transaction exactly once to the master ports.",
            "Return bresp/rdata/rresp without loss, duplication, or reordering.",
            "One outstanding write and one outstanding read are enough.",
            "Reset must idle both interfaces and must not create a transaction.",
        ],
        "axis_adapter": [
            "Convert S_DATA_WIDTH to M_DATA_WIDTH.",
            "Preserve packet boundaries (tlast) and enabled sidebands.",
            "Do not drop or reorder beats except as required by packing/unpacking.",
            "After reset both interfaces are idle.",
        ],
        "axis_async_fifo": [
            "A transfer is accepted when tvalid and tready are both high.",
            "Deliver beats in order with tlast and the enabled sidebands.",
            "s_axis_tready must go low when the FIFO cannot accept another beat, unless a drop/mark-when-full parameter is set.",
            "After reset the FIFO is empty.",
        ],
        "axis_async_fifo_adapter": [
            "Combine an asynchronous AXI-Stream FIFO with a width adapter from S_DATA_WIDTH to M_DATA_WIDTH.",
            "Preserve order, tlast, and enabled sidebands.",
            "After reset both interfaces are idle and the FIFO is empty.",
        ],
        "axis_fifo": [
            "Store DEPTH words. Preserve order, tlast, and enabled sidebands.",
            "After reset the FIFO is empty.",
            "FRAME_FIFO and drop/mark parameters change frame behavior as named.",
        ],
        "axis_register": [
            "REG_TYPE 0 is a wire, 1 is a simple buffer, 2 is a skid buffer that must not drop a beat when the output stalls.",
            "Preserve tdata and enabled sidebands.",
            "After reset the slice is empty.",
        ],
        "axis_switch": [
            "Route S_COUNT inputs to M_COUNT outputs using tdest.",
            "Do not drop or duplicate a beat that is granted.",
            "When ARB_TYPE_ROUND_ROBIN is set, arbitrate fairly among inputs that want the same output.",
            "After reset all ports are idle.",
        ],
        "axixclk": [
            "Accept AXI4 on the slave ports and forward each burst exactly once to the master ports.",
            "Return write responses and read data without loss or reordering beyond AXI outstanding-transaction rules.",
            "Reset must not create a burst.",
            "OPT_WRITE_ONLY / OPT_READ_ONLY may omit the unused direction.",
            "LGFIFO sizes internal buffering. XCLOCK_FFS is an implementation parameter; choose a safe crossing yourself.",
        ],
        "cdc_2phase_clearable": [
            "Every accepted source beat must appear exactly once at the destination, in order.",
            "The channel may hold one outstanding item.",
            "src_clear_i and dst_clear_i request a coordinated flush: isolate the channel, drop in-flight data, then return both sides to idle.",
            "src_clear_pending_o / dst_clear_pending_o stay high until that side has finished the clear.",
            "Reset and clear must not create a destination beat.",
        ],
        "cdc_4phase": [
            "A source transfer is accepted when src_valid_i and src_ready_o are both high.",
            "Each accepted item appears exactly once at the destination, in order.",
            "While dst_valid_o is high and dst_ready_i is low, dst_data_o must stay stable.",
            "DECOUPLED, when set, allows the source to accept a new item before the previous destination handshake fully returns.",
            "SEND_RESET_MSG / RESET_MSG, when set, emit RESET_MSG after reset instead of staying idle.",
            "Reset must not create a spurious destination beat unless SEND_RESET_MSG is set.",
        ],
        "cdc_fifo_2phase": [
            "Accept source beats when src_valid_i and src_ready_o are high.",
            "Deliver destination beats in order when dst_valid_o and dst_ready_i are high.",
            "src_ready_o must be low when the FIFO cannot accept another item.",
            "After reset the FIFO is empty and dest is idle.",
        ],
        "cdc_fifo_gray": [
            "Accept source beats when src_valid_i and src_ready_o are high.",
            "Deliver destination beats in order.",
            "Pointers and data that leave their clock domain must remain coherent.",
            "SYNC_STAGES is an implementation parameter; choose a safe crossing yourself.",
            "After reset the FIFO is empty.",
        ],
        "cdc_fifo_gray_clearable": [
            "Same valid/ready async FIFO rules as the non-clearable FIFO in this family.",
            "src_clear_i / dst_clear_i request a flush: isolate both sides, drop stored and in-flight data, then return to empty.",
            "*_clear_pending_o stays high until that side finishes.",
            "Clear and reset must not create a destination beat.",
        ],
        "cdc_reset_ctrlr": [
            "When either side requests clear (*_clear_i), first raise both isolate outputs, wait for both isolate acks, then raise both clear outputs, wait for both clear acks, then release isolate and clear.",
            "Do not leave one domain cleared while the other is still live.",
            "After reset, isolate and clear outputs are inactive.",
        ],
        "data_sync": [
            "When dready_i indicates a new source value, present a coherent dout and pulse dready_o in clk.",
            "Do not tear multi-bit dout.",
            "After reset, dready_o is low.",
        ],
        "edge_propagator": [
            "A pulse or edge on edge_i in the TX domain must produce one pulse on edge_o in the RX domain.",
            "Do not lose or double-count isolated edges.",
            "After reset, edge_o is low.",
        ],
        "i2c_master": [
            "Accept commands on s_axis_cmd_* and write bytes on s_axis_data_*.",
            "Drive open-drain style scl/sda outputs (o and t).",
            "Return read bytes on m_axis_data_*.",
            "prescale sets SCL timing. Honor start/stop/read/write command bits.",
            "missed_ack reports a missing slave ACK.",
            "After reset the bus drivers are released.",
        ],
        "isochronous_4phase_handshake": [
            "Implement a four-phase valid/ready handshake with no data payload.",
            "src_ready_o and dst_valid_o must follow four-phase order.",
            "After reset both sides are idle.",
        ],
        "isochronous_spill_register": [
            "Every accepted source beat appears exactly once at the destination, in order.",
            "The buffer absorbs a short rate mismatch between the related clocks.",
            "After reset dest is idle.",
        ],
        "pulse_sync": [
            "A one-cycle pulse on pulseA_i in domain A must produce one pulse on pulseB_o in domain B.",
            "busy_o is high while a pulse is in flight; ignore additional pulseA_i while busy.",
            "After reset, pulseB_o and busy_o are low.",
        ],
        "rstgen": [
            "rst_no is the synchronized active-low reset output.",
            "init_no is a short initialization qualifier after reset release.",
            "test_mode_i bypasses synchronization for scan/test when high.",
        ],
        "spi_master_slave": [
            "The testbench instantiates spi_master.",
            "Accept N-bit words on di_i when wren_i is high; wr_ack_o acknowledges the write.",
            "Shift the word out on spi_mosi_o with spi_sck_o and spi_ssel_o.",
            "Capture spi_miso_i and present it on do_o with do_valid_o.",
            "di_req_o requests the next word.",
            "After reset, selects are inactive and outputs are idle.",
        ],
        "sync": [
            "serial_i is an asynchronous single-bit input. serial_o is that bit in clk_i.",
            "STAGES is the pipeline depth.",
            "After reset, serial_o equals ResetValue.",
        ],
        "sync_multistage": [
            "The top module name is sync.",
            "serial_i is an asynchronous single-bit input. serial_o is that bit in clk_i.",
            "STAGES is the pipeline depth.",
            "After reset, serial_o equals ResetValue.",
        ],
        "sync_reset": [
            "out asserts with rst and deasserts only after a safe number of clk edges.",
            "N is the pipeline depth.",
        ],
        "sync_wedge": [
            "serial_i is an asynchronous bit. serial_o is that bit in clk_i.",
            "When en_i is high, r_edge_o / f_edge_o pulse for one cycle on rising / falling edges of the synchronized bit.",
            "After reset, outputs are low.",
        ],
        "synchronizer": [
            "async_sig_i is an asynchronous single-bit input. sync_sig_o is the synchronized bit.",
            "STAGES is the pipeline depth.",
            "After reset, sync_sig_o is low.",
        ],
        "uart16550": [
            "The top module name is uart_top.",
            "Implement Wishbone slave registers, serial stx_pad_o / srx_pad_i, modem pins, and int_o.",
            "Register, baud, and FIFO behavior must match a conventional 16550 so the testbench can program and loop back data.",
        ],
        "wbxclk": [
            "Accept pipelined Wishbone cycles on the i_wb_* ports.",
            "Forward each accepted cycle exactly once to the o_xclk_* ports.",
            "Return ack/err/data to the source.",
            "o_wb_stall must go high when the crossing cannot accept another cycle.",
            "Reset must idle both buses and must not create a destination cycle.",
        ],
    }
)

PARAM_DESC = {
    "WIDTH": "Payload width in bits.",
    "DSIZE": "Payload width in bits.",
    "ASIZE": "Log2 of the number of FIFO entries.",
    "LGFIFO": "Log2 of the number of FIFO entries.",
    "LOG_DEPTH": "Log2 of the number of FIFO entries.",
    "ADDR_WIDTH": "Address or pointer width.",
    "DATA_WIDTH": "Data width in bits.",
    "FALLTHROUGH": "First-word fall-through when TRUE.",
    "OPT_REGISTERED": "When set, register crossing payload and response fields. Behavior must stay the same.",
    "C_APB_ADDR_WIDTH": "APB address width.",
    "C_APB_DATA_WIDTH": "APB data width.",
    "STAGES": "Implementation depth parameter. Choose a safe crossing yourself.",
    "SYNC_STAGES": "Implementation depth parameter. Choose a safe crossing yourself.",
    "CHAINS": "Implementation depth parameter. Choose a safe crossing yourself.",
    "N": "Implementation depth or word width, as used by the module.",
    "NFF": "Implementation parameter. Choose a safe crossing yourself.",
    "XCLOCK_FFS": "Implementation parameter. Choose a safe crossing yourself.",
    "RST_POL": "1 means async_rst_i is active-high.",
    "ResetValue": "Value of the synchronized bit after reset.",
    "DECOUPLED": "When set, source may accept a new item before the previous destination handshake returns.",
    "SEND_RESET_MSG": "When set, emit RESET_MSG after reset.",
    "RESET_MSG": "Payload emitted after reset when SEND_RESET_MSG is set.",
    "CLEAR_ON_ASYNC_RESET": "When set, also flush on async reset.",
}

PORT_DESC = {
    "src_clk_i": "Source-domain clock.",
    "dst_clk_i": "Destination-domain clock.",
    "src_rst_ni": "Active-low source-domain reset.",
    "dst_rst_ni": "Active-low destination-domain reset.",
    "src_data_i": "Source payload.",
    "dst_data_o": "Destination payload.",
    "src_valid_i": "Source valid.",
    "src_ready_o": "Source ready.",
    "dst_valid_o": "Destination valid.",
    "dst_ready_i": "Destination ready.",
    "wclk": "Write-domain clock.",
    "rclk": "Read-domain clock.",
    "wrst_n": "Active-low write-domain reset.",
    "rrst_n": "Active-low read-domain reset.",
    "winc": "Write increment / write request.",
    "rinc": "Read increment / read request.",
    "wdata": "Write data.",
    "rdata": "Read data.",
    "wfull": "FIFO full, write domain.",
    "rempty": "FIFO empty, read domain.",
    "awfull": "Almost full, write domain.",
    "arempty": "Almost empty, read domain.",
    "S_APB_PCLK": "Source APB clock.",
    "M_APB_PCLK": "Destination APB clock.",
    "S_PRESETn": "Active-low source reset.",
    "M_PRESETn": "Active-low destination reset output.",
    "S_APB_PREADY": "Source APB ready. Assert only after the destination transfer completes.",
    "M_APB_PREADY": "Destination APB ready input.",
    "S_APB_PSEL": "Source APB select.",
    "M_APB_PSEL": "Destination APB select.",
    "S_APB_PENABLE": "Source APB enable (access phase).",
    "M_APB_PENABLE": "Destination APB enable (access phase).",
    "S_APB_PWRITE": "Source write/read.",
    "M_APB_PWRITE": "Destination write/read.",
    "S_APB_PSLVERR": "Source slave error.",
    "M_APB_PSLVERR": "Destination slave error.",
}


def lang_label(hdl: str) -> str:
    if "systemverilog" in hdl.lower() or hdl.lower() == "sv":
        return "SystemVerilog"
    return "Verilog-2001"


def yaml_list(text: str, key: str) -> list[str]:
    if f"{key}:" not in text:
        return []
    block = text.split(f"{key}:", 1)[1]
    nxt = re.search(r"^[a-z_]+:", block, re.M)
    if nxt:
        block = block[: nxt.start()]
    return re.findall(r"^  - (\S+)", block, re.M)


def extract_header(bench: Path, top: str) -> str:
    files = list((bench / "original" / "rtl").rglob("*.v")) + list(
        (bench / "original" / "rtl").rglob("*.sv")
    )
    files += list((bench / "fixed" / "rtl").rglob("*.v")) + list(
        (bench / "fixed" / "rtl").rglob("*.sv")
    )
    for path in files:
        text = path.read_text(errors="replace")
        text = re.sub(r"`ifdef\s+\w+.*?`endif", "", text, flags=re.S)
        text = re.sub(r"`ifndef\s+\w+.*?`endif", "", text, flags=re.S)
        m = re.search(rf"module\s+{re.escape(top)}\b", text)
        if not m:
            continue
        chunk = text[m.start() :]
        end = chunk.find(");")
        if end == -1:
            continue
        header = chunk[: end + 2]
        lines = []
        for line in header.splitlines():
            stripped = line.split("//")[0].rstrip()
            if stripped.strip():
                lines.append(stripped)
        return "\n".join(lines) + "\n"
    raise SystemExit(f"no module {top} in {bench}")


def parse_parameters(header: str) -> list[str]:
    m = re.search(r"#\s*\((.*)\)\s*\(", header, re.S)
    if not m:
        return []
    names = []
    for raw in m.group(1).split(","):
        raw = re.sub(r"\s+", " ", raw).strip()
        if not raw:
            continue
        if "localparam" in raw:
            continue
        raw = re.sub(r"^parameter\s+", "", raw)
        raw = re.sub(r"^(int unsigned|bit|type)\s+", "", raw)
        raw = re.sub(r"^\[.*?\]\s+", "", raw)
        name = raw.split("=")[0].split()[-1].strip()
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            names.append(name)
    return names


PORT_RE = re.compile(
    r"\b(input|output|inout)\b"
    r"(?:[ \t]+(?:wire|reg|logic|signed|unsigned))*"
    r"(?:[ \t]+\[[^\]]+\])?"
    r"[ \t]+([A-Za-z_][A-Za-z0-9_]*(?:[ \t]*,[ \t]*[A-Za-z_][A-Za-z0-9_]*)*)",
)

RESERVED = {"input", "output", "inout", "wire", "reg", "logic", "signed", "unsigned"}


def parse_ports(header: str) -> list[tuple[str, str]]:
    ports_part = re.split(r"\)\s*\(", header, maxsplit=1)[-1]
    found: list[tuple[str, str]] = []
    for direction, names in PORT_RE.findall(ports_part):
        for name in names.split(","):
            name = name.strip().rstrip(";").split("=")[0].strip()
            if name in RESERVED:
                continue
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
                found.append((direction, name))
    if found:
        return found
    # Old Verilog port list: module top (a, b, c);
    m = re.search(r"module\s+\w+\s*\((.*)\)\s*;", header, re.S)
    if not m:
        return []
    for raw in m.group(1).split(","):
        name = raw.strip().split()[-1] if raw.strip() else ""
        name = re.sub(r"[^A-Za-z0-9_]", "", name)
        if not name or name in RESERVED or name.startswith("UART_") or name in {"endif", "ifdef", "ifndef"}:
            continue
        nl = name.lower()
        direction = "output" if re.search(r"(_o|_out|int_o)$", nl) else "input"
        found.append((direction, name))
    return found


def reset_polarity(name: str) -> str:
    n = name.lower()
    if n.endswith("n") or "rstn" in n or "rst_n" in n or "presetn" in n or "aresetn" in n:
        return "active-low"
    if n in {"rst", "reset", "i_reset", "wb_rst_i", "rst_i"} or n.endswith("_rst"):
        return "active-high"
    return "reset"


def port_meaning(name: str, direction: str, clocks: list[str], resets: list[str]) -> str:
    if name in PORT_DESC:
        return PORT_DESC[name]
    nl = name.lower()
    if name in clocks or re.search(r"clk", nl):
        return "Clock."
    if name in resets or re.search(r"rst|reset", nl):
        return f"{reset_polarity(name).capitalize()} reset."
    if "valid" in nl:
        return "Handshake valid."
    if "ready" in nl:
        return "Handshake ready."
    if re.search(r"data|wdata|rdata|tdata|pwdata|prdata", nl):
        return "Data payload."
    if "addr" in nl:
        return "Address."
    if "strb" in nl or "wstrb" in nl:
        return "Write strobes."
    if "prot" in nl:
        return "Protection bits."
    if "resp" in nl:
        return "Response status."
    if "full" in nl:
        return "FIFO full flag."
    if "empty" in nl:
        return "FIFO empty flag."
    if direction == "inout":
        return "Bidirectional pin."
    return "See Behavior."


def clock_line(name: str, clocks: list[str], mode: str) -> str:
    if mode == "single":
        return f"    {name}: Single clock."
    if mode == "related":
        others = [c for c in clocks if c != name]
        peer = others[0] if others else "the other clock"
        return f"    {name}: Related (integer-ratio) clock with {peer}."
    others = [c for c in clocks if c != name]
    peer = others[0] if others else "the other clock"
    extra = ""
    if name in {"src_clk_i", "wclk", "S_APB_PCLK", "S_AXI_ACLK"}:
        extra = " No fixed frequency or phase relationship."
    return f"    {name}: Independent asynchronous clock (async to {peer}).{extra}"


def render(
    bench_id: str,
    top: str,
    hdl: str,
    header: str,
    clocks: list[str],
    resets: list[str],
    cdc: bool,
) -> str:
    mode = CLOCK_MODE.get(bench_id, "async" if len(clocks) > 1 else "single")
    ports = parse_ports(header)
    params = parse_parameters(header)
    ins = [(d, n) for d, n in ports if d == "input"]
    outs = [(d, n) for d, n in ports if d == "output"]
    inouts = [(d, n) for d, n in ports if d == "inout"]

    def port_block(items: list[tuple[str, str]]) -> str:
        if not items:
            return "    None."
        return "\n".join(
            f"    {n}: {port_meaning(n, d, clocks, resets)}" for d, n in items
        )

    clock_lines = (
        "\n".join(clock_line(c, clocks, mode) for c in clocks)
        if clocks
        else "    None."
    )
    reset_lines = (
        "\n".join(f"    {r}: {reset_polarity(r)}." for r in resets)
        if resets
        else "    None."
    )
    if params:
        param_lines = "\n".join(
            f"    {p}: {PARAM_DESC.get(p, 'See Behavior.')}" for p in params
        )
    else:
        param_lines = "    None."

    lines = [
        "Please act as a professional Verilog designer.",
        "",
        f"Implement {IMPLEMENT[bench_id]}",
        "",
        "Module name:",
        f"    {top}",
        "",
        "Language:",
        f"    {lang_label(hdl)}",
        "",
        "Clocks:",
        clock_lines,
        "",
        "Resets:",
        reset_lines,
        "",
        "Input ports:",
        port_block(ins),
        "",
        "Output ports:",
        port_block(outs),
    ]
    if inouts:
        lines += ["", "Inout ports:", port_block(inouts)]
    lines += [
        "",
        "Parameters:",
        param_lines,
        "",
        "Behavior:",
        *[f"    - {b}" for b in BEHAVIOR[bench_id]],
        "",
    ]
    if cdc:
        lines += ["CDC requirement:", *[f"    {ln}" for ln in CDC_LINE.splitlines()], ""]
    lines += [CLOSER, "", header.rstrip(), ""]
    return "\n".join(lines)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    wrote = []
    missing = []
    for man in sorted(BENCH.glob("*/manifest.yaml")):
        bench_id = man.parent.name
        text = man.read_text()
        top = re.search(r"^top_module:\s*(\S+)", text, re.M).group(1)
        hdl = re.search(r"^hdl:\s*(\S+)", text, re.M).group(1)
        clocks = yaml_list(text, "clocks")
        resets = yaml_list(text, "resets")
        if bench_id not in IMPLEMENT or bench_id not in BEHAVIOR:
            missing.append(bench_id)
            continue
        header = extract_header(man.parent, top)
        for cdc, suffix in ((False, "functional"), (True, "cdc_explicit")):
            (OUT / f"{bench_id}.{suffix}.md").write_text(
                render(bench_id, top, hdl, header, clocks, resets, cdc)
            )
        wrote.append(bench_id)
    if missing:
        raise SystemExit("missing spec for: " + ", ".join(missing))
    print(f"wrote {len(wrote)} circuits ({len(wrote) * 2} files)")


if __name__ == "__main__":
    main()
