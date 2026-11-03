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
    wire               cc_buffer_valid_o;
    wire [WIDTH-1:0]   cc_buffer_data_o;

    // Cross clock buffer instance
    cross_clock_buffer #(
        .WIDTH(WIDTH)
    ) cc_buffer_inst (
        .clk_i        (src_clk_i),
        .rst_ni       (src_rst_ni),
        .valid_i      (src_valid_i),
        .data_i       (src_data_i),
        .valid_o      (cc_buffer_valid_o),
        .data_o       (cc_buffer_data_o)
    );

    // Spill register instance
    spill_register #(
        .WIDTH(WIDTH)
    ) spill_reg_inst (
        .clk_i        (dst_clk_i),
        .rst_ni       (dst_rst_ni),
        .valid_i      (cc_buffer_valid_o),
        .data_i       (cc_buffer_data_o),
        .valid_o      (dst_valid_o),
        .data_o       (dst_data_o),
        .ready_o      (src_ready_o),
        .ready_i      (dst_ready_i)
    );

endmodule

// Cross clock buffer module
module cross_clock_buffer #(
    parameter WIDTH = 8
)(
    input              clk_i,
    input              rst_ni,
    input              valid_i,
    input  [WIDTH-1:0] data_i,
    output             valid_o,
    output [WIDTH-1:0] data_o
);

    reg                valid_meta;
    reg                valid_sync;
    reg [WIDTH-1:0]    data_meta;
    reg [WIDTH-1:0]    data_sync;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            valid_meta <= 1'b0;
            valid_sync <= 1'b0;
            data_meta  <= {WIDTH{1'b0}};
            data_sync  <= {WIDTH{1'b0}};
        end else begin
            valid_meta <= valid_i;
            valid_sync <= valid_meta;
            data_meta  <= data_i;
            data_sync  <= data_meta;
        end
    end

    assign valid_o = valid_sync;
    assign data_o  = data_sync;

endmodule

// Spill register module
module spill_register #(
    parameter WIDTH = 8
)(
    input              clk_i,
    input              rst_ni,
    input              valid_i,
    input  [WIDTH-1:0] data_i,
    output             valid_o,
    output [WIDTH-1:0] data_o,
    output             ready_o,
    input              ready_i
);

    reg                valid_reg1;
    reg                valid_reg2;
    reg [WIDTH-1:0]    data_reg1;
    reg [WIDTH-1:0]    data_reg2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            valid_reg1 <= 1'b0;
            valid_reg2 <= 1'b0;
            data_reg1  <= {WIDTH{1'b0}};
            data_reg2  <= {WIDTH{1'b0}};
        end else begin
            if (ready_i) begin
                if (valid_reg2) begin
                    valid_reg2 <= 1'b0;
                end else if (valid_reg1) begin
                    valid_reg2 <= 1'b1;
                    valid_reg1 <= 1'b0;
                    data_reg2  <= data_reg1;
                end else if (valid_i) begin
                    valid_reg1 <= 1'b1;
                    data_reg1  <= data_i;
                end
            end else begin
                if (valid_i && !valid_reg1 && !valid_reg2) begin
                    valid_reg1 <= 1'b1;
                    data_reg1  <= data_i;
                end
            end
        end
    end

    assign valid_o = valid_reg2 | valid_reg1;
    assign data_o  = valid_reg2 ? data_reg2 : data_reg1;
    assign ready_o = !(valid_reg1 && valid_i);

endmodule
