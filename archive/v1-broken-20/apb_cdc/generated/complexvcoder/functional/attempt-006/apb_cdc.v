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

    reg [ADDR_WIDTH-1:0] src_addr_reg;
    reg [DATA_WIDTH-1:0] src_data_reg;
    reg [DATA_WIDTH/8-1:0] src_strb_reg;
    reg [2:0] src_prot_reg;
    reg src_sel_reg;
    reg src_enable_reg;
    reg src_write_reg;

    reg [DATA_WIDTH-1:0] dst_data_reg;
    reg dst_sel_reg;
    reg dst_enable_reg;
    reg dst_write_reg;

    reg src_ready_reg;
    reg src_slverr_reg;

    wire dst_ready_reg;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_reg <= 0;
            src_data_reg <= 0;
            src_strb_reg <= 0;
            src_prot_reg <= 0;
            src_sel_reg <= 0;
            src_enable_reg <= 0;
            src_write_reg <= 0;
            src_ready_reg <= 0;
            src_slverr_reg <= 0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                src_addr_reg <= src_paddr_i;
                src_data_reg <= src_pwdata_i;
                src_strb_reg <= src_pstrb_i;
                src_prot_reg <= src_pprot_i;
                src_sel_reg <= src_psel_i;
                src_enable_reg <= src_penable_i;
                src_write_reg <= src_pwrite_i;
                src_ready_reg <= 0;
                src_slverr_reg <= 0;
            end else begin
                src_ready_reg <= 1;
                src_slverr_reg <= dst_pslverr_i;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_sel_reg <= 0;
            dst_enable_reg <= 0;
            dst_write_reg <= 0;
        end else begin
            if (dst_pready_i) begin
                dst_sel_reg <= src_sel_reg;
                dst_enable_reg <= src_enable_reg;
                dst_write_reg <= src_write_reg;
                dst_data_reg <= src_data_reg;
            end else begin
                dst_sel_reg <= 0;
                dst_enable_reg <= 0;
                dst_write_reg <= 0;
            end
        end
    end

    assign dst_paddr_o = src_addr_reg;
    assign dst_pwdata_o = src_data_reg;
    assign dst_pstrb_o = src_strb_reg;
    assign dst_pprot_o = src_prot_reg;
    assign dst_psel_o = dst_sel_reg;
    assign dst_penable_o = dst_enable_reg;
    assign dst_pwrite_o = dst_write_reg;

    assign src_pready_o = src_ready_reg;
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = src_slverr_reg;

endmodule
