module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals for FIFOs
    wire req_fifo_wready;
    wire [2+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3-1:0] req_fifo_rdata;
    wire req_fifo_rvalid;
    wire req_fifo_rready;

    wire resp_fifo_wready;
    wire [DATA_WIDTH+1-1:0] resp_fifo_rdata;
    wire resp_fifo_rvalid;
    wire resp_fifo_rready;

    // APB request FIFO
    async_fifo #(
        .WIDTH(2+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3),
        .DEPTH(2**LOG_DEPTH)
    ) req_fifo_inst (
        .wclk(src_pclk_i),
        .wrst_n(src_preset_ni),
        .wvalid(src_psel_i),
        .wdata({src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .wready(req_fifo_wready),
        .rclk(dst_pclk_i),
        .rrst_n(dst_preset_ni),
        .rdata(req_fifo_rdata),
        .rvalid(req_fifo_rvalid),
        .rready(req_fifo_rready)
    );

    // APB response FIFO
    async_fifo #(
        .WIDTH(DATA_WIDTH+1),
        .DEPTH(2**LOG_DEPTH)
    ) resp_fifo_inst (
        .wclk(dst_pclk_i),
        .wrst_n(dst_preset_ni),
        .wvalid(dst_pready_i),
        .wdata({dst_prdata_i, dst_pslverr_i}),
        .wready(resp_fifo_wready),
        .rclk(src_pclk_i),
        .rrst_n(src_preset_ni),
        .rdata(resp_fifo_rdata),
        .rvalid(resp_fifo_rvalid),
        .rready(resp_fifo_rready)
    );

    // Assign outputs based on FIFO signals
    assign src_pready_o = req_fifo_wready;
    assign src_prdata_o = resp_fifo_rdata[0+:DATA_WIDTH];
    assign src_pslverr_o = resp_fifo_rdata[DATA_WIDTH];
    assign resp_fifo_rready = resp_fifo_rvalid;
    assign dst_psel_o = req_fifo_rvalid;
    assign dst_penable_o = req_fifo_rdata[0];
    assign dst_pwrite_o = req_fifo_rdata[1];
    assign dst_paddr_o = req_fifo_rdata[2+:ADDR_WIDTH];
    assign dst_pwdata_o = req_fifo_rdata[2+ADDR_WIDTH+:DATA_WIDTH];
    assign dst_pstrb_o = req_fifo_rdata[2+ADDR_WIDTH+DATA_WIDTH+:DATA_WIDTH/8];
    assign dst_pprot_o = req_fifo_rdata[2+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+:3];
    assign req_fifo_rready = dst_pready_i;

endmodule

module async_fifo #(
    parameter WIDTH = 1,
    parameter DEPTH = 2
)(
    input                      wclk,
    input                      wrst_n,
    input                      wvalid,
    input  [WIDTH-1:0]         wdata,
    output                     wready,
    input                      rclk,
    input                      rrst_n,
    output [WIDTH-1:0]         rdata,
    output                     rvalid,
    input                      rready
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wptr, rptr;
    reg [$clog2(DEPTH):0] wptr_gray, rptr_gray;
    reg [$clog2(DEPTH):0] wptr_gray_synced, rptr_gray_synced;

    wire [$clog2(DEPTH):0] wptr_bin_synced;
    wire [$clog2(DEPTH):0] rptr_bin_synced;

    // Binary to Gray conversion for write pointer
    assign wptr_gray = wptr ^ (wptr >> 1);

    // Binary to Gray conversion for read pointer
    assign rptr_gray = rptr ^ (rptr >> 1);

    // Synchronize write pointer Gray code to read clock domain
    sync_gray #(
        .WIDTH($clog2(DEPTH) + 1)
    ) sync_wptr (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(wptr_gray),
        .dout(wptr_gray_synced)
    );

    // Synchronize read pointer Gray code to write clock domain
    sync_gray #(
        .WIDTH($clog2(DEPTH) + 1)
    ) sync_rptr (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(rptr_gray),
        .dout(rptr_gray_synced)
    );

    // Gray to Binary conversion for synchronized write pointer
    assign wptr_bin_synced = (wptr_gray_synced >> 1) ^ wptr_gray_synced;

    // Gray to Binary conversion for synchronized read pointer
    assign rptr_bin_synced = (rptr_gray_synced >> 1) ^ rptr_gray_synced;

    // Write enable logic
    wire wren = wvalid & wready;

    // Read enable logic
    wire rden = rvalid & rready;

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (wren) begin
            wptr <= wptr + 1;
        end
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rden) begin
            rptr <= rptr + 1;
        end
    end

    // FIFO write operation
    always @(posedge wclk) begin
        if (wren) begin
            mem[wptr] <= wdata;
        end
    end

    // FIFO read operation
    always @(posedge rclk) begin
        rdata <= mem[rptr];
    end

    // FIFO status flags
    assign wready = (wptr_bin_synced != (rptr_bin_synced + 1));
    assign rvalid = (wptr_bin_synced != rptr_bin_synced);

endmodule

module sync_gray #(
    parameter WIDTH = 2
)(
    input                      clk,
    input                      rst_n,
    input  [WIDTH-1:0]         din,
    output reg [WIDTH-1:0]     dout
);

    reg [WIDTH-1:0] dout_reg1;
    reg [WIDTH-1:0] dout_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_reg1 <= 0;
            dout_reg2 <= 0;
        end else begin
            dout_reg1 <= din;
            dout_reg2 <= dout_reg1;
        end
    end

    assign dout = dout_reg2;

endmodule
