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

    reg [ADDR_WIDTH-1:0]       src_paddr;
    reg [DATA_WIDTH-1:0]       src_pwdata;
    reg [DATA_WIDTH/8-1:0]     src_pstrb;
    reg [2:0]                  src_pprot;
    reg                        src_pwrite;
    reg                        src_psel;
    reg                        src_penable;
    reg                        src_pready;
    reg [DATA_WIDTH-1:0]       src_prdata;
    reg                        src_pslverr;

    reg [ADDR_WIDTH-1:0]       dst_paddr;
    reg [DATA_WIDTH-1:0]       dst_pwdata;
    reg [DATA_WIDTH/8-1:0]     dst_pstrb;
    reg [2:0]                  dst_pprot;
    reg                        dst_pwrite;
    reg                        dst_psel;
    reg                        dst_penable;
    reg [DATA_WIDTH-1:0]       dst_prdata;
    reg                        dst_pslverr;

    reg [LOG_DEPTH-1:0]        fifo_empty;
    reg [LOG_DEPTH-1:0]        fifo_full;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_paddr <= 0;
            src_pwdata <= 0;
            src_pstrb <= 0;
            src_pprot <= 0;
            src_pwrite <= 0;
            src_psel <= 0;
            src_penable <= 0;
            src_pready <= 0;
            src_prdata <= 0;
            src_pslverr <= 0;
            fifo_empty <= {LOG_DEPTH{1'b1}};
            fifo_full <= {LOG_DEPTH{1'b0}};
        end else if (src_psel_i && src_penable_i) begin
            src_paddr <= src_paddr_i;
            src_pwdata <= src_pwdata_i;
            src_pstrb <= src_pstrb_i;
            src_pprot <= src_pprot_i;
            src_pwrite <= src_pwrite_i;
            src_psel <= src_psel_i;
            src_penable <= src_penable_i;
            if (!fifo_full[0]) begin
                fifo_empty <= {LOG_DEPTH{1'b0}};
                fifo_full <= {LOG_DEPTH{1'b1}};
            end
        end else if (fifo_empty[0] && src_pready) begin
            src_pready <= 0;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_paddr <= 0;
            dst_pwdata <= 0;
            dst_pstrb <= 0;
            dst_pprot <= 0;
            dst_pwrite <= 0;
            dst_psel <= 0;
            dst_penable <= 0;
            dst_prdata <= 0;
            dst_pslverr <= 0;
        end else if (fifo_full[0] && !dst_pready_i) begin
            dst_paddr <= src_paddr;
            dst_pwdata <= src_pwdata;
            dst_pstrb <= src_pstrb;
            dst_pprot <= src_pprot;
            dst_pwrite <= src_pwrite;
            dst_psel <= src_psel;
            dst_penable <= src_penable;
            fifo_full <= {LOG_DEPTH{1'b0}};
            fifo_empty <= {LOG_DEPTH{1'b1}};
        end else if (dst_pready_i && !fifo_empty[0]) begin
            dst_prdata <= dst_prdata_i;
            dst_pslverr <= dst_pslverr_i;
            fifo_empty <= {LOG_DEPTH{1'b0}};
            fifo_full <= {LOG_DEPTH{1'b1}};
        end
    end

    assign src_pready_o = src_pready;
    assign src_prdata_o = dst_prdata;
    assign src_pslverr_o = dst_pslverr;
    assign dst_psel_o = dst_psel;
    assign dst_penable_o = dst_penable;
    assign dst_pwrite_o = dst_pwrite;
    assign dst_paddr_o = dst_paddr;
    assign dst_pwdata_o = dst_pwdata;
    assign dst_pstrb_o = dst_pstrb;
    assign dst_pprot_o = dst_pprot;

endmodule
