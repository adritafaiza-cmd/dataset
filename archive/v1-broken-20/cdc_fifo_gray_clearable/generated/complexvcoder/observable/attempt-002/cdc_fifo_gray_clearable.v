module sync_register #(
    parameter WIDTH = 8
)(
    input                  rst_ni,
    input                  clk_i,
    input                  clear_i,
    input                  valid_i,
    input  [WIDTH-1:0]     data_i,
    output                 ready_o,
    output                 src_clear_pending_o,
    output                 dst_clear_pending_o
);
    reg [WIDTH-1:0] data_reg;
    reg valid_reg;
    reg clear_reg;
    reg ready_reg;
    reg clear_pending;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_reg <= 0;
            valid_reg <= 0;
            clear_reg <= 0;
            ready_reg <= 0;
            clear_pending <= 0;
        end else begin
            if (clear_i) begin
                clear_pending <= 1;
                data_reg <= 0;
                valid_reg <= 0;
            end else if (ready_o && valid_i) begin
                data_reg <= data_i;
                valid_reg <= 1;
                clear_pending <= 0;
            end else if (ready_o) begin
                valid_reg <= 0;
                clear_pending <= 0;
            end
        end
    end

    assign src_clear_pending_o = clear_pending;
    assign dst_clear_pending_o = clear_pending;
    assign ready_o = !clear_pending;
endmodule

module fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    input                  src_valid_i,
    input  [WIDTH-1:0]     src_data_i,
    output                 src_ready_o,
    output                 dst_valid_o,
    output [WIDTH-1:0]     dst_data_o,
    input                  dst_ready_i
);
    reg [WIDTH-1:0] mem [0:((1<<LOG_DEPTH)-1)];
    reg [LOG_DEPTH-1:0] wr_ptr;
    reg [LOG_DEPTH-1:0] rd_ptr;
    reg full;
    reg empty;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (clear_i) begin
                wr_ptr <= 0;
                rd_ptr <= 0;
                full <= 0;
                empty <= 1;
            end else if (!full && src_valid_i && dst_ready_i) begin
                mem[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                full <= wr_ptr == rd_ptr;
                empty <= 0;
            end else if (!empty && dst_ready_i) begin
                rd_ptr <= rd_ptr + 1;
                full <= 0;
                empty <= rd_ptr == wr_ptr;
            end
        end
    end

    assign src_ready_o = !full;
    assign dst_valid_o = !empty;
    assign dst_data_o = mem[rd_ptr];
endmodule

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
    sync_register src_sync (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .valid_i(src_valid_i),
        .data_i(src_data_i),
        .ready_o(src_ready_o),
        .src_clear_pending_o(src_clear_pending_o),
        .dst_clear_pending_o(src_clear_pending_o)
    );

    sync_register dst_sync (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .valid_i(dst_valid_o),
        .data_i(dst_data_o),
        .ready_o(dst_ready_i),
        .src_clear_pending_o(dst_clear_pending_o),
        .dst_clear_pending_o(dst_clear_pending_o)
    );

    fifo_gray fifo (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_pending_o | dst_clear_pending_o),
        .src_valid_i(src_sync.valid_o),
        .src_data_i(src_sync.data_o),
        .ready_o(src_sync.ready_o),
        .dst_valid_o(dst_sync.valid_o),
        .dst_data_o(dst_sync.data_o),
        .dst_ready_i(dst_ready_i)
    );
endmodule
