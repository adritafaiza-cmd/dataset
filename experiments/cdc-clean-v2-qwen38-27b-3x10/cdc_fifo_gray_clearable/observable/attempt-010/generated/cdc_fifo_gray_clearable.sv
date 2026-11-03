module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;
    localparam GRAY_WIDTH = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] src_rd_ptr_sync;
    reg [GRAY_WIDTH-1:0] src_wr_ptr_gray;
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync;
    reg src_clear_pending;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_sync;
    reg [GRAY_WIDTH-1:0] dst_rd_ptr_gray;
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync;
    reg dst_clear_pending;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Gray code conversion functions
    function [GRAY_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_WIDTH-1:0] gray2bin;
        input [GRAY_WIDTH-1:0] gray;
        integer i;
        begin
            gray2bin[GRAY_WIDTH-1] = gray[GRAY_WIDTH-1];
            for (i = GRAY_WIDTH-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Source domain: write pointer and memory
    wire src_full;
    wire src_empty;
    wire src_wr_en;
    wire src_rd_en;

    assign src_wr_en = src_valid_i & src_ready_o & ~src_clear_pending;
    assign src_rd_en = dst_valid_reg & dst_ready_i & ~dst_clear_pending;

    // Full/empty detection using Gray codes
    // Full: write pointer gray equals read pointer gray with MSB different
    // Empty: write pointer gray equals read pointer gray
    wire [GRAY_WIDTH-1:0] src_wr_ptr_gray_next;
    wire [GRAY_WIDTH-1:0] src_rd_ptr_gray_next;

    assign src_wr_ptr_gray_next = bin2gray(src_wr_ptr + 1'b1);
    assign src_rd_ptr_gray_next = bin2gray(src_rd_ptr_sync + 1'b1);

    // Full condition: (wr_ptr + 1) gray == rd_ptr gray
    assign src_full = (src_wr_ptr_gray_next == src_rd_ptr_gray_sync);
    assign src_empty = (src_wr_ptr_gray == src_rd_ptr_gray_sync);

    assign src_ready_o = ~src_full & ~src_clear_pending;

    // Write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
            src_clear_pending <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
            end else if (src_clear_pending) begin
                // Wait for destination to acknowledge clear
                if (dst_clear_pending_sync) begin
                    src_clear_pending <= 1'b0;
                    src_wr_ptr <= {PTR_WIDTH{1'b0}};
                    src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
                end
            end else if (src_wr_en) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
                src_wr_ptr_gray <= src_wr_ptr_gray_next;
            end
        end
    end

    // Synchronize read pointer from destination to source
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync_r [0:SYNC_STAGES-1];
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync_r[i] <= {GRAY_WIDTH{1'b0}};
        end else begin
            src_rd_ptr_gray_sync_r[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync_r[i] <= src_rd_ptr_gray_sync_r[i-1];
        end
    end
    assign src_rd_ptr_gray_sync = src_rd_ptr_gray_sync_r[SYNC_STAGES-1];
    assign src_rd_ptr_sync = gray2bin(src_rd_ptr_gray_sync);

    // Synchronize clear pending from destination to source
    reg dst_clear_pending_sync_r [0:SYNC_STAGES-1];
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1)
                dst_clear_pending_sync_r[i] <= 1'b0;
        end else begin
            dst_clear_pending_sync_r[0] <= dst_clear_pending;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_pending_sync_r[i] <= dst_clear_pending_sync_r[i-1];
        end
    end
    wire dst_clear_pending_sync = dst_clear_pending_sync_r[SYNC_STAGES-1];

    assign src_clear_pending_o = src_clear_pending;

    // Destination domain: read pointer and output
    wire dst_full;
    wire dst_empty;

    assign dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr + 1'b1);
    assign dst_wr_ptr_gray_next = bin2gray(dst_wr_ptr_sync + 1'b1);

    assign dst_full = (dst_rd_ptr_gray_next == dst_wr_ptr_gray_sync);
    assign dst_empty = (dst_rd_ptr_gray == dst_wr_ptr_gray_sync);

    // Read from memory
    wire [WIDTH-1:0] mem_rd_data;
    assign mem_rd_data = mem[dst_rd_ptr[LOG_DEPTH-1:0]];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
            dst_clear_pending <= 1'b0;
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_pending) begin
                // Wait for source to acknowledge clear
                if (src_clear_pending_sync) begin
                    dst_clear_pending <= 1'b0;
                    dst_rd_ptr <= {PTR_WIDTH{1'b0}};
                    dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
                    dst_valid_reg <= 1'b0;
                end
            end else begin
                if (dst_valid_reg & dst_ready_i) begin
                    dst_rd_ptr <= dst_rd_ptr + 1'b1;
                    dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
                    dst_valid_reg <= 1'b0;
                end else if (~dst_valid_reg & ~dst_empty) begin
                    dst_data_reg <= mem_rd_data;
                    dst_valid_reg <= 1'b1;
                end
            end
        end
    end

    // Synchronize write pointer from source to destination
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync_r [0:SYNC_STAGES-1];
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync_r[i] <= {GRAY_WIDTH{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync_r[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync_r[i] <= dst_wr_ptr_gray_sync_r[i-1];
        end
    end
    assign dst_wr_ptr_gray_sync = dst_wr_ptr_gray_sync_r[SYNC_STAGES-1];
    assign dst_wr_ptr_sync = gray2bin(dst_wr_ptr_gray_sync);

    // Synchronize clear pending from source to destination
    reg src_clear_pending_sync_r [0:SYNC_STAGES-1];
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1)
                src_clear_pending_sync_r[i] <= 1'b0;
        end else begin
            src_clear_pending_sync_r[0] <= src_clear_pending;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_pending_sync_r[i] <= src_clear_pending_sync_r[i-1];
        end
    end
    wire src_clear_pending_sync = src_clear_pending_sync_r[SYNC_STAGES-1];

    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
