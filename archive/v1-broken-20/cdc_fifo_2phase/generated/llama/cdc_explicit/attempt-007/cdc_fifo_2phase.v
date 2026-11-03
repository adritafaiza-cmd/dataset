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

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0]                fifo [DEPTH-1:0];
    reg [LOG_DEPTH-1:0]            wr_ptr;
    reg [LOG_DEPTH-1:0]            rd_ptr;
    reg [LOG_DEPTH-1:0]            gray_wr_ptr;
    reg [LOG_DEPTH-1:0]            gray_rd_ptr;
    reg [LOG_DEPTH-1:0]            sync_wr_ptr [1:0];
    reg [LOG_DEPTH-1:0]            sync_rd_ptr [1:0];
    reg [WIDTH-1:0]                dst_data_reg;
    reg                            dst_valid_reg;
    reg                            src_ready_reg;
    reg                            full;
    reg                            empty;

    assign src_ready_o = src_ready_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            gray_wr_ptr <= 0;
            src_ready_reg <= 1'b1;
            full <= 1'b0;
        end else begin
            if (src_valid_i && src_ready_reg) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                gray_wr_ptr <= gray_wr_ptr + 1;
                if (wr_ptr == (DEPTH - 1)) begin
                    full <= 1'b1;
                    src_ready_reg <= 1'b0;
                end else begin
                    full <= 1'b0;
                    src_ready_reg <= 1'b1;
                end
            end else if (!src_valid_i && src_ready_reg) begin
                src_ready_reg <= 1'b1;
            end else if (src_valid_i && !src_ready_reg) begin
                src_ready_reg <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            gray_rd_ptr <= 0;
            dst_valid_reg <= 1'b0;
            empty <= 1'b1;
        end else begin
            if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
                rd_ptr <= rd_ptr + 1;
                gray_rd_ptr <= gray_rd_ptr + 1;
                if (rd_ptr == (DEPTH - 1)) begin
                    empty <= 1'b1;
                end else begin
                    empty <= 1'b0;
                end
            end else if (!dst_valid_reg && !empty) begin
                dst_data_reg <= fifo[rd_ptr];
                dst_valid_reg <= 1'b1;
            end else if (dst_valid_reg && !dst_ready_i) begin
                dst_valid_reg <= 1'b1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_wr_ptr[0] <= 0;
            sync_wr_ptr[1] <= 0;
        end else begin
            sync_wr_ptr[0] <= gray_wr_ptr;
            sync_wr_ptr[1] <= sync_wr_ptr[0];
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_rd_ptr[0] <= 0;
            sync_rd_ptr[1] <= 0;
        end else begin
            sync_rd_ptr[0] <= gray_rd_ptr;
            sync_rd_ptr[1] <= sync_rd_ptr[0];
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_reg <= 1'b1;
        end else if (sync_rd_ptr[1] == (wr_ptr - 1)) begin
            src_ready_reg <= 1'b0;
        end else begin
            src_ready_reg <= 1'b1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
        end else if (sync_wr_ptr[1] == (rd_ptr + 1)) begin
            dst_valid_reg <= 1'b1;
        end else begin
            dst_valid_reg <= 1'b0;
        end
    end

endmodule
