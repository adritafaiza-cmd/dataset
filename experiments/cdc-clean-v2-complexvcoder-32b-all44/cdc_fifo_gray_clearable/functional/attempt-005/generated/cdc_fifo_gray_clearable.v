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
    reg [LOG_DEPTH:0]      src_ptr;
    reg [LOG_DEPTH:0]      dst_ptr;
    reg [LOG_DEPTH:0]      gray_src_ptr;
    reg [LOG_DEPTH:0]      gray_dst_ptr;
    reg [LOG_DEPTH:0]      sync_gray_src_ptr;
    reg [LOG_DEPTH:0]      sync_gray_dst_ptr;
    reg [WIDTH-1:0]        fifo_mem [0:(1<<LOG_DEPTH)-1];
    reg                    src_clear_reg;
    reg                    dst_clear_reg;
    reg                    src_clear_pending;
    reg                    dst_clear_pending;
    reg                    src_ready;
    reg                    dst_valid;
    reg [LOG_DEPTH:0]      src_gray_ptr_next;
    reg [LOG_DEPTH:0]      dst_gray_ptr_next;
    reg [LOG_DEPTH:0]      src_ptr_next;
    reg [LOG_DEPTH:0]      dst_ptr_next;
    reg [LOG_DEPTH:0]      src_ptr_gray_sync;
    reg [LOG_DEPTH:0]      dst_ptr_gray_sync;
    reg [LOG_DEPTH:0]      src_ptr_gray_sync_reg;
    reg [LOG_DEPTH:0]      dst_ptr_gray_sync_reg;
    reg [LOG_DEPTH:0]      src_ptr_gray_sync_reg_reg;
    reg [LOG_DEPTH:0]      dst_ptr_gray_sync_reg_reg;
    reg [LOG_DEPTH:0]      src_ptr_gray_sync_reg_reg_reg;
    reg [LOG_DEPTH:0]      dst_ptr_gray_sync_reg_reg_reg;
    reg [LOG_DEPTH:0]      gray_src_ptr_sync;
    reg [LOG_DEPTH:0]      gray_dst_ptr_sync;

    // Gray code conversion
    function [LOG_DEPTH:0] bin2gray;
        input [LOG_DEPTH:0] bin;
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    function [LOG_DEPTH:0] gray2bin;
        input [LOG_DEPTH:0] gray;
        integer i;
        reg [LOG_DEPTH:0] bin;
        bin = gray;
        for (i = LOG_DEPTH-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        return bin;
    endfunction

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            gray_src_ptr <= 0;
            src_clear_reg <= 0;
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                src_ptr <= 0;
                gray_src_ptr <= 0;
                src_clear_reg <= 1;
                src_clear_pending <= 1;
            end else if (src_clear_reg && !src_clear_pending) begin
                src_clear_reg <= 0;
            end else if (src_ready && src_valid_i) begin
                fifo_mem[src_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_ptr <= src_ptr_next;
                gray_src_ptr <= src_gray_ptr_next;
            end
        end
    end

    always @(*) begin
        src_ptr_next = src_ptr + 1;
        src_gray_ptr_next = bin2gray(src_ptr_next);
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready <= 1;
        end else begin
            if (src_clear_i) begin
                src_ready <= 0;
            end else if (src_clear_reg) begin
                src_ready <= 0;
            end else begin
                src_ready <= (gray_src_ptr_next != sync_gray_dst_ptr);
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending_o <= 0;
        end else begin
            src_clear_pending_o <= src_clear_pending;
            if (src_clear_reg && !src_clear_pending) begin
                src_clear_pending <= 0;
            end
        end
    end

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            gray_dst_ptr <= 0;
            dst_clear_reg <= 0;
            dst_clear_pending <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_ptr <= 0;
                gray_dst_ptr <= 0;
                dst_clear_reg <= 1;
                dst_clear_pending <= 1;
            end else if (dst_clear_reg && !dst_clear_pending) begin
                dst_clear_reg <= 0;
            end else if (dst_valid && dst_ready_i) begin
                dst_ptr <= dst_ptr_next;
                gray_dst_ptr <= dst_gray_ptr_next;
            end
        end
    end

    always @(*) begin
        dst_ptr_next = dst_ptr + 1;
        dst_gray_ptr_next = bin2gray(dst_ptr_next);
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid <= 0;
            dst_data_o <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_valid <= 0;
                dst_data_o <= 0;
            end else if (dst_clear_reg) begin
                dst_valid <= 0;
                dst_data_o <= 0;
            end else if (sync_gray_src_ptr != gray_dst_ptr) begin
                dst_valid <= 1;
                dst_data_o <= fifo_mem[dst_ptr[LOG_DEPTH-1:0]];
            end else begin
                dst_valid <= 0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending_o <= 0;
        end else begin
            dst_clear_pending_o <= dst_clear_pending;
            if (dst_clear_reg && !dst_clear_pending) begin
                dst_clear_pending <= 0;
            end
        end
    end

    // Synchronization logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_gray_dst_ptr <= 0;
        end else begin
            sync_gray_dst_ptr <= gray_dst_ptr_sync;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            gray_dst_ptr_sync <= 0;
            dst_ptr_gray_sync_reg <= 0;
            dst_ptr_gray_sync_reg_reg <= 0;
            dst_ptr_gray_sync_reg_reg_reg <= 0;
        end else begin
            gray_dst_ptr_sync <= gray_dst_ptr;
            dst_ptr_gray_sync_reg <= gray_dst_ptr_sync;
            dst_ptr_gray_sync_reg_reg <= dst_ptr_gray_sync_reg;
            dst_ptr_gray_sync_reg_reg_reg <= dst_ptr_gray_sync_reg_reg;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_gray_src_ptr <= 0;
        end else begin
            sync_gray_src_ptr <= gray_src_ptr_sync;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            gray_src_ptr_sync <= 0;
            src_ptr_gray_sync_reg <= 0;
            src_ptr_gray_sync_reg_reg <= 0;
            src_ptr_gray_sync_reg_reg_reg <= 0;
        end else begin
            gray_src_ptr_sync <= gray_src_ptr;
            src_ptr_gray_sync_reg <= gray_src_ptr_sync;
            src_ptr_gray_sync_reg_reg <= src_ptr_gray_sync_reg;
            src_ptr_gray_sync_reg_reg_reg <= src_ptr_gray_sync_reg_reg;
        end
    end

endmodule
