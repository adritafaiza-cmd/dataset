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

    reg [ADDR_WIDTH-1:0]       src_addr;
    reg [DATA_WIDTH-1:0]       src_wdata;
    reg [DATA_WIDTH/8-1:0]     src_wstrb;
    reg [2:0]                  src_prot;
    reg                        src_write;
    reg                        src_valid;
    reg                        src_ready;
    reg [DATA_WIDTH-1:0]       src_rdata;
    reg                        src_error;

    reg [ADDR_WIDTH-1:0]       dst_addr;
    reg [DATA_WIDTH-1:0]       dst_wdata;
    reg [DATA_WIDTH/8-1:0]     dst_wstrb;
    reg [2:0]                  dst_prot;
    reg                        dst_write;
    reg                        dst_valid;
    reg                        dst_ready;
    reg [DATA_WIDTH-1:0]       dst_rdata;
    reg                        dst_error;

    reg [LOG_DEPTH-1:0]        fifo_ptr;
    reg                        fifo_empty;
    reg                        fifo_full;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_valid <= 1'b0;
            src_addr <= {ADDR_WIDTH{1'b0}};
            src_wdata <= {DATA_WIDTH{1'b0}};
            src_wstrb <= {DATA_WIDTH/8{1'b0}};
            src_prot <= 3'b0;
            src_write <= 1'b0;
            src_ready <= 1'b0;
        end else if (src_psel_i && src_penable_i) begin
            src_valid <= 1'b1;
            src_addr <= src_paddr_i;
            src_wdata <= src_pwdata_i;
            src_wstrb <= src_pstrb_i;
            src_prot <= src_pprot_i;
            src_write <= src_pwrite_i;
        end else if (src_valid && src_ready) begin
            src_valid <= 1'b0;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_valid <= 1'b0;
            dst_addr <= {ADDR_WIDTH{1'b0}};
            dst_wdata <= {DATA_WIDTH{1'b0}};
            dst_wstrb <= {DATA_WIDTH/8{1'b0}};
            dst_prot <= 3'b0;
            dst_write <= 1'b0;
            dst_ready <= 1'b0;
        end else if (dst_valid && dst_pready_i) begin
            dst_valid <= 1'b0;
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_rdata <= {DATA_WIDTH{1'b0}};
            src_error <= 1'b0;
        end else if (src_valid && src_ready) begin
            src_rdata <= dst_rdata;
            src_error <= dst_error;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_rdata <= {DATA_WIDTH{1'b0}};
            dst_error <= 1'b0;
        end else if (dst_valid && dst_pready_i) begin
            dst_rdata <= dst_prdata_i;
            dst_error <= dst_pslverr_i;
        end
    end

    assign src_pready_o = src_ready;
    assign src_prdata_o = src_rdata;
    assign src_pslverr_o = src_error;

    assign dst_psel_o = dst_valid;
    assign dst_penable_o = dst_valid;
    assign dst_pwrite_o = dst_write;
    assign dst_paddr_o = dst_addr;
    assign dst_pwdata_o = dst_wdata;
    assign dst_pstrb_o = dst_wstrb;
    assign dst_pprot_o = dst_prot;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_empty <= 1'b1;
            fifo_full <= 1'b0;
            fifo_ptr <= {LOG_DEPTH{1'b0}};
        end else if (src_valid && !fifo_full) begin
            fifo_empty <= 1'b0;
            fifo_ptr <= fifo_ptr + 1'b1;
            if (fifo_ptr == {LOG_DEPTH{1'b1}}) begin
                fifo_full <= 1'b1;
            end
        end else if (!fifo_empty && dst_valid && dst_pready_i) begin
            fifo_empty <= 1'b1;
            fifo_ptr <= {LOG_DEPTH{1'b0}};
            fifo_full <= 1'b0;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_valid <= 1'b0;
            dst_addr <= {ADDR_WIDTH{1'b0}};
            dst_wdata <= {DATA_WIDTH{1'b0}};
            dst_wstrb <= {DATA_WIDTH/8{1'b0}};
            dst_prot <= 3'b0;
            dst_write <= 1'b0;
        end else if (!fifo_empty && !dst_valid) begin
            dst_valid <= 1'b1;
            dst_addr <= src_addr;
            dst_wdata <= src_wdata;
            dst_wstrb <= src_wstrb;
            dst_prot <= src_prot;
            dst_write <= src_write;
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_ready <= 1'b0;
        end else if (src_valid && !fifo_full) begin
            src_ready <= 1'b1;
        end else if (src_valid && src_ready) begin
            src_ready <= 1'b0;
        end
    end

endmodule
