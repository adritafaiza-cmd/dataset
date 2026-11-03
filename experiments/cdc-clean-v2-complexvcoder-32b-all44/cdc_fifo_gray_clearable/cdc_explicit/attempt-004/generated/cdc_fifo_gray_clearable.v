module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    reg                    src_clear_pending;
    reg                    dst_clear_pending;
    reg                    src_ready;
    reg                    dst_valid;

    // Gray counters and synchronizers
    wire [LOG_DEPTH:0]     gray_src_code;
    wire [LOG_DEPTH:0]     gray_dst_code;
    wire [LOG_DEPTH:0]     sync_gray_src_to_dst;
    wire [LOG_DEPTH:0]     sync_gray_dst_to_src;

    // FIFO pointers and logic
    reg [LOG_DEPTH:0]      src_gray_ptr;
    reg [LOG_DEPTH:0]      dst_gray_ptr;
    reg [LOG_DEPTH:0]      src_gray_ptr_next;
    reg [LOG_DEPTH:0]      dst_gray_ptr_next;
    reg                    src_full;
    reg                    dst_empty;

    // Data register
    reg [WIDTH-1:0]        data_reg;
    reg                    valid_reg;
    reg                    data_accepted;

    // Gray counter for source
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .sync_gray_i(sync_gray_dst_to_src),
        .gray_code_o(gray_src_code)
    );

    // Gray counter for destination
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .sync_gray_i(sync_gray_src_to_dst),
        .gray_code_o(gray_dst_code)
    );

    // Synchronizer for source Gray code to destination
    sync_register #(.WIDTH(LOG_DEPTH+1)) sync_gray_src_to_dst_reg (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .src_data_i(gray_src_code),
        .dst_data_o(sync_gray_src_to_dst)
    );

    // Synchronizer for destination Gray code to source
    sync_register #(.WIDTH(LOG_DEPTH+1)) sync_gray_dst_to_src_reg (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .src_data_i(gray_dst_code),
        .dst_data_o(sync_gray_dst_to_src)
    );

    // Data register
    data_register #(.WIDTH(WIDTH)) data_reg_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .data_o(dst_data_o),
        .valid_o(dst_valid_o)
    );

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_ptr <= 0;
            src_gray_ptr_next <= 0;
            src_clear_pending <= 0;
            src_ready <= 1;
        end else begin
            if (src_clear_i) begin
                src_gray_ptr <= 0;
                src_gray_ptr_next <= 0;
                src_clear_pending <= 1;
                src_ready <= 0;
            end else begin
                src_gray_ptr_next <= src_gray_ptr + 1;
                src_ready <= !(src_full || src_clear_pending);
            end

            if (src_ready && src_valid_i) begin
                src_gray_ptr <= src_gray_ptr_next;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_ptr <= 0;
            dst_gray_ptr_next <= 0;
            dst_clear_pending <= 0;
            dst_valid <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_gray_ptr <= 0;
                dst_gray_ptr_next <= 0;
                dst_clear_pending <= 1;
                dst_valid <= 0;
            end else begin
                dst_gray_ptr_next <= dst_gray_ptr + 1;
                dst_valid <= !(dst_empty || dst_clear_pending);
            end

            if (dst_valid && dst_ready_i) begin
                dst_gray_ptr <= dst_gray_ptr_next;
            end
        end
    end

    // Full and empty conditions
    assign src_full = (src_gray_ptr_next == {1'b1, sync_gray_dst_to_src[LOG_DEPTH-1:0]});
    assign dst_empty = (dst_gray_ptr == sync_gray_src_to_dst);

    // Clear pending outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

    // Source ready output
    assign src_ready_o = src_ready;

    // Destination valid output
    assign dst_valid_o = dst_valid;

endmodule

// Gray code counter module
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    input  [LOG_DEPTH:0] sync_gray_i,
    output [LOG_DEPTH:0] gray_code_o
);

    reg [LOG_DEPTH:0] gray_code;
    reg [LOG_DEPTH:0] gray_code_next;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_code <= 0;
        end else if (clear_i) begin
            gray_code <= 0;
        end else begin
            if (sync_gray_i == gray_code) begin
                gray_code <= gray_code_next;
            end
        end
    end

    assign gray_code_next = gray_code + 1;
    assign gray_code_o = gray_code;

endmodule

// Sync register module
module sync_register #(
    parameter WIDTH = 4
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0] src_data_i,
    output [WIDTH-1:0] dst_data_o
);

    reg [WIDTH-1:0] sync_stage1;
    reg [WIDTH-1:0] sync_stage2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stage1 <= 0;
            sync_stage2 <= 0;
        end else begin
            sync_stage1 <= src_data_i;
            sync_stage2 <= sync_stage1;
        end
    end

    assign dst_data_o = sync_stage2;

endmodule

// Data register module
module data_register #(
    parameter WIDTH = 8
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0] data_i,
    input                  valid_i,
    output [WIDTH-1:0] data_o,
    output                 valid_o
);

    reg [WIDTH-1:0] data_reg;
    reg                 valid_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_reg <= 0;
            valid_reg <= 0;
        end else begin
            if (valid_i) begin
                data_reg <= data_i;
                valid_reg <= 1;
            end else if (valid_reg && dst_ready_i) begin
                valid_reg <= 0;
            end
        end
    end

    assign data_o = data_reg;
    assign valid_o = valid_reg;

endmodule
