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

    reg [ADDR_WIDTH-1:0]        fifo_addr;
    reg [DATA_WIDTH-1:0]        fifo_wdata;
    reg [DATA_WIDTH/8-1:0]      fifo_wstrb;
    reg [2:0]                   fifo_wprot;
    reg                         fifo_write;
    reg                         fifo_read;
    reg                         fifo_empty;
    reg                         fifo_full;
    reg                         src_pready_int;
    reg                         dst_psel_int;
    reg                         dst_penable_int;
    reg                         dst_pwrite_int;
    reg [ADDR_WIDTH-1:0]        dst_paddr_int;
    reg [DATA_WIDTH-1:0]        dst_pwdata_int;
    reg [DATA_WIDTH/8-1:0]      dst_pstrb_int;
    reg [2:0]                   dst_pprot_int;
    reg                         src_pslverr_int;
    reg [DATA_WIDTH-1:0]        src_prdata_int;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (~src_preset_ni) begin
            src_pready_int <= 1'b0;
            fifo_write <= 1'b0;
        end else if (src_psel_i && src_penable_i) begin
            src_pready_int <= 1'b1;
            fifo_write <= 1'b1;
        end else begin
            src_pready_int <= 1'b0;
            fifo_write <= 1'b0;
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (~src_preset_ni) begin
            fifo_addr <= {ADDR_WIDTH{1'b0}};
            fifo_wdata <= {DATA_WIDTH{1'b0}};
            fifo_wstrb <= {DATA_WIDTH/8{1'b0}};
            fifo_wprot <= 3'b0;
        end else if (fifo_write && ~fifo_full) begin
            fifo_addr <= src_paddr_i;
            fifo_wdata <= src_pwdata_i;
            fifo_wstrb <= src_pstrb_i;
            fifo_wprot <= src_pprot_i;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (~dst_preset_ni) begin
            dst_psel_int <= 1'b0;
            dst_penable_int <= 1'b0;
            dst_pwrite_int <= 1'b0;
            dst_paddr_int <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_int <= {DATA_WIDTH{1'b0}};
            dst_pstrb_int <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_int <= 3'b0;
        end else if (~fifo_empty && ~dst_psel_int) begin
            dst_psel_int <= 1'b1;
            dst_penable_int <= 1'b0;
            dst_pwrite_int <= fifo_wdata[0];
            dst_paddr_int <= fifo_addr;
            dst_pwdata_int <= fifo_wdata;
            dst_pstrb_int <= fifo_wstrb;
            dst_pprot_int <= fifo_wprot;
        end else if (dst_psel_int && ~dst_penable_int && dst_pready_i) begin
            dst_penable_int <= 1'b1;
        end else if (dst_psel_int && dst_penable_int && dst_pready_i) begin
            dst_psel_int <= 1'b0;
            dst_penable_int <= 1'b0;
            fifo_read <= 1'b1;
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (~src_preset_ni) begin
            src_prdata_int <= {DATA_WIDTH{1'b0}};
            src_pslverr_int <= 1'b0;
        end else if (fifo_read) begin
            src_prdata_int <= dst_prdata_i;
            src_pslverr_int <= dst_pslverr_i;
        end
    end

    assign src_pready_o = src_pready_int;
    assign src_prdata_o = src_prdata_int;
    assign src_pslverr_o = src_pslverr_int;
    assign dst_psel_o = dst_psel_int;
    assign dst_penable_o = dst_penable_int;
    assign dst_pwrite_o = dst_pwrite_int;
    assign dst_paddr_o = dst_paddr_int;
    assign dst_pwdata_o = dst_pwdata_int;
    assign dst_pstrb_o = dst_pstrb_int;
    assign dst_pprot_o = dst_pprot_int;

    // FIFO implementation
    reg [LOG_DEPTH-1:0]        fifo_ptr;
    reg [LOG_DEPTH-1:0]        fifo_cnt;
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (~src_preset_ni) begin
            fifo_ptr <= {LOG_DEPTH{1'b0}};
            fifo_cnt <= {LOG_DEPTH{1'b0}};
            fifo_empty <= 1'b1;
            fifo_full <= 1'b0;
        end else if (fifo_write && ~fifo_full) begin
            fifo_ptr <= fifo_ptr + 1'b1;
            fifo_cnt <= fifo_cnt + 1'b1;
            if (fifo_cnt == (1 << LOG_DEPTH) - 1) begin
                fifo_full <= 1'b1;
            end
        end else if (fifo_read && ~fifo_empty) begin
            fifo_ptr <= fifo_ptr - 1'b1;
            fifo_cnt <= fifo_cnt - 1'b1;
            if (fifo_cnt == 1'b0) begin
                fifo_empty <= 1'b1;
            end
        end
    end

    always @(*) begin
        if (fifo_cnt == (1 << LOG_DEPTH)) begin
            fifo_full = 1'b1;
        end else begin
            fifo_full = 1'b0;
        end
        if (fifo_cnt == 0) begin
            fifo_empty = 1'b1;
        end else begin
            fifo_empty = 1'b0;
        end
    end

endmodule
