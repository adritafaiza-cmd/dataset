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

    // Source domain signals
    reg  [PTR_WIDTH-1:0] src_wr_ptr;
    reg  [GRAY_WIDTH-1:0] src_wr_ptr_gray;
    reg  [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync;
    reg  [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync_next;
    reg  [WIDTH-1:0] mem [0:DEPTH-1];
    reg  src_clear_pending;
    reg  src_clear_active;

    // Destination domain signals
    reg  [PTR_WIDTH-1:0] dst_rd_ptr;
    reg  [GRAY_WIDTH-1:0] dst_rd_ptr_gray;
    reg  [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync;
    reg  [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync_next;
    reg  [WIDTH-1:0] dst_data_reg;
    reg  dst_valid_reg;
    reg  dst_clear_pending;
    reg  dst_clear_active;

    // Synchronizer registers for source read pointer gray
    reg  [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync_r [0:SYNC_STAGES-1];

    // Synchronizer registers for destination write pointer gray
    reg  [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync_r [0:SYNC_STAGES-1];

    // Binary to Gray conversion
    function [GRAY_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Gray to binary conversion
    function [PTR_WIDTH-1:0] gray2bin;
        input [GRAY_WIDTH-1:0] gray;
        integer i;
        reg [PTR_WIDTH-1:0] bin;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1) begin
                bin[i] = gray[i] ^ bin[i+1];
            end
            gray2bin = bin;
        end
    endfunction

    // Source domain logic
    wire [PTR_WIDTH-1:0] src_rd_ptr_bin;
    wire [PTR_WIDTH-1:0] src_wr_ptr_bin;
    wire src_full;
    wire src_empty;
    wire src_wr_en;
    wire src_rd_en;

    assign src_rd_ptr_bin = gray2bin(src_rd_ptr_gray_sync);
    assign src_wr_ptr_bin = src_wr_ptr;

    // Full condition: write pointer gray equals read pointer gray with MSB difference
    assign src_full = (src_wr_ptr_gray == src_rd_ptr_gray_sync) && 
                      (src_wr_ptr[PTR_WIDTH-1] != src_rd_ptr_bin[PTR_WIDTH-1]);

    assign src_empty = (src_wr_ptr_gray == src_rd_ptr_gray_sync) && 
                       (src_wr_ptr[PTR_WIDTH-1] == src_rd_ptr_bin[PTR_WIDTH-1]);

    assign src_ready_o = !src_full && !src_clear_active;

    assign src_wr_en = src_valid_i && src_ready_o;

    // Source clear logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_clear_active <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
                src_clear_active <= 1'b1;
            end else if (src_clear_pending) begin
                // Wait for destination to acknowledge clear
                // We need to synchronize the clear completion
                src_clear_active <= 1'b0;
                src_clear_pending <= 1'b0;
            end
        end
    end

    // Source write pointer update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
        end else if (src_clear_active) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
        end else if (src_wr_en) begin
            src_wr_ptr <= src_wr_ptr + 1'b1;
            src_wr_ptr_gray <= bin2gray(src_wr_ptr + 1'b1);
        end
    end

    // Source memory write
    always @(posedge src_clk_i) begin
        if (src_wr_en) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Synchronize destination read pointer gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync_r[0] <= {GRAY_WIDTH{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_rd_ptr_gray_sync_r[i] <= {GRAY_WIDTH{1'b0}};
            end
        end else begin
            src_rd_ptr_gray_sync_r[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_rd_ptr_gray_sync_r[i] <= src_rd_ptr_gray_sync_r[i-1];
            end
        end
    end

    assign src_rd_ptr_gray_sync = src_rd_ptr_gray_sync_r[SYNC_STAGES-1];

    // Destination domain logic
    wire [PTR_WIDTH-1:0] dst_wr_ptr_bin;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_bin;
    wire dst_full;
    wire dst_empty;
    wire dst_rd_en;

    assign dst_wr_ptr_bin = gray2bin(dst_wr_ptr_gray_sync);
    assign dst_rd_ptr_bin = dst_rd_ptr;

    // Empty condition
    assign dst_empty = (dst_rd_ptr_gray == dst_wr_ptr_gray_sync) && 
                       (dst_rd_ptr[PTR_WIDTH-1] == dst_wr_ptr_bin[PTR_WIDTH-1]);

    assign dst_rd_en = dst_valid_reg && dst_ready_i && !dst_clear_active;

    // Destination clear logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_clear_active <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
                dst_clear_active <= 1'b1;
            end else if (dst_clear_pending) begin
                dst_clear_active <= 1'b0;
                dst_clear_pending <= 1'b0;
            end
        end
    end

    // Destination read pointer update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
        end else if (dst_clear_active) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
        end else if (dst_rd_en) begin
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
            dst_rd_ptr_gray <= bin2gray(dst_rd_ptr + 1'b1);
        end
    end

    // Destination data read and valid
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else if (dst_clear_active) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else if (dst_rd_en) begin
            dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
            dst_valid_reg <= 1'b1;
        end else if (dst_valid_reg && !dst_ready_i) begin
            // Hold valid if not ready
            dst_valid_reg <= 1'b1;
        end else begin
            dst_valid_reg <= 1'b0;
        end
    end

    // Synchronize source write pointer gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync_r[0] <= {GRAY_WIDTH{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_wr_ptr_gray_sync_r[i] <= {GRAY_WIDTH{1'b0}};
            end
        end else begin
            dst_wr_ptr_gray_sync_r[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_wr_ptr_gray_sync_r[i] <= dst_wr_ptr_gray_sync_r[i-1];
            end
        end
    end

    assign dst_wr_ptr_gray_sync = dst_wr_ptr_gray_sync_r[SYNC_STAGES-1];

    // Output assignments
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
