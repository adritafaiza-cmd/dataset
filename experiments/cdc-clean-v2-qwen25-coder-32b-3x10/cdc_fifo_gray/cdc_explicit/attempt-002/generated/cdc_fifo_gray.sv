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
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [ADDR_WIDTH:0] src_wr_ptr_gray, src_wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray, src_rd_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray, dst_wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray, dst_rd_ptr_gray_nxt;

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    // Gray code conversion functions
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        bin = gray;
        for (i = ADDR_WIDTH; i > 0; i = i - 1) begin
            bin[i-1] = bin[i] ^ bin[i-1];
        end
        gray2bin = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
            src_rd_ptr_gray <= 0;
        end else begin
            src_wr_ptr_gray <= src_wr_ptr_gray_nxt;
            src_rd_ptr_gray <= src_rd_ptr_gray_nxt;
        end
    end

    always @(*) begin
        src_wr_ptr_gray_nxt = src_wr_ptr_gray;
        src_rd_ptr_gray_nxt = src_rd_ptr_gray;

        if (src_valid_i && src_ready_o) begin
            src_wr_ptr_gray_nxt = bin2gray(gray2bin(src_wr_ptr_gray) + 1);
        end

        if (dst_valid_o && dst_ready_i) begin
            src_rd_ptr_gray_nxt = bin2gray(gray2bin(src_rd_ptr_gray) + 1);
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray <= 0;
            dst_rd_ptr_gray <= 0;
        end else begin
            dst_wr_ptr_gray <= dst_wr_ptr_gray_nxt;
            dst_rd_ptr_gray <= dst_rd_ptr_gray_nxt;
        end
    end

    always @(*) begin
        dst_wr_ptr_gray_nxt = dst_wr_ptr_gray;
        dst_rd_ptr_gray_nxt = dst_rd_ptr_gray;

        if (src_valid_i && src_ready_o) begin
            dst_wr_ptr_gray_nxt = bin2gray(gray2bin(dst_wr_ptr_gray) + 1);
        end

        if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr_gray_nxt = bin2gray(gray2bin(dst_rd_ptr_gray) + 1);
        end
    end

    // Cross-domain synchronization
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_sync [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_sync [SYNC_STAGES-1:0];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync <= {SYNC_STAGES{ADDR_WIDTH+1{1'b0}}};
        end else begin
            src_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_wr_ptr_gray_sync[i] <= src_wr_ptr_gray_sync[i-1];
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync <= {SYNC_STAGES{ADDR_WIDTH+1{1'b0}}};
        end else begin
            dst_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_rd_ptr_gray_sync[i] <= dst_rd_ptr_gray_sync[i-1];
            end
        end
    end

    // FIFO memory write and read
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            // Do nothing
        end else if (src_valid_i && src_ready_o) begin
            mem[gray2bin(src_wr_ptr_gray)] <= src_data_i;
        end
    end

    reg [WIDTH-1:0] dst_data_o_reg [SYNC_STAGES-1:0];
    reg dst_valid_o_reg [SYNC_STAGES-1:0];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o_reg <= {SYNC_STAGES{WIDTH{1'b0}}};
            dst_valid_o_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            if (src_valid_i && src_ready_o) begin
                dst_data_o_reg[0] <= mem[gray2bin(dst_wr_ptr_gray)];
                dst_valid_o_reg[0] <= 1'b1;
            end else if (dst_valid_o && dst_ready_i) begin
                dst_valid_o_reg[0] <= 1'b0;
            end

            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_data_o_reg[i] <= dst_data_o_reg[i-1];
                dst_valid_o_reg[i] <= dst_valid_o_reg[i-1];
            end
        end
    end

    assign dst_data_o = dst_data_o_reg[SYNC_STAGES-1];
    assign dst_valid_o = dst_valid_o_reg[SYNC_STAGES-1];

    // Source ready signal
    wire src_full;
    assign src_full = (src_wr_ptr_gray_sync[SYNC_STAGES-1] == bin2gray(gray2bin(src_rd_ptr_gray) + DEPTH));

    assign src_ready_o = ~src_full;

endmodule
