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

    // Internal signals
    reg [WIDTH-1:0]         fifo [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH-1:0]     src_head, dst_tail;
    reg                     src_full, dst_empty;
    reg                     src_clearing, dst_clearing;
    reg                     src_clear_pending, dst_clear_pending;

    // Synchronizers
    reg [WIDTH-1:0]         src_data_sync [0:SYNC_STAGES-1];
    reg                     src_valid_sync [0:SYNC_STAGES-1];
    reg                     src_ready_sync [0:SYNC_STAGES-1];
    reg [WIDTH-1:0]         dst_data_sync [0:SYNC_STAGES-1];
    reg                     dst_valid_sync [0:SYNC_STAGES-1];
    reg                     dst_ready_sync [0:SYNC_STAGES-1];

    // Shift registers for clear signals
    reg                     src_clear_sync [0:SYNC_STAGES-1];
    reg                     dst_clear_sync [0:SYNC_STAGES-1];

    // Synchronizers for clear pending signals
    reg                     src_clear_pending_sync [0:SYNC_STAGES-1];
    reg                     dst_clear_pending_sync [0:SYNC_STAGES-1];

    // Synchronizers for FIFO pointers
    reg [LOG_DEPTH-1:0]     src_head_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH-1:0]     dst_tail_sync [0:SYNC_STAGES-1];

    // Synchronizers for FIFO status
    reg                     src_full_sync [0:SYNC_STAGES-1];
    reg                     dst_empty_sync [0:SYNC_STAGES-1];

    // Generate synchronizers for source domain
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i++) begin : src_sync
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_data_sync[i] <= 0;
                    src_valid_sync[i] <= 0;
                    src_ready_sync[i] <= 0;
                    src_clear_sync[i] <= 0;
                    src_clear_pending_sync[i] <= 0;
                    src_head_sync[i] <= 0;
                end else begin
                    src_data_sync[i] <= src_data_i;
                    src_valid_sync[i] <= src_valid_i;
                    src_ready_sync[i] <= src_ready_o;
                    src_clear_sync[i] <= src_clear_i;
                    src_clear_pending_sync[i] <= src_clear_pending;
                    src_head_sync[i] <= src_head;
                end
            end
        end
    endgenerate

    // Generate synchronizers for destination domain
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i++) begin : dst_sync
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_data_sync[i] <= 0;
                    dst_valid_sync[i] <= 0;
                    dst_ready_sync[i] <= 0;
                    dst_clear_sync[i] <= 0;
                    dst_clear_pending_sync[i] <= 0;
                    dst_tail_sync[i] <= 0;
                end else begin
                    dst_data_sync[i] <= dst_data_o;
                    dst_valid_sync[i] <= dst_valid_o;
                    dst_ready_sync[i] <= dst_ready_i;
                    dst_clear_sync[i] <= dst_clear_i;
                    dst_clear_pending_sync[i] <= dst_clear_pending;
                    dst_tail_sync[i] <= dst_tail;
                end
            end
        end
    endgenerate

    // Register the synchronized signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_data_i <= 0;
            src_valid_i <= 0;
            src_ready_o <= 0;
            src_clear_i <= 0;
            src_clear_pending <= 0;
            src_head <= 0;
        end else begin
            src_data_i <= src_data_sync[SYNC_STAGES-1];
            src_valid_i <= src_valid_sync[SYNC_STAGES-1];
            src_ready_o <= src_ready_sync[SYNC_STAGES-1];
            src_clear_i <= src_clear_sync[SYNC_STAGES-1];
            src_clear_pending <= src_clear_pending_sync[SYNC_STAGES-1];
            src_head <= src_head_sync[SYNC_STAGES-1];
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
            dst_valid_o <= 0;
            dst_ready_i <= 0;
            dst_clear_i <= 0;
            dst_clear_pending <= 0;
            dst_tail <= 0;
        end else begin
            dst_data_o <= dst_data_sync[SYNC_STAGES-1];
            dst_valid_o <= dst_valid_sync[SYNC_STAGES-1];
            dst_ready_i <= dst_ready_sync[SYNC_STAGES-1];
            dst_clear_i <= dst_clear_sync[SYNC_STAGES-1];
            dst_clear_pending <= dst_clear_pending_sync[SYNC_STAGES-1];
            dst_tail <= dst_tail_sync[SYNC_STAGES-1];
        end
    end

    // FIFO logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_full <= 0;
            src_clearing <= 0;
        end else begin
            if (src_clearing) begin
                src_full <= 0;
                src_head <= 0;
            end else begin
                src_full <= (src_head == (src_tail + 1) % (1<<LOG_DEPTH));
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_empty <= 1;
            dst_clearing <= 0;
        end else begin
            if (dst_clearing) begin
                dst_empty <= 1;
                dst_tail <= 0;
            end else begin
                dst_empty <= (src_tail == dst_tail);
            end
        end
    end

    // Clear logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1;
                src_clearing <= 1;
            end else if (src_clearing && src_head == src_tail) begin
                src_clearing <= 0;
                src_clear_pending <= 0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1;
                dst_clearing <= 1;
            end else if (dst_clearing && src_tail == dst_tail) begin
                dst_clearing <= 0;
                dst_clear_pending <= 0;
            end
        end
    end

    // Assign outputs
    assign src_ready_o = !src_full;
    assign dst_valid_o = !dst_empty;
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
