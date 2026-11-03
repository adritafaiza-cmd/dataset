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
    reg [WIDTH-1:0] sram_data [1:0];
    reg [1:0]       write_ptr;
    reg [1:0]       read_ptr;
    reg             full;
    reg             empty;
    reg             src_ready;
    reg             dst_valid;
    reg [WIDTH-1:0] dst_data;

    // Single-port SRAM for data storage
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= 2'b00;
            full      <= 1'b0;
        end else if (src_valid_i && src_ready) begin
            sram_data[write_ptr] <= src_data_i;
            write_ptr            <= write_ptr + 1'b1;
            full                 <= (write_ptr == read_ptr) ? 1'b1 : 1'b0;
        end
    end

    // Source ready signal
    always @(*) begin
        src_ready = ~full;
    end

    // Destination valid and data signal
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr  <= 2'b00;
            empty     <= 1'b1;
            dst_valid <= 1'b0;
            dst_data  <= {WIDTH{1'b0}};
        end else if (dst_valid && dst_ready_i) begin
            read_ptr  <= read_ptr + 1'b1;
            empty     <= (read_ptr == write_ptr) ? 1'b1 : 1'b0;
            dst_valid <= ~empty;
            dst_data  <= sram_data[read_ptr];
        end else if (!dst_valid) begin
            dst_valid <= ~empty;
            dst_data  <= sram_data[read_ptr];
        end
    end

    // Output assignments
    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;
    assign dst_data_o  = dst_data;

endmodule
