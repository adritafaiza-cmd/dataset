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

    // Source domain signals
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray;
    reg [PTR_WIDTH-1:0] src_rd_ptr_gray_synced;
    reg [PTR_WIDTH-1:0] src_rd_ptr_gray_synced_next;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg src_clear_pending;
    reg src_clear_done;

    // Destination domain signals
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_gray_synced;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_gray_synced_next;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;
    reg dst_clear_done;

    // Synchronizer chains for source read pointer gray
    reg [PTR_WIDTH-1:0] src_rd_ptr_gray_sync [0:SYNC_STAGES-1];
    // Synchronizer chains for destination write pointer gray
    reg [PTR_WIDTH-1:0] dst_wr_ptr_gray_sync [0:SYNC_STAGES-1];

    // Clear handshake signals
    reg src_clear_req;
    reg dst_clear_req;
    reg src_clear_ack;
    reg dst_clear_ack;

    // Binary to Gray conversion
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Gray to Binary conversion
    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        reg [PTR_WIDTH-1:0] bin;
        integer i;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Source domain: write pointer management
    wire src_wr_ptr_gray_next = bin2gray(src_wr_ptr + 1'b1);
    wire src_can_write = (src_wr_ptr_gray != src_rd_ptr_gray_synced) && !src_clear_pending;
    wire src_write = src_valid_i && src_ready_o && !src_clear_pending;

    assign src_ready_o = src_can_write;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {PTR_WIDTH{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_done <= 1'b0;
            src_clear_req <= 1'b0;
            src_clear_ack <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_req <= 1'b1;
                src_clear_pending <= 1'b1;
                src_clear_done <= 1'b0;
            end else if (src_clear_req && src_clear_ack) begin
                src_clear_req <= 1'b0;
                src_clear_pending <= 1'b0;
                src_clear_done <= 1'b1;
                src_wr_ptr <= {PTR_WIDTH{1'b0}};
                src_wr_ptr_gray <= {PTR_WIDTH{1'b0}};
            end else if (src_write) begin
                src_wr_ptr <= src_wr_ptr + 1'b1;
                src_wr_ptr_gray <= src_wr_ptr_gray_next;
            end
        end
    end

    // Source domain: synchronizer for destination read pointer gray
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync[0] <= {PTR_WIDTH{1'b0}};
            src_rd_ptr_gray_sync[1] <= {PTR_WIDTH{1'b0}};
            src_rd_ptr_gray_sync[2] <= {PTR_WIDTH{1'b0}};
        end else begin
            src_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            src_rd_ptr_gray_sync[1] <= src_rd_ptr_gray_sync[0];
            src_rd_ptr_gray_sync[2] <= src_rd_ptr_gray_sync[1];
        end
    end

    assign src_rd_ptr_gray_synced = src_rd_ptr_gray_sync[SYNC_STAGES-1];

    // Source domain: clear acknowledgment from destination
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_ack <= 1'b0;
        end else begin
            src_clear_ack <= dst_clear_ack;
        end
    end

    // Destination domain: read pointer management
    wire dst_rd_ptr_gray_next = bin2gray(dst_rd_ptr + 1'b1);
    wire dst_can_read = (dst_rd_ptr_gray != dst_wr_ptr_gray_synced) && !dst_clear_pending;
    wire dst_read = dst_valid_reg && dst_ready_i && !dst_clear_pending;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {PTR_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_clear_pending <= 1'b0;
            dst_clear_done <= 1'b0;
            dst_clear_req <= 1'b0;
            dst_clear_ack <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_req <= 1'b1;
                dst_clear_pending <= 1'b1;
                dst_clear_done <= 1'b0;
            end else if (dst_clear_req && src_clear_ack) begin
                dst_clear_req <= 1'b0;
                dst_clear_pending <= 1'b0;
                dst_clear_done <= 1'b1;
                dst_rd_ptr <= {PTR_WIDTH{1'b0}};
                dst_rd_ptr_gray <= {PTR_WIDTH{1'b0}};
                dst_valid_reg <= 1'b0;
            end else if (dst_read) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_rd_ptr_gray <= dst_rd_ptr_gray_next;
                dst_valid_reg <= 1'b0;
            end else if (dst_can_read && !dst_valid_reg) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    // Destination domain: synchronizer for source write pointer gray
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync[0] <= {PTR_WIDTH{1'b0}};
            dst_wr_ptr_gray_sync[1] <= {PTR_WIDTH{1'b0}};
            dst_wr_ptr_gray_sync[2] <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            dst_wr_ptr_gray_sync[1] <= dst_wr_ptr_gray_sync[0];
            dst_wr_ptr_gray_sync[2] <= dst_wr_ptr_gray_sync[1];
        end
    end

    assign dst_wr_ptr_gray_synced = dst_wr_ptr_gray_sync[SYNC_STAGES-1];

    // Destination domain: clear acknowledgment to source
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_ack <= 1'b0;
        end else begin
            dst_clear_ack <= src_clear_ack;
        end
    end

    // Memory write in source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            // No reset for memory array, but we can leave it uninitialized
        end else if (src_write) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Output assignments
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
