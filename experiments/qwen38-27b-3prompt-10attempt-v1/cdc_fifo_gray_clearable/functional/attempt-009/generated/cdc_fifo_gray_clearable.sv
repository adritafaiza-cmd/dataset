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

    // Source domain signals
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] src_wr_ptr_gray;
    reg [PTR_W-1:0] src_rd_ptr_gray_synced;
    reg [PTR_W-1:0] src_rd_ptr_gray_synced_next;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg src_clear_pending;
    reg src_clear_active;

    // Destination domain signals
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] dst_rd_ptr_gray;
    reg [PTR_W-1:0] dst_wr_ptr_gray_synced;
    reg [PTR_W-1:0] dst_wr_ptr_gray_synced_next;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;
    reg dst_clear_active;

    // Synchronizer registers for source read pointer gray
    reg [PTR_W-1:0] src_rd_ptr_gray_sync [0:SYNC_STAGES-1];

    // Synchronizer registers for destination write pointer gray
    reg [PTR_W-1:0] dst_wr_ptr_gray_sync [0:SYNC_STAGES-1];

    // Helper function: binary to gray
    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Helper function: gray to binary
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

    // Source domain: write pointer management
    wire src_wr_ptr_gray_next = bin2gray(src_wr_ptr + 1'b1);
    wire src_full = (src_wr_ptr_gray == src_rd_ptr_gray_synced) && 
                    (src_wr_ptr[PTR_W-1] != src_rd_ptr_gray_synced[PTR_W-1]);
    wire src_empty = (src_wr_ptr_gray == src_rd_ptr_gray_synced);

    // Source domain: clear logic
    wire src_clear_req = src_clear_i | src_clear_active;
    wire src_clear_done = src_clear_active && src_empty && 
                          (src_rd_ptr_gray_synced == {PTR_W{1'b0}});

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
            src_wr_ptr_gray <= {PTR_W{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_active <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_active <= 1'b1;
                src_clear_pending <= 1'b1;
            end else if (src_clear_active) begin
                if (src_clear_done) begin
                    src_clear_active <= 1'b0;
                    src_clear_pending <= 1'b0;
                    src_wr_ptr <= {PTR_W{1'b0}};
                    src_wr_ptr_gray <= {PTR_W{1'b0}};
                end
            end else begin
                if (src_valid_i && !src_full) begin
                    mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                    src_wr_ptr <= src_wr_ptr + 1'b1;
                    src_wr_ptr_gray <= src_wr_ptr_gray_next;
                end
            end
        end
    end

    // Source domain: synchronizer for destination read pointer gray
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync[0] <= {PTR_W{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync[i] <= {PTR_W{1'b0}};
        end else begin
            src_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync[i] <= src_rd_ptr_gray_sync[i-1];
        end
    end

    assign src_rd_ptr_gray_synced = src_rd_ptr_gray_sync[SYNC_STAGES-1];
    assign src_ready_o = !src_full && !src_clear_active;
    assign src_clear_pending_o = src_clear_pending;

    // Destination domain: read pointer management
    wire dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr + 1'b1);
    wire dst_empty = (dst_rd_ptr_gray == dst_wr_ptr_gray_synced);
    wire dst_full = (dst_rd_ptr_gray == dst_wr_ptr_gray_synced) && 
                    (dst_rd_ptr[PTR_W-1] != dst_wr_ptr_gray_synced[PTR_W-1]);

    // Destination domain: clear logic
    wire dst_clear_req = dst_clear_i | dst_clear_active;
    wire dst_clear_done = dst_clear_active && dst_empty && 
                          (dst_wr_ptr_gray_synced == {PTR_W{1'b0}});

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_rd_ptr_gray <= {PTR_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_clear_pending <= 1'b0;
            dst_clear_active <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_active <= 1'b1;
                dst_clear_pending <= 1'b1;
                dst_valid_reg <= 1'b0;
            end else if (dst_clear_active) begin
                if (dst_clear_done) begin
                    dst_clear_active <= 1'b0;
                    dst_clear_pending <= 1'b0;
                    dst_rd_ptr <= {PTR_W{1'b0}};
                    dst_rd_ptr_gray <= {PTR_W{1'b0}};
                    dst_valid_reg <= 1'b0;
                end
            end else begin
                if (dst_valid_reg && dst_ready_i) begin
                    dst_rd_ptr <= dst_rd_ptr + 1'b1;
                    dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
                    dst_valid_reg <= 1'b0;
                end else if (!dst_valid_reg && !dst_empty) begin
                    dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                    dst_valid_reg <= 1'b1;
                end
            end
        end
    end

    // Destination domain: synchronizer for source write pointer gray
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync[0] <= {PTR_W{1'b0}};
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync[i] <= {PTR_W{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync[i] <= dst_wr_ptr_gray_sync[i-1];
        end
    end

    assign dst_wr_ptr_gray_synced = dst_wr_ptr_gray_sync[SYNC_STAGES-1];
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg && !dst_clear_active;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
