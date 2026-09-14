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

    reg src_pready_o;
    reg [DATA_WIDTH-1:0] src_prdata_o;
    reg src_pslverr_o;

    reg dst_psel_o;
    reg dst_penable_o;
    reg dst_pwrite_o;
    reg [ADDR_WIDTH-1:0] dst_paddr_o;
    reg [DATA_WIDTH-1:0] dst_pwdata_o;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_o;
    reg [2:0] dst_pprot_o;

    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg [DATA_WIDTH-1:0] src_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [2:0] src_pprot_reg;
    reg src_pwrite_reg;
    reg src_penable_reg;
    reg src_psel_reg;

    reg dst_pready_reg;
    reg [DATA_WIDTH-1:0] dst_prdata_reg;
    reg dst_pslverr_reg;

    reg [1:0] state;
    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS = 2'b10;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o <= 1'b0;
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;

            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_o <= 3'b000;

            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    src_pready_o <= 1'b1;
                    dst_psel_o <= 1'b0;
                    dst_penable_o <= 1'b0;
                    dst_pwrite_o <= 1'b0;
                    dst_paddr_o <= {ADDR_WIDTH{1'b0}};
                    dst_pwdata_o <= {DATA_WIDTH{1'b0}};
                    dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
                    dst_pprot_o <= 3'b000;

                    if (src_psel_i && src_penable_i) begin
                        src_pready_o <= 1'b0;
                        src_paddr_reg <= src_paddr_i;
                        src_pwdata_reg <= src_pwdata_i;
                        src_pstrb_reg <= src_pstrb_i;
                        src_pprot_reg <= src_pprot_i;
                        src_pwrite_reg <= src_pwrite_i;
                        src_penable_reg <= src_penable_i;
                        src_psel_reg <= src_psel_i;

                        if (src_pwrite_i) begin
                            state <= SETUP;
                        end else begin
                            state <= ACCESS;
                        end
                    end
                end

                SETUP: begin
                    dst_psel_o <= 1'b1;
                    dst_penable_o <= 1'b0;
                    dst_pwrite_o <= src_pwrite_reg;
                    dst_paddr_o <= src_paddr_reg;
                    dst_pwdata_o <= src_pwdata_reg;
                    dst_pstrb_o <= src_pstrb_reg;
                    dst_pprot_o <= src_pprot_reg;

                    if (dst_pready_i) begin
                        dst_psel_o <= 1'b0;
                        dst_penable_o <= 1'b1;
                        dst_pwrite_o <= src_pwrite_reg;
                        dst_paddr_o <= src_paddr_reg;
                        dst_pwdata_o <= src_pwdata_reg;
                        dst_pstrb_o <= src_pstrb_reg;
                        dst_pprot_o <= src_pprot_reg;

                        state <= ACCESS;
                    end
                end

                ACCESS: begin
                    if (dst_pready_i) begin
                        if (src_pwrite_reg) begin
                            src_prdata_o <= dst_prdata_i;
                            src_pslverr_o <= dst_pslverr_i;
                        end
                        src_pready_o <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
