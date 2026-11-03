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
    reg src_write_reg;
    reg src_valid_reg;
    reg [DATA_WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_ready_reg;

    wire [DATA_WIDTH-1:0] src_prdata;
    wire src_pslverr;

    // Source to Destination
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_reg <= 0;
            src_data_reg <= 0;
            src_strb_reg <= 0;
            src_prot_reg <= 0;
            src_write_reg <= 0;
            src_valid_reg <= 0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                src_addr_reg <= src_paddr_i;
                src_data_reg <= src_pwdata_i;
                src_strb_reg <= src_pstrb_i;
                src_prot_reg <= src_pprot_i;
                src_write_reg <= src_pwrite_i;
                src_valid_reg <= 1;
            end else if (src_valid_reg && dst_ready_reg) begin
                src_valid_reg <= 0;
            end
        end
    end

    // Destination to Source
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_ready_reg <= 0;
            dst_valid_reg <= 0;
            src_pready_o <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
        end else begin
            dst_ready_reg <= dst_pready_i;
            if (dst_valid_reg) begin
                src_prdata_o <= dst_prdata_i;
                src_pslverr_o <= dst_pslverr_i;
                src_pready_o <= 1;
            end else if (src_valid_reg && dst_ready_reg) begin
                dst_valid_reg <= 1;
            end else begin
                src_pready_o <= 0;
            end
        end
    end

    // Forward signals to destination
    assign dst_psel_o = src_valid_reg && dst_ready_reg;
    assign dst_penable_o = src_valid_reg && dst_ready_reg;
    assign dst_pwrite_o = src_write_reg;
    assign dst_paddr_o = src_addr_reg;
    assign dst_pwdata_o = src_data_reg;
    assign dst_pstrb_o = src_strb_reg;
    assign dst_pprot_o = src_prot_reg;

endmodule
