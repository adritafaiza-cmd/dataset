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

    // Internal signals
    wire [LOG_DEPTH:0] wr_ptr_gray, rd_ptr_gray;
    wire [LOG_DEPTH:0] wr_ptr_sync, rd_ptr_sync;
    reg  [WIDTH-1:0] fifo_mem [0:(2**LOG_DEPTH)-1];
    reg                wr_en, rd_en;

    // Source side Gray counter
    gray_counter #(
        .WIDTH(LOG_DEPTH+1)
    ) gray_counter_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .en_i(wr_en),
        .load_i(1'b0),
        .load_data_i({LOG_DEPTH+1{1'b0}}),
        .gray_count(wr_ptr_gray),
        .bin_count()
    );

    // Destination side Gray counter
    gray_counter #(
        .WIDTH(LOG_DEPTH+1)
    ) gray_counter_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .en_i(rd_en),
        .load_i(1'b0),
        .load_data_i({LOG_DEPTH+1{1'b0}}),
        .gray_count(rd_ptr_gray),
        .bin_count()
    );

    // Synchronizer for write pointer
    sync_reg #(
        .WIDTH(LOG_DEPTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_reg_wr_ptr (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .async_data(wr_ptr_gray),
        .sync_data(wr_ptr_sync)
    );

    // Synchronizer for read pointer
    sync_reg #(
        .WIDTH(LOG_DEPTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_reg_rd_ptr (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .async_data(rd_ptr_gray),
        .sync_data(rd_ptr_sync)
    );

    // Write enable logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_en <= 1'b0;
        end else begin
            wr_en <= src_valid_i && !full;
        end
    end

    // Read enable logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_en <= 1'b0;
        end else begin
            rd_en <= dst_ready_i && dst_valid_o;
        end
    end

    // FIFO memory write logic
    always @(posedge src_clk_i) begin
        if (wr_en) begin
            fifo_mem[wr_ptr_gray[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // FIFO memory read logic
    always @(posedge dst_clk_i) begin
        if (rd_en) begin
            dst_data_o <= fifo_mem[rd_ptr_gray[LOG_DEPTH-1:0]];
        end
    end

    // FIFO status signals
    wire full, empty;
    assign full  = (wr_ptr_gray[LOG_DEPTH:0] == {rd_ptr_sync[LOG_DEPTH], ~rd_ptr_sync[LOG_DEPTH-1:0]});
    assign empty = (wr_ptr_sync[LOG_DEPTH:0] == {rd_ptr_gray[LOG_DEPTH], ~rd_ptr_gray[LOG_DEPTH-1:0]});

    // Ready and valid signals
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

endmodule

// Gray code counter module
module gray_counter #(
    parameter WIDTH = 4
)(
    input                  clk_i,
    input                  rst_ni,
    input                  en_i,
    input                  load_i,
    input  [WIDTH-1:0]     load_data_i,
    output [WIDTH-1:0]     gray_count,
    output [WIDTH-1:0]     bin_count
);

    reg  [WIDTH-1:0] gray_reg;
    reg  [WIDTH-1:0] bin_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_reg <= {WIDTH{1'b0}};
            bin_reg  <= {WIDTH{1'b0}};
        end else if (load_i) begin
            gray_reg <= load_data_i ^ (load_data_i >> 1);
            bin_reg  <= load_data_i;
        end else if (en_i) begin
            bin_reg  <= bin_reg + 1;
            gray_reg <= bin_reg ^ (bin_reg + 1);
        end
    end

    assign gray_count = gray_reg;
    assign bin_count  = bin_reg;

endmodule

// Synchronizer register module
module sync_reg #(
    parameter WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     async_data,
    output [WIDTH-1:0]     sync_data
);

    reg  [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= {WIDTH{1'b0}};
            end
        end else begin
            sync_reg[0] <= async_data;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign sync_data = sync_reg[SYNC_STAGES-1];

endmodule
