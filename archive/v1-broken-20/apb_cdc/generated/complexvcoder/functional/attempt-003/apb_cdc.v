module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    localparam FIFO_WIDTH = DATA_WIDTH + 8 + 4 + 3 + 1 + 1 + 1 + 1;

    wire [FIFO_WIDTH-1:0] src_to_dst_fifo_wr_data;
    wire [FIFO_WIDTH-1:0] src_to_dst_fifo_rd_data;
    wire src_to_dst_fifo_wr_en;
    wire src_to_dst_fifo_rd_en;
    wire src_to_dst_fifo_full;
    wire src_to_dst_fifo_empty;

    wire [FIFO_WIDTH-1:0] dst_to_src_fifo_wr_data;
    wire [FIFO_WIDTH-1:0] dst_to_src_fifo_rd_data;
    wire dst_to_src_fifo_wr_en;
    wire dst_to_src_fifo_rd_en;
    wire dst_to_src_fifo_full;
    wire dst_to_src_fifo_empty;

    apb_fifo #(
        .WIDTH(FIFO_WIDTH),
        .LOG2_DEPTH(LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .wr_en_i(src_to_dst_fifo_wr_en),
        .wr_data_i(src_to_dst_fifo_wr_data),
        .rd_en_i(src_to_dst_fifo_rd_en),
        .rd_data_o(src_to_dst_fifo_rd_data),
        .full_o(src_to_dst_fifo_full),
        .empty_o(src_to_dst_fifo_empty)
    );

    apb_fifo #(
        .WIDTH(FIFO_WIDTH),
        .LOG2_DEPTH(LOG_DEPTH)
    ) dst_to_src_fifo (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .wr_en_i(dst_to_src_fifo_wr_en),
        .wr_data_i(dst_to_src_fifo_wr_data),
        .rd_en_i(dst_to_src_fifo_rd_en),
        .rd_data_o(dst_to_src_fifo_rd_data),
        .full_o(dst_to_src_fifo_full),
        .empty_o(dst_to_src_fifo_empty)
    );

    reg [DATA_WIDTH-1:0] src_prdata_o_reg;
    reg src_pslverr_o_reg;
    reg src_pready_o_reg;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_o_reg <= 0;
            src_pslverr_o_reg <= 0;
            src_pready_o_reg <= 0;
        end else begin
            src_prdata_o_reg <= dst_prdata_i;
            src_pslverr_o_reg <= dst_pslverr_i;
            src_pready_o_reg <= src_to_dst_fifo_empty;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_pwrite_o <= 0;
            dst_paddr_o <= 0;
            dst_pwdata_o <= 0;
            dst_pstrb_o <= 0;
            dst_pprot_o <= 0;
        end else begin
            if (!src_to_dst_fifo_empty) begin
                dst_psel_o <= 1;
                dst_penable_o <= 1;
                dst_pwrite_o <= src_pwrite_i;
                dst_paddr_o <= src_paddr_i;
                dst_pwdata_o <= src_pwdata_i;
                dst_pstrb_o <= src_pstrb_i;
                dst_pprot_o <= src_pprot_i;
            end else begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
                dst_pwrite_o <= 0;
                dst_paddr_o <= 0;
                dst_pwdata_o <= 0;
                dst_pstrb_o <= 0;
                dst_pprot_o <= 0;
            end
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_to_dst_fifo_wr_en <= 0;
            src_to_dst_fifo_wr_data <= 0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                src_to_dst_fifo_wr_en <= 1;
                src_to_dst_fifo_wr_data <= {src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i, 0, 0, 0};
            end else begin
                src_to_dst_fifo_wr_en <= 0;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_to_src_fifo_rd_en <= 0;
        end else begin
            if (!src_to_dst_fifo_empty) begin
                dst_to_src_fifo_rd_en <= 1;
            end else begin
                dst_to_src_fifo_rd_en <= 0;
            end
        end
    end

endmodule

module apb_fifo #(
    parameter WIDTH = 8,
    parameter LOG2_DEPTH = 1
)(
    input                      clk_i,
    input                      rst_ni,
    input                      wr_en_i,
    input [WIDTH-1:0]          wr_data_i,
    input                      rd_en_i,
    output [WIDTH-1:0]         rd_data_o,
    output                     full_o,
    output                     empty_o
);

    reg [WIDTH-1:0] mem [0:2**LOG2_DEPTH-1];
    reg [LOG2_DEPTH:0] wr_ptr;
    reg [LOG2_DEPTH:0] rd_ptr;

    assign rd_data_o = mem[rd_ptr];
    assign full_o = wr_ptr == rd_ptr + 1;
    assign empty_o = wr_ptr == rd_ptr;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (wr_en_i && !full_o) begin
                mem[wr_ptr] <= wr_data_i;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en_i && !empty_o) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

endmodule
