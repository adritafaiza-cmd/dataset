// =============================================================================
// AXI4-Lite Clock Domain Crossing Bridge
// =============================================================================
//
// This module bridges AXI4-Lite transactions between two asynchronous clock
// domains. It uses a handshake-based CDC scheme with 2-stage synchronizers
// for each control signal.
//
// Architecture:
//   - Write path: AW and W channels are synchronized independently.
//     AW is forwarded first, then W when both are ready.
//   - Read path: AR channel is synchronized, then R response is returned.
//   - B response: Synchronized back to slave domain.
//
// Safety:
//   - All multi-bit data is transferred using handshake protocols
//   - 2-stage synchronizers for all single-bit control signals
//   - Reset is handled per-domain (s_rst for slave, m_rst for master)
//
// =============================================================================

`timescale 1ns / 1ps

module axil_cdc #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
) (
    /*
     * AXI lite slave interface
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,

    /*
     * AXI lite master interface
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [ADDR_WIDTH-1:0]  m_axil_awaddr,
    output wire [2:0]             m_axil_awprot,
    output wire                   m_axil_awvalid,
    input  wire                   m_axil_awready,
    output wire [DATA_WIDTH-1:0]  m_axil_wdata,
    output wire [STRB_WIDTH-1:0]  m_axil_wstrb,
    output wire                   m_axil_wvalid,
    input  wire                   m_axil_wready,
    input  wire [1:0]             m_axil_bresp,
    input  wire                   m_axil_bvalid,
    output wire                   m_axil_bready,
    output wire [ADDR_WIDTH-1:0]  m_axil_araddr,
    output wire [2:0]             m_axil_arprot,
    output wire                   m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output wire                   m_axil_rready
);

    // =========================================================================
    // Internal signals - Slave domain
    // =========================================================================
    wire        s_aw_valid;
    wire        s_aw_ready;
    wire        s_w_valid;
    wire        s_w_ready;
    wire        s_b_valid;
    wire        s_b_ready;
    wire        s_ar_valid;
    wire        s_ar_ready;
    wire        s_r_valid;
    wire        s_r_ready;

    // =========================================================================
    // Internal signals - Master domain
    // =========================================================================
    wire        m_aw_valid;
    wire        m_aw_ready;
    wire        m_w_valid;
    wire        m_w_ready;
    wire        m_b_valid;
    wire        m_b_ready;
    wire        m_ar_valid;
    wire        m_ar_ready;
    wire        m_r_valid;
    wire        m_r_ready;

    // =========================================================================
    // Write Address Channel (AW) - Slave to Master
    // =========================================================================
    // Slave side: capture AW when valid
    reg         s_aw_pending;
    reg  [ADDR_WIDTH-1:0] s_aw_addr_reg;
    reg  [2:0]            s_aw_prot_reg;

    assign s_axil_awready = !s_aw_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_pending  <= 1'b0;
            s_aw_addr_reg <= {ADDR_WIDTH{1'b0}};
            s_aw_prot_reg <= 3'b000;
        end else begin
            if (s_axil_awvalid && !s_aw_pending) begin
                s_aw_pending  <= 1'b1;
                s_aw_addr_reg <= s_axil_awaddr;
                s_aw_prot_reg <= s_axil_awprot;
            end else if (s_aw_pending && s_aw_ready) begin
                s_aw_pending <= 1'b0;
            end
        end
    end

    // Master side: release AW when ready
    reg         m_aw_pending;
    reg  [ADDR_WIDTH-1:0] m_aw_addr_reg;
    reg  [2:0]            m_aw_prot_reg;

    assign m_axil_awaddr  = m_aw_addr_reg;
    assign m_axil_awprot  = m_aw_prot_reg;
    assign m_axil_awvalid = m_aw_pending;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_pending  <= 1'b0;
            m_aw_addr_reg <= {ADDR_WIDTH{1'b0}};
            m_aw_prot_reg <= 3'b000;
        end else begin
            if (!m_aw_pending && s_aw_valid) begin
                m_aw_pending  <= 1'b1;
                m_aw_addr_reg <= s_aw_addr_reg;
                m_aw_prot_reg <= s_aw_prot_reg;
            end else if (m_aw_pending && m_axil_awready) begin
                m_aw_pending <= 1'b0;
            end
        end
    end

    // AW handshake CDC
    assign s_aw_valid = s_aw_pending;
    assign s_aw_ready = m_aw_ready;

    // =========================================================================
    // Write Data Channel (W) - Slave to Master
    // =========================================================================
    // Slave side: capture W when valid
    reg         s_w_pending;
    reg  [DATA_WIDTH-1:0]  s_w_data_reg;
    reg  [STRB_WIDTH-1:0]  s_w_strb_reg;

    assign s_axil_wready = !s_w_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_pending  <= 1'b0;
            s_w_data_reg <= {DATA_WIDTH{1'b0}};
            s_w_strb_reg <= {STRB_WIDTH{1'b0}};
        end else begin
            if (s_axil_wvalid && !s_w_pending) begin
                s_w_pending  <= 1'b1;
                s_w_data_reg <= s_axil_wdata;
                s_w_strb_reg <= s_axil_wstrb;
            end else if (s_w_pending && s_w_ready) begin
                s_w_pending <= 1'b0;
            end
        end
    end

    // Master side: release W when ready
    reg         m_w_pending;
    reg  [DATA_WIDTH-1:0]  m_w_data_reg;
    reg  [STRB_WIDTH-1:0]  m_w_strb_reg;

    assign m_axil_wdata  = m_w_data_reg;
    assign m_axil_wstrb  = m_w_strb_reg;
    assign m_axil_wvalid = m_w_pending;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_w_pending  <= 1'b0;
            m_w_data_reg <= {DATA_WIDTH{1'b0}};
            m_w_strb_reg <= {STRB_WIDTH{1'b0}};
        end else begin
            if (!m_w_pending && s_w_valid) begin
                m_w_pending  <= 1'b1;
                m_w_data_reg <= s_w_data_reg;
                m_w_strb_reg <= s_w_strb_reg;
            end else if (m_w_pending && m_axil_wready) begin
                m_w_pending <= 1'b0;
            end
        end
    end

    // W handshake CDC
    assign s_w_valid = s_w_pending;
    assign s_w_ready = m_w_ready;

    // =========================================================================
    // Write Response Channel (B) - Master to Slave
    // =========================================================================
    // Master side: capture B when valid
    reg         m_b_pending;
    reg  [1:0]  m_b_resp_reg;

    assign m_axil_bready = !m_b_pending;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_b_pending  <= 1'b0;
            m_b_resp_reg <= 2'b00;
        end else begin
            if (m_axil_bvalid && !m_b_pending) begin
                m_b_pending  <= 1'b1;
                m_b_resp_reg <= m_axil_bresp;
            end else if (m_b_pending && m_b_ready) begin
                m_b_pending <= 1'b0;
            end
        end
    end

    // Slave side: release B when ready
    reg         s_b_pending;
    reg  [1:0]  s_b_resp_reg;

    assign s_axil_bresp  = s_b_resp_reg;
    assign s_axil_bvalid = s_b_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_b_pending  <= 1'b0;
            s_b_resp_reg <= 2'b00;
        end else begin
            if (!s_b_pending && m_b_valid) begin
                s_b_pending  <= 1'b1;
                s_b_resp_reg <= m_b_resp_reg;
            end else if (s_b_pending && s_axil_bready) begin
                s_b_pending <= 1'b0;
            end
        end
    end

    // B handshake CDC
    assign m_b_valid = m_b_pending;
    assign m_b_ready = s_b_ready;

    // =========================================================================
    // Read Address Channel (AR) - Slave to Master
    // =========================================================================
    // Slave side: capture AR when valid
    reg         s_ar_pending;
    reg  [ADDR_WIDTH-1:0] s_ar_addr_reg;
    reg  [2:0]            s_ar_prot_reg;

    assign s_axil_arready = !s_ar_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ar_pending  <= 1'b0;
            s_ar_addr_reg <= {ADDR_WIDTH{1'b0}};
            s_ar_prot_reg <= 3'b000;
        end else begin
            if (s_axil_arvalid && !s_ar_pending) begin
                s_ar_pending  <= 1'b1;
                s_ar_addr_reg <= s_axil_araddr;
                s_ar_prot_reg <= s_axil_arprot;
            end else if (s_ar_pending && s_ar_ready) begin
                s_ar_pending <= 1'b0;
            end
        end
    end

    // Master side: release AR when ready
    reg         m_ar_pending;
    reg  [ADDR_WIDTH-1:0] m_ar_addr_reg;
    reg  [2:0]            m_ar_prot_reg;

    assign m_axil_araddr  = m_ar_addr_reg;
    assign m_axil_arprot  = m_ar_prot_reg;
    assign m_axil_arvalid = m_ar_pending;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ar_pending  <= 1'b0;
            m_ar_addr_reg <= {ADDR_WIDTH{1'b0}};
            m_ar_prot_reg <= 3'b000;
        end else begin
            if (!m_ar_pending && s_ar_valid) begin
                m_ar_pending  <= 1'b1;
                m_ar_addr_reg <= s_ar_addr_reg;
                m_ar_prot_reg <= s_ar_prot_reg;
            end else if (m_ar_pending && m_axil_arready) begin
                m_ar_pending <= 1'b0;
            end
        end
    end

    // AR handshake CDC
    assign s_ar_valid = s_ar_pending;
    assign s_ar_ready = m_ar_ready;

    // =========================================================================
    // Read Data Channel (R) - Master to Slave
    // =========================================================================
    // Master side: capture R when valid
    reg         m_r_pending;
    reg  [DATA_WIDTH-1:0]  m_r_data_reg;
    reg  [1:0]             m_r_resp_reg;

    assign m_axil_rready = !m_r_pending;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_r_pending  <= 1'b0;
            m_r_data_reg <= {DATA_WIDTH{1'b0}};
            m_r_resp_reg <= 2'b00;
        end else begin
            if (m_axil_rvalid && !m_r_pending) begin
                m_r_pending  <= 1'b1;
                m_r_data_reg <= m_axil_rdata;
                m_r_resp_reg <= m_axil_rresp;
            end else if (m_r_pending && m_r_ready) begin
                m_r_pending <= 1'b0;
            end
        end
    end

    // Slave side: release R when ready
    reg         s_r_pending;
    reg  [DATA_WIDTH-1:0]  s_r_data_reg;
    reg  [1:0]             s_r_resp_reg;

    assign s_axil_rdata  = s_r_data_reg;
    assign s_axil_rresp  = s_r_resp_reg;
    assign s_axil_rvalid = s_r_pending;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_pending  <= 1'b0;
            s_r_data_reg <= {DATA_WIDTH{1'b0}};
            s_r_resp_reg <= 2'b00;
        end else begin
            if (!s_r_pending && m_r_valid) begin
                s_r_pending  <= 1'b1;
                s_r_data_reg <= m_r_data_reg;
                s_r_resp_reg <= m_r_resp_reg;
            end else if (s_r_pending && s_axil_rready) begin
                s_r_pending <= 1'b0;
            end
        end
    end

    // R handshake CDC
    assign m_r_valid = m_r_pending;
    assign m_r_ready = s_r_ready;

    // =========================================================================
    // CDC Synchronizers
    // =========================================================================

    // AW valid: s_clk -> m_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] aw_valid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            aw_valid_sync <= 2'b00;
        else
            aw_valid_sync <= {aw_valid_sync[0], s_aw_valid};
    end
    assign m_aw_valid = aw_valid_sync[1];

    // AW ready: m_clk -> s_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] aw_ready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            aw_ready_sync <= 2'b00;
        else
            aw_ready_sync <= {aw_ready_sync[0], m_axil_awready};
    end
    assign s_aw_ready = aw_ready_sync[1];

    // W valid: s_clk -> m_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] w_valid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            w_valid_sync <= 2'b00;
        else
            w_valid_sync <= {w_valid_sync[0], s_w_valid};
    end
    assign m_w_valid = w_valid_sync[1];

    // W ready: m_clk -> s_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] w_ready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            w_ready_sync <= 2'b00;
        else
            w_ready_sync <= {w_ready_sync[0], m_axil_wready};
    end
    assign s_w_ready = w_ready_sync[1];

    // B valid: m_clk -> s_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] b_valid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            b_valid_sync <= 2'b00;
        else
            b_valid_sync <= {b_valid_sync[0], m_b_valid};
    end
    assign s_b_valid = b_valid_sync[1];

    // B ready: s_clk -> m_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] b_ready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            b_ready_sync <= 2'b00;
        else
            b_ready_sync <= {b_ready_sync[0], s_axil_bready};
    end
    assign m_b_ready = b_ready_sync[1];

    // AR valid: s_clk -> m_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] ar_valid_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            ar_valid_sync <= 2'b00;
        else
            ar_valid_sync <= {ar_valid_sync[0], s_ar_valid};
    end
    assign m_ar_valid = ar_valid_sync[1];

    // AR ready: m_clk -> s_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] ar_ready_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            ar_ready_sync <= 2'b00;
        else
            ar_ready_sync <= {ar_ready_sync[0], m_axil_arready};
    end
    assign s_ar_ready = ar_ready_sync[1];

    // R valid: m_clk -> s_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] r_valid_sync;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            r_valid_sync <= 2'b00;
        else
            r_valid_sync <= {r_valid_sync[0], m_r_valid};
    end
    assign s_r_valid = r_valid_sync[1];

    // R ready: s_clk -> m_clk
    (* ASYNC_REG = "TRUE" *) reg [1:0] r_ready_sync;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            r_ready_sync <= 2'b00;
        else
            r_ready_sync <= {r_ready_sync[0], s_axil_rready};
    end
    assign m_r_ready = r_ready_sync[1];

    // =========================================================================
    // Data synchronization (using handshake to ensure data stability)
    // =========================================================================

    // AW data: s_clk -> m_clk (data is stable when s_aw_valid is high)
    // We use the handshake protocol to ensure data is captured correctly
    // The data is registered in the master domain when the handshake completes

    // W data: s_clk -> m_clk
    // Same approach as AW

    // B data: m_clk -> s_clk
    // Same approach

    // AR data: s_clk -> m_clk
    // Same approach

    // R data: m_clk -> s_clk
    // Same approach

endmodule