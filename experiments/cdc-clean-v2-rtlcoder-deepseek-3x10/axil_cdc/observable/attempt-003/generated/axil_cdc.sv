The following Verilog code implements an AXI4-Lite clock-domain bridge. The bridge uses a handshake protocol to transfer data between the two clock domains. The bridge also uses a FIFO to store incoming transactions and a FIFO to store outgoing transactions.

```
module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
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

    // FIFO to store incoming transactions
    reg [DATA_WIDTH-1:0] fifo_in [0:1];
    reg [1:0] fifo_in_wr_ptr;
    reg [1:0] fifo_in_rd_ptr;
    reg fifo_in_full;
    reg fifo_in_empty;

    // FIFO to store outgoing transactions
    reg [DATA_WIDTH-1:0] fifo_out [0:1];
    reg [1:0] fifo_out_wr_ptr;
    reg [1:0] fifo_out_rd_ptr;
    reg fifo_out_full;
    reg fifo_out_empty;

    // Handshake signals
    reg s_aw_handshake;
    reg s_w_handshake;
    reg s_b_handshake;
    reg s_ar_handshake;
    reg s_r_handshake;
    reg m_aw_handshake;
    reg m_w_handshake;
    reg m_b_handshake;
    reg m_ar_handshake;
    reg m_r_handshake;

    // Write data and strobe
    reg [DATA_WIDTH-1:0] write_data;
    reg [STRB_WIDTH-1:0] write_strobe;

    // Read data and response
    reg [DATA_WIDTH-1:0] read_data;
    reg [1:0] read_resp;

    // Write address and protection
    reg [ADDR_WIDTH-1:0] write_addr;
    reg [2:0] write_prot;

    // Read address and protection
    reg [ADDR_WIDTH-1:0] read_addr;
    reg [2:0] read_prot;

    // Write response
    reg [1:0] write_resp;

    // Write address handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_aw_handshake <= 0;
        end else begin
            if (s_axil_awvalid && !s_aw_handshake) begin
                s_aw_handshake <= 1;
            end else if (s_axil_awready && s_aw_handshake) begin
                s_aw_handshake <= 0;
            end
        end
    end

    // Write data handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_w_handshake <= 0;
        end else begin
            if (s_axil_wvalid && !s_w_handshake) begin
                s_w_handshake <= 1;
            end else if (s_axil_wready && s_w_handshake) begin
                s_w_handshake <= 0;
            end
        end
    end

    // Write response handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_b_handshake <= 0;
        end else begin
            if (s_axil_bvalid && !s_b_handshake) begin
                s_b_handshake <= 1;
            end else if (s_axil_bready && s_b_handshake) begin
                s_b_handshake <= 0;
            end
        end
    end

    // Read address handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_ar_handshake <= 0;
        end else begin
            if (s_axil_arvalid && !s_ar_handshake) begin
                s_ar_handshake <= 1;
            end else if (s_axil_arready && s_ar_handshake) begin
                s_ar_handshake <= 0;
            end
        end
    end

    // Read data handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_r_handshake <= 0;
        end else begin
            if (s_axil_rvalid && !s_r_handshake) begin
                s_r_handshake <= 1;
            end else if (s_axil_rready && s_r_handshake) begin
                s_r_handshake <= 0;
            end
        end
    end

    // Write address handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_aw_handshake <= 0;
        end else begin
            if (m_axil_awvalid && !m_aw_handshake) begin
                m_aw_handshake <= 1;
            end else if (m_axil_awready && m_aw_handshake) begin
                m_aw_handshake <= 0;
            end
        end
    end

    // Write data handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_w_handshake <= 0;
        end else begin
            if (m_axil_wvalid && !m_w_handshake) begin
                m_w_handshake <= 1;
            end else if (m_axil_wready && m_w_handshake) begin
                m_w_handshake <= 0;
            end
        end
    end

    // Write response handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_b_handshake <= 0;
        end else begin
            if (m_axil_bvalid && !m_b_handshake) begin
                m_b_handshake <= 1;
            end else if (m_axil_bready && m_b_handshake) begin
                m_b_handshake <= 0;
            end
        end
    end

    // Read address handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_ar_handshake <= 0;
        end else begin
            if (m_axil_arvalid && !m_ar_handshake) begin
                m_ar_handshake <= 1;
            end else if (m_axil_arready && m_ar_handshake) begin
                m_ar_handshake <= 0;
            end
        end
    end

    // Read data handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_r_handshake <= 0;
        end else begin
            if (m_axil_rvalid && !m_r_handshake) begin
                m_r_handshake <= 1;
            end else if (m_axil_rready && m_r_handshake) begin
                m_r_handshake <= 0;
            end
        end
    end

    // Write address FIFO
    always @(posedge s_clk) begin
        if (s_rst) begin
            fifo_in_wr_ptr <= 0;
            fifo_in_full <= 0;
        end else begin
            if (s_aw_handshake && !fifo_in_full) begin
                fifo_in[fifo_in_wr_ptr] <= s_axil_awaddr;
                fifo_in_wr_ptr <= fifo_in_wr_ptr + 1;
                if (fifo_in_wr_ptr == 1) begin
                    fifo_in_full <= 1;
                end
            end
        end
    end

    // Write data FIFO
    always @(posedge s_clk) begin
        if (s_rst) begin
            fifo_in_wr_ptr <= 0;
            fifo_in_full <= 0;
        end else begin
            if (s_w_handshake && !fifo_in_full) begin
                fifo_in[fifo_in_wr_ptr] <= s_axil_wdata;
                fifo_in_wr_ptr <= fifo_in_wr_ptr + 1;
                if (fifo_in_wr_ptr == 1) begin
                    fifo_in_full <= 1;
                end
            end
        end
    end

    // Write strobe FIFO
    always @(posedge s_clk) begin
        if (s_rst) begin
            fifo_in_wr_ptr <= 0;
            fifo_in_full <= 0;
        end else begin
            if (s_w_handshake && !fifo_in_full) begin
                fifo_in[fifo_in_wr_ptr] <= s_axil_wstrb;
                fifo_in_wr_ptr <= fifo_in_wr_ptr + 1;
                if (fifo_in_wr_ptr == 1) begin
                    fifo_in_full <= 1;
                end
            end
        end
    end

    // Read address FIFO
    always @(posedge s_clk) begin
        if (s_rst) begin
            fifo_in_wr_ptr <= 0;
            fifo_in_full <= 0;
        end else begin
            if (s_ar_handshake && !fifo_in_full) begin
                fifo_in[fifo_in_wr_ptr] <= s_axil_araddr;
                fifo_in_wr_ptr <= fifo_in_wr_ptr + 1;
                if (fifo_in_wr_ptr == 1) begin
                    fifo_in_full <= 1;
                end
            end
        end
    end

    // Read protection FIFO
    always @(posedge s_clk) begin
        if (s_rst) begin
            fifo_in_wr_ptr <= 0;
            fifo_in_full <= 0;
        end else begin
            if (s_ar_handshake && !fifo_in_full) begin
                fifo_in[fifo_in_wr_ptr] <= s_axil_arprot;
                fifo_in_wr_ptr <= fifo_in_wr_ptr + 1;
                if (fifo_in_wr_ptr == 1) begin
                    fifo_in_full <= 1;
                end
            end
        end
    end

    // Write response FIFO
    always @(posedge s_clk) begin
        if (s_rst) begin
            fifo_out_wr_ptr <= 0;
            fifo_out_full <= 0;
        end else begin
            if (s_b_handshake && !fifo_out_full) begin
                fifo_out[fifo_out_wr_ptr] <= s_axil_bresp;
                fifo_out_wr_ptr <= fifo_out_wr_ptr + 1;
                if (fifo_out_wr_ptr == 1) begin
                    fifo_out_full <= 1;
                end
            end
        end
    end

    // Read data FIFO
    always @(posedge s_clk) begin
        if (s_rst) begin
            fifo_out_wr_ptr <= 0;
            fifo_out_full <= 0;
        end else begin
            if (s_r_handshake && !fifo_out_full) begin
                fifo_out[fifo_out_wr_ptr] <= s_axil_rdata;
                fifo_out_wr_ptr <= fifo_out_wr_ptr + 1;
                if (fifo_out_wr_ptr == 1) begin
                    fifo_out_full <= 1;
                end
            end
        end
    end

    // Read response FIFO
    always @(posedge s_clk) begin
        if (s_rst) begin
            fifo_out_wr_ptr <= 0;
            fifo_out_full <= 0;
        end else begin
            if (s_r_handshake && !fifo_out_full) begin
                fifo_out[fifo_out_wr_ptr] <= s_axil_rresp;
                fifo_out_wr_ptr <= fifo_out_wr_ptr + 1;
                if (fifo_out_wr_ptr == 1) begin
                    fifo_out_full <= 1;
                end
            end
        end
    end

    // Write address
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_addr <= 0;
        end else begin
            if (s_aw_handshake && !fifo_in_empty) begin
                write_addr <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Write protection
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_prot <= 0;
        end else begin
            if (s_aw_handshake && !fifo_in_empty) begin
                write_prot <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Write data
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_data <= 0;
        end else begin
            if (s_w_handshake && !fifo_in_empty) begin
                write_data <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Write strobe
    always @(posedge s_clk) begin
        if (s_rst) begin
            write_strobe <= 0;
        end else begin
            if (s_w_handshake && !fifo_in_empty) begin
                write_strobe <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Read address
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_addr <= 0;
        end else begin
            if (s_ar_handshake && !fifo_in_empty) begin
                read_addr <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Read protection
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_prot <= 0;
        end else begin
            if (s_ar_handshake && !fifo_in_empty) begin
                read_prot <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Read data
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_data <= 0;
        end else begin
            if (s_r_handshake && !fifo_out_empty) begin
                read_data <= fifo_out[fifo_out_rd_ptr];
                fifo_out_rd_ptr <= fifo_out_rd_ptr + 1;
                if (fifo_out_rd_ptr == 1) begin
                    fifo_out_empty <= 1;
                end
            end
        end
    end

    // Read response
    always @(posedge s_clk) begin
        if (s_rst) begin
            read_resp <= 0;
        end else begin
            if (s_r_handshake && !fifo_out_empty) begin
                read_resp <= fifo_out[fifo_out_rd_ptr];
                fifo_out_rd_ptr <= fifo_out_rd_ptr + 1;
                if (fifo_out_rd_ptr == 1) begin
                    fifo_out_empty <= 1;
                end
            end
        end
    end

    // Write address handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_aw_handshake <= 0;
        end else begin
            if (m_aw_handshake && !fifo_in_empty) begin
                m_axil_awaddr <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Write protection handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_aw_handshake <= 0;
        end else begin
            if (m_aw_handshake && !fifo_in_empty) begin
                m_axil_awprot <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Write data handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_w_handshake <= 0;
        end else begin
            if (m_w_handshake && !fifo_in_empty) begin
                m_axil_wdata <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Write strobe handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_w_handshake <= 0;
        end else begin
            if (m_w_handshake && !fifo_in_empty) begin
                m_axil_wstrb <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Read address handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_ar_handshake <= 0;
        end else begin
            if (m_ar_handshake && !fifo_in_empty) begin
                m_axil_araddr <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Read protection handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_ar_handshake <= 0;
        end else begin
            if (m_ar_handshake && !fifo_in_empty) begin
                m_axil_arprot <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Write response handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_b_handshake <= 0;
        end else begin
            if (m_b_handshake && !fifo_out_empty) begin
                m_axil_bresp <= fifo_out[fifo_out_rd_ptr];
                fifo_out_rd_ptr <= fifo_out_rd_ptr + 1;
                if (fifo_out_rd_ptr == 1) begin
                    fifo_out_empty <= 1;
                end
            end
        end
    end

    // Read data handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_r_handshake <= 0;
        end else begin
            if (m_r_handshake && !fifo_out_empty) begin
                m_axil_rdata <= fifo_out[fifo_out_rd_ptr];
                fifo_out_rd_ptr <= fifo_out_rd_ptr + 1;
                if (fifo_out_rd_ptr == 1) begin
                    fifo_out_empty <= 1;
                end
            end
        end
    end

    // Read response handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_r_handshake <= 0;
        end else begin
            if (m_r_handshake && !fifo_out_empty) begin
                m_axil_rresp <= fifo_out[fifo_out_rd_ptr];
                fifo_out_rd_ptr <= fifo_out_rd_ptr + 1;
                if (fifo_out_rd_ptr == 1) begin
                    fifo_out_empty <= 1;
                end
            end
        end
    end

    // Write address handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_axil_awready <= 0;
        end else begin
            if (s_aw_handshake && !fifo_in_full) begin
                s_axil_awready <= 1;
            end else if (s_axil_awready && s_aw_handshake) begin
                s_axil_awready <= 0;
            end
        end
    end

    // Write data handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_axil_wready <= 0;
        end else begin
            if (s_w_handshake && !fifo_in_full) begin
                s_axil_wready <= 1;
            end else if (s_axil_wready && s_w_handshake) begin
                s_axil_wready <= 0;
            end
        end
    end

    // Write response handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_axil_bvalid <= 0;
        end else begin
            if (s_b_handshake && !fifo_out_full) begin
                s_axil_bvalid <= 1;
            end else if (s_axil_bvalid && s_b_handshake) begin
                s_axil_bvalid <= 0;
            end
        end
    end

    // Read address handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_axil_arready <= 0;
        end else begin
            if (s_ar_handshake && !fifo_in_full) begin
                s_axil_arready <= 1;
            end else if (s_axil_arready && s_ar_handshake) begin
                s_axil_arready <= 0;
            end
        end
    end

    // Read data handshake
    always @(posedge s_clk) begin
        if (s_rst) begin
            s_axil_rvalid <= 0;
        end else begin
            if (s_r_handshake && !fifo_out_full) begin
                s_axil_rvalid <= 1;
            end else if (s_axil_rvalid && s_r_handshake) begin
                s_axil_rvalid <= 0;
            end
        end
    end

    // Write address handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_awvalid <= 0;
        end else begin
            if (m_aw_handshake && !fifo_in_empty) begin
                m_axil_awvalid <= 1;
            end else if (m_axil_awvalid && m_aw_handshake) begin
                m_axil_awvalid <= 0;
            end
        end
    end

    // Write data handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_wvalid <= 0;
        end else begin
            if (m_w_handshake && !fifo_in_empty) begin
                m_axil_wvalid <= 1;
            end else if (m_axil_wvalid && m_w_handshake) begin
                m_axil_wvalid <= 0;
            end
        end
    end

    // Write response handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_bready <= 0;
        end else begin
            if (m_b_handshake && !fifo_out_empty) begin
                m_axil_bready <= 1;
            end else if (m_axil_bready && m_b_handshake) begin
                m_axil_bready <= 0;
            end
        end
    end

    // Read address handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_arvalid <= 0;
        end else begin
            if (m_ar_handshake && !fifo_in_empty) begin
                m_axil_arvalid <= 1;
            end else if (m_axil_arvalid && m_ar_handshake) begin
                m_axil_arvalid <= 0;
            end
        end
    end

    // Read data handshake
    always @(posedge m_clk) begin
        if (m_rst) begin
            m_axil_rready <= 0;
        end else begin
            if (m_r_handshake && !fifo_out_empty) begin
                m_axil_rready <= 1;
            end else if (m_axil_rready && m_r_handshake) begin
                m_axil_rready <= 0;
            end
        end
    end

    // Write address
    always @(posedge s_clk) begin
        if (s_rst) begin
            m_axil_awaddr <= 0;
        end else begin
            if (s_aw_handshake && !fifo_in_empty) begin
                m_axil_awaddr <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Write protection
    always @(posedge s_clk) begin
        if (s_rst) begin
            m_axil_awprot <= 0;
        end else begin
            if (s_aw_handshake && !fifo_in_empty) begin
                m_axil_awprot <= fifo_in[fifo_in_rd_ptr];
                fifo_in_rd_ptr <= fifo_in_rd_ptr + 1;
                if (fifo_in_rd_ptr == 1) begin
                    fifo_in_empty <= 1;
                end
            end
        end
    end

    // Write data
    always @(posedge s_clk) begin
        if (s_rst) begin
            m_axil_wdata <= 0;
        end