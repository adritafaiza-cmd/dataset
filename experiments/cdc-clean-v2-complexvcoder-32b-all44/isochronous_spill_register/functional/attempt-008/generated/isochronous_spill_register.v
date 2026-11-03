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
    reg                src_ready;
    reg                dst_valid;
    reg                buffer_full;
    reg                buffer_empty;
    reg [1:0]          buffer_ptr;
    reg [WIDTH-1:0]    buffer_data [1:0];

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready <= 1'b1;
            buffer_full <= 1'b0;
            buffer_empty <= 1'b1;
        end else begin
            if (src_valid_i && src_ready) begin
                buffer_data[buffer_ptr] <= src_data_i;
                buffer_empty <= 1'b0;
                if (buffer_ptr == 1'b1)
                    buffer_full <= 1'b1;
                buffer_ptr <= buffer_ptr + 1'b1;
            end
            src_ready <= ~buffer_full;
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid <= 1'b0;
            buffer_full <= 1'b0;
            buffer_empty <= 1'b1;
        end else begin
            if (dst_ready_i && dst_valid) begin
                buffer_full <= 1'b0;
                if (buffer_ptr == 1'b0)
                    buffer_empty <= 1'b1;
                buffer_ptr <= buffer_ptr - 1'b1;
            end
            dst_valid <= ~buffer_empty;
            if (dst_ready_i && dst_valid)
                dst_data_o <= buffer_data[buffer_ptr];
        end
    end

    // Output assignments
    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;

endmodule
