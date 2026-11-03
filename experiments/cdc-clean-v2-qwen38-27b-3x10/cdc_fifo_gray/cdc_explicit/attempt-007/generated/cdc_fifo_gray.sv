module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_W = LOG_DEPTH + 1;

    // Gray code conversion
    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_W-1:0] gray2bin;
        input [PTR_W-1:0] gray;
        reg [PTR_W-1:0] bin;
        integer i;
        begin
            bin[PTR_W-1] = gray[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Source domain
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] src_rd_ptr_sync; // synchronized read pointer (gray)
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    wire [PTR_W-1:0] src_wr_gray = bin2gray(src_wr_ptr);
    wire [PTR_W-1:0] src_rd_gray_sync = src_rd_ptr_sync;
    wire [PTR_W-1:0] src_rd_ptr_bin = gray2bin(src_rd_gray_sync);

    wire src_full = (src_wr_ptr[PTR_W-1] != src_rd_ptr_bin[PTR_W-1]) &&
                    (src_wr_ptr[PTR_W-2:0] == src_rd_ptr_bin[PTR_W-2:0]);
    wire src_empty = (src_wr_ptr == src_rd_ptr_bin);

    assign src_ready_o = ~src_full;

    wire src_write_en = src_valid_i & src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_wr_ptr <= {PTR_W{1'b0}};
        else if (src_write_en)
            src_wr_ptr <= src_wr_ptr + 1'b1;
    end

    always @(posedge src_clk_i) begin
        if (src_write_en)
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] dst_wr_ptr_sync; // synchronized write pointer (gray)
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;

    wire [PTR_W-1:0] dst_rd_gray = bin2gray(dst_rd_ptr);
    wire [PTR_W-1:0] dst_wr_gray_sync = dst_wr_ptr_sync;
    wire [PTR_W-1:0] dst_wr_ptr_bin = gray2bin(dst_wr_gray_sync);

    wire dst_full = (dst_rd_ptr[PTR_W-1] != dst_wr_ptr_bin[PTR_W-1]) &&
                    (dst_rd_ptr[PTR_W-2:0] == dst_wr_ptr_bin[PTR_W-2:0]);
    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_bin);

    assign dst_valid_o = dst_valid_reg;
    assign dst_data_o  = dst_data_reg;

    wire dst_read_en = dst_valid_reg & dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr    <= {PTR_W{1'b0}};
            dst_data_reg  <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_read_en) begin
                dst_rd_ptr    <= dst_rd_ptr + 1'b1;
                dst_valid_reg <= 1'b0;
            end else if (!dst_empty && !dst_valid_reg) begin
                dst_data_reg  <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    // Synchronizers: src_wr_gray -> dst domain
    reg [PTR_W-1:0] src_wr_gray_sync [0:SYNC_STAGES-1];
    integer i;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                src_wr_gray_sync[i] <= {PTR_W{1'b0}};
        end else begin
            src_wr_gray_sync[0] <= src_wr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                src_wr_gray_sync[i] <= src_wr_gray_sync[i-1];
        end
    end
    assign dst_wr_ptr_sync = src_wr_gray_sync[SYNC_STAGES-1];

    // Synchronizers: dst_rd_gray -> src domain
    reg [PTR_W-1:0] dst_rd_gray_sync [0:SYNC_STAGES-1];
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                dst_rd_gray_sync[i] <= {PTR_W{1'b0}};
        end else begin
            dst_rd_gray_sync[0] <= dst_rd_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                dst_rd_gray_sync[i] <= dst_rd_gray_sync[i-1];
        end
    end
    assign src_rd_ptr_sync = dst_rd_gray_sync[SYNC_STAGES-1];

endmodule
