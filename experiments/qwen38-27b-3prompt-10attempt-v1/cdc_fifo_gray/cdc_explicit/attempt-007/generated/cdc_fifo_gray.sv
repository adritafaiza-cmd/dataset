module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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
    localparam PTR_W = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] dst_rd_ptr_src;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] src_wr_ptr_dst;
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;

    // Synchronizer registers
    reg [PTR_W-1:0] wr_ptr_sync [0:SYNC_STAGES-1];
    reg [PTR_W-1:0] rd_ptr_sync [0:SYNC_STAGES-1];

    // Source domain: write pointer and memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else begin
            if (src_valid_i && src_ready_o) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
            end
        end
    end

    // Source domain: read pointer synchronized from destination
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_sync[0] <= {PTR_W{1'b0}};
        end else begin
            rd_ptr_sync[0] <= dst_rd_ptr;
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : rd_ptr_sync_gen
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    rd_ptr_sync[i] <= {PTR_W{1'b0}};
                end else begin
                    rd_ptr_sync[i] <= rd_ptr_sync[i-1];
                end
            end
        end
    endgenerate

    assign dst_rd_ptr_src = rd_ptr_sync[SYNC_STAGES-1];

    // Source domain: ready signal
    assign src_ready_o = (src_wr_ptr != dst_rd_ptr_src);

    // Destination domain: read pointer and data
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
            end else if (!dst_valid_reg && (src_wr_ptr_dst != dst_rd_ptr)) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
            end
        end
    end

    // Destination domain: write pointer synchronized from source
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_sync[0] <= {PTR_W{1'b0}};
        end else begin
            wr_ptr_sync[0] <= src_wr_ptr;
        end
    end

    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : wr_ptr_sync_gen
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    wr_ptr_sync[i] <= {PTR_W{1'b0}};
                end else begin
                    wr_ptr_sync[i] <= wr_ptr_sync[i-1];
                end
            end
        end
    endgenerate

    assign src_wr_ptr_dst = wr_ptr_sync[SYNC_STAGES-1];

    // Destination outputs
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
