`timescale 1ns/1ps

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
    localparam GRAY_WIDTH = LOG_DEPTH;

    // Internal signals
    reg [DEPTH-1:0]     mem_data;
    reg [LOG_DEPTH-1:0] wr_ptr;
    reg [LOG_DEPTH-1:0] rd_ptr;
    reg [LOG_DEPTH-1:0] wr_gray;
    reg [LOG_DEPTH-1:0] rd_gray;
    reg                 wr_en;
    reg                 rd_en;
    reg                 full;
    reg                 empty;
    reg                 src_clear_req;
    reg                 dst_clear_req;
    reg                 src_clear_pending;
    reg                 dst_clear_pending;
    reg [WIDTH-1:0]     dst_data_reg;
    reg                 dst_valid_reg;
    reg                 dst_valid_sync;

    // Synchronizers for control signals
    // src_clear_i sync to dst domain
    reg [SYNC_STAGES-1:0] src_clear_sync;
    reg [SYNC_STAGES-1:0] dst_clear_sync;

    // src_clear_pending_o logic
    // High when clear is requested and not yet completed
    assign src_clear_pending_o = src_clear_req & ~src_clear_pending;

    // dst_clear_pending_o logic
    // High when clear is requested and not yet completed
    assign dst_clear_pending_o = dst_clear_req & ~dst_clear_pending;

    // Synchronize src_clear_i to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_clear_sync <= {SYNC_STAGES{1'b0}};
        else
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
    end

    // Synchronize dst_clear_i to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_clear_sync <= {SYNC_STAGES{1'b0}};
        else
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end

    // Decode clear requests
    assign src_clear_req = src_clear_sync[SYNC_STAGES-1];
    assign dst_clear_req = dst_clear_sync[SYNC_STAGES-1];

    // State machine for clear operation
    // We need to track if a clear is in progress on each side
    reg src_clear_in_progress;
    reg dst_clear_in_progress;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            wr_gray <= '0;
            rd_gray <= '0;
            mem_data <= '0;
            src_clear_in_progress <= 1'b0;
            dst_clear_in_progress <= 1'b0;
            src_clear_pending <= 1'b0;
            dst_clear_pending <= 1'b0;
            full <= 1'b0;
            empty <= 1'b1;
        end
        else begin
            // Update clear in-progress flags
            src_clear_in_progress <= src_clear_req;
            dst_clear_in_progress <= dst_clear_req;

            // If clear is requested, set pending flag
            if (src_clear_req)
                src_clear_pending <= 1'b1;
            if (dst_clear_req)
                dst_clear_pending <= 1'b1;

            // Check if clear is complete
            // Clear is complete when both pointers are at 0 and no more data is being written/read
            // However, we must ensure that the clear operation has actually flushed the data
            // We use a simple approach: if clear is requested, we wait until pointers are at 0
            // and then clear the pending flag
            
            if (src_clear_req && (wr_ptr == '0 && rd_ptr == '0))
                src_clear_pending <= 1'b0;
            if (dst_clear_req && (wr_ptr == '0 && rd_ptr == '0))
                dst_clear_pending <= 1'b0;

            // Normal FIFO operations
            if (!src_clear_req && !dst_clear_req) begin
                // Write pointer update
                if (src_valid_i && dst_ready_i && !full) begin
                    wr_en <= 1'b1;
                    rd_en <= 1'b0;
                    mem_data[wr_ptr] <= src_data_i;
                    wr_gray <= wr_ptr;
                    full <= 1'b1;
                    empty <= 1'b0;
                end
                else if (src_valid_i && dst_ready_i && full) begin
                    // FIFO full, wait for ready
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                end
                else begin
                    wr_en <= 1'b0;
                    
                    // Read pointer update
                    if (rd_en) begin
                        rd_gray <= rd_ptr;
                        empty <= 1'b1;
                        full <= 1'b0;
                    end
                end
            end
            else if (src_clear_req || dst_clear_req) begin
                // During clear, we stop normal operations
                wr_en <= 1'b0;
                rd_en <= 1'b0;
                
                // If both pointers are at 0, we can clear the pending flags
                if (wr_ptr == '0 && rd_ptr == '0) begin
                    src_clear_pending <= 1'b0;
                    dst_clear_pending <= 1'b0;
                end
            end
        end
    end

    // Gray code generation for write pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wr_gray <= '0;
        else if (wr_en)
            wr_gray <= wr_ptr;
        else
            wr_gray <= wr_gray;
    end

    // Gray code generation for read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rd_gray <= '0;
        else if (rd_en)
            rd_gray <= rd_ptr;
        else
            rd_gray <= rd_gray;
    end

    // Synchronize Gray codes to opposite domains
    // Write Gray to dst domain
    reg [SYNC_STAGES-1:0] wr_gray_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            wr_gray_sync <= {SYNC_STAGES{1'b0}};
        else
            wr_gray_sync <= {wr_gray_sync[SYNC_STAGES-2:0], wr_gray[SYNC_STAGES-1]};
    end

    // Read Gray to src domain
    reg [SYNC_STAGES-1:0] rd_gray_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            rd_gray_sync <= {SYNC_STAGES{1'b0}};
        else
            rd_gray_sync <= {rd_gray_sync[SYNC_STAGES-2:0], rd_gray[SYNC_STAGES-1]};
    end

    // Full detection in dst domain
    reg full_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            full_sync <= 1'b0;
        else if (wr_gray_sync[SYNC_STAGES-1])
            full_sync <= 1'b1;
        else
            full_sync <= 1'b0;
    end

    // Empty detection in src domain
    reg empty_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            empty_sync <= 1'b1;
        else if (rd_gray_sync[SYNC_STAGES-1])
            empty_sync <= 1'b0;
        else
            empty_sync <= 1'b1;
    end

    // Update full/empty flags based on synchronized signals
    // Note: We need to be careful here to avoid race conditions
    // The full/empty flags are updated in the main process block based on the synchronized signals
    
    // Re-implement the main process block with proper synchronization
    // We'll use a separate process for the main FIFO logic to handle the synchronization properly

    // Main FIFO logic in src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            mem_data <= '0;
            full <= 1'b0;
            empty <= 1'b1;
        end
        else begin
            // Check for clear request
            if (src_clear_req) begin
                src_clear_pending <= 1'b1;
                wr_en <= 1'b0;
                rd_en <= 1'b0;
                
                // Wait until pointers are at 0
                if (wr_ptr == '0 && rd_ptr == '0)
                    src_clear_pending <= 1'b0;
            end
            else if (dst_clear_req) begin
                dst_clear_pending <= 1'b1;
                wr_en <= 1'b0;
                rd_en <= 1'b0;
                
                // Wait until pointers are at 0
                if (wr_ptr == '0 && rd_ptr == '0)
                    dst_clear_pending <= 1'b0;
            end
            else begin
                // Normal operation
                if (src_valid_i && dst_ready_i && !full) begin
                    wr_en <= 1'b1;
                    rd_en <= 1'b0;
                    mem_data[wr_ptr] <= src_data_i;
                    full <= 1'b1;
                    empty <= 1'b0;
                end
                else if (src_valid_i && dst_ready_i && full) begin
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                end
                else begin
                    wr_en <= 1'b0;
                    
                    if (rd_en) begin
                        rd_en <= 1'b0;
                        empty <= 1'b1;
                        full <= 1'b0;
                    end
                end
            end
        end
    end

    // Main FIFO logic in dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= '0;
            wr_ptr <= '0;
            mem_data <= '0;
            full <= 1'b0;
            empty <= 1'b1;
        end
        else begin
            // Check for clear request
            if (dst_clear_req) begin
                dst_clear_pending <= 1'b1;
                rd_en <= 1'b0;
                wr_en <= 1'b0;
                
                // Wait until pointers are at 0
                if (rd_ptr == '0 && wr_ptr == '0)
                    dst_clear_pending <= 1'b0;
            end
            else if (src_clear_req) begin
                src_clear_pending <= 1'b1;
                rd_en <= 1'b0;
                wr_en <= 1'b0;
                
                // Wait until pointers are at 0
                if (rd_ptr == '0 && wr_ptr == '0)
                    src_clear_pending <= 1'b0;
            end
            else begin
                // Normal operation
                if (rd_en) begin
                    rd_en <= 1'b0;
                    empty <= 1'b1;
                    full <= 1'b0;
                end
                else if (src_valid_i && dst_ready_i && !full) begin
                    wr_en <= 1'b1;
                    rd_en <= 1'b0;
                    mem_data[wr_ptr] <= src_data_i;
                    full <= 1'b1;
                    empty <= 1'b0;
                end
                else if (src_valid_i && dst_ready_i && full) begin
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                end
                else begin
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                end
            end
        end
    end

    // This approach has issues with the dual-domain state machine.
    // Let's use a cleaner approach with a single state machine that tracks both sides.

    // Reset the state machine
    reg [2:0] fsm_state; // 0: idle, 1: src_clear, 2: dst_clear, 3: both_clear
    reg src_clear_done;
    reg dst_clear_done;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fsm_state <= 3'b000;
            src_clear_done <= 1'b0;
            dst_clear_done <= 1'b0;
            wr_ptr <= '0;
            rd_ptr <= '0;
            mem_data <= '0;
            full <= 1'b0;
            empty <= 1'b1;
        end
        else begin
            // Update clear done flags
            if (src_clear_req && wr_ptr == '0 && rd_ptr == '0)
                src_clear_done <= 1'b1;
            else
                src_clear_done <= 1'b0;

            if (dst_clear_req && wr_ptr == '0 && rd_ptr == '0)
                dst_clear_done <= 1'b1;
            else
                dst_clear_done <= 1'b0;

            // State machine
            case (fsm_state)
                3'b000: begin // Idle
                    if (src_clear_req)
                        fsm_state <= 3'b001;
                    else if (dst_clear_req)
                        fsm_state <= 3'b010;
                    else begin
                        // Normal operation
                        if (src_valid_i && dst_ready_i && !full) begin
                            wr_en <= 1'b1;
                            rd_en <= 1'b0;
                            mem_data[wr_ptr] <= src_data_i;
                            full <= 1'b1;
                            empty <= 1'b0;
                        end
                        else if (src_valid_i && dst_ready_i && full) begin
                            wr_en <= 1'b0;
                            rd_en <= 1'b0;
                        end
                        else begin
                            wr_en <= 1'b0;
                            if (rd_en) begin
                                rd_en <= 1'b0;
                                empty <= 1'b1;
                                full <= 1'b0;
                            end
                        end
                    end
                end
                3'b001: begin // Src clear in progress
                    src_clear_pending <= 1'b1;
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                    if (wr_ptr == '0 && rd_ptr == '0) begin
                        src_clear_pending <= 1'b0;
                        fsm_state <= 3'b000;
                    end
                end
                3'b010: begin // Dst clear in progress
                    dst_clear_pending <= 1'b1;
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                    if (wr_ptr == '0 && rd_ptr == '0) begin
                        dst_clear_pending <= 1'b0;
                        fsm_state <= 3'b000;
                    end
                end
                3'b011: begin // Both clear in progress
                    src_clear_pending <= 1'b1;
                    dst_clear_pending <= 1'b1;
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                    if (wr_ptr == '0 && rd_ptr == '0) begin
                        src_clear_pending <= 1'b0;
                        dst_clear_pending <= 1'b0;
                        fsm_state <= 3'b000;
                    end
                end
                default: begin
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                end
            endcase
        end
    end

    // This is getting complex. Let's simplify by using a single process for the FIFO logic
    // and separate processes for the clear logic.

    // Reset the FIFO pointers and data
    reg [LOG_DEPTH-1:0] wr_ptr_reg;
    reg [LOG_DEPTH-1:0] rd_ptr_reg;
    reg [DEPTH-1:0] mem_data_reg;
    reg full_reg;
    reg empty_reg;
    reg src_clear_pending_reg;
    reg dst_clear_pending_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_reg <= '0;
            rd_ptr_reg <= '0;
            mem_data_reg <= '0;
            full_reg <= 1'b0;
            empty_reg <= 1'b1;
            src_clear_pending_reg <= 1'b0;
            dst_clear_pending_reg <= 1'b0;
        end
        else begin
            // Check for clear requests
            if (src_clear_req) begin
                src_clear_pending_reg <= 1'b1;
                wr_en <= 1'b0;
                rd_en <= 1'b0;
                
                // Wait until pointers are at 0
                if (wr_ptr_reg == '0 && rd_ptr_reg == '0)
                    src_clear_pending_reg <= 1'b0;
            end
            else if (dst_clear_req) begin
                dst_clear_pending_reg <= 1'b1;
                wr_en <= 1'b0;
                rd_en <= 1'b0;
                
                // Wait until pointers are at 0
                if (wr_ptr_reg == '0 && rd_ptr_reg == '0)
                    dst_clear_pending_reg <= 1'b0;
            end
            else begin
                // Normal operation
                if (src_valid_i && dst_ready_i && !full_reg) begin
                    wr_en <= 1'b1;
                    rd_en <= 1'b0;
                    mem_data_reg[wr_ptr_reg] <= src_data_i;
                    full_reg <= 1'b1;
                    empty_reg <= 1'b0;
                end
                else if (src_valid_i && dst_ready_i && full_reg) begin
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                end
                else begin
                    wr_en <= 1'b0;
                    
                    if (rd_en) begin
                        rd_en <= 1'b0;
                        empty_reg <= 1'b1;
                        full_reg <= 1'b0;
                    end
                end
            end
        end
    end

    // Update pointers based on clear requests
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_reg <= '0;
            rd_ptr_reg <= '0;
        end
        else begin
            if (src_clear_req || dst_clear_req) begin
                // During clear, we don't update pointers
                // They will be updated when clear is complete
            end
            else begin
                if (wr_en)
                    wr_ptr_reg <= wr_ptr_reg + 1'b1;
                if (rd_en)
                    rd_ptr_reg <= rd_ptr_reg + 1'b1;
            end
        end
    end

    // Generate Gray codes
    reg [SYNC_STAGES-1:0] wr_gray_sync;
    reg [SYNC_STAGES-1:0] rd_gray_sync;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wr_gray_sync <= {SYNC_STAGES{1'b0}};
        else if (wr_en)
            wr_gray_sync <= {wr_gray_sync[SYNC_STAGES-2:0], wr_ptr_reg[SYNC_STAGES-1]};
        else
            wr_gray_sync <= wr_gray_sync;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rd_gray_sync <= {SYNC_STAGES{1'b0}};
        else if (rd_en)
            rd_gray_sync <= {rd_gray_sync[SYNC_STAGES-2:0], rd_ptr_reg[SYNC_STAGES-1]};
        else
            rd_gray_sync <= rd_gray_sync;
    end

    // Full detection in dst domain
    reg full_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            full_sync <= 1'b0;
        else if (wr_gray_sync[SYNC_STAGES-1])
            full_sync <= 1'b1;
        else
            full_sync <= 1'b0;
    end

    // Empty detection in src domain
    reg empty_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            empty_sync <= 1'b1;
        else if (rd_gray_sync[SYNC_STAGES-1])
            empty_sync <= 1'b0;
        else
            empty_sync <= 1'b1;
    end

    // Update full/empty flags based on synchronized signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            full_reg <= 1'b0;
            empty_reg <= 1'b1;
        end
        else begin
            if (src_clear_req || dst_clear_req) begin
                // During clear, we don't update full/empty
            end
            else begin
                full_reg <= full_sync;
                empty_reg <= empty_sync;
            end
        end
    end

    // Output assignments
    assign src_ready_o = !full_reg;
    assign dst_valid_o = empty_reg;
    assign dst_data_o = mem_data_reg[rd_ptr_reg];

    // Clear pending outputs
    assign src_clear_pending_o = src_clear_pending_reg;
    assign dst_clear_pending_o = dst_clear_pending_reg;

endmodule

`timescale 1ns/1ps

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
    localparam GRAY_WIDTH = LOG_DEPTH;

    // Internal signals
    reg [DEPTH-1:0]     mem_data;
    reg [LOG_DEPTH-1:0] wr_ptr;
    reg [LOG_DEPTH-1:0] rd_ptr;
    reg                 wr_en;
    reg                 rd_en;
    reg                 full;
    reg                 empty;
    reg                 src_clear_req;
    reg                 dst_clear_req;
    reg                 src_clear_pending;
    reg                 dst_clear_pending;
    reg                 clear_in_progress;

    // Synchronizers for control signals
    reg [SYNC_STAGES-1:0] src_clear_sync;
    reg [SYNC_STAGES-1:0] dst_clear_sync;

    // Synchronize src_clear_i to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_clear_sync <= {SYNC_STAGES{1'b0}};
        else
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
    end

    // Synchronize dst_clear_i to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_clear_sync <= {SYNC_STAGES{1'b0}};
        else
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end

    // Decode clear requests
    assign src_clear_req = src_clear_sync[SYNC_STAGES-1];
    assign dst_clear_req = dst_clear_sync[SYNC_STAGES-1];

    // Clear in progress flag
    reg src_clear_done;
    reg dst_clear_done;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            mem_data <= '0;
            full <= 1'b0;
            empty <= 1'b1;
            src_clear_done <= 1'b0;
            dst_clear_done <= 1'b0;
            src_clear_pending <= 1'b0;
            dst_clear_pending <= 1'b0;
            wr_en <= 1'b0;
            rd_en <= 1'b0;
        end
        else begin
            // Update clear done flags
            if (src_clear_req && wr_ptr == '0 && rd_ptr == '0)
                src_clear_done <= 1'b1;
            else
                src_clear_done <= 1'b0;

            if (dst_clear_req && wr_ptr == '0 && rd_ptr == '0)
                dst_clear_done <= 1'b1;
            else
                dst_clear_done <= 1'b0;

            // Determine if clear is in progress
            clear_in_progress <= src_clear_req || dst_clear_req;

            // Update clear pending flags
            if (src_clear_req && !src_clear_done)
                src_clear_pending <= 1'b1;
            else if (src_clear_done)
                src_clear_pending <= 1'b0;

            if (dst_clear_req && !dst_clear_done)
                dst_clear_pending <= 1'b1;
            else if (dst_clear_done)
                dst_clear_pending <= 1'b0;

            // During clear, disable normal operations
            if (clear_in_progress) begin
                wr_en <= 1'b0;
                rd_en <= 1'b0;
            end
            else begin
                // Normal FIFO operation
                if (src_valid_i && dst_ready_i && !full) begin
                    wr_en <= 1'b1;
                    rd_en <= 1'b0;
                    mem_data[wr_ptr] <= src_data_i;
                    full <= 1'b1;
                    empty <= 1'b0;
                end
                else if (src_valid_i && dst_ready_i && full) begin
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                end
                else begin
                    wr_en <= 1'b0;
                    
                    if (rd_en) begin
                        rd_en <= 1'b0;
                        empty <= 1'b1;
                        full <= 1'b0;
                    end
                end
            end
        end
    end

    // Update pointers
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end
        else begin
            if (wr_en)
                wr_ptr <= wr_ptr + 1'b1;
            if (rd_en)
                rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Gray code generation for write pointer
    reg [SYNC_STAGES-1:0] wr_gray_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wr_gray_sync <= {SYNC_STAGES{1'b0}};
        else if (wr_en)
            wr_gray_sync <= {wr_gray_sync[SYNC_STAGES-2:0], wr_ptr[SYNC_STAGES-1]};
        else
            wr_gray_sync <= wr_gray_sync;
    end

    // Gray code generation for read pointer
    reg [SYNC_STAGES-1:0] rd_gray_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rd_gray_sync <= {SYNC_STAGES{1'b0}};
        else if (rd_en)
            rd_gray_sync <= {rd_gray_sync[SYNC_STAGES-2:0], rd_ptr[SYNC_STAGES-1]};
        else
            rd_gray_sync <= rd_gray_sync;
    end

    // Full detection in dst domain
    reg full_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            full_sync <= 1'b0;
        else if (wr_gray_sync[SYNC_STAGES-1])
            full_sync <= 1'b1;
        else
            full_sync <= 1'b0;
    end

    // Empty detection in src domain
    reg empty_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            empty_sync <= 1'b1;
        else if (rd_gray_sync[SYNC_STAGES-1])
            empty_sync <= 1'b0;
        else
            empty_sync <= 1'b1;
    end

    // Update full/empty flags based on synchronized signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            full <= 1'b0;
            empty <= 1'b1;
        end
        else begin
            if (clear_in_progress) begin
                // During clear, maintain current state
            end
            else begin
                full <= full_sync;
                empty <= empty_sync;
            end
        end
    end

    // Output assignments
    assign src_ready_o = !full;
    assign dst_valid_o = empty;
    assign dst_data_o = mem_data[rd_ptr];

    // Clear pending outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
