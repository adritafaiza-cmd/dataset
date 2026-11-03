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

    // Internal signals for FIFO control
    reg                        req_fifo_wren;
    reg                        req_fifo_rden;
    wire                       req_fifo_empty;
    wire                       req_fifo_full;

    reg                        resp_fifo_wren;
    reg                        resp_fifo_rden;
    wire                       resp_fifo_empty;
    wire                       resp_fifo_full;

    // FIFO instantiation for request signals
    fifo_sync #(
        .WIDTH(1 + 1 + 1 + ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo_inst (
        .clk(src_pclk_i),
        .rst_ni(src_preset_ni),
        .din({src_psel_i, src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .wren(req_fifo_wren),
        .clk_dest(dst_pclk_i),
        .rst_ni_dest(dst_preset_ni),
        .rden(req_fifo_rden),
        .dout({dst_psel_o, dst_penable_o, dst_pwrite_o, dst_paddr_o, dst_pwdata_o, dst_pstrb_o, dst_pprot_o}),
        .empty(req_fifo_empty),
        .full(req_fifo_full)
    );

    // FIFO instantiation for response signals
    fifo_sync #(
        .WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo_inst (
        .clk(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .din(dst_prdata_i),
        .wren(resp_fifo_wren),
        .clk_dest(src_pclk_i),
        .rst_ni_dest(src_preset_ni),
        .rden(resp_fifo_rden),
        .dout(src_prdata_o),
        .empty(resp_fifo_empty),
        .full(resp_fifo_full)
    );

    // Control logic for request FIFO write enable
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_fifo_wren <= 1'b0;
        end else begin
            req_fifo_wren <= src_penable_i & ~req_fifo_full;
        end
    end

    // Control logic for request FIFO read enable
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_fifo_rden <= 1'b0;
        end else begin
            req_fifo_rden <= src_pready_o;
        end
    end

    // Control logic for response FIFO write enable
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            resp_fifo_wren <= 1'b0;
        end else begin
            resp_fifo_wren <= dst_pready_i;
        end
    end

    // Control logic for response FIFO read enable
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            resp_fifo_rden <= 1'b0;
        end else begin
            resp_fifo_rden <= ~resp_fifo_empty;
        end
    end

    // Output signals
    assign src_pready_o = ~req_fifo_full & (req_fifo_empty | dst_pready_i);
    assign src_pslverr_o = dst_pslverr_i;

endmodule

module fifo_sync #(
    parameter WIDTH = 1,
    parameter LOG_DEPTH = 1
)(
    input                      clk,
    input                      rst_ni,
    input  [WIDTH-1:0]       din,
    input                      wren,
    input                      clk_dest,
    input                      rst_ni_dest,
    input                      rden,
    output [WIDTH-1:0]       dout,
    output                     empty,
    output                     full
);

    localparam DEPTH = 1 << LOG_DEPTH;
    reg [WIDTH-1:0]          mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0]  wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0]    count;

    // Write pointer and memory update
    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            count <= 0;
        end else if (wren & ~full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
    end

    // Read pointer and memory read
    always @(posedge clk_dest or negedge rst_ni_dest) begin
        if (!rst_ni_dest) begin
            rd_ptr <= 0;
        end else if (rden & ~empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Output data
    always @(posedge clk_dest) begin
        if (rden & ~empty) begin
            dout <= mem[rd_ptr];
        end
    end

    // FIFO status signals
    assign full = (count == DEPTH);
    assign empty = (count == 0);

endmodule
