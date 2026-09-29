module isochronous_spill_register #(
    parameter WIDTH = 8
) (
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
    reg [1:0] wptr_bin, rptr_bin_sync;
    reg [1:0] wptr_gray, rptr_gray_sync;
    reg [WIDTH-1:0] entry0, entry1;
    reg valid0, valid1;
    reg full;

    // Destination domain signals
    reg [1:0] rptr_bin, wptr_bin_sync;
    reg [1:0] rptr_gray, wptr_gray_sync;
    reg [WIDTH-1:0] entry0_dst, entry1_dst;
    reg valid0_dst, valid1_dst;
    reg empty;

    // Gray code conversion functions
    function [1:0] bin2gray(input [1:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    function [1:0] gray2bin(input [1:0] gray);
        gray2bin[1] = gray[1];
        gray2bin[0] = gray2bin[1] ^ gray[0];
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_bin <= 2'b00;
            rptr_gray_sync <= 2'b00;
            valid0 <= 1'b0;
            valid1 <= 1'b0;
            entry0 <= 0;
            entry1 <= 0;
            full <= 1'b0;
        end else begin
            // Synchronize read pointer from destination
            rptr_gray_sync <= {rptr_gray_sync[0], rptr_gray};

            // Update full condition
            full <= valid0 && valid1;

            // Write data if not full and valid
            if (src_valid_i && src_ready_o) begin
                if (!valid0) begin
                    entry0 <= src_data_i;
                    valid0 <= 1'b1;
                end else if (!valid1) begin
                    entry1 <= src_data_i;
                    valid1 <= 1'b1;
                end
                wptr_bin <= wptr_bin + 1;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_bin <= 2'b00;
            wptr_gray_sync <= 2'b00;
            valid0_dst <= 1'b0;
            valid1_dst <= 1'b0;
            empty <= 1'b1;
        end else begin
            // Synchronize write pointer from source
            wptr_gray_sync <= {wptr_gray_sync[0], wptr_gray};

            // Update empty condition
            empty <= !valid0_dst && !valid1_dst;

            // Read data if valid and ready
            if (dst_ready_i && dst_valid_o) begin
                if (valid0_dst) begin
                    valid0_dst <= 1'b0;
                    if (valid1_dst) begin
                        entry0_dst <= entry1_dst;
                        valid0_dst <= 1'b1;
                        valid1_dst <= 1'b0;
                    end
                end
                rptr_bin <= rptr_bin + 1;
            end
        end
    end

    // Assign outputs
    assign src_ready_o = !full;
    assign dst_valid_o = valid0_dst;
    assign dst_data_o = entry0_dst;

endmodule
