module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    // Internal signals
    wire               fifo_push_i;
    wire               fifo_push_ready_o;
    wire               fifo_pop_i;
    wire               fifo_pop_valid_o;
    wire [WIDTH-1:0]   fifo_data_i;
    wire [WIDTH-1:0]   fifo_data_o;

    // CDC handshake signals
    wire               src_valid_meta;
    wire               src_ready_meta;
    wire               dst_valid_meta;
    wire               dst_ready_meta;

    // CDC handshake for src_valid_i to dst_valid_o
    cdc_handshake u_cdc_handshake_src_to_dst (
        .clk_i      (dst_clk_i),
        .rst_ni     (dst_rst_ni),
        .valid_i    (src_valid_meta),
        .ready_i    (dst_ready_i),
        .ready_o    (src_ready_meta),
        .valid_o    (dst_valid_o)
    );

    // CDC handshake for dst_ready_i to src_ready_o
    cdc_handshake u_cdc_handshake_dst_to_src (
        .clk_i      (src_clk_i),
        .rst_ni     (src_rst_ni),
        .valid_i    (dst_ready_i),
        .ready_i    (src_valid_i),
        .ready_o    (dst_ready_meta),
        .valid_o    (src_ready_o)
    );

    // CDC synchronizer for src_valid_i to src_valid_meta
    synchronizer u_synchronizer_src_valid (
        .clk_i      (dst_clk_i),
        .rst_ni     (dst_rst_ni),
        .din        (src_valid_i),
        .dout       (src_valid_meta)
    );

    // CDC synchronizer for src_ready_meta to src_ready_o
    synchronizer u_synchronizer_src_ready (
        .clk_i      (src_clk_i),
        .rst_ni     (src_rst_ni),
        .din        (src_ready_meta),
        .dout       (src_ready_o)
    );

    // CDC synchronizer for dst_ready_i to dst_ready_meta
    synchronizer u_synchronizer_dst_ready (
        .clk_i      (src_clk_i),
        .rst_ni     (src_rst_ni),
        .din        (dst_ready_i),
        .dout       (dst_ready_meta)
    );

    // CDC synchronizer for dst_valid_meta to dst_valid_o
    synchronizer u_synchronizer_dst_valid (
        .clk_i      (dst_clk_i),
        .rst_ni     (dst_rst_ni),
        .din        (dst_valid_meta),
        .dout       (dst_valid_o)
    );

    // 2-deep FIFO
    fifo u_fifo_inst (
        .clk_i        (src_clk_i),
        .rst_ni       (src_rst_ni),
        .push_i       (fifo_push_i),
        .push_ready_o (fifo_push_ready_o),
        .data_i       (fifo_data_i),
        .clk_o        (dst_clk_i),
        .rst_o        (dst_rst_ni),
        .pop_i        (fifo_pop_i),
        .pop_valid_o  (fifo_pop_valid_o),
        .data_o       (fifo_data_o)
    );

    // Assign FIFO control signals
    assign fifo_push_i = src_valid_i & src_ready_o;
    assign fifo_pop_i  = dst_valid_o & dst_ready_i;
    assign fifo_data_i = src_data_i;

    // Assign FIFO output to destination data
    assign dst_data_o = fifo_data_o;

endmodule

// CDC handshake module
module cdc_handshake (
    input  clk_i,
    input  rst_ni,
    input  valid_i,
    input  ready_i,
    output ready_o,
    output valid_o
);

    reg    valid_meta;
    reg    ready_meta;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            valid_meta <= 1'b0;
            ready_meta <= 1'b0;
        end else begin
            valid_meta <= valid_i;
            ready_meta <= ready_i;
        end
    end

    assign ready_o = ready_meta;
    assign valid_o = valid_meta;

endmodule

// Synchronizer module
module synchronizer (
    input  clk_i,
    input  rst_ni,
    input  din,
    output dout
);

    reg [1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 2'b0;
        end else begin
            sync_reg[0] <= din;
            sync_reg[1] <= sync_reg[0];
        end
    end

    assign dout = sync_reg[1];

endmodule

// 2-deep FIFO module
module fifo #(
    parameter WIDTH = 8
)(
    input              clk_i,
    input              rst_ni,
    input              push_i,
    output             push_ready_o,
    input  [WIDTH-1:0] data_i,
    input              clk_o,
    input              rst_o,
    input              pop_i,
    output             pop_valid_o,
    output [WIDTH-1:0] data_o
);

    reg  [WIDTH-1:0] mem [1:0];
    reg  [1:0]       wr_ptr;
    reg  [1:0]       rd_ptr;
    reg              full;
    reg              empty;

    // Write pointer logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 2'b0;
        end else if (push_i && !full) begin
            mem[wr_ptr] <= data_i;
            wr_ptr      <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge clk_o or negedge rst_o) begin
        if (!rst_o) begin
            rd_ptr <= 2'b0;
        end else if (pop_i && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Full and empty flags
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            full  <= 1'b0;
            empty <= 1'b1;
        end else begin
            full  <= (wr_ptr == rd_ptr + 1) || (wr_ptr == 2'b11 && rd_ptr == 2'b00);
            empty <= (wr_ptr == rd_ptr);
        end
    end

    // Output valid and data
    assign pop_valid_o = !empty;
    assign data_o      = mem[rd_ptr];
    assign push_ready_o = !full;

endmodule
