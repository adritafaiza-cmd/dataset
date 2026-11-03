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

    wire [LOG_DEPTH-1:0] src_wr_ptr;
    wire [LOG_DEPTH-1:0] dst_rd_ptr;
    wire [LOG_DEPTH-1:0] sync_wr_ptr_gray;
    wire [LOG_DEPTH-1:0] sync_rd_ptr_gray;
    wire [LOG_DEPTH-1:0] sync_wr_ptr_bin;
    wire [LOG_DEPTH-1:0] sync_rd_ptr_bin;
    wire                 src_wr_en;
    wire                 dst_rd_en;
    reg  [WIDTH-1:0]     fifo_mem [0:(2**LOG_DEPTH)-1];

    // Source-side logic
    assign src_wr_en = src_valid_i & src_ready_o;
    assign src_ready_o = (sync_wr_ptr_bin != (src_wr_ptr + 1));

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_src (
        .clk      (src_clk_i),
        .rst_ni   (src_rst_ni),
        .wr_en    (src_wr_en),
        .gray_ptr (src_wr_ptr)
    );

    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) sync_wr_ptr (
        .src_clk    (src_clk_i),
        .src_rst_ni (src_rst_ni),
        .dst_clk    (dst_clk_i),
        .dst_rst_ni (dst_rst_ni),
        .src_gray_ptr (src_wr_ptr),
        .dst_gray_ptr (sync_wr_ptr_gray)
    );

    // Convert synchronized gray code to binary
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_wr_ptr_bin <= {LOG_DEPTH{1'b0}};
        end else begin
            sync_wr_ptr_bin <= (sync_wr_ptr_gray ^ (sync_wr_ptr_gray >> 1));
        end
    end

    // Destination-side logic
    assign dst_rd_en = dst_valid_o & dst_ready_i;
    assign dst_valid_o = (sync_wr_ptr_bin != sync_rd_ptr_bin);

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_dst (
        .clk      (dst_clk_i),
        .rst_ni   (dst_rst_ni),
        .wr_en    (dst_rd_en),
        .gray_ptr (dst_rd_ptr)
    );

    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) sync_rd_ptr (
        .src_clk    (dst_clk_i),
        .src_rst_ni (dst_rst_ni),
        .dst_clk    (src_clk_i),
        .dst_rst_ni (src_rst_ni),
        .src_gray_ptr (dst_rd_ptr),
        .dst_gray_ptr (sync_rd_ptr_gray)
    );

    // Convert synchronized gray code to binary
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_rd_ptr_bin <= {LOG_DEPTH{1'b0}};
        end else begin
            sync_rd_ptr_bin <= (sync_rd_ptr_gray ^ (sync_rd_ptr_gray >> 1));
        end
    end

    // FIFO memory write and read
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            // Clear FIFO memory on reset
            for (integer i = 0; i < (2**LOG_DEPTH); i = i + 1) begin
                fifo_mem[i] <= {WIDTH{1'b0}};
            end
        end else if (src_wr_en) begin
            // Write data to FIFO memory
            fifo_mem[src_wr_ptr] <= src_data_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= {WIDTH{1'b0}};
        end else if (dst_valid_o & dst_ready_i) begin
            // Read data from FIFO memory
            dst_data_o <= fifo_mem[sync_rd_ptr_bin];
        end
    end

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  wr_en,
    output [LOG_DEPTH-1:0] gray_ptr
);

    reg [LOG_DEPTH-1:0] bin_ptr;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_ptr <= {LOG_DEPTH{1'b0}};
        end else if (wr_en) begin
            bin_ptr <= bin_ptr + 1;
        end
    end

    assign gray_ptr = (bin_ptr ^ (bin_ptr >> 1));

endmodule

module sync_gray #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_clk,
    input                  src_rst_ni,
    input                  dst_clk,
    input                  dst_rst_ni,
    input  [LOG_DEPTH-1:0] src_gray_ptr,
    output [LOG_DEPTH-1:0] dst_gray_ptr
);

    reg [LOG_DEPTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge src_clk or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_reg[0] <= {LOG_DEPTH{1'b0}};
        end else begin
            sync_reg[0] <= src_gray_ptr;
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge src_clk or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    sync_reg[i] <= {LOG_DEPTH{1'b0}};
                end else begin
                    sync_reg[i] <= sync_reg[i-1];
                end
            end
        end
    endgenerate

    always @(posedge dst_clk or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_ptr <= {LOG_DEPTH{1'b0}};
        end else begin
            dst_gray_ptr <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule
