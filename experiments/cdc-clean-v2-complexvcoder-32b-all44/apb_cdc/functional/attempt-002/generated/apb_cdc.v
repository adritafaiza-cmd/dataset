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

    // Internal signals
    reg                        fifo_full;
    wire [ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3:0] fifo_dout;
    reg                        fifo_empty;

    // FIFO instance
    fifo #(
        .DATA_WIDTH(ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+4),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_inst (
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .wr_en(src_psel_i & src_penable_i & ~fifo_full),
        .din({src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .full(fifo_full),
        .clk_r(dst_pclk_i),
        .rst_n_r(dst_preset_ni),
        .dout(fifo_dout),
        .empty(fifo_empty),
        .rd_en(dst_pready_i & ~fifo_empty)
    );

    // Source interface outputs
    assign src_pready_o = fifo_empty;
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

    // Destination interface outputs
    assign dst_psel_o = ~fifo_empty;
    assign dst_penable_o = ~fifo_empty;
    assign dst_pwrite_o = fifo_dout[0];
    assign dst_paddr_o = fifo_dout[ADDR_WIDTH:1];
    assign dst_pwdata_o = fifo_dout[ADDR_WIDTH+DATA_WIDTH:ADDR_WIDTH+1];
    assign dst_pstrb_o = fifo_dout[ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8:ADDR_WIDTH+DATA_WIDTH+1];
    assign dst_pprot_o = fifo_dout[ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3:ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+1];

endmodule

module fifo #(
    parameter DATA_WIDTH = 36,
    parameter LOG_DEPTH = 1
)(
    input clk,
    input rst_n,
    input wr_en,
    input [DATA_WIDTH-1:0] din,
    output reg full,
    input clk_r,
    input rst_n_r,
    output [DATA_WIDTH-1:0] dout,
    output reg empty,
    input rd_en
);

    localparam DEPTH = 1 << LOG_DEPTH;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            cnt <= 0;
            full <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
                cnt <= cnt + 1;
                if (cnt == DEPTH-1)
                    full <= 1;
            end
        end
    end

    always @(posedge clk_r or negedge rst_n_r) begin
        if (!rst_n_r) begin
            rd_ptr <= 0;
            cnt <= 0;
            empty <= 1;
        end else begin
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                cnt <= cnt - 1;
                if (cnt == 0)
                    empty <= 1;
            end
        end
    end

    assign dout = mem[rd_ptr];
    always @(posedge clk_r or negedge rst_n_r) begin
        if (!rst_n_r)
            empty <= 1;
        else if (wr_en && !full && rd_en && !empty && wr_ptr == rd_ptr)
            empty <= 1;
        else if (wr_en && !full && cnt < DEPTH)
            empty <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            full <= 0;
        else if (wr_en && !full && cnt < DEPTH)
            full <= 0;
        else if (wr_en && !rd_en && cnt == DEPTH-1)
            full <= 1;
    end

endmodule
