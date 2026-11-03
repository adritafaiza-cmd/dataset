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

    wire [LOG_DEPTH-1:0] gray_counter_src_gray_o;
    wire [LOG_DEPTH-1:0] gray_counter_dst_gray_o;
    wire [LOG_DEPTH-1:0] gray_counter_src_bin_o;
    wire [LOG_DEPTH-1:0] gray_counter_dst_bin_o;
    wire [LOG_DEPTH-1:0] sync_register_src_data_o;
    wire [LOG_DEPTH-1:0] sync_register_dst_data_o;
    wire [WIDTH-1:0] fifo_memory_inst_data_o;
    wire wr_en;
    wire rd_en;
    wire src_clear_pending;
    wire dst_clear_pending;
    wire src_ready;
    wire dst_valid;

    // Source Gray Counter
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .en_i(wr_en),
        .gray_i(sync_register_dst_data_o),
        .gray_o(gray_counter_src_gray_o),
        .bin_o(gray_counter_src_bin_o)
    );

    // Destination Gray Counter
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .en_i(rd_en),
        .gray_i(sync_register_src_data_o),
        .gray_o(gray_counter_dst_gray_o),
        .bin_o(gray_counter_dst_bin_o)
    );

    // Source to Destination Synchronizer
    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_register_src (
        .clk_i(dst_clk_i),
        .data_i(gray_counter_src_gray_o),
        .data_o(sync_register_src_data_o)
    );

    // Destination to Source Synchronizer
    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_register_dst (
        .clk_i(src_clk_i),
        .data_i(gray_counter_dst_gray_o),
        .data_o(sync_register_dst_data_o)
    );

    // FIFO Memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_memory_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .wr_en(wr_en),
        .wr_addr(gray_counter_src_bin_o),
        .data_i(src_data_i),
        .rd_en(rd_en),
        .rd_addr(gray_counter_dst_bin_o),
        .data_o(fifo_memory_inst_data_o)
    );

    // Source Clear Pending
    reg [SYNC_STAGES-1:0] src_clear_pipeline;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pipeline <= {SYNC_STAGES{1'b0}};
        end else begin
            src_clear_pipeline <= {src_clear_i, src_clear_pipeline[SYNC_STAGES-1:1]};
        end
    end
    assign src_clear_pending_o = src_clear_pipeline[0];

    // Destination Clear Pending
    reg [SYNC_STAGES-1:0] dst_clear_pipeline;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pipeline <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_clear_pipeline <= {dst_clear_i, dst_clear_pipeline[SYNC_STAGES-1:1]};
        end
    end
    assign dst_clear_pending_o = dst_clear_pipeline[0];

    // Write Enable
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_en <= 1'b0;
        end else begin
            wr_en <= src_valid_i & src_ready;
        end
    end

    // Read Enable
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_en <= 1'b0;
        end else begin
            rd_en <= dst_valid & dst_ready_i;
        end
    end

    // Source Ready
    assign src_ready = (gray_counter_src_bin_o != sync_register_dst_data_o);

    // Destination Valid
    assign dst_valid = (gray_counter_dst_bin_o != sync_register_src_data_o);

    // Destination Data
    assign dst_data_o = fifo_memory_inst_data_o;

    // Destination Valid Output
    reg [SYNC_STAGES-1:0] dst_valid_pipeline;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_pipeline <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_valid_pipeline <= {dst_valid, dst_valid_pipeline[SYNC_STAGES-1:1]};
        end
    end
    assign dst_valid_o = dst_valid_pipeline[0];

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    input                  en_i,
    input  [LOG_DEPTH-1:0] gray_i,
    output [LOG_DEPTH-1:0] gray_o,
    output [LOG_DEPTH-1:0] bin_o
);

    reg [LOG_DEPTH-1:0] bin_reg;
    reg [LOG_DEPTH-1:0] gray_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_reg <= {LOG_DEPTH{1'b0}};
            gray_reg <= {LOG_DEPTH{1'b0}};
        end else if (clear_i) begin
            bin_reg <= {LOG_DEPTH{1'b0}};
            gray_reg <= {LOG_DEPTH{1'b0}};
        end else if (en_i) begin
            bin_reg <= bin_reg + 1;
            gray_reg <= bin_reg ^ (bin_reg >> 1);
        end
    end

    assign gray_o = gray_reg;
    assign bin_o = bin_reg;

endmodule

module sync_register #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input  [LOG_DEPTH-1:0] data_i,
    output [LOG_DEPTH-1:0] data_o
);

    reg [LOG_DEPTH-1:0] sync_reg;

    always @(posedge clk_i) begin
        sync_reg <= data_i;
    end

    assign data_o = sync_reg;

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  wr_en,
    input  [LOG_DEPTH-1:0] wr_addr,
    input  [WIDTH-1:0]     data_i,
    input                  rd_en,
    input  [LOG_DEPTH-1:0] rd_addr,
    output [WIDTH-1:0]     data_o
);

    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < (2**LOG_DEPTH); i = i + 1) begin
                mem[i] <= {WIDTH{1'b0}};
            end
        end else begin
            if (wr_en) begin
                mem[wr_addr] <= data_i;
            end
        end
    end

    assign data_o = mem[rd_addr];

endmodule
