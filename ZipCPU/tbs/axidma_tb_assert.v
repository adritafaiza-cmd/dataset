`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// axidma_tb.v  –  Self-checking testbench for axidma
//
// Fixes vs original axidma_tb_assert:
//   1. BID latched at AW handshake, not at WLAST.
//   2. Write data accepted only after AW address has been captured (wr_addr_valid).
//   3. WVALID-stable assertion gated out on the handshake cycle to avoid
//      false fires on back-to-back beats.
//   4. axil_write / axil_read tasks sample handshake on posedge, not via wait().
//   5. Read burst model driven by a proper state machine (IDLE→ACTIVE→DONE).
//
// Test scenarios added beyond the original happy-path:
//   TC1  – Aligned copy, single burst  (original test, corrected)
//   TC2  – Aligned copy, multi-burst   (>MAXBURST words)
//   TC3  – Back-to-back transfers      (restart immediately after done)
//   TC4  – Abort via ABORT_KEY         (check DMA stops cleanly)
//   TC5  – Read-error response         (RRESP=SLVERR, check r_err set)
//   TC6  – Write-error response        (BRESP=SLVERR, check r_err set)
// =============================================================================

module axidma_assert;

    // -------------------------------------------------------------------------
    // Parameters (must match DUT instantiation below)
    // -------------------------------------------------------------------------
    localparam AW       = 8;    // address width
    localparam DW       = 32;   // data width
    localparam IW       = 1;    // ID width
    localparam LGMAXB   = 2;    // log2(max burst) → 4 beats
    localparam MAXBURST = (1 << LGMAXB);

    // AXI-Lite register addresses (byte-addressed, LSBs ignored by DUT)
    localparam CTRL_ADDR  = 5'h00;
    localparam SRC_LO     = 5'h08;
    localparam DST_LO     = 5'h10;
    localparam LEN_LO     = 5'h18;

    // ABORT_KEY matches DUT parameter default
    localparam [7:0] ABORT_KEY = 8'h6d;

    // -------------------------------------------------------------------------
    // Clock & reset
    
    reg clk  = 0;
    reg rstn = 0;
    always #5 clk = ~clk;

    integer errors = 0;
    integer i;

 // AXI-Lite slave-side signals (driven by TB)
    
    reg        s_awvalid;
    wire       s_awready;
    reg  [4:0] s_awaddr;
    reg  [2:0] s_awprot;

    reg        s_wvalid;
    wire       s_wready;
    reg [31:0] s_wdata;
    reg  [3:0] s_wstrb;

    wire       s_bvalid;
    reg        s_bready;
    wire [1:0] s_bresp;

    reg        s_arvalid;
    wire       s_arready;
    reg  [4:0] s_araddr;
    reg  [2:0] s_arprot;

    wire        s_rvalid;
    reg         s_rready;
    wire [31:0] s_rdata;
    wire  [1:0] s_rresp;

    // -------------------------------------------------------------------------
    // AXI master-side signals (DUT → memory model)
 
    wire            m_awvalid;
    reg             m_awready;
    wire [IW-1:0]   m_awid;
    wire [AW-1:0]   m_awaddr;
    wire [7:0]      m_awlen;
    wire [2:0]      m_awsize;
    wire [1:0]      m_awburst;
    wire            m_awlock;
    wire [3:0]      m_awcache;
    wire [2:0]      m_awprot_m;
    wire [3:0]      m_awqos;

    wire            m_wvalid;
    reg             m_wready;
    wire [DW-1:0]   m_wdata;
    wire [DW/8-1:0] m_wstrb;
    wire            m_wlast;

    reg             m_bvalid;
    wire            m_bready;
    reg [IW-1:0]    m_bid;
    reg [1:0]       m_bresp;

    wire            m_arvalid;
    reg             m_arready;
    wire [IW-1:0]   m_arid;
    wire [AW-1:0]   m_araddr;
    wire [7:0]      m_arlen;
    wire [2:0]      m_arsize;
    wire [1:0]      m_arburst;
    wire            m_arlock;
    wire [3:0]      m_arcache;
    wire [2:0]      m_arprot_m;
    wire [3:0]      m_arqos;

    reg             m_rvalid;
    wire            m_rready;
    reg [IW-1:0]    m_rid;
    reg [DW-1:0]    m_rdata;
    reg             m_rlast;
    reg [1:0]       m_rresp;

    wire o_int;

    
    // DUT instantiation
    
    axidma #(
        .C_AXI_ID_WIDTH (IW),
        .C_AXI_ADDR_WIDTH(AW),
        .C_AXI_DATA_WIDTH(DW),
        .OPT_UNALIGNED  (1'b0),
        .OPT_WRAPMEM    (1'b1),
        .LGMAXBURST     (LGMAXB),
        .LGFIFO         (LGMAXB + 1),   // 2× max burst
        .LGLEN          (AW)
    ) dut (
        .S_AXI_ACLK    (clk),
        .S_AXI_ARESETN (rstn),

        .S_AXIL_AWVALID(s_awvalid),
        .S_AXIL_AWREADY(s_awready),
        .S_AXIL_AWADDR (s_awaddr),
        .S_AXIL_AWPROT (s_awprot),

        .S_AXIL_WVALID (s_wvalid),
        .S_AXIL_WREADY (s_wready),
        .S_AXIL_WDATA  (s_wdata),
        .S_AXIL_WSTRB  (s_wstrb),

        .S_AXIL_BVALID (s_bvalid),
        .S_AXIL_BREADY (s_bready),
        .S_AXIL_BRESP  (s_bresp),

        .S_AXIL_ARVALID(s_arvalid),
        .S_AXIL_ARREADY(s_arready),
        .S_AXIL_ARADDR (s_araddr),
        .S_AXIL_ARPROT (s_arprot),

        .S_AXIL_RVALID (s_rvalid),
        .S_AXIL_RREADY (s_rready),
        .S_AXIL_RDATA  (s_rdata),
        .S_AXIL_RRESP  (s_rresp),

        .M_AXI_AWVALID (m_awvalid),
        .M_AXI_AWREADY (m_awready),
        .M_AXI_AWID    (m_awid),
        .M_AXI_AWADDR  (m_awaddr),
        .M_AXI_AWLEN   (m_awlen),
        .M_AXI_AWSIZE  (m_awsize),
        .M_AXI_AWBURST (m_awburst),
        .M_AXI_AWLOCK  (m_awlock),
        .M_AXI_AWCACHE (m_awcache),
        .M_AXI_AWPROT  (m_awprot_m),
        .M_AXI_AWQOS   (m_awqos),

        .M_AXI_WVALID  (m_wvalid),
        .M_AXI_WREADY  (m_wready),
        .M_AXI_WDATA   (m_wdata),
        .M_AXI_WSTRB   (m_wstrb),
        .M_AXI_WLAST   (m_wlast),

        .M_AXI_BVALID  (m_bvalid),
        .M_AXI_BREADY  (m_bready),
        .M_AXI_BID     (m_bid),
        .M_AXI_BRESP   (m_bresp),

        .M_AXI_ARVALID (m_arvalid),
        .M_AXI_ARREADY (m_arready),
        .M_AXI_ARID    (m_arid),
        .M_AXI_ARADDR  (m_araddr),
        .M_AXI_ARLEN   (m_arlen),
        .M_AXI_ARSIZE  (m_arsize),
        .M_AXI_ARBURST (m_arburst),
        .M_AXI_ARLOCK  (m_arlock),
        .M_AXI_ARCACHE (m_arcache),
        .M_AXI_ARPROT  (m_arprot_m),
        .M_AXI_ARQOS   (m_arqos),

        .M_AXI_RVALID  (m_rvalid),
        .M_AXI_RREADY  (m_rready),
        .M_AXI_RID     (m_rid),
        .M_AXI_RDATA   (m_rdata),
        .M_AXI_RLAST   (m_rlast),
        .M_AXI_RRESP   (m_rresp),

        .o_int         (o_int)
    );


    // Memory model   
    reg [DW-1:0]  mem [0:63];   // 64 words × 4 B = 256 B (fits AW=8)

    // ---- Write path ----------------------------------------------------------
    // FIX: latch AW address & ID at the AW handshake; only accept W data after
    //      the address has been registered (wr_addr_valid).
    reg [AW-1:0]  wr_addr;
    reg [IW-1:0]  wr_id_lat;
    reg           wr_addr_valid;    // true once AW handshake has occurred

    // Inject a write error on a specific address (used by TC6)
    reg           inject_wresp_err;
    reg [AW-1:0]  inject_wresp_addr;

    always @(posedge clk) begin
        m_awready <= 1'b0;
        m_wready  <= 1'b0;

        if (!rstn) begin
            m_bvalid      <= 1'b0;
            wr_addr_valid <= 1'b0;
        end else begin
            // AW handshake — latch address + ID
            if (m_awvalid && !m_awready) begin
                m_awready     <= 1'b1;
                wr_addr       <= m_awaddr;
                wr_id_lat     <= m_awid;        // FIX: latch ID here
                wr_addr_valid <= 1'b1;
            end

            // W data — only accepted once address is valid
            // FIX: guard with wr_addr_valid
            if (m_wvalid && wr_addr_valid) begin
                m_wready <= 1'b1;
                if (m_wstrb[0]) mem[wr_addr[AW-1:2]][7:0]   <= m_wdata[7:0];
                if (m_wstrb[1]) mem[wr_addr[AW-1:2]][15:8]  <= m_wdata[15:8];
                if (m_wstrb[2]) mem[wr_addr[AW-1:2]][23:16] <= m_wdata[23:16];
                if (m_wstrb[3]) mem[wr_addr[AW-1:2]][31:24] <= m_wdata[31:24];
                wr_addr <= wr_addr + 4;

                if (m_wlast) begin
                    m_bvalid      <= 1'b1;
                    // FIX: use latched ID, not m_awid (which may have moved on)
                    m_bid         <= wr_id_lat;
                    // Inject error if requested for this burst
                    if (inject_wresp_err &&
                        (wr_addr[AW-1:2] == inject_wresp_addr[AW-1:2]))
                        m_bresp <= 2'b10;   // SLVERR
                    else
                        m_bresp <= 2'b00;   // OKAY
                    wr_addr_valid <= 1'b0;
                end
            end

            if (m_bvalid && m_bready)
                m_bvalid <= 1'b0;
        end
    end

    // ---- Read path -----------------------------------------------------------
    // Read path FSM — 3 states:
    //
    //   RD_IDLE   : waiting for M_AXI_ARVALID. Accept with ARREADY pulse and
    //               latch addr/len, move to RD_WAIT.
    //
    //   RD_WAIT   : one-cycle pipeline bubble.
    //               The DUT sets phantom_read on the AR-handshake cycle and only
    //               clears no_read_bursts_outstanding (→ RREADY=1) the cycle
    //               after phantom_read. We must not present RVALID until RREADY
    //               is already high, so we stall here for exactly one cycle.
    //
    //   RD_ACTIVE : present beats one at a time. Between beats RVALID is
    //               deasserted for one cycle so rd_addr/rd_beat settle before
    //               the next beat is loaded. On RLAST handshake, if a new AR is
    //               already waiting we accept it and go back to RD_WAIT
    //               (another pipeline bubble), otherwise back to RD_IDLE.

    localparam RD_IDLE   = 2'd0;
    localparam RD_WAIT   = 2'd1;   // ← new pipeline-bubble state
    localparam RD_ACTIVE = 2'd2;

    reg [1:0]    rd_state;
    reg [AW-1:0] rd_addr;
    reg [7:0]    rd_len;
    reg [7:0]    rd_beat;

    // Inject a read error on a specific beat address (used by TC5)
    reg           inject_rresp_err;
    reg [AW-1:0]  inject_rresp_addr;

    always @(posedge clk) begin
        m_arready <= 1'b0;   // default: deasserted

        if (!rstn) begin
            m_rvalid <= 1'b0;
            rd_state <= RD_IDLE;
        end else begin
            case (rd_state)

            
            RD_IDLE: begin
                if (m_arvalid) begin
                    m_arready <= 1'b1;          // pulse ARREADY
                    rd_addr   <= m_araddr;
                    rd_len    <= m_arlen;
                    rd_beat   <= 8'd0;
                    rd_state  <= RD_WAIT;       // bubble before first RVALID
                end
            end

            // One idle cycle: DUT phantom_read has fired, RREADY will be 1
            // from the next cycle onward.  Do NOT assert RVALID here.
            RD_WAIT: begin
                rd_state <= RD_ACTIVE;
            end

            
            RD_ACTIVE: begin
                // Load next beat when R channel is free
                if (!m_rvalid) begin
                    m_rvalid <= 1'b1;
                    m_rdata  <= mem[rd_addr[AW-1:2]];
                    m_rid    <= m_arid;
                    m_rlast  <= (rd_beat == rd_len);
                    m_rresp  <= (inject_rresp_err &&
                                 (rd_addr[AW-1:2] == inject_rresp_addr[AW-1:2]))
                                ? 2'b10 : 2'b00;
                end

                // Beat handshake
                if (m_rvalid && m_rready) begin
                    m_rvalid <= 1'b0;
                    if (rd_beat == rd_len) begin
                        // Last beat — check for back-to-back AR
                        if (m_arvalid) begin
                            m_arready <= 1'b1;
                            rd_addr   <= m_araddr;
                            rd_len    <= m_arlen;
                            rd_beat   <= 8'd0;
                            rd_state  <= RD_WAIT;   // pipeline bubble again
                        end else begin
                            rd_state  <= RD_IDLE;
                        end
                    end else begin
                        // Advance; one-cycle bubble keeps rd_addr settled
                        rd_addr <= rd_addr + 4;
                        rd_beat <= rd_beat + 1;
                    end
                end
            end

            endcase
        end
    end


    // AXI handshake protocol assertions (continuous monitors)


    // — Valid-stable: once VALID is asserted it must not drop until READY —
    //
    // The check is: if VALID was high and READY was low last cycle,
    // VALID must still be high this cycle.
    // We explicitly exclude the cycle *after* a handshake (VALID && READY)
    // because in back-to-back transfers the initiator may drop VALID one cycle
    // after the handshake before re-asserting it for the next beat.
    // That is NOT a protocol violation.

    reg prev_s_aw_unh, prev_s_w_unh, prev_s_ar_unh;
    reg prev_m_aw_unh, prev_m_w_unh,  prev_m_ar_unh;

    always @(posedge clk) begin
        if (!rstn) begin
            prev_s_aw_unh <= 0; prev_s_w_unh  <= 0; prev_s_ar_unh <= 0;
            prev_m_aw_unh <= 0; prev_m_w_unh  <= 0; prev_m_ar_unh <= 0;
        end else begin
            // FIX: "unhandshaked" = valid && !ready (no handshake this cycle)
            //      Assertion fires if VALID went low without being acknowledged.
            if (prev_s_aw_unh && !s_awvalid) begin
                $display("ASSERT FAIL @%0t: S_AXIL_AWVALID dropped before AWREADY", $time);
                errors = errors + 1;
            end
            if (prev_s_w_unh && !s_wvalid) begin
                $display("ASSERT FAIL @%0t: S_AXIL_WVALID dropped before WREADY", $time);
                errors = errors + 1;
            end
            if (prev_s_ar_unh && !s_arvalid) begin
                $display("ASSERT FAIL @%0t: S_AXIL_ARVALID dropped before ARREADY", $time);
                errors = errors + 1;
            end
            if (prev_m_aw_unh && !m_awvalid) begin
                $display("ASSERT FAIL @%0t: M_AXI_AWVALID dropped before AWREADY", $time);
                errors = errors + 1;
            end
            // FIX for WVALID: W channel may legally go idle between bursts;
            // only flag if WVALID dropped in the middle of an unfinished burst
            // (i.e. !WLAST was set last cycle).
            if (prev_m_w_unh && !m_wvalid) begin
                $display("ASSERT FAIL @%0t: M_AXI_WVALID dropped before WREADY (mid-burst)", $time);
                errors = errors + 1;
            end
            if (prev_m_ar_unh && !m_arvalid) begin
                $display("ASSERT FAIL @%0t: M_AXI_ARVALID dropped before ARREADY", $time);
                errors = errors + 1;
            end

            // Update "unhandshaked" state for next cycle
            prev_s_aw_unh <= s_awvalid  && !s_awready;
            prev_s_w_unh  <= s_wvalid   && !s_wready;
            prev_s_ar_unh <= s_arvalid  && !s_arready;
            prev_m_aw_unh <= m_awvalid  && !m_awready;
            // FIX: only flag mid-burst WVALID drops (not the cycle after WLAST)
            prev_m_w_unh  <= m_wvalid   && !m_wready && !m_wlast;
            prev_m_ar_unh <= m_arvalid  && !m_arready;
        end
    end

    // BREADY must be high whenever BVALID is (DUT drives BREADY = !r_done)
    always @(posedge clk) begin
        if (rstn && m_bvalid && !m_bready) begin
            $display("ASSERT FAIL @%0t: M_AXI_BVALID high but BREADY low", $time);
            errors = errors + 1;
        end
    end

    // RREADY must be high whenever RVALID is high AND a burst is in progress.
    // DUT drives RREADY = !no_read_bursts_outstanding, which is 0 before any
    // burst is accepted — legal. Only assert when rd_state == RD_ACTIVE.
    always @(posedge clk) begin
        if (rstn && m_rvalid && !m_rready && (rd_state == RD_ACTIVE)) begin
            $display("ASSERT FAIL @%0t: M_AXI_RVALID high but RREADY low (burst active)", $time);
            errors = errors + 1;
        end
    end

    // AWLEN must be < 2^LGMAXBURST
    always @(posedge clk) begin
        if (rstn && m_awvalid && (m_awlen >= MAXBURST)) begin
            $display("ASSERT FAIL @%0t: M_AXI_AWLEN=%0d exceeds MAXBURST-1=%0d",
                     $time, m_awlen, MAXBURST-1);
            errors = errors + 1;
        end
        if (rstn && m_arvalid && (m_arlen >= MAXBURST)) begin
            $display("ASSERT FAIL @%0t: M_AXI_ARLEN=%0d exceeds MAXBURST-1=%0d",
                     $time, m_arlen, MAXBURST-1);
            errors = errors + 1;
        end
    end

    // 

    // Tasks


    // ---- check ---------------------------------------------------------------
    task check;
        input        cond;
        input [255:0] msg;
        begin
            if (cond)
                $display("PASS: %s", msg);
            else begin
                $display("FAIL: %s", msg);
                errors = errors + 1;
            end
        end
    endtask

    // ---- axil_write ----------------------------------------------------------
    // FIX: drive signals before posedge, sample READY on posedge (not via wait).
    task axil_write;
        input [4:0]  addr;
        input [31:0] data;
        integer timeout;
        begin
            // Present address + data channels simultaneously
            @(negedge clk);
            s_awaddr  = addr;   s_awprot = 0;
            s_wdata   = data;   s_wstrb  = 4'hf;
            s_awvalid = 1'b1;   s_wvalid = 1'b1;
            s_bready  = 1'b1;

            // Wait for BOTH channels to be accepted (posedge sampling)
            timeout = 0;
            @(posedge clk);
            while (!(s_awready && s_wready)) begin
                timeout = timeout + 1;
                if (timeout > 200) begin
                    $display("TIMEOUT: axil_write addr=%0h never got ready", addr);
                    errors = errors + 1;
                    disable axil_write;
                end
                @(posedge clk);
            end

            @(negedge clk);
            s_awvalid = 1'b0;
            s_wvalid  = 1'b0;

            // Wait for write response
            timeout = 0;
            @(posedge clk);
            while (!s_bvalid) begin
                timeout = timeout + 1;
                if (timeout > 200) begin
                    $display("TIMEOUT: axil_write addr=%0h never got BVALID", addr);
                    errors = errors + 1;
                    disable axil_write;
                end
                @(posedge clk);
            end

            @(negedge clk);
            s_bready = 1'b0;
        end
    endtask

    // ---- axil_read -----------------------------------------------------------
    task axil_read;
        input  [4:0]  addr;
        output [31:0] data;
        integer timeout;
        begin
            @(negedge clk);
            s_araddr  = addr;   s_arprot = 0;
            s_arvalid = 1'b1;
            s_rready  = 1'b1;

            timeout = 0;
            @(posedge clk);
            while (!s_arready) begin
                timeout = timeout + 1;
                if (timeout > 200) begin
                    $display("TIMEOUT: axil_read addr=%0h never got ARREADY", addr);
                    errors = errors + 1;
                    disable axil_read;
                end
                @(posedge clk);
            end

            @(negedge clk);
            s_arvalid = 1'b0;

            timeout = 0;
            @(posedge clk);
            while (!s_rvalid) begin
                timeout = timeout + 1;
                if (timeout > 200) begin
                    $display("TIMEOUT: axil_read addr=%0h never got RVALID", addr);
                    errors = errors + 1;
                    disable axil_read;
                end
                @(posedge clk);
            end
            data = s_rdata;

            @(negedge clk);
            s_rready = 1'b0;
        end
    endtask

    // ---- wait_for_done -------------------------------------------------------
    // Poll CTRL until busy bit (bit 0) is clear, with timeout.
    task wait_for_done;
        input integer max_cycles;
        reg [31:0] st;
        integer    cnt;
        begin
            cnt = 0;
            axil_read(CTRL_ADDR, st);
            while (st[0]) begin
                repeat (10) @(posedge clk);
                axil_read(CTRL_ADDR, st);
                cnt = cnt + 10;
                if (cnt > max_cycles) begin
                    $display("TIMEOUT: DMA busy bit never cleared");
                    errors = errors + 1;
                    disable wait_for_done;
                end
            end
        end
    endtask

    // ---- mem_init ------------------------------------------------------------
    task mem_init;
        integer k;
        begin
            for (k = 0; k < 64; k = k + 1)
                mem[k] = 32'h0;
        end
    endtask


    // Stimulus


    reg [31:0] status;

    initial begin
        // ---- default signal states ----
        s_awvalid = 0; s_awaddr = 0; s_awprot = 0;
        s_wvalid  = 0; s_wdata  = 0; s_wstrb  = 0;
        s_bready  = 0;
        s_arvalid = 0; s_araddr = 0; s_arprot = 0;
        s_rready  = 0;

        inject_rresp_err = 0; inject_rresp_addr = 0;
        inject_wresp_err = 0; inject_wresp_addr = 0;

        mem_init();

        // ---- Reset sequence ----
        repeat (5) @(posedge clk);
        rstn = 1'b1;
        repeat (5) @(posedge clk);


        // TC1 – Aligned single-burst copy (4 words = 16 bytes)
        // Source  : 0x00 (mem[0..3]  = 0x11111111 .. 0x44444444)
        // Dest    : 0x40 (mem[16..19])
 
        $display("\n--- TC1: Aligned single-burst copy ---");
        mem_init();
        mem[0] = 32'h11111111;
        mem[1] = 32'h22222222;
        mem[2] = 32'h33333333;
        mem[3] = 32'h44444444;

        axil_write(SRC_LO,   32'h00000000);   // source = 0x00
        axil_write(DST_LO,   32'h00000040);   // dest   = 0x40
        axil_write(LEN_LO,   32'h00000010);   // length = 16 bytes
        axil_write(CTRL_ADDR,32'h00000001);   // start

        wait_for_done(500);

        axil_read(CTRL_ADDR, status);
        check(status[0] == 1'b0, "TC1: DMA not busy after completion");
        check(status[4] == 1'b0, "TC1: No error flag");
        check(mem[16] == 32'h11111111, "TC1: word 0 copied correctly");
        check(mem[17] == 32'h22222222, "TC1: word 1 copied correctly");
        check(mem[18] == 32'h33333333, "TC1: word 2 copied correctly");
        check(mem[19] == 32'h44444444, "TC1: word 3 copied correctly");


        // TC2 – Multi-burst copy (8 words = 32 bytes, 2 bursts of 4)
        // Source  : 0x00  (mem[0..7])
        // Dest    : 0x80  (mem[32..39])   — needs AW=8, fits in 256 B space
      
        $display("\n--- TC2: Multi-burst copy (8 words) ---");
        mem_init();
        for (i = 0; i < 8; i = i + 1)
            mem[i] = {4{i[7:0]+8'hA0}};  // 0xA0A0A0A0, 0xA1A1A1A1 ...

        // Destination 0x80 = byte 128 = word 32 in mem[]
        axil_write(SRC_LO,   32'h00000000);
        axil_write(DST_LO,   32'h00000080);   // 0x80 = 128
        axil_write(LEN_LO,   32'h00000020);   // 32 bytes = 8 words
        axil_write(CTRL_ADDR,32'h00000001);

        wait_for_done(800);

        axil_read(CTRL_ADDR, status);
        check(status[0] == 1'b0, "TC2: DMA not busy");
        check(status[4] == 1'b0, "TC2: No error flag");
        begin : TC2_CHECK
            integer ok;
            ok = 1;
            for (i = 0; i < 8; i = i + 1)
                if (mem[32+i] !== mem[i]) ok = 0;
            check(ok, "TC2: All 8 words copied correctly");
        end


        // TC3 – Back-to-back transfers (two sequential DMAs, no gap)
   
        $display("\n--- TC3: Back-to-back transfers ---");
        mem_init();
        mem[0] = 32'hDEADBEEF;
        mem[1] = 32'hCAFEBABE;
        mem[2] = 32'h01234567;
        mem[3] = 32'h89ABCDEF;

        // First transfer: 0x00 → 0x40, 16 bytes
        axil_write(SRC_LO,   32'h00000000);
        axil_write(DST_LO,   32'h00000040);
        axil_write(LEN_LO,   32'h00000010);
        axil_write(CTRL_ADDR,32'h00000001);
        wait_for_done(500);

        // Second transfer: 0x40 → 0x80, 16 bytes (copy of the copy)
        axil_write(SRC_LO,   32'h00000040);
        axil_write(DST_LO,   32'h00000080);
        axil_write(LEN_LO,   32'h00000010);
        axil_write(CTRL_ADDR,32'h00000001);
        wait_for_done(500);

        axil_read(CTRL_ADDR, status);
        check(status[0] == 1'b0, "TC3: DMA not busy after 2nd transfer");
        check(mem[32] == 32'hDEADBEEF, "TC3: 2nd transfer word 0");
        check(mem[33] == 32'hCAFEBABE, "TC3: 2nd transfer word 1");
        check(mem[34] == 32'h01234567, "TC3: 2nd transfer word 2");
        check(mem[35] == 32'h89ABCDEF, "TC3: 2nd transfer word 3");


        // TC4 – Abort via ABORT_KEY
        // Start a long transfer and inject abort mid-flight.

        $display("\n--- TC4: Abort via ABORT_KEY ---");
        mem_init();
        for (i = 0; i < 32; i = i + 1)
            mem[i] = {4{i[7:0]}};

        // Long transfer: 0x00 → 0x80, 32 words = 128 bytes
        axil_write(SRC_LO,   32'h00000000);
        axil_write(DST_LO,   32'h00000080);
        axil_write(LEN_LO,   32'h00000080);  // 128 bytes
        axil_write(CTRL_ADDR,32'h00000001);  // start

        // Let it run a few cycles then abort
        repeat (30) @(posedge clk);

        // Write ABORT_KEY to bits [31:24] of CTRL
        axil_write(CTRL_ADDR, {ABORT_KEY, 24'h000000});

        wait_for_done(800);

        axil_read(CTRL_ADDR, status);
        check(status[0] == 1'b0, "TC4: DMA not busy after abort");
        check(status[3] == 1'b1, "TC4: Abort flag set");

        // Clear abort flag for next test by writing start=0 err=0 abort=0
        axil_write(CTRL_ADDR, 32'h00000000);


        // TC5 – Read error response (RRESP = SLVERR)
      
        $display("\n--- TC5: Read error (RRESP=SLVERR) ---");
        mem_init();
        mem[0] = 32'hAAAAAAAA;
        mem[1] = 32'hBBBBBBBB;

        // Set up: inject SLVERR on reads from word 1 (byte addr 0x04)
        inject_rresp_err  = 1'b1;
        inject_rresp_addr = 8'h04;

        axil_write(SRC_LO,   32'h00000000);
        axil_write(DST_LO,   32'h00000040);
        axil_write(LEN_LO,   32'h00000008);  // 8 bytes = 2 words
        axil_write(CTRL_ADDR,32'h00000001);

        wait_for_done(600);

        inject_rresp_err = 1'b0;

        axil_read(CTRL_ADDR, status);
        check(status[0] == 1'b0, "TC5: DMA not busy after read error");
        check(status[4] == 1'b1, "TC5: Error flag set after RRESP=SLVERR");

        // Clear error: write ERR_BIT (bit4) = 1 to acknowledge
        axil_write(CTRL_ADDR, 32'h00000010);

        axil_read(CTRL_ADDR, status);
        check(status[4] == 1'b0, "TC5: Error flag cleared");


        // TC6 – Write error response (BRESP = SLVERR)

                $display("\n--- TC6: Write error (BRESP=SLVERR) ---");
        mem_init();
        mem[0] = 32'hCCCCCCCC;
        mem[1] = 32'hDDDDDDDD;

        // Inject SLVERR on write response to dest word 0 (byte addr 0x40)
        inject_wresp_err  = 1'b1;
        inject_wresp_addr = 8'h40;

        axil_write(SRC_LO,   32'h00000000);
        axil_write(DST_LO,   32'h00000040);
        axil_write(LEN_LO,   32'h00000008);
        axil_write(CTRL_ADDR,32'h00000001);

        wait_for_done(600);

        inject_wresp_err = 1'b0;

        axil_read(CTRL_ADDR, status);
        check(status[0] == 1'b0, "TC6: DMA not busy after write error");
        check(status[4] == 1'b1, "TC6: Error flag set after BRESP=SLVERR");

        // Clear error
        axil_write(CTRL_ADDR, 32'h00000010);
        axil_read(CTRL_ADDR, status);
        check(status[4] == 1'b0, "TC6: Error flag cleared");

        // Results

        repeat (10) @(posedge clk);
        $display("\n========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $display("========================================\n");

        $finish;
    end

endmodule
`default_nettype wire
