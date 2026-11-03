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
    reg [WIDTH-1:0] src_fifo_wdata_reg;
    reg             src_fifo_wen_reg;
    reg [WIDTH-1:0] dst_fifo_wdata_reg;
    reg             dst_fifo_wen_reg;
    reg             src_fifo_empty_sync;
    reg             dst_fifo_full_sync;
    reg             src_fifo_full;
    reg             src_fifo_empty;
    reg             dst_fifo_full;
    reg             dst_fifo_empty;
    reg [WIDTH-1:0] src_fifo_rdata;
    reg [WIDTH-1:0] dst_fifo_rdata;
    reg             src_ready;
    reg             dst_valid;

    // Source FIFO
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_fifo_full <= 0;
            src_fifo_empty <= 1;
        end else begin
            if (src_fifo_wen_reg && !src_fifo_full) begin
                if (src_fifo_empty)
                    src_fifo_empty <= 0;
                if (src_fifo_wdata_reg == dst_fifo_rdata)
                    src_fifo_full <= 1;
            end else if (src_fifo_ren && !src_fifo_empty) begin
                if (src_fifo_full)
                    src_fifo_full <= 0;
                if (src_fifo_wdata_reg == dst_fifo_rdata)
                    src_fifo_empty <= 1;
            end
        end
    end

    // Source FIFO write enable
    assign src_fifo_wen_reg = src_valid_i && src_ready;

    // Source FIFO read enable
    assign src_fifo_ren = !src_fifo_empty && !dst_fifo_full_sync;

    // Source FIFO data register
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_fifo_wdata_reg <= 0;
        else if (src_fifo_wen_reg)
            src_fifo_wdata_reg <= src_data_i;
    end

    // Source FIFO instantiation
    dual_clock_fifo #(
        .WIDTH(WIDTH),
        .DEPTH(2)
    ) src_fifo_inst (
        .clk_wr(src_clk_i),
        .rst_wr_n(src_rst_ni),
        .din(src_fifo_wdata_reg),
        .wr_en(src_fifo_wen_reg),
        .full(src_fifo_full),
        .clk_rd(dst_clk_i),
        .rst_rd_n(dst_rst_ni),
        .dout(src_fifo_rdata),
        .rd_en(src_fifo_ren),
        .empty(src_fifo_empty)
    );

    // Destination FIFO
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_fifo_full <= 0;
            dst_fifo_empty <= 1;
        end else begin
            if (dst_fifo_wen_reg && !dst_fifo_full) begin
                if (dst_fifo_empty)
                    dst_fifo_empty <= 0;
                if (dst_fifo_wdata_reg == src_fifo_rdata)
                    dst_fifo_full <= 1;
            end else if (dst_fifo_ren && !dst_fifo_empty) begin
                if (dst_fifo_full)
                    dst_fifo_full <= 0;
                if (dst_fifo_wdata_reg == src_fifo_rdata)
                    dst_fifo_empty <= 1;
            end
        end
    end

    // Destination FIFO write enable
    assign dst_fifo_wen_reg = !src_fifo_empty_sync && !dst_fifo_full;

    // Destination FIFO read enable
    assign dst_fifo_ren = dst_ready_i && !dst_fifo_empty;

    // Destination FIFO data register
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_fifo_wdata_reg <= 0;
        else if (dst_fifo_wen_reg)
            dst_fifo_wdata_reg <= src_fifo_rdata;
    end

    // Destination FIFO instantiation
    dual_clock_fifo #(
        .WIDTH(WIDTH),
        .DEPTH(2)
    ) dst_fifo_inst (
        .clk_wr(src_clk_i),
        .rst_wr_n(src_rst_ni),
        .din(src_fifo_rdata),
        .wr_en(src_fifo_wen_reg),
        .full(dst_fifo_full),
        .clk_rd(dst_clk_i),
        .rst_rd_n(dst_rst_ni),
        .dout(dst_fifo_rdata),
        .rd_en(dst_fifo_ren),
        .empty(dst_fifo_empty)
    );

    // Synchronization of src_fifo_empty to dst_clk_i
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_fifo_empty_sync <= 1;
        else
            src_fifo_empty_sync <= src_fifo_empty;
    end

    // Synchronization of dst_fifo_full to src_clk_i
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_fifo_full_sync <= 0;
        else
            dst_fifo_full_sync <= dst_fifo_full;
    end

    // Source ready output
    assign src_ready_o = !src_fifo_full;

    // Destination valid output
    assign dst_valid_o = !dst_fifo_empty;

    // Destination data output
    assign dst_data_o = dst_fifo_rdata;

endmodule

// Dual-clock FIFO module
module dual_clock_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 2
)(
    input             clk_wr,
    input             rst_wr_n,
    input  [WIDTH-1:0] din,
    input             wr_en,
    output reg        full,
    input             clk_rd,
    input             rst_rd_n,
    output reg [WIDTH-1:0] dout,
    input             rd_en,
    output reg        empty
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Gray code conversion functions
    function [$clog2(DEPTH):0] bin2gray;
        input [$clog2(DEPTH):0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    function [$clog2(DEPTH):0] gray2bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        gray2bin = gray;
        for (i = $clog2(DEPTH)-1; i >= 0; i = i - 1)
            gray2bin[i] = gray2bin[i] ^ gray2bin[i+1];
    endfunction

    // Write pointer logic
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n)
            wr_ptr <= 0;
        else if (wr_en && !full)
            wr_ptr <= wr_ptr + 1;
    end

    // Read pointer logic
    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n)
            rd_ptr <= 0;
        else if (rd_en && !empty)
            rd_ptr <= rd_ptr + 1;
    end

    // Gray code conversion for pointers
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n)
            wr_ptr_gray <= 0;
        else
            wr_ptr_gray <= bin2gray(wr_ptr);
    end

    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n)
            rd_ptr_gray <= 0;
        else
            rd_ptr_gray <= bin2gray(rd_ptr);
    end

    // Synchronize write pointer gray code to read clock domain
    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Synchronize read pointer gray code to write clock domain
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Full and empty flags
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n)
            full <= 0;
        else
            full <= (wr_ptr_gray + 1 == {~rd_ptr_gray_sync[$clog2(DEPTH)], rd_ptr_gray_sync[$clog2(DEPTH)-1:0]});
    end

    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n)
            empty <= 1;
        else
            empty <= (wr_ptr_gray_sync == rd_ptr_gray);
    end

    // Write to memory
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n && wr_en && !full)
            mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
    end

    // Read from memory
    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n && rd_en && !empty)
            dout <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
    end

endmodule
