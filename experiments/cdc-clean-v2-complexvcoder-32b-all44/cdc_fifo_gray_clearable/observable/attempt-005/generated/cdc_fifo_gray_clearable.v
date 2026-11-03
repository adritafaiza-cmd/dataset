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
    reg [LOG_DEPTH-1:0]    src_wr_ptr;
    reg [LOG_DEPTH-1:0]    src_gray_wr_ptr;
    reg [LOG_DEPTH-1:0]    synced_src_gray_wr_ptr;
    reg [LOG_DEPTH-1:0]    dst_rd_ptr;
    reg [LOG_DEPTH-1:0]    dst_gray_rd_ptr;
    reg [LOG_DEPTH-1:0]    synced_dst_gray_rd_ptr;
    reg [WIDTH-1:0]        mem [0:(2**LOG_DEPTH)-1];
    reg                    src_full;
    reg                    src_empty;
    reg                    dst_full;
    reg                    dst_empty;
    reg                    src_clear_reg;
    reg                    dst_clear_reg;

    // Gray counter instances
    gray_counter src_gray_counter (
        .binary(src_wr_ptr),
        .gray(src_gray_wr_ptr)
    );

    gray_counter dst_gray_counter (
        .binary(dst_rd_ptr),
        .gray(dst_gray_rd_ptr)
    );

    // Synchronizer instances
    synchronizer sync_src_gray_wr_ptr (
        .din(src_gray_wr_ptr),
        .dout(synced_src_gray_wr_ptr)
    );

    synchronizer sync_dst_gray_rd_ptr (
        .din(dst_gray_rd_ptr),
        .dout(synced_dst_gray_rd_ptr)
    );

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_gray_wr_ptr <= 0;
            src_clear_reg <= 0;
        end else begin
            if (!src_clear_i) begin
                src_wr_ptr <= 0;
                src_gray_wr_ptr <= 0;
                src_clear_reg <= 0;
            end else begin
                if (src_valid_i && !src_full) begin
                    mem[src_wr_ptr] <= src_data_i;
                    src_wr_ptr <= src_wr_ptr + 1;
                end
            end
        end
    end

    // Calculate full and ready
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_full <= 0;
            src_ready_o <= 1;
        end else begin
            src_full <= (synced_dst_gray_rd_ptr == (src_gray_wr_ptr + 1) % (2**LOG_DEPTH));
            src_ready_o <= !src_full;
        end
    end

    // Source clear pending
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending_o <= 0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending_o <= 1;
            end else begin
                src_clear_pending_o <= src_clear_reg;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_gray_rd_ptr <= 0;
            dst_clear_reg <= 0;
        end else begin
            if (!dst_clear_i) begin
                dst_rd_ptr <= 0;
                dst_gray_rd_ptr <= 0;
                dst_clear_reg <= 0;
            end else begin
                if (dst_ready_i && !dst_empty) begin
                    dst_rd_ptr <= dst_rd_ptr + 1;
                end
            end
        end
    end

    // Calculate empty and valid
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_empty <= 1;
            dst_valid_o <= 0;
            dst_data_o <= 0;
        end else begin
            dst_empty <= (synced_src_gray_wr_ptr == dst_gray_rd_ptr);
            dst_valid_o <= !dst_empty;
            if (!dst_empty) begin
                dst_data_o <= mem[dst_rd_ptr];
            end
        end
    end

    // Destination clear pending
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending_o <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending_o <= 1;
            end else begin
                dst_clear_pending_o <= dst_clear_reg;
            end
        end
    end

endmodule

// Gray counter module
module gray_counter (
    input  [LOG_DEPTH-1:0] binary,
    output [LOG_DEPTH-1:0] gray
);

    assign gray[LOG_DEPTH-1] = binary[LOG_DEPTH-1];
    assign gray[LOG_DEPTH-2:0] = binary[LOG_DEPTH-1:1] ^ binary[LOG_DEPTH-2:0];

endmodule

// Synchronizer module
module synchronizer #(
    parameter WIDTH = LOG_DEPTH,
    parameter STAGES = SYNC_STAGES
)(
    input  [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] reg_array [0:STAGES-1];

    always @(posedge src_clk_i) begin
        reg_array[0] <= din;
    end

    always @(posedge dst_clk_i) begin
        for (integer i = 1; i < STAGES; i = i + 1) begin
            reg_array[i] <= reg_array[i-1];
        end
    end

    assign dout = reg_array[STAGES-1];

endmodule
