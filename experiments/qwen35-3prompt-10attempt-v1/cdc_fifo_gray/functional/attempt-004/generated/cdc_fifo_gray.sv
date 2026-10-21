```verilog
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
    output reg [WIDTH-1:0] dst_data_o,
    output reg             dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam GRAY_WIDTH = $clog2(DEPTH);

    // Internal registers for source domain
    reg [DEPTH-1:0] src_ptr;
    reg [DEPTH-1:0] src_full;
    reg [DEPTH-1:0] src_gray_ptr;
    reg [DEPTH-1:0] src_gray_next;
    reg [DEPTH-1:0] src_data_reg;
    reg src_valid_reg;
    reg src_ready_reg;

    // Internal registers for destination domain
    reg [DEPTH-1:0] dst_ptr;
    reg [DEPTH-1:0] dst_empty;
    reg [DEPTH-1:0] dst_gray_ptr;
    reg [DEPTH-1:0] dst_gray_next;
    reg [DEPTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_ready_reg;

    // Synchronizer for src_valid_i
    reg [SYNC_STAGES-1:0] src_valid_sync;
    reg [SYNC_STAGES-1:0] src_valid_sync_d;

    // Synchronizer for dst_ready_i
    reg [SYNC_STAGES-1:0] dst_ready_sync;
    reg [SYNC_STAGES-1:0] dst_ready_sync_d;

    // Synchronizer for src_rst_ni (active low)
    reg [SYNC_STAGES-1:0] src_rst_sync;
    reg [SYNC_STAGES-1:0] src_rst_sync_d;

    // Synchronizer for dst_rst_ni (active low)
    reg [SYNC_STAGES-1:0] dst_rst_sync;
    reg [SYNC_STAGES-1:0] dst_rst_sync_d;

    // ---------------------------------------------------------
    // Source Domain Logic
    // ---------------------------------------------------------
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_full <= 0;
            src_gray_ptr <= 0;
            src_gray_next <= 0;
            src_data_reg <= 0;
            src_valid_reg <= 0;
            src_ready_reg <= 1;
        end else begin
            // Synchronize reset
            if (src_rst_sync_d[0]) begin
                src_ptr <= 0;
                src_full <= 0;
                src_gray_ptr <= 0;
                src_gray_next <= 0;
                src_data_reg <= 0;
                src_valid_reg <= 0;
                src_ready_reg <= 1;
            end else begin
                // Update valid state
                src_valid_reg <= src_valid_i;
                
                // Calculate next pointer (binary)
                src_ptr <= src_ptr + src_valid_reg;
                
                // Calculate full condition
                src_full <= (src_ptr == (DEPTH - 1)) ? 1 : 0;
                
                // Calculate next gray pointer
                src_gray_next <= src_gray_ptr ^ (src_gray_ptr >> 1);
                
                // Update gray pointer if valid
                if (src_valid_reg) begin
                    src_gray_ptr <= src_gray_next;
                end
                
                // Ready logic: not full and valid
                src_ready_reg <= (!src_full && src_valid_reg);
            end
        end
    end

    // ---------------------------------------------------------
    // Destination Domain Logic
    // ---------------------------------------------------------
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_empty <= 1;
            dst_gray_ptr <= 0;
            dst_gray_next <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
            dst_ready_reg <= 1;
        end else begin
            // Synchronize reset
            if (dst_rst_sync_d[0]) begin
                dst_ptr <= 0;
                dst_empty <= 1;
                dst_gray_ptr <= 0;
                dst_gray_next <= 0;
                dst_data_reg <= 0;
                dst_valid_reg <= 0;
                dst_ready_reg <= 1;
            end else begin
                // Update ready state
                dst_ready_reg <= dst_ready_i;
                
                // Update data and valid if ready and not empty
                if (dst_ready_reg && !dst_empty) begin
                    dst_data_reg <= dst_data_reg; // Hold current data
                    dst_valid_reg <= 1;
                    dst_ptr <= dst_ptr + 1;
                    
                    // Calculate next gray pointer
                    dst_gray_next <= dst_gray_ptr ^ (dst_gray_ptr >> 1);
                    
                    // Update gray pointer if valid
                    if (dst_valid_reg) begin
                        dst_gray_ptr <= dst_gray_next;
                    end
                    
                    // Update empty condition
                    dst_empty <= (dst_ptr == 0) ? 1 : 0;
                end else begin
                    dst_valid_reg <= 0;
                end
            end
        end
    end

    // ---------------------------------------------------------
    // Cross-Domain Synchronization
    // ---------------------------------------------------------
    // Source Valid Synchronizer
    always @(posedge src_clk_i) begin
        if (src_rst_ni) begin
            src_valid_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_i};
        end
    end
    always @(posedge src_clk_i) begin
        if (src_rst_ni) begin
            src_valid_sync_d <= {SYNC_STAGES{1'b0}};
        end else begin
            src_valid_sync_d <= {src_valid_sync_d[SYNC_STAGES-2:0], src_valid_sync[SYNC_STAGES-1]};
        end
    end

    // Destination Ready Synchronizer
    always @(posedge dst_clk_i) begin
        if (dst_rst_ni) begin
            dst_ready_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_i};
        end
    end
    always @(posedge dst_clk_i) begin
        if (dst_rst_ni) begin
            dst_ready_sync_d <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_ready_sync_d <= {dst_ready_sync_d[SYNC_STAGES-2:0], dst_ready_sync[SYNC_STAGES-1]};
        end
    end

    // Reset Synchronizers
    always @(posedge src_clk_i) begin
        if (src_rst_ni) begin
            src_rst_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_rst_sync <= {src_rst_sync[SYNC_STAGES-2:0], !src_rst_ni};
        end
    end
    always @(posedge src_clk_i) begin
        if (src_rst_ni) begin
            src_rst_sync_d <= {SYNC_STAGES{1'b0}};
        end else begin
            src_rst_sync_d <= {src_rst_sync_d[SYNC_STAGES-2:0], src_rst_sync[SYNC_STAGES-1]};
        end
    end

    always @(posedge dst_clk_i) begin
        if (dst_rst_ni) begin
            dst_rst_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_rst_sync <= {dst_rst_sync[SYNC_STAGES-2:0], !dst_rst_ni};
        end
    end
    always @(posedge dst_clk_i) begin
        if (dst_rst_ni) begin
            dst_rst_sync_d <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_rst_sync_d <= {dst_rst_sync_d[SYNC_STAGES-2:0], dst_rst_sync[SYNC_STAGES-1]};
        end
    end

    // ---------------------------------------------------------
    // Output Assignment
    // ---------------------------------------------------------
    // Source Ready: Valid if not full and source valid is synchronized
    assign src_ready_o = src_ready_reg && src_valid_sync_d[0];

    // Destination Data and Valid: Use gray pointer to read data
    // The gray pointer is used to index into the FIFO data
    // Since we are using a simple FIFO, we need to map gray pointer to binary pointer
    // However, for simplicity and correctness in this implementation,
    // we will use the binary pointer to read the data from the FIFO memory
    // and then convert the binary pointer to gray for the output valid signal
    
    // Note: In a real implementation, the FIFO data would be stored in a memory array.
    // Here, we simulate the FIFO behavior by storing the data in a register array.
    reg [WIDTH-1:0] fifo_data [0:DEPTH-1];
    reg [DEPTH-1:0] write_ptr;
    reg [DEPTH-1:0] read_ptr;
    reg [DEPTH-1:0] write_gray;
    reg [DEPTH-1:0] read_gray;
    reg [DEPTH-1:0] write_gray_next;
    reg [DEPTH-1:0] read_gray_next;
    reg [DEPTH-1:0] write_ptr_gray;
    reg [DEPTH-1:0] read_ptr_gray;
    reg [DEPTH-1:0] write_ptr_gray_next;
    reg [DEPTH-1:0] read_ptr_gray_next;
    reg [DEPTH-1:0] write_ptr_gray_d;
    reg [DEPTH-1:0] read_ptr_gray_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] write_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d;
    reg [DEPTH-1:0] read_ptr_gray_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d_d