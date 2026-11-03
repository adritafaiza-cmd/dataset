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
    reg src_clear_active;

    // Destination domain signals
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [GRAY_W-1:0] dst_rd_gray;
    reg [GRAY_W-1:0] dst_wr_gray_sync [0:SYNC_STAGES-1];
    reg [GRAY_W-1:0] dst_wr_gray_sync_next;
    reg dst_clear_pending;
    reg dst_clear_active;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Helper functions
    function [GRAY_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_W-1:0] gray2bin;
        input [GRAY_W-1:0] gray;
        reg [PTR_W-1:0] bin;
        integer i;
        begin
            bin[PTR_W-1] = gray[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    // Source domain logic
    wire [PTR_W-1:0] src_wr_ptr_next;
    wire [GRAY_W-1:0] src_wr_gray_next;
    wire src_can_write;
    wire src_full;
    wire src_empty;

    assign src_full = (src_wr_ptr[PTR_W-1] == src_rd_gray_sync[SYNC_STAGES-1][PTR_W-1]) &&
                      (src_wr_ptr[PTR_W-2:0] != src_rd_gray_sync[SYNC_STAGES-1][PTR_W-2:0]);
    assign src_empty = (src_wr_ptr == {1'b0, {LOG_DEPTH{1'b0}}}) &&
                       (src_rd_gray_sync[SYNC_STAGES-1] == {1'b0, {LOG_DEPTH{1'b0}}});
    assign src_can_write = src_valid_i && !src_full && !src_clear_active;
    assign src_ready_o = !src_full && !src_clear_active;

    assign src_wr_ptr_next = src_wr_ptr + (src_can_write ? 1'b1 : 1'b0);
    assign src_wr_gray_next = bin2gray(src_wr_ptr_next);

    // Synchronize read pointer gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_gray_sync[0] <= {GRAY_W{1'b0}};
            src_rd_gray_sync[1] <= {GRAY_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                src_rd_gray_sync[2] <= {GRAY_W{1'b0}};
            end
        end else begin
            src_rd_gray_sync[0] <= dst_rd_gray;
            src_rd_gray_sync[1] <= src_rd_gray_sync[0];
            if (SYNC_STAGES > 2) begin
                src_rd_gray_sync[2] <= src_rd_gray_sync[1];
            end
        end
    end

    // Source write pointer and memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_wr_gray <= {GRAY_W{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_active <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_active <= 1'b1;
                src_clear_pending <= 1'b1;
            end else if (src_clear_active) begin
                // Wait for destination to acknowledge clear
                if (dst_clear_pending_sync) begin
                    src_clear_active <= 1'b0;
                    src_clear_pending <= 1'b0;
                    src_wr_ptr <= {PTR_W{1'b0}};
                    src_wr_gray <= {GRAY_W{1'b0}};
                end
            end else begin
                if (src_can_write) begin
                    mem[src_wr_ptr[PTR_W-2:0]] <= src_data_i;
                    src_wr_ptr <= src_wr_ptr_next;
                    src_wr_gray <= src_wr_gray_next;
                end
            end
        end
    end

    assign src_clear_pending_o = src_clear_pending;

    // Synchronize dst_clear_pending to source domain
    reg [1:0] dst_clear_pending_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_pending_sync <= 2'b00;
        end else begin
            dst_clear_pending_sync <= {dst_clear_pending_sync[0], dst_clear_pending};
        end
    end

    // Destination domain logic
    wire [PTR_W-1:0] dst_rd_ptr_next;
    wire [GRAY_W-1:0] dst_rd_gray_next;
    wire dst_can_read;
    wire dst_full;
    wire dst_empty;

    assign dst_full = (dst_rd_ptr[PTR_W-1] == dst_wr_gray_sync[SYNC_STAGES-1][PTR_W-1]) &&
                      (dst_rd_ptr[PTR_W-2:0] != dst_wr_gray_sync[SYNC_STAGES-1][PTR_W-2:0]);
    assign dst_empty = (dst_rd_ptr == {1'b0, {LOG_DEPTH{1'b0}}}) &&
                       (dst_wr_gray_sync[SYNC_STAGES-1] == {1'b0, {LOG_DEPTH{1'b0}}});
    assign dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_active;

    assign dst_rd_ptr_next = dst_rd_ptr + (dst_can_read ? 1'b1 : 1'b0);
    assign dst_rd_gray_next = bin2gray(dst_rd_ptr_next);

    // Synchronize write pointer gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_gray_sync[0] <= {GRAY_W{1'b0}};
            dst_wr_gray_sync[1] <= {GRAY_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                dst_wr_gray_sync[2] <= {GRAY_W{1'b0}};
            end
        end else begin
            dst_wr_gray_sync[0] <= src_wr_gray;
            dst_wr_gray_sync[1] <= dst_wr_gray_sync[0];
            if (SYNC_STAGES > 2) begin
                dst_wr_gray_sync[2] <= dst_wr_gray_sync[1];
            end
        end
    end

    // Destination read pointer and output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_rd_gray <= {GRAY_W{1'b0}};
            dst_clear_pending <= 1'b0;
            dst_clear_active <= 1'b0;
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_active <= 1'b1;
                dst_clear_pending <= 1'b1;
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_active) begin
                // Wait for source to acknowledge clear
                if (src_clear_pending_sync) begin
                    dst_clear_active <= 1'b0;
                    dst_clear_pending <= 1'b0;
                    dst_rd_ptr <= {PTR_W{1'b0}};
                    dst_rd_gray <= {GRAY_W{1'b0}};
                    dst_valid_reg <= 1'b0;
                end
            end else begin
                if (dst_can_read) begin
                    dst_rd_ptr <= dst_rd_ptr_next;
                    dst_rd_gray <= dst_rd_gray_next;
                    dst_valid_reg <= 1'b0;
                end else if (!dst_valid_reg && !dst_empty) begin
                    dst_data_reg <= mem[dst_rd_ptr[PTR_W-2:0]];
                    dst_valid_reg <= 1'b1;
                end
            end
        end
    end

    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    // Synchronize src_clear_pending to destination domain
    reg [1:0] src_clear_pending_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_pending_sync <= 2'b00;
        end else begin
            src_clear_pending_sync <= {src_clear_pending_sync[0], src_clear_pending};
        end
    end

endmodule
