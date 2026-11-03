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
    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;
    localparam DATA_WIDTH = WIDTH;

    logic [ADDR_WIDTH-1:0] src_write_address;
    logic [ADDR_WIDTH-1:0] src_read_address;
    logic [ADDR_WIDTH-1:0] dst_write_address;
    logic [ADDR_WIDTH-1:0] dst_read_address;
    logic [DATA_WIDTH-1:0] src_fifo [0:DEPTH-1];
    logic [DATA_WIDTH-1:0] dst_fifo [0:DEPTH-1];
    logic src_fifo_full;
    logic src_fifo_empty;
    logic dst_fifo_full;
    logic dst_fifo_empty;

    // Gray counter for source clock domain
    gray_counter #(
        .WIDTH(ADDR_WIDTH)
    ) src_gray_cnt (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .count_o(src_write_address)
    );

    // Gray counter for destination clock domain
    gray_counter #(
        .WIDTH(ADDR_WIDTH)
    ) dst_gray_cnt (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .count_o(dst_write_address)
    );

    // Source FIFO
    fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) src_fifo_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_o),
        .full_o(src_fifo_full),
        .empty_o(src_fifo_empty)
    );

    // Destination FIFO
    fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dst_fifo_inst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .data_i(dst_fifo[dst_read_address]),
        .valid_i(dst_fifo_valid),
        .ready_o(dst_ready_i),
        .full_o(dst_fifo_full),
        .empty_o(dst_fifo_empty)
    );

    // Synchronous FIFO between source and destination clock domains
    sync_fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_fifo_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_fifo[src_read_address]),
        .valid_i(src_fifo_valid),
        .ready_o(src_fifo_ready),
        .clk_o(dst_clk_i),
        .rst_o(dst_rst_ni),
        .data_o(dst_fifo[dst_write_address]),
        .valid_o(dst_fifo_valid),
        .ready_i(dst_fifo_ready)
    );

    // Assignments
    assign src_clear_pending_o = src_fifo_full;
    assign dst_clear_pending_o = dst_fifo_empty;

    // Gray counter outputs
    assign src_gray_cnt_count_o = src_write_address;
    assign dst_gray_cnt_count_o = dst_write_address;

    // FIFO read address logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_read_address <= 0;
        end else begin
            if (src_fifo_valid && src_ready_o) begin
                src_read_address <= src_read_address + 1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_read_address <= 0;
        end else begin
            if (dst_fifo_valid && dst_ready_i) begin
                dst_read_address <= dst_read_address + 1;
            end
        end
    end

endmodule

module gray_counter #(
    parameter WIDTH
)(
    input clk_i,
    input rst_ni,
    input clear_i,
    output reg [WIDTH-1:0] count_o
);

    reg [WIDTH-1:0] count_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_q <= 0;
        end else if (clear_i) begin
            count_q <= 0;
        end else begin
            count_q <= count_q ^ {count_q[0], count_q[WIDTH-2:1]};
        end
    end

    assign count_o = count_q;

endmodule

module fifo #(
    parameter WIDTH,
    parameter DEPTH
)(
    input clk_i,
    input rst_ni,
    input clear_i,
    input [WIDTH-1:0] data_i,
    input valid_i,
    output reg [WIDTH-1:0] data_o,
    output reg valid_o,
    input ready_o,
    output reg full_o,
    output reg empty_o
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [DEPTH-1:0] write_pointer;
    reg [DEPTH-1:0] read_pointer;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            write_pointer <= 0;
            read_pointer <= 0;
            full_o <= 0;
            empty_o <= 1;
        end else if (clear_i) begin
            write_pointer <= 0;
            read_pointer <= 0;
            full_o <= 0;
            empty_o <= 1;
        end else if (valid_i && ready_o && !full_o) begin
            mem[write_pointer] <= data_i;
            write_pointer <= write_pointer + 1;
            if (write_pointer == DEPTH-1) begin
                write_pointer <= 0;
            end
            full_o <= write_pointer == read_pointer;
            empty_o <= 0;
        end else if (!ready_o) begin
            full_o <= write_pointer == read_pointer;
            empty_o <= 0;
        end else if (full_o) begin
            read_pointer <= read_pointer + 1;
            if (read_pointer == DEPTH-1) begin
                read_pointer <= 0;
            end
            full_o <= 0;
            empty_o <= 0;
        end else if (empty_o) begin
            read_pointer <= read_pointer + 1;
            if (read_pointer == DEPTH-1) begin
                read_pointer <= 0;
            end
            full_o <= 0;
            empty_o <= 0;
        end
    end

    assign data_o = mem[read_pointer];
    assign valid_o = !empty_o;

endmodule

module sync_fifo #(
    parameter WIDTH,
    parameter DEPTH,
    parameter SYNC_STAGES
)(
    input clk_i,
    input rst_ni,
    input [WIDTH-1:0] data_i,
    input valid_i,
    input ready_o,
    input clk_o,
    input rst_o,
    output reg [WIDTH-1:0] data_o,
    output reg valid_o,
    input ready_i
);

    wire [WIDTH-1:0] data_sync [0:SYNC_STAGES-1];
    wire [WIDTH-1:0] valid_sync [0:SYNC_STAGES-1];
    wire ready_sync;

    assign data_o = data_sync[SYNC_STAGES-1];
    assign valid_o = valid_sync[SYNC_STAGES-1];

    sync_ff #(
        .WIDTH(WIDTH)
    ) sync_ff_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .data_i(data_i),
        .valid_i(valid_i),
        .ready_o(ready_sync),
        .clk_o(clk_o),
        .rst_o(rst_o),
        .data_o(data_sync[0]),
        .valid_o(valid_sync[0])
    );

    generate
        genvar i;
        for (i = 1; i < SYNC_STAGES; i++) begin : sync_ffs
            sync_ff #(
                .WIDTH(WIDTH)
            ) sync_ff_inst (
                .clk_i(clk_o),
                .rst_ni(rst_o),
                .data_i(data_sync[i-1]),
                .valid_i(valid_sync[i-1]),
                .ready_o(ready_sync),
                .clk_o(clk_i),
                .rst_o(rst_i),
                .data_o(data_sync[i]),
                .valid_o(valid_sync[i])
            );
        end
    endgenerate

endmodule

module sync_ff #(
    parameter WIDTH
)(
    input clk_i,
    input rst_ni,
    input [WIDTH-1:0] data_i,
    input valid_i,
    input ready_o,
    input clk_o,
    input rst_o,
    output reg [WIDTH-1:0] data_o,
    output reg valid_o
);

    reg [WIDTH-1:0] data_reg;
    reg valid_reg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_reg <= 0;
            valid_reg <= 0;
        end else if (valid_i && ready_o) begin
            data_reg <= data_i;
            valid_reg <= 1;
        end else if (!ready_o) begin
            data_reg <= data_i;
            valid_reg <= 1;
        end else if (valid_reg) begin
            data_reg <= data_reg;
            valid_reg <= 0;
        end
    end

    always_ff @(posedge clk_o or negedge rst_o) begin
        if (!rst_o) begin
            data_o <= 0;
            valid_o <= 0;
        end else begin
            data_o <= data_reg;
            valid_o <= valid_reg;
        end
    end

endmodule
