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
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 2**LOG_DEPTH;

    // FIFO Core
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    reg [LOG_DEPTH:0] wr_ptr;
    reg [LOG_DEPTH:0] rd_ptr;
    reg [LOG_DEPTH:0] count;
    reg full;
    reg empty;

    // Clock Domain Crossing for FIFO signals
    wire fifo_src_valid;
    wire fifo_src_ready;
    wire fifo_dst_valid;
    wire fifo_dst_ready;

    // FIFO Core Logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
                if (count == DEPTH-1)
                    full <= 1;
            end
            if (fifo_dst_ready && !empty) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
                if (count == 0)
                    empty <= 1;
            end
        end
    end

    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

    // Clock Domain Crossing for FIFO signals
    clock_domain_crossing #(
        .WIDTH(WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) cdc_inst (
        .src_clk_i(src_clk_i),
        .src_rst_ni(src_rst_ni),
        .src_valid_i(src_valid_i),
        .src_ready_o(src_ready_o),
        .dst_clk_i(dst_clk_i),
        .dst_rst_ni(dst_rst_ni),
        .dst_valid_o(fifo_dst_valid),
        .dst_ready_i(fifo_dst_ready)
    );

    // Output logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else begin
            if (fifo_dst_valid && dst_ready_i) begin
                dst_data_o <= fifo[rd_ptr];
            end
        end
    end

endmodule

module clock_domain_crossing #(
    parameter WIDTH = 8,
    parameter SYNC_STAGES = 2
)(
    input                  src_clk_i,
    input                  src_rst_ni,
    input  [WIDTH-1:0]     src_valid_i,
    output                 src_ready_o,
    input                  dst_clk_i,
    input                  dst_rst_ni,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];
    reg [WIDTH-1:0] sync_reg_out [0:SYNC_STAGES-1];
    reg [WIDTH-1:0] dst_valid_reg;

    assign src_ready_o = (sync_reg_out[SYNC_STAGES-1] == src_valid_i);

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_reg <= {WIDTH{1'b0}};
            sync_reg_out <= {WIDTH{1'b0}};
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], src_valid_i};
            sync_reg_out <= sync_reg;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 0;
        end else begin
            dst_valid_reg <= sync_reg_out[SYNC_STAGES-1];
        end
    end

    assign dst_valid_o = dst_valid_reg && dst_ready_i;

endmodule
