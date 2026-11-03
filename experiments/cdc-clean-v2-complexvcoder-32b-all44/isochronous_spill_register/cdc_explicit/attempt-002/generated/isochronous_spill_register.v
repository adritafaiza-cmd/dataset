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
    reg                src2dst_valid_sync;
    reg [WIDTH-1:0]    src2dst_data_sync;
    reg                dst2src_ready_sync;
    reg                src_ready_int;
    reg                dst_valid_int;
    reg                buffer_full;
    reg                buffer_empty;
    reg                buffer_ptr;
    reg [WIDTH-1:0]    buffer_data [0:1];

    // Synchronization flip-flops
    ff_sync ff_sync_inst_src2dst_valid (
        .async_in(src_valid_i),
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .sync_out(src2dst_valid_sync)
    );

    ff_sync ff_sync_inst_src2dst_data (
        .async_in(src_data_i),
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .sync_out(src2dst_data_sync)
    );

    ff_sync ff_sync_inst_dst2src_ready (
        .async_in(dst_ready_i),
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .sync_out(dst2src_ready_sync)
    );

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_int <= 1'b0;
            buffer_full <= 1'b0;
            buffer_empty <= 1'b1;
        end else begin
            // Determine buffer full and empty conditions
            buffer_full <= (buffer_ptr && !buffer_empty) || (src2dst_valid_sync && buffer_ptr);
            buffer_empty <= !buffer_ptr && !src2dst_valid_sync;

            // Source ready logic
            src_ready_int <= !buffer_full && dst2src_ready_sync;

            // Write data to buffer
            if (src_valid_i && src_ready_int) begin
                buffer_data[buffer_ptr] <= src_data_i;
                buffer_ptr <= ~buffer_ptr;
            end
        end
    end

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_int <= 1'b0;
            buffer_ptr <= 1'b0;
        end else begin
            // Destination valid logic
            dst_valid_int <= !buffer_empty;

            // Read data from buffer
            if (dst_valid_int && dst_ready_i) begin
                buffer_ptr <= ~buffer_ptr;
            end
        end
    end

    // Output assignments
    assign src_ready_o = src_ready_int;
    assign dst_valid_o = dst_valid_int;
    assign dst_data_o = buffer_data[~buffer_ptr];

endmodule

module ff_sync (
    input  async_in,
    input  clk,
    input  rst_ni,
    output sync_out
);

    reg ff0;
    reg ff1;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            ff0 <= 1'b0;
            ff1 <= 1'b0;
        end else begin
            ff0 <= async_in;
            ff1 <= ff0;
        end
    end

    assign sync_out = ff1;

endmodule
