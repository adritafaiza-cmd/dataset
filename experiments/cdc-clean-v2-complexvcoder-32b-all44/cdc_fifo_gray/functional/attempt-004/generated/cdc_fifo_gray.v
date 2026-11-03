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
    reg  [LOG_DEPTH:0]     src_wr_ptr;
    reg  [LOG_DEPTH:0]     src_rd_ptr;
    reg  [LOG_DEPTH:0]     gray_src_wr_ptr;
    reg  [LOG_DEPTH:0]     gray_src_rd_ptr;
    reg  [LOG_DEPTH:0]     dst_wr_ptr;
    reg  [LOG_DEPTH:0]     dst_rd_ptr;
    reg  [LOG_DEPTH:0]     gray_dst_wr_ptr;
    reg  [LOG_DEPTH:0]     gray_dst_rd_ptr;
    reg  [WIDTH-1:0]       mem [0:(1<<LOG_DEPTH)-1];
    wire                 src_full;
    wire                 src_empty;
    wire                 dst_full;
    wire                 dst_empty;
    wire                 src_wr_en;
    wire                 src_rd_en;
    wire                 dst_wr_en;
    wire                 dst_rd_en;

    // Gray code conversion
    assign gray_src_wr_ptr = {src_wr_ptr[LOG_DEPTH], src_wr_ptr[LOG_DEPTH-1:0] ^ src_wr_ptr[LOG_DEPTH:1]};
    assign gray_src_rd_ptr = {src_rd_ptr[LOG_DEPTH], src_rd_ptr[LOG_DEPTH-1:0] ^ src_rd_ptr[LOG_DEPTH:1]};
    assign gray_dst_wr_ptr = {dst_wr_ptr[LOG_DEPTH], dst_wr_ptr[LOG_DEPTH-1:0] ^ dst_wr_ptr[LOG_DEPTH:1]};
    assign gray_dst_rd_ptr = {dst_rd_ptr[LOG_DEPTH], dst_rd_ptr[LOG_DEPTH-1:0] ^ dst_rd_ptr[LOG_DEPTH:1]};

    // Full and empty flags
    assign src_full = (gray_src_wr_ptr == {gray_src_rd_ptr[LOG_DEPTH-1:0], ~gray_src_rd_ptr[LOG_DEPTH]});
    assign src_empty = (gray_src_wr_ptr == gray_src_rd_ptr);
    assign dst_full = (gray_dst_wr_ptr == {gray_dst_rd_ptr[LOG_DEPTH-1:0], ~gray_dst_rd_ptr[LOG_DEPTH]});
    assign dst_empty = (gray_dst_wr_ptr == gray_dst_rd_ptr);

    // Write and read enables
    assign src_wr_en = src_valid_i && !src_full;
    assign src_rd_en = dst_ready_i && !dst_empty;
    assign dst_wr_en = src_valid_i && !src_full;
    assign dst_rd_en = dst_ready_i && !dst_empty;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_rd_ptr <= 0;
        end else begin
            if (src_wr_en)
                src_wr_ptr <= src_wr_ptr + 1;
            if (src_rd_en)
                src_rd_ptr <= src_rd_ptr + 1;
        end
    end

    // Write data to memory
    always @(posedge src_clk_i) begin
        if (src_wr_en)
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // Ready signal
    assign src_ready_o = !src_full;

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr <= 0;
            dst_rd_ptr <= 0;
        end else begin
            if (dst_wr_en)
                dst_wr_ptr <= dst_wr_ptr + 1;
            if (dst_rd_en)
                dst_rd_ptr <= dst_rd_ptr + 1;
        end
    end

    // Read data from memory
    always @(posedge dst_clk_i) begin
        if (dst_rd_en)
            dst_data_o <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
    end

    // Valid signal
    assign dst_valid_o = !dst_empty;

    // Synchronizers for pointers
    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_wr_ptr (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i(gray_src_wr_ptr),
        .q_o(gray_dst_wr_ptr)
    );

    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_rd_ptr (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(gray_dst_rd_ptr),
        .q_o(gray_src_rd_ptr)
    );

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  en_i,
    output [LOG_DEPTH:0]   count_o
);

    reg  [LOG_DEPTH:0]     count;

    // Gray code counter
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            count <= 0;
        else if (en_i)
            count <= count + 1;
    end

    // Convert binary to gray code
    assign count_o = {count[LOG_DEPTH], count[LOG_DEPTH-1:0] ^ count[LOG_DEPTH:1]};

endmodule

module sync_register #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  clk_i,
    input                  rst_ni,
    input  [LOG_DEPTH:0]   d_i,
    output [LOG_DEPTH:0]   q_o
);

    reg  [LOG_DEPTH:0]     sync_reg [0:SYNC_STAGES-1];

    // Synchronizer stages
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                sync_reg[i] <= 0;
        end else begin
            sync_reg[0] <= d_i;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                sync_reg[i] <= sync_reg[i-1];
        end
    end

    assign q_o = sync_reg[SYNC_STAGES-1];

endmodule
