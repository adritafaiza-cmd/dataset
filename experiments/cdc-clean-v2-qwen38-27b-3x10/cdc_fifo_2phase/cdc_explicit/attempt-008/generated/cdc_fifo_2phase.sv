module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_W = LOG_DEPTH;
    localparam FULL_PTR_W = LOG_DEPTH + 1;

    // Source domain: write pointer and FIFO memory
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] wptr;
    reg [FULL_PTR_W-1:0] wptr_full;

    // Destination domain: read pointer
    reg [PTR_W-1:0] rptr;
    reg [FULL_PTR_W-1:0] rptr_full;

    // Synchronization of write pointer to destination domain
    reg [FULL_PTR_W-1:0] wptr_sync1;
    reg [FULL_PTR_W-1:0] wptr_sync2;

    // Synchronization of read pointer to source domain
    reg [FULL_PTR_W-1:0] rptr_sync1;
    reg [FULL_PTR_W-1:0] rptr_sync2;

    // Destination domain: data pipeline
    reg [WIDTH-1:0] data_pipe1;
    reg [WIDTH-1:0] data_pipe2;
    reg valid_pipe1;
    reg valid_pipe2;

    // Source domain: write enable
    wire src_wr_en = src_valid_i & src_ready_o;

    // Destination domain: read enable
    wire dst_rd_en = dst_valid_o & dst_ready_i;

    // Full/empty logic
    // FIFO is full when wptr_full - rptr_full == DEPTH
    // FIFO is empty when wptr_full == rptr_full
    wire src_full = (wptr_full - rptr_sync2) == DEPTH;
    wire dst_empty = (wptr_sync2 == rptr_full);

    assign src_ready_o = ~src_full;

    // Source clock domain: write pointer update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr <= {PTR_W{1'b0}};
            wptr_full <= {FULL_PTR_W{1'b0}};
        end else begin
            if (src_wr_en) begin
                wptr <= wptr + 1'b1;
                wptr_full <= wptr_full + 1'b1;
            end
        end
    end

    // Source clock domain: write data to memory
    always @(posedge src_clk_i) begin
        if (src_wr_en) begin
            mem[wptr] <= src_data_i;
        end
    end

    // Destination clock domain: read pointer update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr <= {PTR_W{1'b0}};
            rptr_full <= {FULL_PTR_W{1'b0}};
        end else begin
            if (dst_rd_en) begin
                rptr <= rptr + 1'b1;
                rptr_full <= rptr_full + 1'b1;
            end
        end
    end

    // Destination clock domain: read data from memory and pipeline
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            data_pipe1 <= {WIDTH{1'b0}};
            data_pipe2 <= {WIDTH{1'b0}};
            valid_pipe1 <= 1'b0;
            valid_pipe2 <= 1'b0;
        end else begin
            // Stage 1: read from memory
            if (!dst_empty) begin
                data_pipe1 <= mem[rptr];
                valid_pipe1 <= 1'b1;
            end else begin
                valid_pipe1 <= 1'b0;
            end

            // Stage 2: shift to output
            data_pipe2 <= data_pipe1;
            valid_pipe2 <= valid_pipe1;
        end
    end

    assign dst_data_o = data_pipe2;
    assign dst_valid_o = valid_pipe2;

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wptr_sync1 <= {FULL_PTR_W{1'b0}};
            wptr_sync2 <= {FULL_PTR_W{1'b0}};
        end else begin
            wptr_sync1 <= wptr_full;
            wptr_sync2 <= wptr_sync1;
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rptr_sync1 <= {FULL_PTR_W{1'b0}};
            rptr_sync2 <= {FULL_PTR_W{1'b0}};
        end else begin
            rptr_sync1 <= rptr_full;
            rptr_sync2 <= rptr_sync1;
        end
    end

endmodule
