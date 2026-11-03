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
    wire [LOG_DEPTH:0] wr_ptr_gray_o;
    wire [LOG_DEPTH:0] rd_ptr_gray_i;

    // Instantiate the Gray code synchronizer for the write pointer
    gray_sync_counter #(
        .WIDTH(LOG_DEPTH + 1),
        .SYNC_STAGES(SYNC_STAGES)
    ) gray_sync_counter_inst_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .gray_code_o(wr_ptr_gray_o)
    );

    // Instantiate the Gray code synchronizer for the read pointer
    gray_sync_counter #(
        .WIDTH(LOG_DEPTH + 1),
        .SYNC_STAGES(SYNC_STAGES)
    ) gray_sync_counter_inst_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .gray_code_i(rd_ptr_gray_i)
    );

    // Instantiate the FIFO memory
    fifo_memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_memory_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .wr_ptr_i(wr_ptr_gray_o),
        .data_i(src_data_i),
        .wr_en_i(src_valid_i),
        .clk_o(dst_clk_i),
        .rd_ptr_i(rd_ptr_gray_i),
        .rd_en_i(dst_ready_i),
        .data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .src_ready_o(src_ready_o),
        .src_clear_pending_o(src_clear_pending_o),
        .dst_clear_pending_o(dst_clear_pending_o)
    );

endmodule

// Gray code synchronizer module
module gray_sync_counter #(
    parameter WIDTH = 4,
    parameter SYNC_STAGES = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output reg [WIDTH-1:0] gray_code_o
);

    reg [WIDTH-1:0] gray_code_sync [SYNC_STAGES-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_code_o <= 0;
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                gray_code_sync[i] <= 0;
            end
        end else if (clear_i) begin
            gray_code_o <= 0;
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                gray_code_sync[i] <= 0;
            end
        end else begin
            // Binary to Gray conversion
            gray_code_sync[0] <= {gray_code_sync[0][WIDTH-2:0], gray_code_sync[0][WIDTH-1] ^ gray_code_sync[0][WIDTH-2]};
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                gray_code_sync[i] <= gray_code_sync[i-1];
            end
            gray_code_o <= gray_code_sync[SYNC_STAGES-1];
        end
    end

endmodule

// FIFO memory module
module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [LOG_DEPTH:0] wr_ptr_i,
    input  [WIDTH-1:0]     data_i,
    input                  wr_en_i,
    input                  clk_o,
    input  [LOG_DEPTH:0] rd_ptr_i,
    input                  rd_en_i,
    output [WIDTH-1:0]     data_o,
    output                 dst_valid_o,
    output                 src_ready_o,
    output                 src_clear_pending_o,
    output                 dst_clear_pending_o
);

    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH) - 1];
    reg [LOG_DEPTH:0] wr_ptr_bin;
    reg [LOG_DEPTH:0] rd_ptr_bin;
    reg [LOG_DEPTH:0] wr_ptr_gray_sync;
    reg [LOG_DEPTH:0] rd_ptr_gray_sync;
    reg                 clear_src_pending;
    reg                 clear_dst_pending;

    // Write pointer logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr_bin <= 0;
            clear_src_pending <= 0;
        end else if (wr_en_i && !clear_src_pending) begin
            wr_ptr_bin <= wr_ptr_bin + 1;
        end else if (clear_src_pending) begin
            wr_ptr_bin <= 0;
        end
    end

    // Binary to Gray conversion for write pointer
    assign wr_ptr_gray_sync = {wr_ptr_gray_sync[LOG_DEPTH-1:0], wr_ptr_bin[LOG_DEPTH] ^ wr_ptr_bin[LOG_DEPTH-1]};

    // Read pointer logic
    always @(posedge clk_o or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_ptr_bin <= 0;
            clear_dst_pending <= 0;
        end else if (rd_en_i && dst_valid_o && !clear_dst_pending) begin
            rd_ptr_bin <= rd_ptr_bin + 1;
        end else if (clear_dst_pending) begin
            rd_ptr_bin <= 0;
        end
    end

    // Binary to Gray conversion for read pointer
    assign rd_ptr_gray_sync = {rd_ptr_gray_sync[LOG_DEPTH-1:0], rd_ptr_bin[LOG_DEPTH] ^ rd_ptr_bin[LOG_DEPTH-1]};

    // Memory write
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < (1 << LOG_DEPTH); i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (wr_en_i && !clear_src_pending) begin
            mem[wr_ptr_bin[LOG_DEPTH-1:0]] <= data_i;
        end
    end

    // Memory read
    always @(posedge clk_o or negedge rst_ni) begin
        if (!rst_ni) begin
            data_o <= 0;
        end else if (rd_en_i && dst_valid_o && !clear_dst_pending) begin
            data_o <= mem[rd_ptr_bin[LOG_DEPTH-1:0]];
        end
    end

    // Source ready
    assign src_ready_o = (wr_ptr_gray_sync != {wr_ptr_gray_sync[LOG_DEPTH-1:0], ~wr_ptr_gray_sync[LOG_DEPTH]});

    // Destination valid
    assign dst_valid_o = (rd_ptr_gray_sync != {rd_ptr_gray_sync[LOG_DEPTH-1:0], ~rd_ptr_gray_sync[LOG_DEPTH]});

    // Clear pending outputs
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_src_pending <= 0;
        end else begin
            clear_src_pending <= src_clear_i;
        end
    end

    always @(posedge clk_o or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_dst_pending <= 0;
        end else begin
            clear_dst_pending <= dst_clear_i;
        end
    end

    assign src_clear_pending_o = clear_src_pending;
    assign dst_clear_pending_o = clear_dst_pending;

endmodule
