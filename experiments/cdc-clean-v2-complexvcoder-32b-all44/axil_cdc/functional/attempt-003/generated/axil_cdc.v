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

    /*
     * Internal signals
     */
    reg [ADDR_WIDTH+2:0] s_aw_reg;
    reg [DATA_WIDTH+STRB_WIDTH-1:0] s_w_reg;
    reg [ADDR_WIDTH+2:0] s_ar_reg;
    reg s_aw_valid_reg;
    reg s_w_valid_reg;
    reg s_ar_valid_reg;
    reg [2:0] s_b_reg;
    reg s_b_valid_reg;
    reg [DATA_WIDTH+2:0] s_r_reg;
    reg s_r_valid_reg;

    reg [ADDR_WIDTH+2:0] m_aw_reg;
    reg [DATA_WIDTH+STRB_WIDTH-1:0] m_w_reg;
    reg [ADDR_WIDTH+2:0] m_ar_reg;
    reg m_aw_valid_reg;
    reg m_w_valid_reg;
    reg m_ar_valid_reg;

    wire s_aw_fifo_wr_en;
    wire s_aw_fifo_rd_en;
    wire s_aw_fifo_empty;
    wire s_aw_fifo_full;
    wire [ADDR_WIDTH+2:0] s_aw_fifo_data_out;

    wire s_w_fifo_wr_en;
    wire s_w_fifo_rd_en;
    wire s_w_fifo_empty;
    wire s_w_fifo_full;
    wire [DATA_WIDTH+STRB_WIDTH-1:0] s_w_fifo_data_out;

    wire s_ar_fifo_wr_en;
    wire s_ar_fifo_rd_en;
    wire s_ar_fifo_empty;
    wire s_ar_fifo_full;
    wire [ADDR_WIDTH+2:0] s_ar_fifo_data_out;

    wire m_aw_fifo_wr_en;
    wire m_aw_fifo_rd_en;
    wire m_aw_fifo_empty;
    wire m_aw_fifo_full;
    wire [ADDR_WIDTH+2:0] m_aw_fifo_data_out;

    wire m_w_fifo_wr_en;
    wire m_w_fifo_rd_en;
    wire m_w_fifo_empty;
    wire m_w_fifo_full;
    wire [DATA_WIDTH+STRB_WIDTH-1:0] m_w_fifo_data_out;

    wire m_ar_fifo_wr_en;
    wire m_ar_fifo_rd_en;
    wire m_ar_fifo_empty;
    wire m_ar_fifo_full;
    wire [ADDR_WIDTH+2:0] m_ar_fifo_data_out;

    /*
     * FIFOs for crossing clock domains
     */
    fifo_async #(
        .DATA_WIDTH(ADDR_WIDTH+3),
        .DEPTH(4)
    ) s_aw_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .wr_en(s_aw_fifo_wr_en),
        .din({s_axil_awaddr, s_axil_awprot}),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .rd_en(s_aw_fifo_rd_en),
        .dout(s_aw_fifo_data_out),
        .full(s_aw_fifo_full),
        .empty(s_aw_fifo_empty)
    );

    fifo_async #(
        .DATA_WIDTH(DATA_WIDTH+STRB_WIDTH),
        .DEPTH(4)
    ) s_w_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .wr_en(s_w_fifo_wr_en),
        .din({s_axil_wdata, s_axil_wstrb}),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .rd_en(s_w_fifo_rd_en),
        .dout(s_w_fifo_data_out),
        .full(s_w_fifo_full),
        .empty(s_w_fifo_empty)
    );

    fifo_async #(
        .DATA_WIDTH(ADDR_WIDTH+3),
        .DEPTH(4)
    ) s_ar_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .wr_en(s_ar_fifo_wr_en),
        .din({s_axil_araddr, s_axil_arprot}),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .rd_en(s_ar_fifo_rd_en),
        .dout(s_ar_fifo_data_out),
        .full(s_ar_fifo_full),
        .empty(s_ar_fifo_empty)
    );

    fifo_async #(
        .DATA_WIDTH(ADDR_WIDTH+3),
        .DEPTH(4)
    ) m_aw_fifo (
        .clk_wr(m_clk),
        .rst_wr(m_rst),
        .wr_en(m_aw_fifo_wr_en),
        .din(m_aw_reg),
        .clk_rd(s_clk),
        .rst_rd(s_rst),
        .rd_en(m_aw_fifo_rd_en),
        .dout(m_aw_fifo_data_out),
        .full(m_aw_fifo_full),
        .empty(m_aw_fifo_empty)
    );

    fifo_async #(
        .DATA_WIDTH(DATA_WIDTH+STRB_WIDTH),
        .DEPTH(4)
    ) m_w_fifo (
        .clk_wr(m_clk),
        .rst_wr(m_rst),
        .wr_en(m_w_fifo_wr_en),
        .din(m_w_reg),
        .clk_rd(s_clk),
        .rst_rd(s_rst),
        .rd_en(m_w_fifo_rd_en),
        .dout(m_w_fifo_data_out),
        .full(m_w_fifo_full),
        .empty(m_w_fifo_empty)
    );

    fifo_async #(
        .DATA_WIDTH(ADDR_WIDTH+3),
        .DEPTH(4)
    ) m_ar_fifo (
        .clk_wr(m_clk),
        .rst_wr(m_rst),
        .wr_en(m_ar_fifo_wr_en),
        .din(m_ar_reg),
        .clk_rd(s_clk),
        .rst_rd(s_rst),
        .rd_en(m_ar_fifo_rd_en),
        .dout(m_ar_fifo_data_out),
        .full(m_ar_fifo_full),
        .empty(m_ar_fifo_empty)
    );

    /*
     * Slave side logic
     */
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_aw_valid_reg <= 0;
            s_w_valid_reg <= 0;
            s_ar_valid_reg <= 0;
            s_b_valid_reg <= 0;
            s_r_valid_reg <= 0;
        end else begin
            // Write Address Channel
            if (s_axil_awvalid && s_axil_awready) begin
                s_aw_valid_reg <= 1;
                s_aw_reg <= {s_axil_awaddr, s_axil_awprot};
            end else if (m_axil_awready) begin
                s_aw_valid_reg <= 0;
            end

            // Write Data Channel
            if (s_axil_wvalid && s_axil_wready) begin
                s_w_valid_reg <= 1;
                s_w_reg <= {s_axil_wdata, s_axil_wstrb};
            end else if (m_axil_wready) begin
                s_w_valid_reg <= 0;
            end

            // Write Response Channel
            if (m_axil_bvalid && s_axil_bready) begin
                s_b_valid_reg <= 0;
            end else if (m_axil_bvalid && !s_b_valid_reg) begin
                s_b_valid_reg <= 1;
                s_b_reg <= {m_axil_bresp, 1'b1};
            end

            // Read Address Channel
            if (s_axil_arvalid && s_axil_arready) begin
                s_ar_valid_reg <= 1;
                s_ar_reg <= {s_axil_araddr, s_axil_arprot};
            end else if (m_axil_arready) begin
                s_ar_valid_reg <= 0;
            end

            // Read Data Channel
            if (m_axil_rvalid && s_axil_rready) begin
                s_r_valid_reg <= 0;
            end else if (m_axil_rvalid && !s_r_valid_reg) begin
                s_r_valid_reg <= 1;
                s_r_reg <= {m_axil_rdata, m_axil_rresp, 1'b1};
            end
        end
    end

    assign s_axil_awready = !s_aw_fifo_full;
    assign s_axil_wready = !s_w_fifo_full;
    assign s_axil_bresp = s_b_reg[1:0];
    assign s_axil_bvalid = s_b_valid_reg;
    assign s_axil_arready = !s_ar_fifo_full;
    assign s_axil_rdata = s_r_reg[DATA_WIDTH+1:2];
    assign s_axil_rresp = s_r_reg[1:0];
    assign s_axil_rvalid = s_r_valid_reg;

    assign s_aw_fifo_wr_en = s_axil_awvalid && !s_aw_fifo_full;
    assign s_w_fifo_wr_en = s_axil_wvalid && !s_w_fifo_full;
    assign s_ar_fifo_wr_en = s_axil_arvalid && !s_ar_fifo_full;

    assign s_aw_fifo_rd_en = m_axil_awvalid && !m_axil_awready;
    assign s_w_fifo_rd_en = m_axil_wvalid && !m_axil_wready;
    assign s_ar_fifo_rd_en = m_axil_arvalid && !m_axil_arready;

    /*
     * Master side logic
     */
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_aw_valid_reg <= 0;
            m_w_valid_reg <= 0;
            m_ar_valid_reg <= 0;
            m_axil_bready <= 0;
            m_axil_rready <= 0;
        end else begin
            // Write Address Channel
            if (s_aw_fifo_rd_en) begin
                m_aw_valid_reg <= 1;
                m_aw_reg <= s_aw_fifo_data_out;
            end else if (m_axil_awready) begin
                m_aw_valid_reg <= 0;
            end

            // Write Data Channel
            if (s_w_fifo_rd_en) begin
                m_w_valid_reg <= 1;
                m_w_reg <= s_w_fifo_data_out;
            end else if (m_axil_wready) begin
                m_w_valid_reg <= 0;
            end

            // Write Response Channel
            if (m_axil_bvalid && m_axil_bready) begin
                m_axil_bready <= 0;
            end else if (m_axil_bvalid && !m_axil_bready) begin
                m_axil_bready <= 1;
            end

            // Read Address Channel
            if (s_ar_fifo_rd_en) begin
                m_ar_valid_reg <= 1;
                m_ar_reg <= s_ar_fifo_data_out;
            end else if (m_axil_arready) begin
                m_ar_valid_reg <= 0;
            end

            // Read Data Channel
            if (m_axil_rvalid && m_axil_rready) begin
                m_axil_rready <= 0;
            end else if (m_axil_rvalid && !m_axil_rready) begin
                m_axil_rready <= 1;
            end
        end
    end

    assign m_axil_awaddr = m_aw_reg[ADDR_WIDTH+2:3];
    assign m_axil_awprot = m_aw_reg[2:0];
    assign m_axil_awvalid = m_aw_valid_reg;

    assign m_axil_wdata = m_w_reg[DATA_WIDTH+STRB_WIDTH-1:STRB_WIDTH];
    assign m_axil_wstrb = m_w_reg[STRB_WIDTH-1:0];
    assign m_axil_wvalid = m_w_valid_reg;

    assign m_axil_araddr = m_ar_reg[ADDR_WIDTH+2:3];
    assign m_axil_arprot = m_ar_reg[2:0];
    assign m_axil_arvalid = m_ar_valid_reg;

    assign m_aw_fifo_wr_en = m_axil_awvalid && !m_axil_awready;
    assign m_w_fifo_wr_en = m_axil_wvalid && !m_axil_wready;
    assign m_ar_fifo_wr_en = m_axil_arvalid && !m_axil_arready;

    assign m_aw_fifo_rd_en = s_axil_awvalid && !s_axil_awready;
    assign m_w_fifo_rd_en = s_axil_wvalid && !s_axil_wready;
    assign m_ar_fifo_rd_en = s_axil_arvalid && !s_axil_arready;

endmodule

/*
 * Asynchronous FIFO module
 */
module fifo_async #
(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 4
)
(
    input wire clk_wr,
    input wire rst_wr,
    input wire wr_en,
    input wire [DATA_WIDTH-1:0] din,
    input wire clk_rd,
    input wire rst_rd,
    input wire rd_en,
    output reg [DATA_WIDTH-1:0] dout,
    output wire full,
    output wire empty
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray;
    reg [$clog2(DEPTH):0] rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync;
    reg [$clog2(DEPTH):0] rd_ptr_gray_sync;

    wire [$clog2(DEPTH):0] wr_ptr_bin_sync;
    wire [$clog2(DEPTH):0] rd_ptr_bin_sync;

    wire [$clog2(DEPTH):0] wr_ptr_gray_next;
    wire [$clog2(DEPTH):0] rd_ptr_gray_next;

    wire wr_en_gray;
    wire rd_en_gray;

    assign wr_ptr_gray_next = wr_ptr + 1;
    assign rd_ptr_gray_next = rd_ptr + 1;

    assign wr_en_gray = wr_en & ~full;
    assign rd_en_gray = rd_en & ~empty;

    assign full = (wr_ptr_gray_next == {~rd_ptr_gray_sync[$clog2(DEPTH)-1:0], rd_ptr_gray_sync[$clog2(DEPTH)]});
    assign empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);

    // Write side logic
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en_gray) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr_gray_next;
        end
    end

    // Gray code synchronization for read pointer
    always @(posedge clk_wr) begin
        wr_ptr_gray_sync <= wr_ptr_gray;
    end

    // Read side logic
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            dout <= 0;
        end else if (rd_en_gray) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr_gray_next;
            dout <= mem[rd_ptr_bin_sync];
        end
    end

    // Gray code synchronization for write pointer
    always @(posedge clk_rd) begin
        rd_ptr_gray_sync <= rd_ptr_gray;
    end

    // Binary conversion
    assign wr_ptr_bin_sync = gray_to_bin(wr_ptr_gray_sync);
    assign rd_ptr_bin_sync = gray_to_bin(rd_ptr_gray_sync);

    // Gray to binary conversion function
    function [$clog2(DEPTH):0] gray_to_bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        begin
            gray_to_bin = gray[$clog2(DEPTH)];
            for (i = $clog2(DEPTH)-1; i >= 0; i = i - 1) begin
                gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
            end
        end
    endfunction

endmodule
