module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 2**LOG_DEPTH;

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [LOG_DEPTH:0] wr_ptr, rd_ptr;
    logic full, empty;

    // Synchronize src_valid_i and src_ready_o across clock domains
    logic src_valid_sync, src_ready_sync;
    cdc_sync #(
        .WIDTH(1)
    ) src_sync_inst (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_data_i(src_valid_i),
        .src_valid_i(src_valid_sync),
        .src_ready_o(src_ready_sync)
    );

    // Synchronize dst_valid_o and dst_ready_i across clock domains
    logic dst_valid_sync, dst_ready_sync;
    cdc_sync #(
        .WIDTH(1)
    ) dst_sync_inst (
        .src_rst_ni(dst_rst_ni),
        .src_clk_i(dst_clk_i),
        .src_data_i(dst_valid_o),
        .src_valid_i(dst_valid_sync),
        .src_ready_o(dst_ready_sync)
    );

    // FIFO logic
    assign src_ready_o = !full;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (src_valid_sync && src_ready_sync && !full) begin
                mem[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == DEPTH-1)
                    wr_ptr <= 0;
                if (empty)
                    empty <= 0;
                full <= (wr_ptr == rd_ptr);
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 0;
        end else begin
            if (dst_valid_sync && dst_ready_i && !empty) begin
                dst_data_o <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == DEPTH-1)
                    rd_ptr <= 0;
                if (rd_ptr == wr_ptr)
                    empty <= 1;
                if (full)
                    full <= 0;
                dst_valid_o <= 1;
            end else begin
                dst_valid_o <= 0;
            end
        end
    end

endmodule

module cdc_sync #(
    parameter WIDTH = 8
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o
);

    logic [WIDTH-1:0] sync_reg;
    logic sync_valid;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_reg <= 0;
            sync_valid <= 0;
        end else begin
            if (src_valid_i) begin
                sync_reg <= src_data_i;
                sync_valid <= 1;
            end else begin
                sync_valid <= 0;
            end
        end
    end

    assign src_ready_o = sync_valid;

endmodule
