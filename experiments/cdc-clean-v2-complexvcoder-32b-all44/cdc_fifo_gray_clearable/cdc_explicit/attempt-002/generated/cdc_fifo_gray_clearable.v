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
    reg [LOG_DEPTH-1:0] src_wr_ptr_gray;
    reg [LOG_DEPTH-1:0] src_wr_ptr_bin;
    reg [LOG_DEPTH-1:0] dst_rd_ptr_gray;
    reg [LOG_DEPTH-1:0] dst_rd_ptr_bin;
    reg [LOG_DEPTH-1:0] src_wr_ptr_gray_sync;
    reg [LOG_DEPTH-1:0] dst_rd_ptr_gray_sync;
    reg                 src_full;
    reg                 src_empty;
    reg                 dst_full;
    reg                 dst_empty;
    reg                 src_clear_sync;
    reg                 dst_clear_sync;
    reg                 src_clear_pending;
    reg                 dst_clear_pending;
    reg                 src_ready;
    reg                 dst_valid;
    reg                 fifo_wr_en;
    reg                 fifo_rd_en;

    // Synchronize resets
    sync_reset src_sync_reset (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .rst_no(src_rst_no)
    );

    sync_reset dst_sync_reset (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .rst_no(dst_rst_no)
    );

    // Synchronize clear signals
    sync_clear src_sync_clear (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .clear_o(src_clear_sync)
    );

    sync_clear dst_sync_clear (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .clear_o(dst_clear_sync)
    );

    // Generate and synchronize Gray-coded write pointer
    async_gray_counter #(
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_gray_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .enable_i(fifo_wr_en),
        .gray_cnt_o(src_wr_ptr_gray),
        .gray_cnt_sync_o(src_wr_ptr_gray_sync)
    );

    // Generate and synchronize Gray-coded read pointer
    async_gray_counter #(
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_gray_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .enable_i(fifo_rd_en),
        .gray_cnt_o(dst_rd_ptr_gray),
        .gray_cnt_sync_o(dst_rd_ptr_gray_sync)
    );

    // FIFO memory
    fifo_memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_mem (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .wr_en_i(fifo_wr_en),
        .rd_en_i(fifo_rd_en),
        .wr_ptr_i(src_wr_ptr_bin),
        .rd_ptr_i(dst_rd_ptr_bin),
        .data_i(src_data_i),
        .data_o(dst_data_o),
        .valid_o(dst_valid)
    );

    // Convert synchronized Gray-coded pointers to binary
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_bin <= 0;
        end else begin
            src_wr_ptr_bin <= gray_to_bin(src_wr_ptr_gray_sync);
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_bin <= 0;
        end else begin
            dst_rd_ptr_bin <= gray_to_bin(dst_rd_ptr_gray_sync);
        end
    end

    // Determine FIFO full and empty conditions based on binary pointers
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_full <= 0;
            src_empty <= 1;
        end else begin
            src_full <= (src_wr_ptr_bin == (dst_rd_ptr_bin + 1)) && !src_clear_sync;
            src_empty <= (src_wr_ptr_bin == dst_rd_ptr_bin) && !src_clear_sync;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_full <= 0;
            dst_empty <= 1;
        end else begin
            dst_full <= (dst_wr_ptr_bin == (src_rd_ptr_bin + 1)) && !dst_clear_sync;
            dst_empty <= (dst_wr_ptr_bin == src_rd_ptr_bin) && !dst_clear_sync;
        end
    end

    // Handle clear requests
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1;
            end else if (src_empty) begin
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
            end else if (dst_empty) begin
                dst_clear_pending <= 0;
            end
        end
    end

    // Source and destination ready signals
    assign src_ready = !src_full && !src_clear_sync;
    assign src_ready_o = src_ready;

    // FIFO write and read enables
    assign fifo_wr_en = src_valid_i & src_ready;
    assign fifo_rd_en = dst_ready_i & dst_valid;

    // Destination valid signal
    reg [1:0] dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 0;
        end else begin
            dst_valid_reg <= {dst_valid_reg[0], dst_valid};
        end
    end

    assign dst_valid_o = dst_valid_reg[1];

    // Gray to binary conversion function
    function [LOG_DEPTH-1:0] gray_to_bin;
        input [LOG_DEPTH-1:0] gray;
        integer i;
        begin
            gray_to_bin = gray;
            for (i = LOG_DEPTH - 2; i >= 0; i = i - 1) begin
                gray_to_bin[i] = gray_to_bin[i + 1] ^ gray[i];
            end
        end
    endfunction

endmodule

module async_gray_counter #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  enable_i,
    output reg [LOG_DEPTH-1:0] gray_cnt_o,
    output reg [LOG_DEPTH-1:0] gray_cnt_sync_o
);

    reg [LOG_DEPTH-1:0] bin_cnt;
    reg [LOG_DEPTH-1:0] gray_cnt;
    reg [LOG_DEPTH-1:0] gray_cnt_sync [SYNC_STAGES-1:0];

    // Increment binary counter on enable signal
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_cnt <= 0;
        end else if (enable_i) begin
            bin_cnt <= bin_cnt + 1;
        end
    end

    // Convert binary counter to Gray code
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_cnt <= 0;
        end else begin
            gray_cnt <= bin_cnt ^ (bin_cnt >> 1);
        end
    end

    // Synchronize Gray-coded counter to other clock domain using multiple stages
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_cnt_sync[0] <= 0;
        end else begin
            gray_cnt_sync[0] <= gray_cnt;
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    gray_cnt_sync[i] <= 0;
                end else begin
                    gray_cnt_sync[i] <= gray_cnt_sync[i-1];
                end
            end
        end
    endgenerate

    assign gray_cnt_o = gray_cnt;
    assign gray_cnt_sync_o = gray_cnt_sync[SYNC_STAGES-1];

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  wr_en_i,
    input                  rd_en_i,
    input  [LOG_DEPTH-1:0] wr_ptr_i,
    input  [LOG_DEPTH-1:0] rd_ptr_i,
    input  [WIDTH-1:0]     data_i,
    output reg [WIDTH-1:0] data_o,
    output reg             valid_o
);

    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH) - 1];

    // Write data to memory on wr_en_i signal
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            valid_o <= 0;
        end else if (wr_en_i) begin
            mem[wr_ptr_i] <= data_i;
            valid_o <= 1;
        end else if (rd_en_i && (wr_ptr_i == rd_ptr_i)) begin
            valid_o <= 0;
        end
    end

    // Read data from memory on rd_en_i signal
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_o <= 0;
        end else if (rd_en_i) begin
            data_o <= mem[rd_ptr_i];
        end
    end

endmodule

module sync_reset #(
    parameter SYNC_STAGES = 3
)(
    input                  rst_ni,
    input                  clk_i,
    output reg             rst_no
);

    reg [SYNC_STAGES-1:0] rst_sync;

    // Synchronize active-low reset signal to target clock domain using multiple stages
    always @(posedge clk_i) begin
        rst_sync[0] <= rst_ni;
        for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
            rst_sync[i] <= rst_sync[i-1];
        end
    end

    assign rst_no = rst_sync[SYNC_STAGES-1];

endmodule

module sync_clear #(
    parameter SYNC_STAGES = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  clear_i,
    output reg             clear_o
);

    reg [SYNC_STAGES-1:0] clear_sync;

    // Synchronize clear signal to target clock domain using multiple stages
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_sync[0] <= 0;
        end else begin
            clear_sync[0] <= clear_i;
        end
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_sync[1] <= 0;
        end else begin
            clear_sync[1] <= clear_sync[0];
        end
    end

    genvar i;
    generate
        for (i = 2; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    clear_sync[i] <= 0;
                end else begin
                    clear_sync[i] <= clear_sync[i-1];
                end
            end
        end
    endgenerate

    assign clear_o = clear_sync[SYNC_STAGES-1];

endmodule
