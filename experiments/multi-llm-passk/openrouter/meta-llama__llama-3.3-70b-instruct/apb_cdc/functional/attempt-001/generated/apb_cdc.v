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

    reg [ADDR_WIDTH-1:0]        src_paddr_reg;
    reg [DATA_WIDTH-1:0]        src_pwdata_reg;
    reg [DATA_WIDTH/8-1:0]      src_pstrb_reg;
    reg [2:0]                   src_pprot_reg;
    reg                         src_pwrite_reg;
    reg                         src_psel_reg;
    reg                         src_penable_reg;

    reg [ADDR_WIDTH-1:0]        dst_paddr_reg;
    reg [DATA_WIDTH-1:0]        dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0]      dst_pstrb_reg;
    reg [2:0]                   dst_pprot_reg;
    reg                         dst_pwrite_reg;
    reg                         dst_psel_reg;
    reg                         dst_penable_reg;

    reg                         src_pready_reg;
    reg [DATA_WIDTH-1:0]        src_prdata_reg;
    reg                         src_pslverr_reg;

    reg                         dst_pready_reg;
    reg [DATA_WIDTH-1:0]        dst_prdata_reg;
    reg                         dst_pslverr_reg;

    reg                         src_valid;
    reg                         dst_valid;

    reg                         src_empty;
    reg                         dst_empty;

    reg                         src_full;
    reg                         dst_full;

    reg [LOG_DEPTH-1:0]         src_count;
    reg [LOG_DEPTH-1:0]         dst_count;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_valid <= 1'b0;
            src_empty <= 1'b1;
            src_full <= 1'b0;
            src_count <= 'b0;
            src_paddr_reg <= 'b0;
            src_pwdata_reg <= 'b0;
            src_pstrb_reg <= 'b0;
            src_pprot_reg <= 'b0;
            src_pwrite_reg <= 1'b0;
            src_psel_reg <= 1'b0;
            src_penable_reg <= 1'b0;
        end else if (src_psel_i && src_penable_i) begin
            if (!src_full) begin
                src_paddr_reg <= src_paddr_i;
                src_pwdata_reg <= src_pwdata_i;
                src_pstrb_reg <= src_pstrb_i;
                src_pprot_reg <= src_pprot_i;
                src_pwrite_reg <= src_pwrite_i;
                src_psel_reg <= src_psel_i;
                src_penable_reg <= src_penable_i;
                src_valid <= 1'b1;
                src_empty <= 1'b0;
                src_count <= src_count + 1'b1;
                if (src_count == (1 << LOG_DEPTH) - 1) begin
                    src_full <= 1'b1;
                end
            end
        end else if (src_valid && dst_pready_i) begin
            src_valid <= 1'b0;
            src_empty <= 1'b1;
            src_count <= src_count - 1'b1;
            if (src_count == 0) begin
                src_full <= 1'b0;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_valid <= 1'b0;
            dst_empty <= 1'b1;
            dst_full <= 1'b0;
            dst_count <= 'b0;
            dst_paddr_reg <= 'b0;
            dst_pwdata_reg <= 'b0;
            dst_pstrb_reg <= 'b0;
            dst_pprot_reg <= 'b0;
            dst_pwrite_reg <= 1'b0;
            dst_psel_reg <= 1'b0;
            dst_penable_reg <= 1'b0;
        end else if (src_valid) begin
            if (!dst_full) begin
                dst_paddr_reg <= src_paddr_reg;
                dst_pwdata_reg <= src_pwdata_reg;
                dst_pstrb_reg <= src_pstrb_reg;
                dst_pprot_reg <= src_pprot_reg;
                dst_pwrite_reg <= src_pwrite_reg;
                dst_psel_reg <= src_psel_reg;
                dst_penable_reg <= src_penable_reg;
                dst_valid <= 1'b1;
                dst_empty <= 1'b0;
                dst_count <= dst_count + 1'b1;
                if (dst_count == (1 << LOG_DEPTH) - 1) begin
                    dst_full <= 1'b1;
                end
            end
        end else if (dst_valid && dst_pready_i) begin
            dst_valid <= 1'b0;
            dst_empty <= 1'b1;
            dst_count <= dst_count - 1'b1;
            if (dst_count == 0) begin
                dst_full <= 1'b0;
            end
        end
    end

    always @(posedge src_pclk_i) begin
        src_pready_reg <= 1'b0;
        src_prdata_reg <= 'b0;
        src_pslverr_reg <= 1'b0;
        if (dst_valid && dst_pready_i) begin
            src_pready_reg <= 1'b1;
            src_prdata_reg <= dst_prdata_i;
            src_pslverr_reg <= dst_pslverr_i;
        end
    end

    always @(posedge dst_pclk_i) begin
        dst_psel_o <= 1'b0;
        dst_penable_o <= 1'b0;
        dst_pwrite_o <= 1'b0;
        dst_paddr_o <= 'b0;
        dst_pwdata_o <= 'b0;
        dst_pstrb_o <= 'b0;
        dst_pprot_o <= 'b0;
        if (src_valid) begin
            dst_psel_o <= src_psel_reg;
            dst_penable_o <= src_penable_reg;
            dst_pwrite_o <= src_pwrite_reg;
            dst_paddr_o <= src_paddr_reg;
            dst_pwdata_o <= src_pwdata_reg;
            dst_pstrb_o <= src_pstrb_reg;
            dst_pprot_o <= src_pprot_reg;
        end
    end

    assign src_pready_o = src_pready_reg;
    assign src_prdata_o = src_prdata_reg;
    assign src_pslverr_o = src_pslverr_reg;

endmodule
