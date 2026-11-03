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
    wire [ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 3 + 1 - 1:0] req_fifo_rdata;
    wire [DATA_WIDTH + 1 - 1:0] rsp_fifo_rdata;
    wire req_fifo_empty;
    wire req_fifo_full;
    wire rsp_fifo_empty;
    wire rsp_fifo_full;

    // FIFO for request signals
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 3 + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo_inst (
        .wclk(src_pclk_i),
        .wrst(src_preset_ni),
        .wfull(req_fifo_full),
        .wen(src_psel_i & src_penable_i & ~req_fifo_full),
        .wdin({src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i, src_pwrite_i}),
        .rclk(dst_pclk_i),
        .rrst(dst_preset_ni),
        .rempty(req_fifo_empty),
        .ren(dst_psel_o & dst_penable_o),
        .rdout(req_fifo_rdata)
    );

    // FIFO for response signals
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) rsp_fifo_inst (
        .wclk(dst_pclk_i),
        .wrst(dst_preset_ni),
        .wfull(rsp_fifo_full),
        .wen(dst_pready_i & ~rsp_fifo_full),
        .wdin({dst_prdata_i, dst_pslverr_i}),
        .rclk(src_pclk_i),
        .rrst(src_preset_ni),
        .rempty(rsp_fifo_empty),
        .ren(src_pready_o),
        .rdout(rsp_fifo_rdata)
    );

    // Source side logic
    reg src_pready_o_reg;
    reg [DATA_WIDTH-1:0] src_prdata_o_reg;
    reg src_pslverr_o_reg;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o_reg <= 1'b0;
            src_prdata_o_reg <= {DATA_WIDTH{1'b0}};
            src_pslverr_o_reg <= 1'b0;
        end else begin
            if (rsp_fifo_empty) begin
                src_pready_o_reg <= 1'b0;
            end else begin
                src_pready_o_reg <= 1'b1;
                src_prdata_o_reg <= rsp_fifo_rdata[DATA_WIDTH-1:0];
                src_pslverr_o_reg <= rsp_fifo_rdata[DATA_WIDTH];
            end
        end
    end

    assign src_pready_o = src_pready_o_reg;
    assign src_prdata_o = src_prdata_o_reg;
    assign src_pslverr_o = src_pslverr_o_reg;

    // Destination side logic
    reg dst_psel_o_reg;
    reg dst_penable_o_reg;
    reg dst_pwrite_o_reg;
    reg [ADDR_WIDTH-1:0] dst_paddr_o_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_o_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_o_reg;
    reg [2:0] dst_pprot_o_reg;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o_reg <= 1'b0;
            dst_penable_o_reg <= 1'b0;
            dst_pwrite_o_reg <= 1'b0;
            dst_paddr_o_reg <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o_reg <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o_reg <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_o_reg <= 3'b0;
        end else begin
            if (req_fifo_empty) begin
                dst_psel_o_reg <= 1'b0;
                dst_penable_o_reg <= 1'b0;
            end else begin
                dst_psel_o_reg <= 1'b1;
                dst_penable_o_reg <= 1'b1;
                dst_pwrite_o_reg <= req_fifo_rdata[ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 3];
                dst_paddr_o_reg <= req_fifo_rdata[ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 2 -: ADDR_WIDTH];
                dst_pwdata_o_reg <= req_fifo_rdata[ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) - 1 -: DATA_WIDTH];
                dst_pstrb_o_reg <= req_fifo_rdata[ADDR_WIDTH + DATA_WIDTH - 1 -: DATA_WIDTH/8];
                dst_pprot_o_reg <= req_fifo_rdata[ADDR_WIDTH + 2 -: 3];
            end
        end
    end

    assign dst_psel_o = dst_psel_o_reg;
    assign dst_penable_o = dst_penable_o_reg;
    assign dst_pwrite_o = dst_pwrite_o_reg;
    assign dst_paddr_o = dst_paddr_o_reg;
    assign dst_pwdata_o = dst_pwdata_o_reg;
    assign dst_pstrb_o = dst_pstrb_o_reg;
    assign dst_pprot_o = dst_pprot_o_reg;

endmodule

module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      wclk,
    input                      wrst,
    output                     wfull,
    input                      wen,
    input  [DATA_WIDTH-1:0]    wdin,
    input                      rclk,
    input                      rrst,
    output                     rempty,
    input                      ren,
    output [DATA_WIDTH-1:0]    rdout
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam AWIDTH = LOG_DEPTH ? LOG_DEPTH : 1;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [AWIDTH-1:0] wptr, rptr;
    reg [AWIDTH:0] cnt;

    always @(posedge wclk or negedge wrst) begin
        if (!wrst) begin
            wptr <= {AWIDTH{1'b0}};
            cnt <= {AWIDTH+1{1'b0}};
        end else if (wen && !wfull) begin
            mem[wptr] <= wdin;
            wptr <= wptr + 1;
            cnt <= cnt + 1;
        end
    end

    always @(posedge rclk or negedge rrst) begin
        if (!rrst) begin
            rptr <= {AWIDTH{1'b0}};
            cnt <= {AWIDTH+1{1'b0}};
        end else if (ren && !rempty) begin
            rptr <= rptr + 1;
            cnt <= cnt - 1;
        end
    end

    assign wfull = (cnt == DEPTH);
    assign rempty = (cnt == 0);
    assign rdout = mem[rptr];

endmodule
