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

    // Internal signals
    reg [ADDR_WIDTH-1:0] src_addr_reg;
    reg [DATA_WIDTH-1:0] src_wdata_reg;
    reg [DATA_WIDTH/8-1:0] src_strb_reg;
    reg [2:0] src_prot_reg;
    reg src_write_reg;
    reg src_ready_reg;
    reg dst_request_valid;
    reg dst_request_ready;
    reg [ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+1:0] dst_request_data;
    reg dst_response_valid;
    reg dst_response_ready;
    reg [DATA_WIDTH-1:0] dst_rdata_reg;
    reg dst_slverr_reg;

    // FIFO for buffering transactions
    fifo #(.WIDTH(ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+1), .DEPTH(2**LOG_DEPTH)) src_to_dst_fifo (
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .wr_en(src_ready_reg),
        .rd_en(dst_request_ready),
        .din(dst_request_data),
        .dout(dst_request_data),
        .full(),
        .empty(),
        .almost_full(),
        .almost_empty()
    );

    // APB slave interface
    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_slave_inst (
        .clk(src_pclk_i),
        .reset_n(src_preset_ni),
        .sel(src_psel_i),
        .enable(src_penable_i),
        .write(src_pwrite_i),
        .addr(src_paddr_i),
        .wdata(src_pwdata_i),
        .strb(src_pstrb_i),
        .prot(src_pprot_i),
        .ready(src_ready_reg),
        .rdata(src_prdata_o),
        .slverr(src_pslverr_o)
    );

    // APB master interface
    apb_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_master_inst (
        .clk(dst_pclk_i),
        .reset_n(dst_preset_ni),
        .sel(dst_psel_o),
        .enable(dst_penable_o),
        .write(dst_pwrite_o),
        .addr(dst_paddr_o),
        .wdata(dst_pwdata_o),
        .strb(dst_pstrb_o),
        .prot(dst_pprot_o),
        .ready(dst_pready_i),
        .rdata(dst_prdata_i),
        .slverr(dst_pslverr_i)
    );

    // State machine for handling source requests
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_reg <= 0;
            src_wdata_reg <= 0;
            src_strb_reg <= 0;
            src_prot_reg <= 0;
            src_write_reg <= 0;
            src_ready_reg <= 0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                src_addr_reg <= src_paddr_i;
                src_wdata_reg <= src_pwdata_i;
                src_strb_reg <= src_pstrb_i;
                src_prot_reg <= src_pprot_i;
                src_write_reg <= src_pwrite_i;
                src_ready_reg <= 1;
            end else begin
                src_ready_reg <= 0;
            end
        end
    end

    // State machine for handling destination responses
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_response_valid <= 0;
            dst_response_ready <= 0;
        end else begin
            if (dst_pready_i) begin
                dst_response_valid <= 1;
                dst_response_ready <= 1;
                dst_rdata_reg <= dst_prdata_i;
                dst_slverr_reg <= dst_pslverr_i;
            end else begin
                dst_response_valid <= 0;
                dst_response_ready <= 0;
            end
        end
    end

    // Connect internal signals to FIFO and APB interfaces
    assign dst_request_valid = src_ready_reg;
    assign dst_request_data = {src_addr_reg, src_wdata_reg, src_strb_reg, src_write_reg};
    assign src_pready_o = dst_pready_i;
    assign src_prdata_o = dst_rdata_reg;
    assign src_pslverr_o = dst_slverr_reg;

endmodule
