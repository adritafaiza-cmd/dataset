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

    // Internal signals for async_fifo
    reg [LOG_DEPTH:0] wr_ptr_gray, wr_ptr_bin, wr_ptr_gray_sync;
    reg [LOG_DEPTH:0] rd_ptr_gray, rd_ptr_bin, rd_ptr_gray_sync;
    reg [WIDTH-1:0] fifo_memory [0:(1<<LOG_DEPTH)-1];
    reg wr_en, rd_en, full, empty;

    // Gray counter for source read/write pointers
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_src (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .increment(wr_en),
        .count(wr_ptr_gray)
    );

    // Gray counter for destination read/write pointers
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_dst (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .increment(rd_en),
        .count(rd_ptr_gray)
    );

    // Convert source gray code to binary
    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) gray_to_bin_src (
        .gray(wr_ptr_gray),
        .bin(wr_ptr_bin)
    );

    // Convert destination gray code to binary
    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) gray_to_bin_dst (
        .gray(rd_ptr_gray),
        .bin(rd_ptr_bin)
    );

    // Synchronize write pointer to destination domain
    sync_ff #(.LOG_DEPTH(LOG_DEPTH)) sync_ff_wr (
        .src_clk(src_clk_i),
        .src_rst_ni(src_rst_ni),
        .dst_clk(dst_clk_i),
        .dst_rst_ni(dst_rst_ni),
        .data_in(wr_ptr_gray),
        .data_out(wr_ptr_gray_sync)
    );

    // Synchronize read pointer to source domain
    sync_ff #(.LOG_DEPTH(LOG_DEPTH)) sync_ff_rd (
        .src_clk(dst_clk_i),
        .src_rst_ni(dst_rst_ni),
        .dst_clk(src_clk_i),
        .dst_rst_ni(src_rst_ni),
        .data_in(rd_ptr_gray),
        .data_out(rd_ptr_gray_sync)
    );

    // FIFO memory write and read logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_en <= 0;
        end else begin
            wr_en <= src_valid_i && src_ready_o;
            if (wr_en) begin
                fifo_memory[wr_ptr_bin] <= src_data_i;
            end
        end
    end

    // FIFO memory read logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_en <= 0;
        end else begin
            rd_en <= dst_valid_o && dst_ready_i;
        end
    end

    // FIFO full and empty flags
    assign full = (wr_ptr_gray_sync[LOG_DEPTH] != rd_ptr_gray_sync[LOG_DEPTH]) && (wr_ptr_gray_sync[LOG_DEPTH-1:0] == rd_ptr_gray_sync[LOG_DEPTH-1:0]);
    assign empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);

    // FIFO ready and valid signals
    assign src_ready_o = !full;
    assign dst_valid_o = !empty && (dst_ptr_gray_sync != wr_ptr_gray_sync);

    // Registered destination data output
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            if (dst_valid_o) begin
                dst_data_reg <= fifo_memory[rd_ptr_bin];
                dst_valid_reg <= 1;
            end else if (dst_ready_i) begin
                dst_valid_reg <= 0;
            end
        end
    end

    assign dst_data_o = dst_data_reg;

endmodule

// Gray code counter
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  increment,
    output [LOG_DEPTH:0] count
);

    reg [LOG_DEPTH:0] next_count;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= 0;
        end else begin
            if (increment) begin
                count <= next_count;
            end
        end
    end

    assign next_count = (count << 1) ^ {count[LOG_DEPTH-1:0], increment};

endmodule

// Convert gray code to binary
module gray_to_bin #(
    parameter LOG_DEPTH = 3
)(
    input  [LOG_DEPTH:0] gray,
    output [LOG_DEPTH:0] bin
);

    integer i;
    assign bin[0] = gray[0];
    generate
        for (i = 1; i <= LOG_DEPTH; i = i + 1) begin : gen_gray_to_bin
            assign bin[i] = bin[i-1] ^ gray[i];
        end
    endgenerate

endmodule

// Synchronize signal across clock domains
module sync_ff #(
    parameter LOG_DEPTH = 3
)(
    input                  src_clk,
    input                  src_rst_ni,
    input                  dst_clk,
    input                  dst_rst_ni,
    input  [LOG_DEPTH:0] data_in,
    output [LOG_DEPTH:0] data_out
);

    reg [LOG_DEPTH:0] reg1, reg2;

    always @(posedge src_clk or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            reg1 <= 0;
        end else begin
            reg1 <= data_in;
        end
    end

    always @(posedge dst_clk or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            reg2 <= 0;
        end else begin
            reg2 <= reg1;
        end
    end

    assign data_out = reg2;

endmodule
