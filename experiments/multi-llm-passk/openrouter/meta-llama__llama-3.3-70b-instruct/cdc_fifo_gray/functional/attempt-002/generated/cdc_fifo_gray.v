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

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0]             fifo [DEPTH-1:0];
    reg [$clog2(DEPTH)-1:0]     wr_ptr;
    reg [$clog2(DEPTH)-1:0]     rd_ptr;
    reg [$clog2(DEPTH)-1:0]     gray_wr_ptr;
    reg [$clog2(DEPTH)-1:0]     gray_rd_ptr;
    reg [SYNC_STAGES-1:0]       sync_rst_n;
    reg [SYNC_STAGES-1:0]       sync_valid;
    reg [SYNC_STAGES-1:0]       sync_ready;
    reg [WIDTH-1:0]             sync_data [SYNC_STAGES-1:0];

    assign src_ready_o = (wr_ptr != rd_ptr + 1'b1) && src_rst_ni;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            gray_wr_ptr <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1'b1;
            gray_wr_ptr <= gray_wr_ptr + 1'b1;
        end
    end

    always @(posedge src_clk_i) begin
        gray_wr_ptr <= gray_wr_ptr + 1'b1;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            gray_rd_ptr <= 0;
            sync_rst_n <= {SYNC_STAGES{1'b1}};
            sync_valid <= {SYNC_STAGES{1'b0}};
            sync_ready <= {SYNC_STAGES{1'b0}};
            sync_data <= '{default: 0};
        end else begin
            sync_rst_n <= {sync_rst_n[SYNC_STAGES-2:0], src_rst_ni};
            sync_valid <= {sync_valid[SYNC_STAGES-2:0], src_valid_i && src_ready_o};
            sync_ready <= {sync_ready[SYNC_STAGES-2:0], dst_ready_i};
            sync_data <= {sync_data[SYNC_STAGES-2:0], src_data_i};
            if (sync_ready[SYNC_STAGES-1] && sync_valid[SYNC_STAGES-1]) begin
                rd_ptr <= rd_ptr + 1'b1;
                gray_rd_ptr <= gray_rd_ptr + 1'b1;
            end
        end
    end

    assign dst_valid_o = sync_valid[SYNC_STAGES-1] && sync_rst_n[SYNC_STAGES-1];
    assign dst_data_o = sync_data[SYNC_STAGES-1];

endmodule
