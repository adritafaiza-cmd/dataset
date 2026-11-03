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

    wire               src_valid_synced;
    wire               dst_ready_synced;
    wire               buffer_stage1_ready;
    wire               buffer_stage1_valid;
    wire [WIDTH-1:0]   buffer_stage1_data;
    wire               buffer_stage2_valid_in;
    wire               buffer_stage2_ready;
    wire [WIDTH-1:0]   buffer_stage2_data_in;
    wire               buffer_stage2_valid;
    wire [WIDTH-1:0]   buffer_stage2_data;

    synchronizer src_valid_sync (
        .clk_i    (dst_clk_i),
        .rst_ni   (dst_rst_ni),
        .d_i      (src_valid_i),
        .q_o      (src_valid_synced)
    );

    synchronizer dst_ready_sync (
        .clk_i    (src_clk_i),
        .rst_ni   (src_rst_ni),
        .d_i      (dst_ready_i),
        .q_o      (dst_ready_synced)
    );

    buffer buffer_stage1 (
        .clk_i    (src_clk_i),
        .rst_ni   (src_rst_ni),
        .valid_i  (src_valid_i),
        .ready_o  (buffer_stage1_ready),
        .data_i   (src_data_i),
        .valid_o  (buffer_stage1_valid),
        .data_o   (buffer_stage1_data)
    );

    buffer buffer_stage2 (
        .clk_i    (dst_clk_i),
        .rst_ni   (dst_rst_ni),
        .valid_i  (buffer_stage2_valid_in),
        .ready_o  (buffer_stage2_ready),
        .data_i   (buffer_stage2_data_in),
        .valid_o  (buffer_stage2_valid),
        .data_o   (buffer_stage2_data)
    );

    assign src_ready_o           = buffer_stage1_ready;
    assign buffer_stage2_valid_in = buffer_stage1_valid;
    assign buffer_stage2_data_in = buffer_stage1_data;
    assign dst_valid_o           = buffer_stage2_valid;
    assign dst_data_o            = buffer_stage2_data;
    assign buffer_stage2_ready   = dst_ready_synced;

endmodule

module synchronizer (
    input  clk_i,
    input  rst_ni,
    input  d_i,
    output q_o
);

    reg ff1;
    reg ff2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ff1 <= 1'b0;
            ff2 <= 1'b0;
        end else begin
            ff1 <= d_i;
            ff2 <= ff1;
        end
    end

    assign q_o = ff2;

endmodule

module buffer #(
    parameter WIDTH = 8
)(
    input              clk_i,
    input              rst_ni,
    input              valid_i,
    output             ready_o,
    input  [WIDTH-1:0] data_i,
    output             valid_o,
    output [WIDTH-1:0] data_o
);

    reg reg_valid;
    reg [WIDTH-1:0] reg_data;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            reg_valid <= 1'b0;
            reg_data  <= {WIDTH{1'b0}};
        end else begin
            if (ready_o && valid_i) begin
                reg_valid <= 1'b1;
                reg_data  <= data_i;
            end else if (ready_o) begin
                reg_valid <= 1'b0;
            end
        end
    end

    assign ready_o = ~reg_valid;
    assign valid_o = reg_valid;
    assign data_o  = reg_data;

endmodule
