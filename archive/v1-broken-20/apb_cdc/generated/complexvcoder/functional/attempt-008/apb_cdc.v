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
    reg [ADDR_WIDTH-1:0]        dst_paddr_reg;
    reg [DATA_WIDTH-1:0]        dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0]      dst_pstrb_reg;
    reg [2:0]                   dst_pprot_reg;
    reg                         dst_psel_reg;
    reg                         dst_penable_reg;
    reg                         dst_pwrite_reg;
    reg                         dst_pready_reg;
    reg                         src_pready_reg;
    reg                         src_prdata_reg;
    reg                         src_pslverr_reg;

    // Register to hold the current state
    reg [1:0]                   state;

    // States
    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS = 2'b10;

    // Synchronize reset
    reg src_preset_sync;
    reg dst_preset_sync;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_preset_sync <= 1'b0;
        end else begin
            src_preset_sync <= 1'b1;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_preset_sync <= 1'b0;
        end else begin
            dst_preset_sync <= 1'b1;
        end
    end

    // State machine
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_sync) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (src_psel_i && src_penable_i) begin
                        dst_paddr_reg <= src_paddr_i;
                        dst_pwdata_reg <= src_pwdata_i;
                        dst_pstrb_reg <= src_pstrb_i;
                        dst_pprot_reg <= src_pprot_i;
                        dst_psel_reg <= src_psel_i;
                        dst_pwrite_reg <= src_pwrite_i;
                        dst_pready_reg <= 1'b0;
                        state <= SETUP;
                    end
                end
                SETUP: begin
                    if (dst_pready_i) begin
                        state <= ACCESS;
                    end
                end
                ACCESS: begin
                    if (dst_pready_i) begin
                        src_prdata_reg <= dst_prdata_i;
                        src_pslverr_reg <= dst_pslverr_i;
                        src_pready_reg <= 1'b1;
                        state <= IDLE;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // Output assignments
    assign dst_paddr_o = dst_paddr_reg;
    assign dst_pwdata_o = dst_pwdata_reg;
    assign dst_pstrb_o = dst_pstrb_reg;
    assign dst_pprot_o = dst_pprot_reg;
    assign dst_psel_o = dst_psel_reg;
    assign dst_penable_o = dst_penable_reg;
    assign dst_pwrite_o = dst_pwrite_reg;
    assign src_pready_o = src_pready_reg;
    assign src_prdata_o = src_prdata_reg;
    assign src_pslverr_o = src_pslverr_reg;

endmodule
