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
    reg [WIDTH-1:0] src_data_gray;
    reg [WIDTH-1:0] dst_data_gray;
    reg src_valid_gray;
    reg dst_valid_gray;
    reg src_ready_gray;
    reg dst_ready_gray;
    reg [LOG_DEPTH-1:0] src_count_gray;
    reg [LOG_DEPTH-1:0] dst_count_gray;

    // Gray code encoder/decoder
    gray_encoder #(.WIDTH(WIDTH)) src_gray_encoder (
        .data_i(src_data_i),
        .data_gray(src_data_gray)
    );

    gray_decoder #(.WIDTH(WIDTH)) dst_gray_decoder (
        .data_gray(dst_data_gray),
        .data_o(dst_data_o)
    );

    // Synchronization modules
    sync_module #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) src_sync (
        .clk_i(src_clk_i),
        .data_i(src_data_gray),
        .valid_i(src_valid_gray),
        .ready_o(src_ready_gray)
    );

    sync_module #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) dst_sync (
        .clk_i(dst_clk_i),
        .data_i(dst_data_gray),
        .valid_i(dst_valid_gray),
        .ready_o(dst_ready_gray)
    );

    // FIFO instances
    fifo_gray_clearable #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_src (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .clear_pending_o(src_clear_pending_o),
        .data_i(src_data_gray),
        .valid_i(src_valid_gray),
        .ready_o(src_ready_gray)
    );

    fifo_gray_clearable #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_dst (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .clear_pending_o(dst_clear_pending_o),
        .data_i(dst_data_gray),
        .valid_i(dst_valid_gray),
        .ready_o(dst_ready_gray)
    );

    // Handshake logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_gray <= 1'b0;
        end else begin
            src_valid_gray <= src_valid_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_gray <= 1'b0;
        end else begin
            dst_valid_gray <= dst_valid_i;
        end
    end

    assign src_ready_o = src_ready_gray;
    assign dst_ready_o = dst_ready_gray;

endmodule

module gray_encoder #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_i,
    output [WIDTH-1:0] data_gray
);

    always @(*) begin
        data_gray = data_i ^ (data_i >> 1);
    end

endmodule

module gray_decoder #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_gray,
    output [WIDTH-1:0] data_o
);

    always @(*) begin
        data_o = data_gray ^ (data_gray >> 1);
    end

endmodule

module sync_module #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  clk_i,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o
);

    reg [WIDTH-1:0] sync_reg [SYNC_STAGES-1:0];
    reg [WIDTH-1:0] data_out;
    reg valid_out;

    always @(posedge clk_i) begin
        if (valid_i) begin
            sync_reg[0] <= data_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
            data_out <= sync_reg[SYNC_STAGES-1];
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

    assign ready_o = valid_out;

endmodule

module fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  clear_i,
    output                 clear_pending_o,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o
);

    reg [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0] head;
    reg [LOG_DEPTH-1:0] tail;
    reg [LOG_DEPTH-1:0] count;
    reg clear_pending;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
            clear_pending <= 1'b0;
        end else begin
            if (clear_i) begin
                head <= 0;
                tail <= 0;
                count <= 0;
                clear_pending <= 1'b1;
            end else if (valid_i && ready_o) begin
                mem[tail] <= data_i;
                tail <= (tail + 1) % (2**LOG_DEPTH);
                count <= count + 1;
                clear_pending <= 1'b0;
            end
        end
    end

    assign ready_o = (count < 2**LOG_DEPTH - 1);
    assign clear_pending_o = clear_pending;

endmodule
