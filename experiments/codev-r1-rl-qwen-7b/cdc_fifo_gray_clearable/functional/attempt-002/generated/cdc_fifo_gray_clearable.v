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

localparam PTR_WIDTH = LOG_DEPTH + 1;

// Source domain signals
reg [PTR_WIDTH-1:0] wr_ptr_bin, wr_ptr_gray;
reg [PTR_WIDTH-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
reg dst_clear_sync1, dst_clear_sync2;
reg src_clear_pending;

// Destination domain signals
reg [PTR_WIDTH-1:0] rd_ptr_bin, rd_ptr_gray;
reg [PTR_WIDTH-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
reg src_clear_sync1, src_clear_sync2;
reg dst_clear_pending;

// Memory
reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

// FIFO status
wire fifo_empty = (wr_ptr_gray == rd_ptr_gray_sync2);
wire fifo_full = ((wr_ptr_gray[PTR_WIDTH-1] != rd_ptr_gray_sync2[PTR_WIDTH-1]) &&
                  (wr_ptr_gray[PTR_WIDTH-2:0] == rd_ptr_gray_sync2[PTR_WIDTH-2:0]));

// Source domain logic
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        wr_ptr_bin <= 0;
        wr_ptr_gray <= 0;
        dst_clear_sync1 <= 0;
        dst_clear_sync2 <= 0;
        src_clear_pending <= 0;
    end else begin
        // Synchronize dst_clear_i
        dst_clear_sync1 <= dst_clear_i;
        dst_clear_sync2 <= dst_clear_sync1;

        if (src_clear_pending) begin
            if (fifo_empty) begin
                src_clear_pending <= 0;
            end
        end else if (src_clear_i || dst_clear_sync2) begin
            src_clear_pending <= 1;
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= wr_ptr_bin + 1;
        end
    end
end

// Destination domain logic
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        rd_ptr_bin <= 0;
        rd_ptr_gray <= 0;
        src_clear_sync1 <= 0;
        src_clear_sync2 <= 0;
        dst_clear_pending <= 0;
    end else begin
        // Synchronize src_clear_i
        src_clear_sync1 <= src_clear_i;
        src_clear_sync2 <= src_clear_sync1;

        if (dst_clear_pending) begin
            if (fifo_empty) begin
                dst_clear_pending <= 0;
            end
        end else if (dst_clear_i || src_clear_sync2) begin
            dst_clear_pending <= 1;
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= rd_ptr_bin + 1;
        end
    end
end

// Synchronize read pointer to write domain
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        rd_ptr_gray_sync1 <= 0;
        rd_ptr_gray_sync2 <= 0;
    end else begin
        rd_ptr_gray_sync1 <= rd_ptr_gray;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
end

// Synchronize write pointer to read domain
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        wr_ptr_gray_sync1 <= 0;
        wr_ptr_gray_sync2 <= 0;
    end else begin
        wr_ptr_gray_sync1 <= wr_ptr_gray;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
end

// Memory write
always @(posedge src_clk_i) begin
    if (src_valid_i && src_ready_o && !src_clear_pending) begin
        mem[wr_ptr_bin[PTR_WIDTH-2:0]] <= src_data_i;
    end
end

// Memory read
assign dst_data_o = mem[rd_ptr_bin[PTR_WIDTH-2:0]];

// Valid and ready assignments
assign src_ready_o = !src_clear_pending && !fifo_full;
assign dst_valid_o = !dst_clear_pending && !fifo_empty;

// Pending outputs
assign src_clear_pending_o = src_clear_pending;
assign dst_clear_pending_o = dst_clear_pending;

endmodule
