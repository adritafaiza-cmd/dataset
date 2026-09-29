module axixclk #(
    parameter integer C_S_AXI_ID_WIDTH    = 2,
    parameter integer C_S_AXI_DATA_WIDTH  = 32,
    parameter integer C_S_AXI_ADDR_WIDTH  = 6,
    parameter [0:0] OPT_WRITE_ONLY = 1'b0,
    parameter [0:0] OPT_READ_ONLY  = 1'b0,
    parameter XCLOCK_FFS = 2,
    parameter LGFIFO = 5
) (
    // Slave AXI Interface
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    // ... (All other S_AXI ports as per declaration)

    // Master AXI Interface
    output wire M_AXI_ARESETN,
    // ... (All other M_AXI ports as per declaration)
);

// Write Address Channel (AW)
dual_clock_fifo #(
    .DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
    .FIFO_DEPTH(2**LGFIFO)
) aw_fifo (
    .wr_clk(S_AXI_ACLK),
    .wr_rst_n(S_AXI_ARESETN),
    .wr_en(S_AXI_AWVALID && S_AXI_AWREADY),
    .din({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS}),
    .full(aw_fifo_full),
    .rd_clk(M_AXI_ACLK),
    .rd_rst_n(M_AXI_ARESETN),
    .rd_en(M_AXI_AWVALID && M_AXI_AWREADY),
    .dout({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS}),
    .empty(aw_fifo_empty)
);

assign S_AXI_AWREADY = !aw_fifo_full;

// Write Data Channel (W)
dual_clock_fifo #(
    .DATA_WIDTH(C_S_AXI_DATA_WIDTH + (C_S_AXI_DATA_WIDTH/8) + 1 + 1 + 7),
    .FIFO_DEPTH(2**LGFIFO)
) w_fifo (
    .wr_clk(S_AXI_ACLK),
    .wr_rst_n(S_AXI_ARESETN),
    .wr_en(S_AXI_WVALID && S_AXI_WREADY),
    .din({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST, S_AXI_WVALID}),
    .full(w_fifo_full),
    .rd_clk(M_AXI_ACLK),
    .rd_rst_n(M_AXI_ARESETN),
    .rd_en(M_AXI_WVALID && M_AXI_WREADY),
    .dout({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST})
);

assign S_AXI_WREADY = !w_fifo_full;

// Read Address Channel (AR)
dual_clock_fifo #(
    .DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4),
    .FIFO_DEPTH(2**LGFIFO)
) ar_fifo (
    .wr_clk(S_AXI_ACLK),
    .wr_rst_n(S_AXI_ARESETN),
    .wr_en(S_AXI_ARVALID && S_AXI_ARREADY),
    .din({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS}),
    .full(ar_fifo_full),
    .rd_clk(M_AXI_ACLK),
    .rd_rst_n(M_AXI_ARESETN),
    .rd_en(M_AXI_ARVALID && M_AXI_ARREADY),
    .dout({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS})
);

assign S_AXI_ARREADY = !ar_fifo_full;

// Read Data Channel (R)
dual_clock_fifo #(
    .DATA_WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_DATA_WIDTH + 2),
    .FIFO_DEPTH(2**LGFIFO)
) r_fifo (
    .wr_clk(M_AXI_ACLK),
    .wr_rst_n(M_AXI_ARESETN),
    .wr_en(M_AXI_RVALID && M_AXI_RREADY),
    .din({M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST}),
    .full(r_fifo_full),
    .rd_clk(S_AXI_ACLK),
    .rd_rst_n(S_AXI_ARESETN),
    .rd_en(S_AXI_RVALID && S_AXI_RREADY),
    .dout({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST})
);

assign M_AXI_RREADY = !r_fifo_full;

// Write Response Channel (B)
dual_clock_fifo #(
    .DATA_WIDTH(C_S_AXI_ID_WIDTH + 2),
    .FIFO_DEPTH(2**LGFIFO)
) b_fifo (
    .wr_clk(M_AXI_ACLK),
    .wr_rst_n(M_AXI_ARESETN),
    .wr_en(M_AXI_BVALID && M_AXI_BREADY),
    .din({M_AXI_BID, M_AXI_BRESP}),
    .full(b_fifo_full),
    .rd_clk(S_AXI_ACLK),
    .rd_rst_n(S_AXI_ARESETN),
    .rd_en(S_AXI_BVALID && S_AXI_BREADY),
    .dout({S_AXI_BID, S_AXI_BRESP})
);

assign M_AXI_BREADY = !b_fifo_full;

// Assign M_AXI_ARESETN (assuming active-low)
assign M_AXI_ARESETN = S_AXI_ARESETN;

endmodule

// Dual-clock FIFO module
module dual_clock_fifo #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8
) (
    input wr_clk,
    input wr_rst_n,
    input wr_en,
    input [DATA_WIDTH-1:0] din,
    output full,
    input rd_clk,
    input rd_rst_n,
    input rd_en,
    output [DATA_WIDTH-1:0] dout,
    output empty
);

reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
reg [31:0] wr_ptr, rd_ptr;
reg [31:0] wr_ptr_gray, rd_ptr_gray;

// Write logic
always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        wr_ptr <= 0;
        wr_ptr_gray <= 0;
    end else if (wr_en && !full) begin
        mem[wr_ptr] <= din;
        wr_ptr <= wr_ptr + 1;
        wr_ptr_gray <= (wr_ptr >> 1) ^ wr_ptr;
    end
end

// Read logic
always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        rd_ptr <= 0;
        rd_ptr_gray <= 0;
    end else if (rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1;
        rd_ptr_gray <= (rd_ptr >> 1) ^ rd_ptr;
    end
end

// Full and empty conditions
assign full = (wr_ptr_gray == {~rd_ptr_gray[31:0], rd_ptr_gray[0]});
assign empty = (wr_ptr_gray == rd_ptr_gray);

// Read data
assign dout = mem[rd_ptr];

endmodule
