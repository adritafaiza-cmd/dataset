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

    // Source domain signals
    reg [WIDTH-1:0] buffer [0:1];
    reg [1:0] wr_ptr = 0;
    reg [1:0] rd_ptr_sync = 0;

    // Destination domain signals
    reg [1:0] rd_ptr = 0;
    reg [1:0] wr_ptr_sync = 0;

    // Synchronizers for read pointer from destination to source
    reg [1:0] rd_ptr_sync0, rd_ptr_sync1;

    // Synchronize read pointer from destination to source domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else begin
            if (dst_ready_i && dst_valid_o) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    always @(posedge src_clk_i) begin
        rd_ptr_sync0 <= rd_ptr;
        rd_ptr_sync1 <= rd_ptr_sync0;
    end

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                buffer[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    // Assign source ready (buffer not full)
    assign src_ready_o = ( (wr_ptr - rd_ptr_sync) < 2 );

    // Synchronize write pointer to destination domain
    reg [1:0] wr_ptr_gray, wr_ptr_gray_sync0, wr_ptr_gray_sync1;
    reg [1:0] wr_ptr_bin;

    function [1:0] bin2gray(input [1:0] bin);
        bin2gray = {bin[1], bin[1] ^ bin[0]};
    endfunction

    function [1:0] gray2bin(input [1:0] gray);
        gray2bin = {gray[1], gray[1] ^ gray[0]};
    endfunction

    // Convert write pointer to gray and synchronize
    always @(posedge dst_clk_i) begin
        wr_ptr_gray <= bin2gray(wr_ptr);
        wr_ptr_gray_sync0 <= wr_ptr_gray;
        wr_ptr_gray_sync1 <= wr_ptr_gray_sync0;
        wr_ptr_bin <= gray2bin(wr_ptr_gray_sync1);
    end

    // Destination domain logic
    assign dst_valid_o = ( (wr_ptr_bin - rd_ptr) != 0 );
    assign dst_data_o = buffer[rd_ptr];

endmodule
