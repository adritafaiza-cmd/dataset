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
    localparam PTR_W = LOG_DEPTH + 1;
    localparam GRAY_W = LOG_DEPTH + 1;

    // Source domain signals
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [GRAY_W-1:0] src_wr_gray;
    reg [GRAY_W-1:0] src_rd_gray_sync [0:SYNC_STAGES-1];
    reg [GRAY_W-1:0] src_rd_gray_sync_next;
    reg src_clear_pending;
    reg src_clear_sync [0:SYNC_STAGES-1];
    reg src_clear_sync_next;

    // Destination domain signals
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [GRAY_W-1:0] dst_rd_gray;
    reg [GRAY_W-1:0] dst_wr_gray_sync [0:SYNC_STAGES-1];
    reg [GRAY_W-1:0] dst_wr_gray_sync_next;
    reg dst_clear_pending;
    reg dst_clear_sync [0:SYNC_STAGES-1];
    reg dst_clear_sync_next;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Combinational logic for source domain
    wire [GRAY_W-1:0] src_rd_gray_synced = src_rd_gray_sync[SYNC_STAGES-1];
    wire [PTR_W-1:0] src_rd_ptr_bin;
    wire src_full;
    wire src_can_write;
    wire src_clear_active;

    // Combinational logic for destination domain
    wire [GRAY_W-1:0] dst_wr_gray_synced = dst_wr_gray_sync[SYNC_STAGES-1];
    wire [PTR_W-1:0] dst_wr_ptr_bin;
    wire dst_empty;
    wire dst_can_read;
    wire dst_clear_active;

    // Gray to binary conversion
    function [PTR_W-1:0] gray2bin;
        input [GRAY_W-1:0] gray;
        integer i;
        begin
            gray2bin[GRAY_W-1] = gray[GRAY_W-1];
            for (i = GRAY_W-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Binary to Gray conversion
    function [GRAY_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Source domain logic
    assign src_clear_active = src_clear_pending || src_clear_sync[SYNC_STAGES-1];
    assign src_can_write = src_valid_i && !src_full && !src_clear_active;
    assign src_ready_o = !src_full && !src_clear_active;
    assign src_clear_pending_o = src_clear_pending;

    // Destination domain logic
    assign dst_clear_active = dst_clear_pending || dst_clear_sync[SYNC_STAGES-1];
    assign dst_can_read = !dst_empty && dst_ready_i && !dst_clear_active;
    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg && !dst_clear_active;

    // Source clock domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_wr_gray <= {GRAY_W{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_sync[0] <= 1'b0;
            src_clear_sync[1] <= 1'b0;
            src_clear_sync[2] <= 1'b0;
            src_rd_gray_sync[0] <= {GRAY_W{1'b0}};
            src_rd_gray_sync[1] <= {GRAY_W{1'b0}};
            src_rd_gray_sync[2] <= {GRAY_W{1'b0}};
        end else begin
            // Synchronize clear from destination
            src_clear_sync[0] <= dst_clear_sync[SYNC_STAGES-1];
            src_clear_sync[1] <= src_clear_sync[0];
            src_clear_sync[2] <= src_clear_sync[1];

            // Synchronize read pointer gray from destination
            src_rd_gray_sync[0] <= dst_rd_gray;
            src_rd_gray_sync[1] <= src_rd_gray_sync[0];
            src_rd_gray_sync[2] <= src_rd_gray_sync[1];

            // Handle clear
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
            end else if (src_clear_pending && src_clear_sync[SYNC_STAGES-1]) begin
                // Clear is complete when destination has acknowledged
                src_clear_pending <= 1'b0;
            end

            // Write data
            if (src_can_write) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
            end

            // Update gray pointer
            src_wr_gray <= bin2gray(src_wr_ptr + (src_can_write ? 1'b1 : 1'b0));
        end
    end

    // Destination clock domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_rd_gray <= {GRAY_W{1'b0}};
            dst_clear_pending <= 1'b0;
            dst_clear_sync[0] <= 1'b0;
            dst_clear_sync[1] <= 1'b0;
            dst_clear_sync[2] <= 1'b0;
            dst_wr_gray_sync[0] <= {GRAY_W{1'b0}};
            dst_wr_gray_sync[1] <= {GRAY_W{1'b0}};
            dst_wr_gray_sync[2] <= {GRAY_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            // Synchronize clear from source
            dst_clear_sync[0] <= src_clear_sync[SYNC_STAGES-1];
            dst_clear_sync[1] <= dst_clear_sync[0];
            dst_clear_sync[2] <= dst_clear_sync[1];

            // Synchronize write pointer gray from source
            dst_wr_gray_sync[0] <= src_wr_gray;
            dst_wr_gray_sync[1] <= dst_wr_gray_sync[0];
            dst_wr_gray_sync[2] <= dst_wr_gray_sync[1];

            // Handle clear
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
            end else if (dst_clear_pending && dst_clear_sync[SYNC_STAGES-1]) begin
                // Clear is complete when source has acknowledged
                dst_clear_pending <= 1'b0;
            end

            // Read data
            if (dst_can_read) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
            end

            // Update valid
            if (dst_can_read) begin
                dst_valid_reg <= 1'b1;
            end else if (dst_valid_reg && !dst_ready_i) begin
                dst_valid_reg <= 1'b0;
            end

            // Update gray pointer
            dst_rd_gray <= bin2gray(dst_rd_ptr + (dst_can_read ? 1'b1 : 1'b0));
        end
    end

    // Compute full/empty
    assign src_rd_ptr_bin = gray2bin(src_rd_gray_synced);
    assign dst_wr_ptr_bin = gray2bin(dst_wr_gray_synced);

    assign src_full = (src_wr_ptr[PTR_W-1] == src_rd_ptr_bin[PTR_W-1]) &&
                      (src_wr_ptr[PTR_W-2:0] == src_rd_ptr_bin[PTR_W-2:0]);

    assign dst_empty = (dst_rd_ptr[PTR_W-1] == dst_wr_ptr_bin[PTR_W-1]) &&
                       (dst_rd_ptr[PTR_W-2:0] == dst_wr_ptr_bin[PTR_W-2:0]);

endmodule
