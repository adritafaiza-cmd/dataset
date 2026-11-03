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
    wire               stage0_valid;
    wire               stage1_ready;
    wire [WIDTH-1:0]   stage0_data;

    // Instantiate the first stage of the spill buffer
    spill_buffer_stage #(.WIDTH(WIDTH)) stage0 (
        .clk_i      (src_clk_i),
        .rst_ni     (src_rst_ni),
        .valid_i    (src_valid_i),
        .ready_o    (src_ready_o),
        .data_i     (src_data_i),
        .next_clk_i (dst_clk_i),
        .next_rst_ni(dst_rst_ni),
        .next_valid_o(stage0_valid),
        .next_ready_i(stage1_ready),
        .next_data_o (stage0_data)
    );

    // Instantiate the second stage of the spill buffer
    spill_buffer_stage #(.WIDTH(WIDTH)) stage1 (
        .clk_i      (dst_clk_i),
        .rst_ni     (dst_rst_ni),
        .valid_i    (stage0_valid),
        .ready_o    (stage1_ready),
        .data_i     (stage0_data),
        .next_clk_i (dst_clk_i),
        .next_rst_ni(dst_rst_ni),
        .next_valid_o(dst_valid_o),
        .next_ready_i(dst_ready_i),
        .next_data_o (dst_data_o)
    );

endmodule

module spill_buffer_stage #(
    parameter WIDTH = 8
)(
    input              clk_i,
    input              rst_ni,
    input              valid_i,
    output             ready_o,
    input  [WIDTH-1:0] data_i,
    input              next_clk_i,
    input              next_rst_ni,
    output             next_valid_o,
    input              next_ready_i,
    output [WIDTH-1:0] next_data_o
);

    // Internal signals
    reg                storage_valid;
    reg  [WIDTH-1:0]   storage_data;

    // Store data on the rising edge of clk_i if rst_ni is active, valid_i is high, and next_ready_i is high
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            storage_valid <= 0;
        end else if (valid_i && next_ready_i) begin
            storage_valid <= 1;
            storage_data  <= data_i;
        end
    end

    // Output stored data on the rising edge of next_clk_i if next_rst_ni is active and storage_valid is high
    always @(posedge next_clk_i or negedge next_rst_ni) begin
        if (!next_rst_ni) begin
            next_valid_o  <= 0;
        end else if (storage_valid) begin
            next_valid_o  <= 1;
            next_data_o   <= storage_data;
            storage_valid <= 0;
        end
    end

    // ready_o is high if storage_valid is low or next_ready_i is high and storage_valid is high
    assign ready_o = !storage_valid || (next_ready_i && storage_valid);

endmodule
