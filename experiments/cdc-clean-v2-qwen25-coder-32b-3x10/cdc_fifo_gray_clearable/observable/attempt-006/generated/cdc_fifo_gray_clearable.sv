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

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    // Source side signals
    reg [ADDR_WIDTH:0] src_wr_ptr;
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0]    mem [0:DEPTH-1];
    reg                src_clear_pending;
    reg                src_clear;

    // Destination side signals
    reg [ADDR_WIDTH:0] dst_rd_ptr;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;
    reg                dst_clear_pending;
    reg                dst_clear;

    // Clear handling
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear <= 1'b0;
            src_clear_pending <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear <= 1'b1;
                src_clear_pending <= 1'b1;
            end else if (src_clear) begin
                src_clear <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear <= 1'b0;
            dst_clear_pending <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear <= 1'b1;
                dst_clear_pending <= 1'b1;
            end else if (dst_clear) begin
                dst_clear <= 1'b0;
            end
        end
    end

    // Source side write pointer and memory write
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
        end else if (src_clear) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            src_wr_ptr <= src_wr_ptr + 1;
            src_wr_ptr_gray <= src_wr_ptr + 1;
            mem[src_wr_ptr[ADDR_WIDTH-1:0]] <= src_data_i;
        end
    end

    // Source side read pointer gray sync
    generate
        genvar i;
        reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync_reg [0:SYNC_STAGES-1];
        assign src_rd_ptr_gray_sync = src_rd_ptr_gray_sync_reg[SYNC_STAGES-1];
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_src_gray_sync
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_rd_ptr_gray_sync_reg[i] <= 0;
                end else begin
                    if (i == 0) begin
                        src_rd_ptr_gray_sync_reg[i] <= dst_rd_ptr_gray;
                    end else begin
                        src_rd_ptr_gray_sync_reg[i] <= src_rd_ptr_gray_sync_reg[i-1];
                    end
                end
            end
        end
    endgenerate

    // Source side ready signal
    assign src_ready_o = (src_wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] != src_rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1]);

    // Destination side read pointer and data output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
        end else if (dst_clear) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr <= dst_rd_ptr + 1;
            dst_rd_ptr_gray <= dst_rd_ptr + 1;
        end
    end

    // Destination side write pointer gray sync
    generate
        genvar j;
        reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync_reg [0:SYNC_STAGES-1];
        assign dst_wr_ptr_gray_sync = dst_wr_ptr_gray_sync_reg[SYNC_STAGES-1];
        for (j = 0; j < SYNC_STAGES; j = j + 1) begin : gen_dst_gray_sync
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_wr_ptr_gray_sync_reg[j] <= 0;
                end else begin
                    if (j == 0) begin
                        dst_wr_ptr_gray_sync_reg[j] <= src_wr_ptr_gray;
                    end else begin
                        dst_wr_ptr_gray_sync_reg[j] <= dst_wr_ptr_gray_sync_reg[j-1];
                    end
                end
            end
        end
    endgenerate

    // Destination side valid signal
    assign dst_valid_o = (dst_wr_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1] != dst_rd_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1]);

    // Destination side data output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= mem[dst_rd_ptr[ADDR_WIDTH-1:0]];
        end
    end

    // Clear pending outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
