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

    reg [WIDTH-1:0] buffer [0:1];
    reg [1:0] src_buffer_ptr, dst_buffer_ptr;
    reg src_buffer_full, src_buffer_empty;
    reg dst_buffer_full, dst_buffer_empty;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_buffer_ptr <= 0;
            src_buffer_full <= 0;
            src_buffer_empty <= 1;
        end else begin
            if (src_valid_i && !src_buffer_full && !src_buffer_empty) begin
                // Write and read
                buffer[src_buffer_ptr] <= src_data_i;
                src_buffer_ptr <= src_buffer_ptr + 1;
            end else if (src_valid_i && !src_buffer_full) begin
                // Write only
                buffer[src_buffer_ptr] <= src_data_i;
                src_buffer_ptr <= src_buffer_ptr + 1;
                if (src_buffer_ptr == 1)
                    src_buffer_full <= 1;
                src_buffer_empty <= 0;
            end else if (dst_ready_i && !src_buffer_empty) begin
                // Read only
                src_buffer_ptr <= src_buffer_ptr - 1;
                if (src_buffer_ptr == 0)
                    src_buffer_empty <= 1;
                src_buffer_full <= 0;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_buffer_ptr <= 0;
            dst_buffer_full <= 0;
            dst_buffer_empty <= 1;
        end else begin
            if (dst_ready_i && !dst_buffer_empty && !dst_buffer_full) begin
                // Read and write
                dst_buffer_ptr <= dst_buffer_ptr + 1;
            end else if (dst_ready_i && !dst_buffer_empty) begin
                // Read only
                dst_buffer_ptr <= dst_buffer_ptr + 1;
                if (dst_buffer_ptr == 1)
                    dst_buffer_empty <= 1;
                dst_buffer_full <= 0;
            end else if (src_valid_i && !dst_buffer_full) begin
                // Write only
                buffer[dst_buffer_ptr] <= buffer[src_buffer_ptr];
                dst_buffer_ptr <= dst_buffer_ptr - 1;
                if (dst_buffer_ptr == 0)
                    dst_buffer_full <= 1;
                dst_buffer_empty <= 0;
            end
        end
    end

    // Source ready and destination valid
    assign src_ready_o = !src_buffer_full;
    assign dst_valid_o = !dst_buffer_empty;
    assign dst_data_o = buffer[dst_buffer_ptr];

endmodule
