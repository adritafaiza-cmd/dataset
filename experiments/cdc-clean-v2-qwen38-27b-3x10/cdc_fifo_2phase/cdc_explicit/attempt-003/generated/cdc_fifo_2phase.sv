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

    // Source domain: write pointer and FIFO storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] wr_ptr;
    reg [PTR_W-1:0] rd_ptr_src; // synchronized read pointer in src domain

    wire src_wr_en = src_valid_i & src_ready_o;
    wire src_full;

    // Destination domain: read pointer and output register
    reg [PTR_W-1:0] rd_ptr;
    reg [PTR_W-1:0] wr_ptr_dst; // synchronized write pointer in dst domain
    reg [WIDTH-1:0] dst_reg;
    reg dst_valid_reg;

    wire dst_rd_en = dst_valid_o & dst_ready_i;
    wire dst_empty;

    // Source domain logic
    assign src_ready_o = ~src_full;

    // Full condition: write pointer catches up to read pointer (with extra bit)
    // We use the synchronized read pointer in src domain
    wire [FULL_PTR_W-1:0] wr_ptr_full = {1'b0, wr_ptr};
    wire [FULL_PTR_W-1:0] rd_ptr_src_full = {1'b0, rd_ptr_src};
    // Full when the upper bit differs and the lower bits are equal
    assign src_full = (wr_ptr_full[FULL_PTR_W-1] != rd_ptr_src_full[FULL_PTR_W-1]) &&
                      (wr_ptr_full[PTR_W-1:0] == rd_ptr_src_full[PTR_W-1:0]);

    // Write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= {PTR_W{1'b0}};
        end else if (src_wr_en) begin
            mem[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Synchronize read pointer from dst to src domain (2-stage synchronizer)
    reg [PTR_W-1:0] rd_ptr_sync1;
    reg [PTR_W-1:0] rd_ptr_sync2;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_sync1 <= {PTR_W{1'b0}};
            rd_ptr_sync2 <= {PTR_W{1'b0}};
        end else begin
            rd_ptr_sync1 <= rd_ptr;
            rd_ptr_sync2 <= rd_ptr_sync1;
        end
    end

    assign rd_ptr_src = rd_ptr_sync2;

    // Synchronize write pointer from src to dst domain (2-stage synchronizer)
    reg [PTR_W-1:0] wr_ptr_sync1;
    reg [PTR_W-1:0] wr_ptr_sync2;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_sync1 <= {PTR_W{1'b0}};
            wr_ptr_sync2 <= {PTR_W{1'b0}};
        end else begin
            wr_ptr_sync1 <= wr_ptr;
            wr_ptr_sync2 <= wr_ptr_sync1;
        end
    end

    assign wr_ptr_dst = wr_ptr_sync2;

    // Destination domain logic
    // Empty condition: read pointer catches up to write pointer
    wire [FULL_PTR_W-1:0] rd_ptr_full = {1'b0, rd_ptr};
    wire [FULL_PTR_W-1:0] wr_ptr_dst_full = {1'b0, wr_ptr_dst};
    assign dst_empty = (rd_ptr_full[FULL_PTR_W-1] != wr_ptr_dst_full[FULL_PTR_W-1]) &&
                       (rd_ptr_full[PTR_W-1:0] == wr_ptr_dst_full[PTR_W-1:0]);

    // Read from memory and register output
    // We need to handle the case where we read data and advance the pointer
    // The data is read from mem[rd_ptr] when we are not empty
    // We use a registered output to ensure coherence

    wire [WIDTH-1:0] mem_rd_data = mem[rd_ptr];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= {PTR_W{1'b0}};
            dst_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (!dst_empty) begin
                // There is data available
                if (dst_valid_reg) begin
                    // Currently valid, check if ready
                    if (dst_ready_i) begin
                        // Transfer complete, advance pointer
                        rd_ptr <= rd_ptr + 1'b1;
                        // Load next data if available
                        if (!dst_empty) begin
                            dst_reg <= mem_rd_data;
                            dst_valid_reg <= 1'b1;
                        end else begin
                            dst_valid_reg <= 1'b0;
                        end
                    end else begin
                        // Not ready, keep valid
                        dst_valid_reg <= 1'b1;
                    end
                end else begin
                    // Not currently valid, load data
                    dst_reg <= mem_rd_data;
                    dst_valid_reg <= 1'b1;
                end
            end else begin
                // Empty, clear valid
                dst_valid_reg <= 1'b0;
            end
        end
    end

    assign dst_data_o = dst_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
