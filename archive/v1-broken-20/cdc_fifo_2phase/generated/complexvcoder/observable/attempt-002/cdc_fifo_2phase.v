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

    // Define internal signals
    reg [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
    reg [$clog2(2**LOG_DEPTH)-1:0] wr_ptr;
    reg [$clog2(2**LOG_DEPTH)-1:0] rd_ptr;
    reg [$clog2(2**LOG_DEPTH):0] count;
    reg src_ready;
    reg dst_valid;
    reg [WIDTH-1:0] dst_data;

    // Synchronous FIFO for source domain
    fifo_sync #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) src_fifo (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready),
        .clk_o(dst_clk_i),
        .rst_o_ni(dst_rst_ni),
        .data_o(dst_data),
        .valid_o(dst_valid),
        .ready_i(dst_ready_i)
    );

    // Asynchronous FIFO core for destination domain
    fifo_core #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) dst_fifo (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_data),
        .valid_i(dst_valid),
        .ready_o(src_ready),
        .clk_o(src_clk_i),
        .rst_o_ni(src_rst_ni),
        .data_o(src_data_i),
        .valid_o(src_valid_i),
        .ready_i(src_ready_o)
    );

    // Assign outputs
    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;
    assign dst_data_o = dst_data;

endmodule

module fifo_sync #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o,
    input                  clk_o,
    input                  rst_o_ni,
    output [WIDTH-1:0]     data_o,
    output                 valid_o,
    input                  ready_i
);

    // Define internal signals
    reg [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
    reg [$clog2(2**LOG_DEPTH)-1:0] wr_ptr;
    reg [$clog2(2**LOG_DEPTH)-1:0] rd_ptr;
    reg [$clog2(2**LOG_DEPTH):0] count;
    reg ready;
    reg valid;

    // Write process
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            count <= 0;
        end else begin
            if (valid_i && ready_i && count < 2**LOG_DEPTH) begin
                mem[wr_ptr] <= data_i;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
        end
    end

    // Read process
    always @(posedge clk_o or negedge rst_o_ni) begin
        if (!rst_o_ni) begin
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (valid && ready) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end

    // FIFO status
    assign ready_o = (count < 2**LOG_DEPTH);
    assign valid_o = (count > 0);
    assign data_o = mem[rd_ptr];

endmodule

module fifo_core #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o,
    input                  clk_o,
    input                  rst_o_ni,
    output [WIDTH-1:0]     data_o,
    output                 valid_o,
    input                  ready_i
);

    // Define internal signals
    reg [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
    reg [$clog2(2**LOG_DEPTH)-1:0] wr_ptr;
    reg [$clog2(2**LOG_DEPTH)-1:0] rd_ptr;
    reg [$clog2(2**LOG_DEPTH):0] count;
    reg ready;
    reg valid;

    // Write process
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            count <= 0;
        end else begin
            if (valid_i && ready_i && count < 2**LOG_DEPTH) begin
                mem[wr_ptr] <= data_i;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
        end
    end

    // Read process
    always @(posedge clk_o or negedge rst_o_ni) begin
        if (!rst_o_ni) begin
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (valid && ready) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end

    // FIFO status
    assign ready_o = (count < 2**LOG_DEPTH);
    assign valid_o = (count > 0);
    assign data_o = mem[rd_ptr];

endmodule
