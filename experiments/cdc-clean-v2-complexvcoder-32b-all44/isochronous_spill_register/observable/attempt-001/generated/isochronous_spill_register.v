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

    reg [1:0] src_ff_valid;
    reg [WIDTH-1:0] src_ff_data;
    reg src_ff_ready;

    reg [1:0] dst_ff_valid;
    reg [WIDTH-1:0] dst_ff_data;
    reg dst_ff_ready;

    reg src_ready;
    reg dst_valid;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ff_valid <= 2'b00;
            src_ff_ready <= 1'b0;
        end else begin
            if (src_valid_i && src_ready) begin
                src_ff_valid[1] <= src_ff_valid[0];
                src_ff_valid[0] <= 1'b1;
                src_ff_data <= src_data_i;
            end
            if (src_ff_valid[1] && dst_ff_ready) begin
                src_ff_valid[1] <= 1'b0;
            end
        end
    end

    always @(*) begin
        src_ready = ~src_ff_valid[1];
    end

    // Cross src_ff_valid[1] and src_ff_data to destination clock domain
    reg src_ff_valid_1_sync;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ff_valid_1_sync <= 1'b0;
        end else begin
            src_ff_valid_1_sync <= src_ff_valid[1];
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ff_valid <= 2'b0;
            dst_ff_ready <= 1'b0;
        end else begin
            if (dst_ready_i && dst_valid) begin
                dst_ff_valid[1] <= dst_ff_valid[0];
                dst_ff_valid[0] <= 1'b0;
            end
            if (src_ff_valid_1_sync && !dst_ff_valid[1]) begin
                dst_ff_valid[1] <= 1'b1;
                dst_ff_data <= src_ff_data;
            end
        end
    end

    always @(*) begin
        dst_valid = dst_ff_valid[0];
    end

    // Cross dst_ff_ready to source clock domain
    reg dst_ff_ready_sync;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ff_ready_sync <= 1'b0;
        end else begin
            dst_ff_ready_sync <= dst_ff_ready;
        end
    end

    always @(*) begin
        dst_ff_ready = ~dst_ff_valid[0] || dst_ready_i;
    end

    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;
    assign dst_data_o = dst_ff_data;

endmodule
