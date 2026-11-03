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

    // FIFO signals
    reg [ADDR_WIDTH-1:0]       fifo_addr;
    reg [DATA_WIDTH-1:0]       fifo_wdata;
    reg [DATA_WIDTH/8-1:0]     fifo_strb;
    reg [2:0]                  fifo_prot;
    reg                        fifo_wren;
    reg                        fifo_rden;
    reg [DATA_WIDTH-1:0]       fifo_rdata;
    reg                        fifo_empty;
    reg                        fifo_full;

    // Source side signals
    reg                        src_req_valid;
    reg                        src_req_ready;
    reg                        src_req_accepted;
    reg                        src_req_done;

    // Destination side signals
    reg                        dst_req_valid;
    reg                        dst_req_ready;
    reg                        dst_req_accepted;
    reg                        dst_req_done;

    // FIFO instantiation
    apb_cdc_fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) apb_cdc_fifo_inst (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .wren_i(fifo_wren),
        .rden_i(fifo_rden),
        .wdata_i({src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .rdata_o({fifo_addr, fifo_wdata, fifo_strb, fifo_prot}),
        .empty_o(fifo_empty),
        .full_o(fifo_full)
    );

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_valid <= 0;
            src_req_accepted <= 0;
            src_req_done <= 0;
            fifo_wren <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_req_valid) begin
                src_req_valid <= 1;
            end
            if (src_req_valid && !fifo_full) begin
                fifo_wren <= 1;
                src_req_accepted <= 1;
            end else begin
                fifo_wren <= 0;
            end
            if (src_req_accepted && fifo_empty) begin
                src_req_valid <= 0;
                src_req_accepted <= 0;
            end
            if (src_req_accepted && dst_req_done) begin
                src_req_done <= 1;
            end
            if (src_req_done && src_pready_o) begin
                src_req_done <= 0;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_valid <= 0;
            dst_req_accepted <= 0;
            dst_req_done <= 0;
            fifo_rden <= 0;
        end else begin
            if (!fifo_empty && !dst_req_valid) begin
                fifo_rden <= 1;
                dst_req_valid <= 1;
            end else begin
                fifo_rden <= 0;
            end
            if (dst_req_valid && dst_pready_i) begin
                dst_req_accepted <= 1;
            end
            if (dst_req_accepted && dst_pready_i) begin
                dst_req_valid <= 0;
                dst_req_accepted <= 0;
                dst_req_done <= 1;
            end
            if (dst_req_done) begin
                dst_req_done <= 0;
            end
        end
    end

    // Source side outputs
    assign src_pready_o = src_req_done;
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

    // Destination side outputs
    assign dst_psel_o = dst_req_valid;
    assign dst_penable_o = dst_req_valid;
    assign dst_pwrite_o = src_pwrite_i;
    assign dst_paddr_o = fifo_addr;
    assign dst_pwdata_o = fifo_wdata;
    assign dst_pstrb_o = fifo_strb;
    assign dst_pprot_o = fifo_prot;

endmodule

// FIFO module
module apb_cdc_fifo #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_i,
    input                      rst_ni,
    input                      wren_i,
    input                      rden_i,
    input  [DATA_WIDTH-1:0]    wdata_i,
    output [DATA_WIDTH-1:0]    rdata_o,
    output                     empty_o,
    output                     full_o
);

    localparam DEPTH = 1 << LOG_DEPTH;
    reg [DATA_WIDTH-1:0]       mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0]      wr_ptr;
    reg [$clog2(DEPTH):0]      rd_ptr;
    reg [$clog2(DEPTH):0]      cnt;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt <= 0;
        end else begin
            if (wren_i && !full_o) begin
                mem[wr_ptr] <= wdata_i;
                wr_ptr <= wr_ptr + 1;
                cnt <= cnt + 1;
            end
            if (rden_i && !empty_o) begin
                rd_ptr <= rd_ptr + 1;
                cnt <= cnt - 1;
            end
        end
    end

    assign rdata_o = mem[rd_ptr];
    assign empty_o = (cnt == 0);
    assign full_o = (cnt == DEPTH);

endmodule
