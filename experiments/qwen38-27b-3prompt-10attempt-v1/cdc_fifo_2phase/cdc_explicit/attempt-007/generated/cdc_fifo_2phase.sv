module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input  [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] wr_ptr_full;
    reg [PTR_WIDTH-1:0] rd_ptr_src;

    wire src_wr_en = src_valid_i & src_ready_o;
    wire src_full = (wr_ptr_full == rd_ptr_src);
    assign src_ready_o = ~src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            wr_ptr_full <= {PTR_WIDTH{1'b0}};
        end else if (src_wr_en) begin
            mem[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1'b1;
            wr_ptr_full <= wr_ptr_full + 1'b1;
        end
    end

    // Destination domain
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr_dst;
    reg [PTR_WIDTH-1:0] wr_ptr_dst;
    reg [WIDTH-1:0] data_reg;
    reg valid_reg;

    wire dst_rd_en = dst_valid_o & dst_ready_i;
    wire dst_empty = (rd_ptr_dst == wr_ptr_dst);
    assign dst_valid_o = valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr_dst <= {PTR_WIDTH{1'b0}};
            data_reg <= {WIDTH{1'b0}};
            valid_reg <= 1'b0;
        end else begin
            if (dst_rd_en) begin
                valid_reg <= ~dst_empty;
                if (~dst_empty) begin
                    data_reg <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1'b1;
                    rd_ptr_dst <= rd_ptr_dst + 1'b1;
                end
            end else if (~dst_empty) begin
                valid_reg <= 1'b1;
                data_reg <= mem[rd_ptr];
            end
        end
    end

    // CDC: source write pointer to destination
    reg [PTR_WIDTH-1:0] wr_ptr_dst_r1, wr_ptr_dst_r2;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_dst_r1 <= {PTR_WIDTH{1'b0}};
            wr_ptr_dst_r2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_ptr_dst_r1 <= wr_ptr_full;
            wr_ptr_dst_r2 <= wr_ptr_dst_r1;
        end
    end
    assign wr_ptr_dst = wr_ptr_dst_r2;

    // CDC: destination read pointer to source
    reg [PTR_WIDTH-1:0] rd_ptr_src_r1, rd_ptr_src_r2;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_src_r1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_src_r2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_ptr_src_r1 <= rd_ptr_dst;
            rd_ptr_src_r2 <= rd_ptr_src_r1;
        end
    end
    assign rd_ptr_src = rd_ptr_src_r2;

endmodule
