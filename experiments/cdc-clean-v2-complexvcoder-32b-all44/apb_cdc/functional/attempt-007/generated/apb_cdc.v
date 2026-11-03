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
    reg request_fifo_valid;
    reg request_fifo_ready;
    reg dst_request_fifo_valid;
    reg dst_request_fifo_ready;
    reg response_fifo_valid;
    reg response_fifo_ready;
    reg src_response_fifo_valid;
    reg src_response_fifo_ready;
    wire [3+ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+3-1:0] dst_data_o;
    wire [DATA_WIDTH+1-1:0] src_data_o;

    // Instantiate FIFO for requests
    fifo_sync #(
        .DATA_WIDTH(3+ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+3),
        .LOG_DEPTH(LOG_DEPTH)
    ) request_fifo (
        .clk_i(src_pclk_i),
        .reset_ni(src_preset_ni),
        .data_i({src_psel_i, src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .valid_i(request_fifo_valid),
        .ready_o(request_fifo_ready),
        .clk_o(dst_pclk_i),
        .reset_no(dst_preset_ni),
        .data_o(dst_data_o),
        .valid_o(dst_request_fifo_valid),
        .ready_i(dst_request_fifo_ready)
    );

    // Instantiate FIFO for responses
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH+1),
        .LOG_DEPTH(LOG_DEPTH)
    ) response_fifo (
        .clk_i(dst_pclk_i),
        .reset_ni(dst_preset_ni),
        .data_i({dst_prdata_i, dst_pslverr_i}),
        .valid_i(response_fifo_valid),
        .ready_o(response_fifo_ready),
        .clk_o(src_pclk_i),
        .reset_no(src_preset_ni),
        .data_o(src_data_o),
        .valid_o(src_response_fifo_valid),
        .ready_i(src_response_fifo_ready)
    );

    // Decode FIFO data
    assign dst_psel_o    = dst_data_o[0];
    assign dst_penable_o = dst_data_o[1];
    assign dst_pwrite_o  = dst_data_o[2];
    assign dst_paddr_o   = dst_data_o[3+:ADDR_WIDTH];
    assign dst_pwdata_o  = dst_data_o[3+ADDR_WIDTH+:DATA_WIDTH];
    assign dst_pstrb_o   = dst_data_o[3+ADDR_WIDTH+DATA_WIDTH+:DATA_WIDTH/8];
    assign dst_pprot_o   = dst_data_o[3+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+:3];

    assign src_prdata_o  = src_data_o[0+:DATA_WIDTH];
    assign src_pslverr_o = src_data_o[DATA_WIDTH];

    // Control logic for request FIFO
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            request_fifo_valid <= 0;
        end else begin
            if (src_psel_i && src_penable_i && request_fifo_ready) begin
                request_fifo_valid <= 1;
            end else if (dst_request_fifo_ready) begin
                request_fifo_valid <= 0;
            end
        end
    end

    // Control logic for response FIFO
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            response_fifo_valid <= 0;
        end else begin
            if (dst_pready_i && dst_request_fifo_valid) begin
                response_fifo_valid <= 1;
            end else if (src_response_fifo_ready) begin
                response_fifo_valid <= 0;
            end
        end
    end

    // Source ready signal
    assign src_pready_o = src_response_fifo_valid;

    // Destination ready signal
    assign dst_request_fifo_ready = request_fifo_valid;

endmodule

// FIFO synchronization module
module fifo_sync #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_i,
    input                      reset_ni,
    input  [DATA_WIDTH-1:0]    data_i,
    input                      valid_i,
    output                     ready_o,
    input                      clk_o,
    input                      reset_no,
    output [DATA_WIDTH-1:0]    data_o,
    output                     valid_o,
    input                      ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] count;

    always @(posedge clk_i or negedge reset_ni) begin
        if (!reset_ni) begin
            wr_ptr <= 0;
            count <= 0;
        end else if (valid_i && ready_o) begin
            mem[wr_ptr] <= data_i;
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
    end

    always @(posedge clk_o or negedge reset_no) begin
        if (!reset_no) begin
            rd_ptr <= 0;
        end else if (valid_o && ready_i) begin
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end
    end

    assign data_o = mem[rd_ptr];
    assign valid_o = (count != 0);
    assign ready_o = (count != DEPTH);

endmodule
