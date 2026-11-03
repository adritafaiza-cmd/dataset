Sure, here is the complete Verilog-2001 code for the APB clock-domain bridge module:

```
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
    reg [DATA_WIDTH-1:0] src_pwdata_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg [ADDR_WIDTH-1:0] dst_paddr_reg;
    reg src_pwrite_reg;
    reg dst_pwrite_reg;
    reg src_psel_reg;
    reg dst_psel_reg;
    reg src_penable_reg;
    reg dst_penable_reg;
    reg src_pready_reg;
    reg dst_pready_reg;
    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg [DATA_WIDTH-1:0] dst_prdata_reg;
    reg src_pslverr_reg;
    reg dst_pslverr_reg;
    reg [2:0] src_pprot_reg;
    reg [2:0] dst_pprot_reg;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_psel_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_psel_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_penable_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_penable_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_pready_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_pready_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_prdata_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_prdata_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_prdata_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_prdata_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_pwdata_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pwdata_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_pstrb_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pstrb_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_paddr_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_paddr_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_pwrite_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pwrite_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_psel_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_psel_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_penable_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_penable_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_pready_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pready_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] src_prdata_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_prdata_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_prdata_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_prdata_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_pslverr_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pslverr_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] src_pprot_fifo_rd_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_wr_ptr_next;
    reg [LOG_DEPTH-1:0] dst_pprot_fifo_rd_ptr_next;
    reg [DATA_WIDTH-1:0] src_pwdata_fifo [2**LOG_DEPTH-1:0];
    reg [DATA_WIDTH-1:0] dst_pwdata_fifo [2**LOG_DEPTH-1:0];
    reg [DATA_WIDTH/8-1:0] src_pstrb_fifo [2**LOG_DEPTH-1:0];
    reg [DATA_WIDTH/8-1:0] dst_pstrb_fifo [2**LOG_DEPTH-1:0];
    reg [ADDR_WIDTH-1:0] src_paddr_fifo [2**LOG_DEPTH-1:0];
    reg [ADDR_WIDTH-1:0] dst_paddr_fifo [2**LOG_DEPTH-1:0];
    reg src_pwrite_fifo [2**LOG_DEPTH-1:0];
    reg dst_pwrite_fifo [2**LOG_DEPTH-1:0];
    reg src_psel_fifo [2**LOG_DEPTH-1:0];
    reg dst_psel_fifo [2**LOG_DEPTH-1:0];
    reg src_penable_fifo [2**LOG_DEPTH-1:0];
    reg dst_penable_fifo [2**LOG_DEPTH-1:0];
    reg src_pready_fifo [2**LOG_DEPTH-1:0];
    reg dst_pready_fifo [2**LOG_DEPTH-1:0];
    reg [DATA_WIDTH-1:0] src_prdata_fifo [2**LOG_DEPTH-1:0];
    reg [DATA_WIDTH-1:0] dst_prdata_fifo [2**LOG_DEPTH-1:0];
    reg src_pslverr_fifo [2**LOG_DEPTH-1:0];
    reg dst_pslverr_fifo [2**LOG_DEPTH-1:0];
    reg [2:0] src_pprot_fifo [2**LOG_DEPTH-1:0];
    reg [2:0] dst_pprot_fifo [2**LOG_DEPTH-1:0];

    // FIFO write pointers
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 0) begin
            src_pwdata_fifo_wr_ptr <= 0;
            src_pwdata_fifo_rd_ptr <= 0;
            src_pstrb_fifo_wr_ptr <= 0;
            src_pstrb_fifo_rd_ptr <= 0;
            src_paddr_fifo_wr_ptr <= 0;
            src_paddr_fifo_rd_ptr <= 0;
            src_pwrite_fifo_wr_ptr <= 0;
            src_pwrite_fifo_rd_ptr <= 0;
            src_psel_fifo_wr_ptr <= 0;
            src_psel_fifo_rd_ptr <= 0;
            src_penable_fifo_wr_ptr <= 0;
            src_penable_fifo_rd_ptr <= 0;
            src_pready_fifo_wr_ptr <= 0;
            src_pready_fifo_rd_ptr <= 0;
            src_prdata_fifo_wr_ptr <= 0;
            src_prdata_fifo_rd_ptr <= 0;
            src_pslverr_fifo_wr_ptr <= 0;
            src_pslverr_fifo_rd_ptr <= 0;
            src_pprot_fifo_wr_ptr <= 0;
            src_pprot_fifo_rd_ptr <= 0;
        end else begin
            src_pwdata_fifo_wr_ptr <= src_pwdata_fifo_wr_ptr_next;
            src_pwdata_fifo_rd_ptr <= src_pwdata_fifo_rd_ptr_next;
            src_pstrb_fifo_wr_ptr <= src_pstrb_fifo_wr_ptr_next;
            src_pstrb_fifo_rd_ptr <= src_pstrb_fifo_rd_ptr_next;
            src_paddr_fifo_wr_ptr <= src_paddr_fifo_wr_ptr_next;
            src_paddr_fifo_rd_ptr <= src_paddr_fifo_rd_ptr_next;
            src_pwrite_fifo_wr_ptr <= src_pwrite_fifo_wr_ptr_next;
            src_pwrite_fifo_rd_ptr <= src_pwrite_fifo_rd_ptr_next;
            src_psel_fifo_wr_ptr <= src_psel_fifo_wr_ptr_next;
            src_psel_fifo_rd_ptr <= src_psel_fifo_rd_ptr_next;
            src_penable_fifo_wr_ptr <= src_penable_fifo_wr_ptr_next;
            src_penable_fifo_rd_ptr <= src_penable_fifo_rd_ptr_next;
            src_pready_fifo_wr_ptr <= src_pready_fifo_wr_ptr_next;
            src_pready_fifo_rd_ptr <= src_pready_fifo_rd_ptr_next;
            src_prdata_fifo_wr_ptr <= src_prdata_fifo_wr_ptr_next;
            src_prdata_fifo_rd_ptr <= src_prdata_fifo_rd_ptr_next;
            src_pslverr_fifo_wr_ptr <= src_pslverr_fifo_wr_ptr_next;
            src_pslverr_fifo_rd_ptr <= src_pslverr_fifo_rd_ptr_next;
            src_pprot_fifo_wr_ptr <= src_pprot_fifo_wr_ptr_next;
            src_pprot_fifo_rd_ptr <= src_pprot_fifo_rd_ptr_next;
        end
    end

    always @(posedge dst_pclk_i) begin
        if (dst_preset_ni == 0) begin
            dst_pwdata_fifo_wr_ptr <= 0;
            dst_pwdata_fifo_rd_ptr <= 0;
            dst_pstrb_fifo_wr_ptr <= 0;
            dst_pstrb_fifo_rd_ptr <= 0;
            dst_paddr_fifo_wr_ptr <= 0;
            dst_paddr_fifo_rd_ptr <= 0;
            dst_pwrite_fifo_wr_ptr <= 0;
            dst_pwrite_fifo_rd_ptr <= 0;
            dst_psel_fifo_wr_ptr <= 0;
            dst_psel_fifo_rd_ptr <= 0;
            dst_penable_fifo_wr_ptr <= 0;
            dst_penable_fifo_rd_ptr <= 0;
            dst_pready_fifo_wr_ptr <= 0;
            dst_pready_fifo_rd_ptr <= 0;
            dst_prdata_fifo_wr_ptr <= 0;
            dst_prdata_fifo_rd_ptr <= 0;
            dst_pslverr_fifo_wr_ptr <= 0;
            dst_pslverr_fifo_rd_ptr <= 0;
            dst_pprot_fifo_wr_ptr <= 0;
            dst_pprot_fifo_rd_ptr <= 0;
        end else begin
            dst_pwdata_fifo_wr_ptr <= dst_pwdata_fifo_wr_ptr_next;
            dst_pwdata_fifo_rd_ptr <= dst_pwdata_fifo_rd_ptr_next;
            dst_pstrb_fifo_wr_ptr <= dst_pstrb_fifo_wr_ptr_next;
            dst_pstrb_fifo_rd_ptr <= dst_pstrb_fifo_rd_ptr_next;
            dst_paddr_fifo_wr_ptr <= dst_paddr_fifo_wr_ptr_next;
            dst_paddr_fifo_rd_ptr <= dst_paddr_fifo_rd_ptr_next;
            dst_pwrite_fifo_wr_ptr <= dst_pwrite_fifo_wr_ptr_next;
            dst_pwrite_fifo_rd_ptr <= dst_pwrite_fifo_rd_ptr_next;
            dst_psel_fifo_wr_ptr <= dst_psel_fifo_wr_ptr_next;
            dst_psel_fifo_rd_ptr <= dst_psel_fifo_rd_ptr_next;
            dst_penable_fifo_wr_ptr <= dst_penable_fifo_wr_ptr_next;
            dst_penable_fifo_rd_ptr <= dst_penable_fifo_rd_ptr_next;
            dst_pready_fifo_wr_ptr <= dst_pready_fifo_wr_ptr_next;
            dst_pready_fifo_rd_ptr <= dst_pready_fifo_rd_ptr_next;
            dst_prdata_fifo_wr_ptr <= dst_prdata_fifo_wr_ptr_next;
            dst_prdata_fifo_rd_ptr <= dst_prdata_fifo_rd_ptr_next;
            dst_pslverr_fifo_wr_ptr <= dst_pslverr_fifo_wr_ptr_next;
            dst_pslverr_fifo_rd_ptr <= dst_pslverr_fifo_rd_ptr_next;
            dst_pprot_fifo_wr_ptr <= dst_pprot_fifo_wr_ptr_next;
            dst_pprot_fifo_rd_ptr <= dst_pprot_fifo_rd_ptr_next;
        end
    end

    // FIFO read pointers
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 0) begin
            src_pwdata_fifo_rd_ptr_next <= 0;
            src_pstrb_fifo_rd_ptr_next <= 0;
            src_paddr_fifo_rd_ptr_next <= 0;
            src_pwrite_fifo_rd_ptr_next <= 0;
            src_psel_fifo_rd_ptr_next <= 0;
            src_penable_fifo_rd_ptr_next <= 0;
            src_pready_fifo_rd_ptr_next <= 0;
            src_prdata_fifo_rd_ptr_next <= 0;
            src_pslverr_fifo_rd_ptr_next <= 0;
            src_pprot_fifo_rd_ptr_next <= 0;
        end else begin
            src_pwdata_fifo_rd_ptr_next <= src_pwdata_fifo_rd_ptr + 1;
            src_pstrb_fifo_rd_ptr_next <= src_pstrb_fifo_rd_ptr + 1;
            src_paddr_fifo_rd_ptr_next <= src_paddr_fifo_rd_ptr + 1;
            src_pwrite_fifo_rd_ptr_next <= src_pwrite_fifo_rd_ptr + 1;
            src_psel_fifo_rd_ptr_next <= src_psel_fifo_rd_ptr + 1;
            src_penable_fifo_rd_ptr_next <= src_penable_fifo_rd_ptr + 1;
            src_pready_fifo_rd_ptr_next <= src_pready_fifo_rd_ptr + 1;
            src_prdata_fifo_rd_ptr_next <= src_prdata_fifo_rd_ptr + 1;
            src_pslverr_fifo_rd_ptr_next <= src_pslverr_fifo_rd_ptr + 1;
            src_pprot_fifo_rd_ptr_next <= src_pprot_fifo_rd_ptr + 1;
        end
    end

    always @(posedge dst_pclk_i) begin
        if (dst_preset_ni == 0) begin
            dst_pwdata_fifo_rd_ptr_next <= 0;
            dst_pstrb_fifo_rd_ptr_next <= 0;
            dst_paddr_fifo_rd_ptr_next <= 0;
            dst_pwrite_fifo_rd_ptr_next <= 0;
            dst_psel_fifo_rd_ptr_next <= 0;
            dst_penable_fifo_rd_ptr_next <= 0;
            dst_pready_fifo_rd_ptr_next <= 0;
            dst_prdata_fifo_rd_ptr_next <= 0;
            dst_pslverr_fifo_rd_ptr_next <= 0;
            dst_pprot_fifo_rd_ptr_next <= 0;
        end else begin
            dst_pwdata_fifo_rd_ptr_next <= dst_pwdata_fifo_rd_ptr + 1;
            dst_pstrb_fifo_rd_ptr_next <= dst_pstrb_fifo_rd_ptr + 1;
            dst_paddr_fifo_rd_ptr_next <= dst_paddr_fifo_rd_ptr + 1;
            dst_pwrite_fifo_rd_ptr_next <= dst_pwrite_fifo_rd_ptr + 1;
            dst_psel_fifo_rd_ptr_next <= dst_psel_fifo_rd_ptr + 1;
            dst_penable_fifo_rd_ptr_next <= dst_penable_fifo_rd_ptr + 1;
            dst_pready_fifo_rd_ptr_next <= dst_pready_fifo_rd_ptr + 1;
            dst_prdata_fifo_rd_ptr_next <= dst_prdata_fifo_rd_ptr + 1;
            dst_pslverr_fifo_rd_ptr_next <= dst_pslverr_fifo_rd_ptr + 1;
            dst_pprot_fifo_rd_ptr_next <= dst_pprot_fifo_rd_ptr + 1;
        end
    end

    // FIFO write data
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 0) begin
            src_pwdata_fifo[0] <= 0;
            src_pstrb_fifo[0] <= 0;
            src_paddr_fifo[0] <= 0;
            src_pwrite_fifo[0] <= 0;
            src_psel_fifo[0] <= 0;
            src_penable_fifo[0] <= 0;
            src_pready_fifo[0] <= 0;
            src_prdata_fifo[0] <= 0;
            src_pslverr_fifo[0] <= 0;
            src_pprot_fifo[0] <= 0;
        end else begin
            src_pwdata_fifo[src_pwdata_fifo_wr_ptr] <= src_pwdata_i;
            src_pstrb_fifo[src_pstrb_fifo_wr_ptr] <= src_pstrb_i;
            src_paddr_fifo[src_paddr_fifo_wr_ptr] <= src_paddr_i;
            src_pwrite_fifo[src_pwrite_fifo_wr_ptr] <= src_pwrite_i;
            src_psel_fifo[src_psel_fifo_wr_ptr] <= src_psel_i;
            src_penable_fifo[src_penable_fifo_wr_ptr] <= src_penable_i;
            src_pready_fifo[src_pready_fifo_wr_ptr] <= src_pready_o;
            src_prdata_fifo[src_prdata_fifo_wr_ptr] <= src_prdata_o;
            src_pslverr_fifo[src_pslverr_fifo_wr_ptr] <= src_pslverr_o;
            src_pprot_fifo[src_pprot_fifo_wr_ptr] <= src_pprot_i;
        end
    end

    always @(posedge dst_pclk_i) begin
        if (dst_preset_ni == 0) begin
            dst_pwdata_fifo[0] <= 0;
            dst_pstrb_fifo[0] <= 0;
            dst_paddr_fifo[0] <= 0;
            dst_pwrite_fifo[0] <= 0;
            dst_psel_fifo[0] <= 0;
            dst_penable_fifo[0] <= 0;
            dst_pready_fifo[0] <= 0;
            dst_prdata_fifo[0] <= 0;
            dst_pslverr_fifo[0] <= 0;
            dst_pprot_fifo[0] <= 0;
        end else begin
            dst_pwdata_fifo[dst_pwdata_fifo_wr_ptr] <= dst_pwdata_reg;
            dst_pstrb_fifo[dst_pstrb_fifo_wr_ptr] <= dst_pstrb_reg;
            dst_paddr_fifo[dst_paddr_fifo_wr_ptr] <= dst_paddr_reg;
            dst_pwrite_fifo[dst_pwrite_fifo_wr_ptr] <= dst_pwrite_reg;
            dst_psel_fifo[dst_psel_fifo_wr_ptr] <= dst_psel_reg;
            dst_penable_fifo[dst_penable_fifo_wr_ptr] <= dst_penable_reg;
            dst_pready_fifo[dst_pready_fifo_wr_ptr] <= dst_pready_reg;
            dst_prdata_fifo[dst_prdata_fifo_wr_ptr] <= dst_prdata_reg;
            dst_pslverr_fifo[dst_pslverr_fifo_wr_ptr] <= dst_pslverr_reg;
            dst_pprot_fifo[dst_pprot_fifo_wr_ptr] <= dst_pprot_reg;
        end
    end

    // FIFO write pointers
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 0) begin
            src_pwdata_fifo_wr_ptr_next <= 0;
            src_pstrb_fifo_wr_ptr_next <= 0;
            src_paddr_fifo_wr_ptr_next <= 0;
            src_pwrite_fifo_wr_ptr_next <= 0;
            src_psel_