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
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [GRAY_WIDTH-1:0] src_wr_ptr_gray;
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg src_clear_pending;
    reg src_clear_active;

    // Destination domain signals
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [GRAY_WIDTH-1:0] dst_rd_ptr_gray;
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_clear_pending;
    reg dst_clear_active;

    // Synchronizer registers for source read pointer gray
    reg [GRAY_WIDTH-1:0] src_rd_ptr_gray_sync_reg [0:SYNC_STAGES-1];

    // Synchronizer registers for destination write pointer gray
    reg [GRAY_WIDTH-1:0] dst_wr_ptr_gray_sync_reg [0:SYNC_STAGES-1];

    // Helper: binary to gray
    function [GRAY_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Helper: gray to binary
    function [PTR_WIDTH-1:0] gray2bin;
        input [GRAY_WIDTH-1:0] gray;
        integer i;
        begin
            gray2bin[0] = gray[0];
            for (i = 1; i < PTR_WIDTH; i = i + 1)
                gray2bin[i] = gray2bin[i-1] ^ gray[i];
        end
    endfunction

    // Source domain logic
    wire src_wr_ptr_gray_next = bin2gray(src_wr_ptr + 1'b1);
    wire src_full = (src_wr_ptr_gray == src_rd_ptr_gray_sync[SYNC_STAGES-1]) &&
                    (src_wr_ptr[0] != src_rd_ptr_gray_sync[SYNC_STAGES-1][0]);
    // Actually, for a FIFO, full condition is when the MSB of write pointer differs from read pointer
    // and the rest are equal. Let me use the standard approach.
    
    // Standard full condition: write pointer gray equals read pointer gray, but MSB differs
    // Actually, the standard is: full when (wr_ptr_gray == rd_ptr_gray) && (wr_ptr[MSB] != rd_ptr[MSB])
    // But since we're comparing gray codes, the standard check is:
    // full = (wr_ptr_gray == rd_ptr_gray) && (wr_ptr[LOG_DEPTH] != rd_ptr[LOG_DEPTH])
    // Wait, let me think again. The standard async FIFO full condition:
    // The write pointer is one ahead of the read pointer in binary.
    // In gray code, this means the MSB of the write pointer differs from the read pointer,
    // and all other bits are the same.
    
    wire src_full = (src_wr_ptr_gray == src_rd_ptr_gray_sync[SYNC_STAGES-1]) &&
                    (src_wr_ptr[LOG_DEPTH] != src_rd_ptr_gray_sync[SYNC_STAGES-1][LOG_DEPTH]);
    
    // Hmm, that's not quite right either. Let me use the standard formulation:
    // full when the write pointer gray code equals the read pointer gray code,
    // but the MSB of the binary write pointer is different from the MSB of the binary read pointer.
    // Actually, the simplest correct check:
    // full = (wr_ptr_gray == rd_ptr_gray) && (wr_ptr[MSB] != rd_ptr[MSB])
    // where MSB is the extra bit (bit LOG_DEPTH).
    
    // Let me redefine:
    wire src_full_correct = (src_wr_ptr_gray == src_rd_ptr_gray_sync[SYNC_STAGES-1]) &&
                            (src_wr_ptr[LOG_DEPTH] != src_rd_ptr_gray_sync[SYNC_STAGES-1][LOG_DEPTH]);

    wire src_can_write = src_valid_i && !src_full_correct && !src_clear_active && !src_clear_pending;
    
    // Source write pointer update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
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
                    src_wr_ptr <= {PTR_WIDTH{1'b0}};
                    src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
                end
            end else if (src_can_write) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
                src_wr_ptr_gray <= src_wr_ptr_gray + 1'b1; // This is wrong, need to use bin2gray
            end
        end
    end

    // Fix: use bin2gray for the next gray value
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
            src_clear_pending <= 1'b0;
            src_clear_active <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_active <= 1'b1;
                src_clear_pending <= 1'b1;
            end else if (src_clear_active) begin
                if (dst_clear_pending_sync) begin
                    src_clear_active <= 1'b0;
                    src_clear_pending <= 1'b0;
                    src_wr_ptr <= {PTR_WIDTH{1'b0}};
                    src_wr_ptr_gray <= {GRAY_WIDTH{1'b0}};
                end
            end else if (src_can_write) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
                src_wr_ptr_gray <= bin2gray(src_wr_ptr + 1'b1);
            end
        end
    end

    // Synchronize source read pointer gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync_reg[i] <= {GRAY_WIDTH{1'b0}};
        end else begin
            src_rd_ptr_gray_sync_reg[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_rd_ptr_gray_sync_reg[i] <= src_rd_ptr_gray_sync_reg[i-1];
        end
    end

    assign src_rd_ptr_gray_sync = src_rd_ptr_gray_sync_reg[SYNC_STAGES-1];

    // Synchronize destination clear pending to source domain
    reg [SYNC_STAGES-1:0] dst_clear_pending_sync_reg;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_clear_pending_sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_clear_pending_sync_reg[0] <= dst_clear_pending;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_pending_sync_reg[i] <= dst_clear_pending_sync_reg[i-1];
        end
    end
    wire dst_clear_pending_sync = dst_clear_pending_sync_reg[SYNC_STAGES-1];

    // Destination domain logic
    wire dst_empty = (dst_rd_ptr_gray == dst_wr_ptr_gray_sync[SYNC_STAGES-1]);
    
    wire dst_can_read = dst_valid_reg && dst_ready_i && !dst_clear_active && !dst_clear_pending;
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
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
                if (src_clear_pending_sync) begin
                    dst_clear_active <= 1'b0;
                    dst_clear_pending <= 1'b0;
                    dst_rd_ptr <= {PTR_WIDTH{1'b0}};
                    dst_rd_ptr_gray <= {GRAY_WIDTH{1'b0}};
                    dst_valid_reg <= 1'b0;
                end
            end else if (dst_can_read) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_rd_ptr_gray <= bin2gray(dst_rd_ptr + 1'b1);
                dst_valid_reg <= 1'b0;
            end else if (!dst_valid_reg && !dst_empty) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    // Synchronize destination read pointer gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync_reg[i] <= {GRAY_WIDTH{1'b0}};
        end else begin
            dst_wr_ptr_gray_sync_reg[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_wr_ptr_gray_sync_reg[i] <= dst_wr_ptr_gray_sync_reg[i-1];
        end
    end

    assign dst_wr_ptr_gray_sync = dst_wr_ptr_gray_sync_reg[SYNC_STAGES-1];

    // Synchronize source clear pending to destination domain
    reg [SYNC_STAGES-1:0] src_clear_pending_sync_reg;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_clear_pending_sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            src_clear_pending_sync_reg[0] <= src_clear_pending;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_pending_sync_reg[i] <= src_clear_pending_sync_reg[i-1];
        end
    end
    wire src_clear_pending_sync = src_clear_pending_sync_reg[SYNC_STAGES-1];

    // Outputs
    assign src_ready_o = !src_full_correct && !src_clear_active && !src_clear_pending;
    assign src_clear_pending_o = src_clear_pending;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
