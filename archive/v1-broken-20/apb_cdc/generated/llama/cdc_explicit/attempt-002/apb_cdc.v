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

    reg [ADDR_WIDTH-1:0]        addr;
    reg [DATA_WIDTH-1:0]        wdata;
    reg [DATA_WIDTH/8-1:0]      wstrb;
    reg [2:0]                   wprot;
    reg                        write;
    reg                        valid;
    reg                        ready;
    reg                        error;
    reg [DATA_WIDTH-1:0]        rdata;

    reg [LOG_DEPTH-1:0]         src_fifo_ptr;
    reg [LOG_DEPTH-1:0]         dst_fifo_ptr;
    reg                        src_fifo_empty;
    reg                        dst_fifo_full;
    reg                        src_fifo_valid;
    reg                        dst_fifo_valid;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_fifo_ptr <= 0;
            src_fifo_empty <= 1'b1;
            src_fifo_valid <= 1'b0;
        end else if (src_psel_i && src_penable_i && !src_fifo_valid) begin
            src_fifo_ptr <= src_fifo_ptr + 1;
            src_fifo_empty <= 1'b0;
            src_fifo_valid <= 1'b1;
            addr <= src_paddr_i;
            wdata <= src_pwdata_i;
            wstrb <= src_pstrb_i;
            wprot <= src_pprot_i;
            write <= src_pwrite_i;
        end else if (src_fifo_valid && ready) begin
            src_fifo_valid <= 1'b0;
            src_fifo_empty <= 1'b1;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_fifo_ptr <= 0;
            dst_fifo_full <= 1'b0;
            dst_fifo_valid <= 1'b0;
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_o <= {3{1'b0}};
        end else if (src_fifo_valid && !dst_fifo_full) begin
            dst_fifo_ptr <= dst_fifo_ptr + 1;
            dst_fifo_full <= 1'b1;
            dst_fifo_valid <= 1'b1;
            dst_psel_o <= 1'b1;
            dst_penable_o <= 1'b1;
            dst_pwrite_o <= write;
            dst_paddr_o <= addr;
            dst_pwdata_o <= wdata;
            dst_pstrb_o <= wstrb;
            dst_pprot_o <= wprot;
        end else if (dst_pready_i && dst_fifo_valid) begin
            dst_fifo_valid <= 1'b0;
            dst_fifo_full <= 1'b0;
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            rdata <= dst_prdata_i;
            error <= dst_pslverr_i;
            ready <= 1'b1;
        end else if (ready && src_fifo_valid) begin
            ready <= 1'b0;
        end
    end

    assign src_pready_o = ready;
    assign src_prdata_o = rdata;
    assign src_pslverr_o = error;

endmodule
