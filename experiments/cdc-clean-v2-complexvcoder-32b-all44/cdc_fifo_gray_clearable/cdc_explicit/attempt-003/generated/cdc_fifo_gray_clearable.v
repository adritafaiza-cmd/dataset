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
    reg [LOG_DEPTH-1:0] gray_src;
    reg [LOG_DEPTH-1:0] gray_dst;
    reg [LOG_DEPTH-1:0] gray_dst_sync;
    reg [LOG_DEPTH-1:0] gray_src_sync;
    reg                 src_clear_sync;
    reg                 dst_clear_sync;
    reg                 wr_en;
    reg                 rd_en;
    reg                 full;
    reg                 empty;

    // Gray code counter for source domain
    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    gray_counter_src (
        .clk    (src_clk_i),
        .rst_ni (src_rst_ni),
        .clear_i(src_clear_i),
        .en     (wr_en),
        .gray_o (gray_src)
    );

    // Gray code counter for destination domain
    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    gray_counter_dst (
        .clk    (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .clear_i(dst_clear_i),
        .en     (rd_en),
        .gray_o (gray_dst)
    );

    // Synchronize Gray code from source to destination domain
    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES))
    sync_gray_src2dst (
        .src_clk (src_clk_i),
        .dst_clk (dst_clk_i),
        .src_gray(gray_src),
        .dst_gray(gray_dst_sync)
    );

    // Synchronize Gray code from destination to source domain
    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES))
    sync_gray_dst2src (
        .src_clk (dst_clk_i),
        .dst_clk (src_clk_i),
        .src_gray(gray_dst),
        .dst_gray(gray_src_sync)
    );

    // Synchronize clear signal from source to destination domain
    sync_bit #(.SYNC_STAGES(SYNC_STAGES))
    sync_src_clear (
        .src_clk (src_clk_i),
        .dst_clk (dst_clk_i),
        .src_bit (src_clear_i),
        .dst_bit (src_clear_sync)
    );

    // Synchronize clear signal from destination to source domain
    sync_bit #(.SYNC_STAGES(SYNC_STAGES))
    sync_dst_clear (
        .src_clk (dst_clk_i),
        .dst_clk (src_clk_i),
        .src_bit (dst_clear_i),
        .dst_bit (dst_clear_sync)
    );

    // FIFO memory
    memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH))
    fifo_memory (
        .clk     (src_clk_i),
        .rst_ni  (src_rst_ni),
        .wr_en   (wr_en),
        .wr_addr (gray_src),
        .wr_data (src_data_i),
        .rd_en   (rd_en),
        .rd_addr (gray_dst),
        .rd_data (dst_data_o)
    );

    // Control logic for source side
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b0;
            wr_en       <= 1'b0;
            full        <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_ready_o <= 1'b0;
                wr_en       <= 1'b0;
                full        <= 1'b0;
            end else begin
                wr_en <= src_valid_i & ~full & ~src_clear_sync;
                src_ready_o <= ~full & ~src_clear_sync;
                full <= (gray_src == {LOG_DEPTH{1'b1}}) & (gray_src_sync == {LOG_DEPTH{1'b0}});
            end
        end
    end

    // Control logic for destination side
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
            rd_en       <= 1'b0;
            empty       <= 1'b1;
        end else begin
            if (dst_clear_i) begin
                dst_valid_o <= 1'b0;
                rd_en       <= 1'b0;
                empty       <= 1'b1;
            end else begin
                rd_en <= dst_valid_o & dst_ready_i & ~dst_clear_sync;
                dst_valid_o <= ~empty & ~dst_clear_sync;
                empty <= (gray_dst == gray_dst_sync);
            end
        end
    end

    // Clear pending signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending_o <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending_o <= 1'b1;
            end else if (empty) begin
                src_clear_pending_o <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending_o <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending_o <= 1'b1;
            end else if (empty) begin
                dst_clear_pending_o <= 1'b0;
            end
        end
    end

endmodule

// Gray code counter module
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input  clk,
    input  rst_ni,
    input  clear_i,
    input  en,
    output reg [LOG_DEPTH-1:0] gray_o
);

    reg [LOG_DEPTH-1:0] bin;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            bin <= {LOG_DEPTH{1'b0}};
        end else if (clear_i) begin
            bin <= {LOG_DEPTH{1'b0}};
        end else if (en) begin
            bin <= bin + 1;
        end
    end

    assign gray_o = bin ^ (bin >> 1);

endmodule

// Gray code synchronizer module
module sync_gray #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input  src_clk,
    input  dst_clk,
    input  [LOG_DEPTH-1:0] src_gray,
    output reg [LOG_DEPTH-1:0] dst_gray
);

    reg [LOG_DEPTH-1:0] sync_stage [SYNC_STAGES-1:0];

    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            if (i == 0) begin
                always @(posedge dst_clk) begin
                    sync_stage[i] <= src_gray;
                end
            end else begin
                always @(posedge dst_clk) begin
                    sync_stage[i] <= sync_stage[i-1];
                end
            end
        end
    endgenerate

    assign dst_gray = sync_stage[SYNC_STAGES-1];

endmodule

// Bit synchronizer module
module sync_bit #(
    parameter SYNC_STAGES = 3
)(
    input  src_clk,
    input  dst_clk,
    input  src_bit,
    output reg dst_bit
);

    reg sync_stage [SYNC_STAGES-1:0];

    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            if (i == 0) begin
                always @(posedge dst_clk) begin
                    sync_stage[i] <= src_bit;
                end
            end else begin
                always @(posedge dst_clk) begin
                    sync_stage[i] <= sync_stage[i-1];
                end
            end
        end
    endgenerate

    assign dst_bit = sync_stage[SYNC_STAGES-1];

endmodule

// FIFO memory module
module memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input  clk,
    input  rst_ni,
    input  wr_en,
    input  [LOG_DEPTH-1:0] wr_addr,
    input  [WIDTH-1:0] wr_data,
    input  rd_en,
    input  [LOG_DEPTH-1:0] rd_addr,
    output reg [WIDTH-1:0] rd_data
);

    reg [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_data <= {WIDTH{1'b0}};
        end else begin
            if (rd_en) begin
                rd_data <= mem[rd_addr];
            end
        end
    end

    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

endmodule
