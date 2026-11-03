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

    localparam FIFO_WIDTH = ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 3 + 1;

    // Internal signals
    reg src_request_valid;
    reg src_request_ready;
    reg dst_request_valid;
    reg dst_request_ready;
    reg fifo_full;
    reg fifo_empty;
    reg [FIFO_WIDTH-1:0] fifo_data_out;
    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg src_pslverr_reg;

    // FIFO instantiation
    apb_cdc_fifo #(
        .DATA_WIDTH(FIFO_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) u_apb_cdc_fifo (
        .src_clk_i(src_pclk_i),
        .src_rst_ni(src_preset_ni),
        .src_data_i({src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i, src_pwrite_i}),
        .src_valid_i(src_request_valid),
        .src_ready_o(src_request_ready),
        .dst_clk_i(dst_pclk_i),
        .dst_rst_ni(dst_preset_ni),
        .dst_data_o(fifo_data_out),
        .dst_valid_o(dst_request_valid),
        .dst_ready_i(dst_request_ready),
        .fifo_full_o(fifo_full),
        .fifo_empty_o(fifo_empty)
    );

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
        end else begin
            if (src_request_ready && src_penable_i) begin
                src_pready_o <= 0;
            end else if (dst_pready_i && dst_request_valid) begin
                src_pready_o <= 1;
                src_prdata_o <= src_prdata_reg;
                src_pslverr_o <= src_pslverr_reg;
            end
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_reg <= 0;
            src_pslverr_reg <= 0;
        end else if (dst_pready_i && dst_request_valid) begin
            src_prdata_reg <= dst_prdata_i;
            src_pslverr_reg <= dst_pslverr_i;
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_request_valid <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_pready_o && !fifo_full) begin
                src_request_valid <= 1;
            end else if (src_request_ready) begin
                src_request_valid <= 0;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
        end else begin
            if (dst_request_valid && !dst_pready_i) begin
                dst_psel_o <= 1;
                dst_penable_o <= 1;
            end else if (dst_pready_i) begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_pwrite_o <= 0;
            dst_paddr_o <= 0;
            dst_pwdata_o <= 0;
            dst_pstrb_o <= 0;
            dst_pprot_o <= 0;
        end else if (dst_request_valid && !dst_pready_i) begin
            dst_pwrite_o <= fifo_data_out[FIFO_WIDTH-1];
            dst_paddr_o <= fifo_data_out[FIFO_WIDTH-2-:ADDR_WIDTH];
            dst_pwdata_o <= fifo_data_out[FIFO_WIDTH-3-ADDR_WIDTH-:DATA_WIDTH];
            dst_pstrb_o <= fifo_data_out[FIFO_WIDTH-4-ADDR_WIDTH-DATA_WIDTH-:DATA_WIDTH/8];
            dst_pprot_o <= fifo_data_out[FIFO_WIDTH-5-ADDR_WIDTH-DATA_WIDTH-DATA_WIDTH/8-:3];
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_request_ready <= 0;
        end else begin
            if (dst_pready_i) begin
                dst_request_ready <= 1;
            end else begin
                dst_request_ready <= 0;
            end
        end
    end

endmodule

// FIFO module for asynchronous crossing
module apb_cdc_fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_clk_i,
    input                      src_rst_ni,
    input  [DATA_WIDTH-1:0]    src_data_i,
    input                      src_valid_i,
    output                     src_ready_o,
    input                      dst_clk_i,
    input                      dst_rst_ni,
    output [DATA_WIDTH-1:0]    dst_data_o,
    output                     dst_valid_o,
    input                      dst_ready_i,
    output                     fifo_full_o,
    output                     fifo_empty_o
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] src_wr_ptr;
    reg [ADDR_WIDTH-1:0] dst_rd_ptr;
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;

    // Gray code conversion functions
    function [ADDR_WIDTH:0] binary_to_gray;
        input [ADDR_WIDTH:0] bin;
        binary_to_gray = bin ^ (bin >> 1);
    endfunction

    function [ADDR_WIDTH:0] gray_to_binary;
        input [ADDR_WIDTH:0] gray;
        reg [ADDR_WIDTH:0] bin;
        integer i;
        bin = gray;
        for (i = 0; i < ADDR_WIDTH; i = i + 1) begin
            bin = bin ^ (bin >> 1);
        end
        gray_to_binary = bin;
    endfunction

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            mem[src_wr_ptr] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1;
            src_wr_ptr_gray <= binary_to_gray(src_wr_ptr + 1);
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr <= dst_rd_ptr + 1;
            dst_rd_ptr_gray <= binary_to_gray(dst_rd_ptr + 1);
        end
    end

    // FIFO control signals
    assign src_ready_o = !(src_wr_ptr_gray[ADDR_WIDTH] ^ dst_rd_ptr_gray[ADDR_WIDTH]) && (src_wr_ptr_gray[ADDR_WIDTH-1:0] != dst_rd_ptr_gray[ADDR_WIDTH-1:0]);
    assign dst_valid_o = !(src_wr_ptr_gray[ADDR_WIDTH] ^ dst_rd_ptr_gray[ADDR_WIDTH]) && (src_wr_ptr_gray[ADDR_WIDTH-1:0] != dst_rd_ptr_gray[ADDR_WIDTH-1:0]);
    assign fifo_full_o = (src_wr_ptr_gray[ADDR_WIDTH] ^ dst_rd_ptr_gray[ADDR_WIDTH]) && (src_wr_ptr_gray[ADDR_WIDTH-1:0] == dst_rd_ptr_gray[ADDR_WIDTH-1:0]);
    assign fifo_empty_o = !(src_wr_ptr_gray[ADDR_WIDTH] ^ dst_rd_ptr_gray[ADDR_WIDTH]) && (src_wr_ptr_gray[ADDR_WIDTH-1:0] == dst_rd_ptr_gray[ADDR_WIDTH-1:0]);

    // Data output
    assign dst_data_o = mem[gray_to_binary(dst_rd_ptr_gray)];

endmodule
