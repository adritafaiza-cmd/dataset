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
    reg                      req_fifo_push;
    reg                      req_fifo_pop;
    wire                     req_fifo_full;
    wire                     req_fifo_empty;
    wire [3+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+2:0] req_fifo_data_out;

    reg                      resp_fifo_push;
    reg                      resp_fifo_pop;
    wire                     resp_fifo_full;
    wire                     resp_fifo_empty;
    wire [DATA_WIDTH:0]        resp_fifo_data_out;

    reg                      req_accepted;
    reg                      req_valid;
    reg                      resp_valid;

    // Request FIFO
    cdc_fifo #(
        .WIDTH(3+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo (
        .wr_clk(src_pclk_i),
        .wr_rst_n(src_preset_ni),
        .wr_en(req_fifo_push),
        .rd_clk(dst_pclk_i),
        .rd_rst_n(dst_preset_ni),
        .rd_en(req_fifo_pop),
        .wr_data({src_psel_i, src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .rd_data(req_fifo_data_out),
        .full(req_fifo_full),
        .empty(req_fifo_empty)
    );

    // Response FIFO
    cdc_fifo #(
        .WIDTH(DATA_WIDTH+1),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo (
        .wr_clk(dst_pclk_i),
        .wr_rst_n(dst_preset_ni),
        .wr_en(resp_fifo_push),
        .rd_clk(src_pclk_i),
        .rd_rst_n(src_preset_ni),
        .rd_en(resp_fifo_pop),
        .wr_data({dst_prdata_i, dst_pslverr_i}),
        .rd_data(resp_fifo_data_out),
        .full(resp_fifo_full),
        .empty(resp_fifo_empty)
    );

    // Request FIFO control
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_accepted <= 0;
            req_valid <= 0;
        end else begin
            req_accepted <= 0;
            if (!req_fifo_full && src_psel_i && src_penable_i) begin
                req_fifo_push <= 1;
                req_accepted <= 1;
            end else begin
                req_fifo_push <= 0;
            end
            req_valid <= !req_fifo_empty;
        end
    end

    // Response FIFO control
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            resp_valid <= 0;
        end else begin
            resp_valid <= !resp_fifo_empty;
            if (!resp_fifo_empty && resp_fifo_pop) begin
                resp_fifo_pop <= 0;
            end else if (resp_valid && !resp_fifo_empty) begin
                resp_fifo_pop <= 1;
            end else begin
                resp_fifo_pop <= 0;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            resp_fifo_push <= 0;
        end else begin
            if (!resp_fifo_full && dst_pready_i && !req_fifo_empty) begin
                req_fifo_pop <= 1;
                resp_fifo_push <= 1;
            end else begin
                req_fifo_pop <= 0;
                resp_fifo_push <= 0;
            end
        end
    end

    // Output assignments
    assign src_pready_o = !req_fifo_full;
    assign src_prdata_o = resp_valid ? resp_fifo_data_out[DATA_WIDTH-1:0] : {DATA_WIDTH{1'b0}};
    assign src_pslverr_o = resp_valid ? resp_fifo_data_out[DATA_WIDTH] : 1'b0;

    assign dst_psel_o = !req_fifo_empty ? req_fifo_data_out[0] : 1'b0;
    assign dst_penable_o = !req_fifo_empty ? req_fifo_data_out[1] : 1'b0;
    assign dst_pwrite_o = !req_fifo_empty ? req_fifo_data_out[2] : 1'b0;
    assign dst_paddr_o = !req_fifo_empty ? req_fifo_data_out[3+:ADDR_WIDTH] : {ADDR_WIDTH{1'b0}};
    assign dst_pwdata_o = !req_fifo_empty ? req_fifo_data_out[3+ADDR_WIDTH+:DATA_WIDTH] : {DATA_WIDTH{1'b0}};
    assign dst_pstrb_o = !req_fifo_empty ? req_fifo_data_out[3+ADDR_WIDTH+DATA_WIDTH+:DATA_WIDTH/8] : {DATA_WIDTH/8{1'b0}};
    assign dst_pprot_o = !req_fifo_empty ? req_fifo_data_out[3+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+:3] : 3'b0;

endmodule

module cdc_fifo #(
    parameter WIDTH = 1,
    parameter LOG_DEPTH = 1
)(
    input                      wr_clk,
    input                      wr_rst_n,
    input                      wr_en,
    input                      rd_clk,
    input                      rd_rst_n,
    input                      rd_en,
    input  [WIDTH-1:0]         wr_data,
    output [WIDTH-1:0]         rd_data,
    output                     full,
    output                     empty
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync;

    // Write pointer logic
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr_gray + 1;
        end
    end

    // Read pointer logic
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                rd_ptr_gray <= rd_ptr_gray + 1;
            end
        end
    end

    // Memory write
    always @(posedge wr_clk) begin
        if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
        end
    end

    // Memory read
    always @(posedge rd_clk) begin
        rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
    end

    // Gray code conversion for synchronization
    wire [ADDR_WIDTH:0] wr_ptr_gray_sync;
    sync_gray #(
        .WIDTH(ADDR_WIDTH+1)
    ) sync_wr_ptr_gray (
        .clk(rd_clk),
        .rst_n(rd_rst_n),
        .din(wr_ptr_gray),
        .dout(wr_ptr_gray_sync)
    );

    // Full and empty flags
    assign full = (wr_ptr_gray_sync[ADDR_WIDTH:0] == {~rd_ptr_gray[ADDR_WIDTH], rd_ptr_gray[ADDR_WIDTH-1:0]});
    assign empty = (wr_ptr_gray[ADDR_WIDTH:0] == rd_ptr_gray_sync[ADDR_WIDTH:0]);

endmodule

module sync_gray #(
    parameter WIDTH = 1
)(
    input                      clk,
    input                      rst_n,
    input  [WIDTH-1:0]         din,
    output [WIDTH-1:0]         dout
);

    reg [WIDTH-1:0] sync_reg1;
    reg [WIDTH-1:0] sync_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= din;
            sync_reg2 <= sync_reg1;
        end
    end

    assign dout = sync_reg2;

endmodule
