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

    wire [DATA_WIDTH+2:0] src_to_dst_data;
    wire [DATA_WIDTH+2:0] dst_to_src_data;
    wire src_to_dst_valid;
    wire src_to_dst_ready;
    wire dst_to_src_valid;
    wire dst_to_src_ready;

    apb_fifos #(
        .DATA_WIDTH(DATA_WIDTH + 2),
        .ADDR_WIDTH(ADDR_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .wr_en_i(src_psel_i),
        .valid_i(src_penable_i),
        .write_i(src_pwrite_i),
        .addr_i(src_paddr_i),
        .data_i({src_pprot_i, src_pstrb_i, src_pwdata_i}),
        .ready_o(src_pready_o),
        .clk_o(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .rd_en_i(dst_pready_i),
        .data_o(dst_to_src_data),
        .slverr_o(src_pslverr_o)
    );

    apb_fifos #(
        .DATA_WIDTH(DATA_WIDTH + 2),
        .ADDR_WIDTH(ADDR_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_to_src_fifo (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .wr_en_i(dst_psel_i),
        .valid_i(dst_penable_i),
        .write_i(dst_pwrite_i),
        .addr_i(dst_paddr_i),
        .data_i({dst_pprot_i, dst_pstrb_i, dst_pwdata_i}),
        .ready_o(dst_pready_o),
        .clk_o(src_pclk_i),
        .rst_ni(src_preset_ni),
        .rd_en_i(src_pready_i),
        .data_o(src_to_dst_data),
        .slverr_o(dst_pslverr_o)
    );

    assign dst_psel_o = src_to_dst_ready;
    assign dst_pwdata_o = src_to_dst_data[DATA_WIDTH+1:1];
    assign dst_paddr_o = src_to_dst_data[ADDR_WIDTH:0];
    assign dst_pstrb_o = src_to_dst_data[DATA_WIDTH];
    assign dst_pprot_o = src_to_dst_data[DATA_WIDTH+1];

    assign src_to_dst_valid = dst_to_src_ready;
    assign src_prdata_o = dst_to_src_data[DATA_WIDTH+1:1];
    assign src_pslverr_o = dst_to_src_data[DATA_WIDTH];
    assign src_pready_o = dst_to_src_ready;

endmodule

module apb_fifos #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,
    parameter LOG_DEPTH = 1
)(
    input                      clk_i,
    input                      rst_ni,
    input                      wr_en_i,
    input                      valid_i,
    input                      write_i,
    input  [ADDR_WIDTH-1:0]    addr_i,
    input  [DATA_WIDTH-1:0]    data_i,
    output                     ready_o,
    input                      clk_o,
    input                      rst_ni,
    input                      rd_en_i,
    output [DATA_WIDTH-1:0]    data_o,
    output                     slverr_o
);

    reg  [DATA_WIDTH-1:0]       mem [0:(1<<LOG_DEPTH)-1];
    reg  [DATA_WIDTH+2:0]       fifo [0:(1<<LOG_DEPTH)-1];
    reg  [LOG_DEPTH:0]          wr_ptr;
    reg  [LOG_DEPTH:0]          rd_ptr;
    reg  [LOG_DEPTH:0]          cnt;

    wire [DATA_WIDTH+2:0]        read_data;
    wire [DATA_WIDTH+2:0]        write_data;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt <= 0;
        end else begin
            if (wr_en_i && valid_i && cnt < (1<<LOG_DEPTH)) begin
                mem[wr_ptr] <= data_i;
                wr_ptr <= wr_ptr + 1;
                cnt <= cnt + 1;
            end
            if (rd_en_i && cnt > 0) begin
                rd_ptr <= rd_ptr + 1;
                cnt <= cnt - 1;
            end
        end
    end

    always @(posedge clk_o or negedge rst_ni) begin
        if (!rst_ni) begin
            ready_o <= 0;
        end else begin
            ready_o <= cnt > 0;
        end
    end

    assign read_data = cnt > 0 ? {mem[rd_ptr], 2'b0} : {DATA_WIDTH+2'b0};
    assign write_data = {write_i, data_i, addr_i};

    assign data_o = read_data[DATA_WIDTH+1:1];
    assign slverr_o = read_data[DATA_WIDTH];

endmodule
