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

    reg [WIDTH-1:0]         fifo [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]    wr_ptr;
    reg [LOG_DEPTH-1:0]    rd_ptr;
    reg [LOG_DEPTH-1:0]    gray_wr_ptr;
    reg [LOG_DEPTH-1:0]    gray_rd_ptr;
    reg [SYNC_STAGES-1:0]  sync_wr_ptr [LOG_DEPTH-1:0];
    reg [SYNC_STAGES-1:0]  sync_rd_ptr [LOG_DEPTH-1:0];
    reg                    src_ready;
    reg                    dst_valid;
    reg [WIDTH-1:0]        dst_data;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            wr_ptr <= 0;
            gray_wr_ptr <= 0;
            src_ready <= 1'b1;
        end else if (src_valid_i && src_ready) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            gray_wr_ptr <= gray_wr_ptr + 1;
            src_ready <= ~(wr_ptr == {LOG_DEPTH{1'b1}} - 1);
        end else if (~src_valid_i && src_ready) begin
            src_ready <= 1'b1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            rd_ptr <= 0;
            gray_rd_ptr <= 0;
            dst_valid <= 1'b0;
            dst_data <= 0;
        end else if (dst_ready_i && dst_valid) begin
            dst_data <= fifo[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            gray_rd_ptr <= gray_rd_ptr + 1;
            dst_valid <= ~(rd_ptr == {LOG_DEPTH{1'b1}} - 1);
        end else if (~dst_ready_i && dst_valid) begin
            dst_valid <= 1'b1;
        end else if (~dst_valid) begin
            dst_valid <= 1'b0;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            sync_wr_ptr[0] <= 0;
        end else begin
            sync_wr_ptr[0] <= gray_wr_ptr;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            sync_rd_ptr[0] <= 0;
        end else begin
            sync_rd_ptr[0] <= gray_rd_ptr;
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i++) begin
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (~src_rst_ni) begin
                    sync_wr_ptr[i] <= 0;
                end else begin
                    sync_wr_ptr[i] <= sync_wr_ptr[i-1];
                end
            end

            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (~dst_rst_ni) begin
                    sync_rd_ptr[i] <= 0;
                end else begin
                    sync_rd_ptr[i] <= sync_rd_ptr[i-1];
                end
            end
        end
    endgenerate

    assign src_ready_o = src_ready;
    assign dst_data_o = dst_data;
    assign dst_valid_o = dst_valid;

endmodule
